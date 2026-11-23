#!/usr/bin/env bash
# Usage: scripts/project-context.sh [branch] [output-file]
set -euo pipefail

repo_root="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
cd "$repo_root"

branch="${1:-$(git rev-parse --abbrev-ref HEAD)}"
base="${BASE_BRANCH:-master}"
repo_name="$(basename "$repo_root")"
out="${2:-$HOME/claude-context/${repo_name}-${branch//\//-}.md}"
mkdir -p "$(dirname "$out")"

git fetch --quiet origin 2>/dev/null || echo "warning: git fetch failed, using local refs" >&2

if git rev-parse --verify --quiet "$branch^{commit}" >/dev/null; then
  ref="$branch"
elif git rev-parse --verify --quiet "origin/$branch^{commit}" >/dev/null; then
  ref="origin/$branch"
else
  echo "branch not found: $branch" >&2
  exit 1
fi

remote="$(git remote get-url origin 2>/dev/null || echo '')"
web_url="$(sed -E 's#^git@([^:]+):#https://\1/#; s#\.git$##' <<<"$remote")"

lang_for() {
  case "$1" in
    *.cs) echo csharp ;;
    *.csproj|*.slnx|*.xml|*.DotSettings*) echo xml ;;
    *.json) echo json ;;
    *.yaml|*.yml) echo yaml ;;
    *.rest|*.http) echo http ;;
    *.sh) echo bash ;;
    *.md) echo markdown ;;
    *) echo "" ;;
  esac
}

{
  echo "# ${repo_name} — контекст ветки \`${branch}\`"
  echo
  echo "- Репозиторий: ${web_url:-$remote}"
  echo "- Ветка: \`${branch}\` (${web_url:+${web_url}/tree/${branch}})"
  echo "- Базовая ветка: \`${base}\`"
  echo "- Коммит: \`$(git rev-parse --short "$ref")\` — $(git log -1 --format='%s (%ci)' "$ref")"
  echo "- Собрано: $(date '+%Y-%m-%d %H:%M %z')"

  if git rev-parse --verify --quiet "origin/$branch" >/dev/null && [ "$ref" = "$branch" ]; then
    read -r behind ahead < <(git rev-list --left-right --count "origin/$branch...$branch")
    echo "- Относительно origin/${branch}: впереди ${ahead}, позади ${behind}"
  fi

  if git cat-file -e "$ref:PROJECT.md" 2>/dev/null; then
    echo
    git show "$ref:PROJECT.md" | sed -E 's/^#/##/'
  elif [ -f PROJECT.md ]; then
    echo
    sed -E 's/^#/##/' PROJECT.md
  fi

  echo
  echo "## Коммиты ветки относительно \`${base}\`"
  echo
  echo '```'
  git log --format='%h %ad %s' --date=short "${base}..${ref}" || true
  echo '```'
  echo
  echo "## Изменённые файлы относительно \`${base}\`"
  echo
  echo '```'
  git diff --stat "${base}...${ref}" || true
  echo '```'

  current="$(git rev-parse --abbrev-ref HEAD)"
  if [ "$current" = "$branch" ] && [ -n "$(git status --porcelain)" ]; then
    echo
    echo "## Незакоммиченные изменения (рабочая копия)"
    echo
    echo '```'
    git status --short
    echo '```'
    echo
    echo '```diff'
    git diff HEAD
    echo '```'
  fi

  echo
  echo "## Структура"
  echo
  echo '```'
  git ls-tree -r --name-only "$ref"
  echo '```'
  echo
  echo "## Исходники (состояние коммита \`$(git rev-parse --short "$ref")\`)"

  git ls-tree -r --name-only "$ref" | while read -r f; do
    case "$f" in
      PROJECT.md|*.user|.idea/*|*.png|*.jpg|*.ico|*.dll|*.exe) continue ;;
    esac
    echo
    echo "### \`$f\`"
    echo
    echo "\`\`\`$(lang_for "$f")"
    git show "$ref:$f"
    echo '```'
  done
} >"$out"

echo "$out"
