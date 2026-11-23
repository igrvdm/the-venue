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

resolve_ref() {
  if git rev-parse --verify --quiet "$1^{commit}" >/dev/null; then
    echo "$1"
  elif git rev-parse --verify --quiet "origin/$1^{commit}" >/dev/null; then
    echo "origin/$1"
  fi
}

ref="$(resolve_ref "$branch")"
[ -n "$ref" ] || { echo "branch not found: $branch" >&2; exit 1; }

if git rev-parse --verify --quiet "origin/$base^{commit}" >/dev/null; then
  base_ref="origin/$base"
else
  base_ref="$(resolve_ref "$base")"
  [ -n "$base_ref" ] || { echo "base branch not found: $base" >&2; exit 1; }
fi

current="$(git rev-parse --abbrev-ref HEAD)"
is_current=false
[ "$current" = "$branch" ] && is_current=true

remote="$(git remote get-url origin 2>/dev/null || echo '')"
web_url="$(sed -E 's#://[^@/]+@#://#; s#^ssh://([^/:]+)(:[0-9]+)?/#https://\1/#; s#^[^@/:]+@([^:]+):#https://\1/#; s#\.git$##' <<<"$remote")"

is_excluded() {
  case "$1" in
    PROJECT.md|*.user|.idea/*|.vs/*) return 0 ;;
    .env|.env.*|*/.env|*/.env.*) return 0 ;;
    *.pfx|*.p12|*.pem|*.key|*.snk|*.jks|*.keystore|*.crt|*.cer) return 0 ;;
    *secrets*.json|*credentials*|appsettings.Production*.json|*/appsettings.Production*.json|appsettings.Staging*.json|*/appsettings.Staging*.json) return 0 ;;
  esac
  return 1
}

secret_pathspecs=(
  ':(exclude,glob)**/.env' ':(exclude,glob)**/.env.*'
  ':(exclude,glob)**/*.pfx' ':(exclude,glob)**/*.p12' ':(exclude,glob)**/*.pem'
  ':(exclude,glob)**/*.key' ':(exclude,glob)**/*.snk'
  ':(exclude,glob)**/*secrets*.json' ':(exclude,glob)**/*credentials*'
  ':(exclude,glob)**/appsettings.Production*.json' ':(exclude,glob)**/appsettings.Staging*.json'
)

lang_for() {
  case "$1" in
    *.cs) echo csharp ;;
    *.csproj|*.slnx|*.xml|*.props|*.targets|*.DotSettings*) echo xml ;;
    *.json) echo json ;;
    *.yaml|*.yml) echo yaml ;;
    *.rest|*.http) echo http ;;
    *.sh) echo bash ;;
    *.sql) echo sql ;;
    *.md) echo markdown ;;
    Dockerfile|*/Dockerfile) echo dockerfile ;;
    *) echo "" ;;
  esac
}

{
  echo "# ${repo_name} — контекст ветки \`${branch}\`"
  echo
  echo "- Репозиторий: ${web_url}"
  echo "- Ветка: \`${branch}\`${web_url:+ (${web_url}/tree/${branch})}"
  echo "- Базовая ветка: \`${base_ref}\`"
  echo "- Коммит: \`$(git rev-parse --short "$ref")\` — $(git log -1 --format='%s (%ci)' "$ref")"
  echo "- Собрано: $(date '+%Y-%m-%d %H:%M %z')"

  if [ "$ref" = "$branch" ] && git rev-parse --verify --quiet "origin/$branch" >/dev/null; then
    read -r behind ahead < <(git rev-list --left-right --count "origin/$branch...$branch")
    echo "- Относительно origin/${branch}: впереди ${ahead}, позади ${behind}"
  fi

  if $is_current && [ -f PROJECT.md ]; then
    echo
    sed -E 's/^#/##/' PROJECT.md
  elif git cat-file -e "$ref:PROJECT.md" 2>/dev/null; then
    echo
    git show "$ref:PROJECT.md" | sed -E 's/^#/##/'
  fi

  echo
  echo "## Коммиты ветки относительно \`${base_ref}\`"
  echo
  echo '```'
  git log --format='%h %ad %s' --date=short "${base_ref}..${ref}"
  echo '```'
  echo
  echo "## Изменённые файлы относительно \`${base_ref}\`"
  echo
  echo '```'
  git diff --stat "${base_ref}...${ref}"
  echo '```'

  if $is_current && [ -n "$(git status --porcelain)" ]; then
    echo
    echo "## Незакоммиченные изменения (рабочая копия)"
    echo
    echo '```'
    git status --short
    echo '```'
    echo
    echo '```diff'
    git diff HEAD -- . "${secret_pathspecs[@]}"
    echo '```'
  fi

  echo
  echo "## Структура"
  echo
  echo '```'
  git -c core.quotepath=off ls-tree -r --name-only "$ref"
  echo '```'
  echo
  echo "## Исходники (состояние коммита \`$(git rev-parse --short "$ref")\`)"

  git ls-tree -r -z "$ref" | while IFS=$'\t' read -r -d '' meta f; do
    read -r _ type blob <<<"$meta"
    [ "$type" = blob ] || continue
    is_excluded "$f" && continue
    git cat-file blob "$blob" | grep -cI '' >/dev/null || continue
    echo
    echo "### \`$f\`"
    echo
    echo "\`\`\`$(lang_for "$f")"
    git cat-file blob "$blob"
    echo '```'
  done
} >"$out"

echo "$out"
