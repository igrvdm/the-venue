# План обучения: современный .NET на проекте The Venue

Цель и контекст — в `PROJECT.md`. Проект таргетит `net10.0` (LTS), локально установлен SDK 11.

## Как устроен план

Каждый блок состоит из четырёх частей:

- **Теория** — что изучить. Отмечено, что изменилось со времён .NET Framework (⟲) и с чем это сравнить из Scala (≈).
- **В проекте** — что сделать в коде The Venue. Задачи привязаны к реальному коду и к находкам ревью (R1–R9 из `~/claude-context/reviews/the-venue-admin-api.md`).
- **Юнит-тесты** — какие тест-кейсы реализовать. Даны поведение и ожидаемый результат, код пишется самостоятельно.
- **Готово, когда** — критерий завершения блока.

Блоки идут по порядку: каждый опирается на предыдущие. Блоки 0–1 — фундамент, без них тесты в остальных негде писать. После каждого блока — `/code-review` и обновление файла ревью.

Структура тестовых проектов, к которой придём:

```
tests/
  TheVenue.Domain.Tests/         юнит-тесты домена
  TheVenue.AdminApi.Tests/       юнит-тесты обработчиков, валидации, сервисов
  TheVenue.Api.Tests/            юнит-тесты публичного API
  TheVenue.IntegrationTests/     WebApplicationFactory + Testcontainers (блок 9)
```

---

## Блок 0. Платформа, сборка, структура решения

### Теория
- ⟲ .NET Framework → .NET Core → .NET 5+: одна платформа, кроссплатформенность, ежегодные релизы (чётные — LTS, нечётные — STS), `TargetFramework` вроде `net10.0` вместо `v4.x`.
- SDK-style `.csproj`: файлы подхватываются по глобу, нет `packages.config`, `PackageReference` прямо в проекте. ⟲ Сравните с огромными `.csproj` из Framework.
- `dotnet` CLI: `new`, `build`, `run`, `test`, `add package`, `sln`, `format`, `watch`. Формат решения `.slnx` (у вас уже он).
- `global.json` — фиксация версии SDK. ≈ `project/build.properties` с версией sbt.
- `Directory.Build.props` / `Directory.Build.targets` — общие настройки для всех проектов. ≈ `ThisBuild / settings` и общие `settings` в `build.sbt`.
- Central Package Management (`Directory.Packages.props`, `ManagePackageVersionsCentrally`). ≈ `Dependencies.scala`.
- Анализаторы Roslyn, `AnalysisLevel`, `TreatWarningsAsErrors`, `.editorconfig` как источник правил стиля и severity. ≈ scalafmt + scalafix + `-Xfatal-warnings`.
- `ImplicitUsings`, `Nullable` — что они включают на уровне компилятора.

Документация: learn.microsoft.com → .NET → «SDK-style projects», «Central Package Management», «Code analysis overview».

### В проекте
1. Добавить `global.json` с версией SDK и `rollForward`. Осознанно решить: остаёмся на `net10.0` (LTS) или переходим на `net11.0`.
2. Вынести общие свойства (`TargetFramework`, `Nullable`, `ImplicitUsings`, `TreatWarningsAsErrors`, `AnalysisLevel`) в `Directory.Build.props`, убрать дубли из трёх `.csproj`.
3. Перевести версии пакетов в `Directory.Packages.props`.
4. Добавить `.editorconfig`: правила стиля C#, severity для неиспользуемых `using` (IDE0005) — это закроет R9 и не даст ему вернуться.
5. Удалить из git `TheVenue.sln.DotSettings.user` и `.idea`, если они отслеживаются, дополнить `.gitignore`.
6. Привести в порядок `src/TheVenue.Api/Program.cs` (лишние пустые строки и отступы — `dotnet format`).

### Юнит-тесты
Тестов ещё нет — проверка через сборку:
- `dotnet build` проходит с `TreatWarningsAsErrors`.
- `dotnet format --verify-no-changes` проходит.
- Специально добавленный неиспользуемый `using` ломает сборку (проверить и откатить).

### Готово, когда
Все проекты собираются одной командой, настройки в одном месте, предупреждения — ошибки, R9 закрыт.

---

## Блок 1. Тестирование в .NET

### Теория
- xUnit v3: `[Fact]`, `[Theory]` + `[InlineData]` / `[MemberData]` / `TheoryData<T>`, жизненный цикл (новый экземпляр класса на каждый тест, конструктор и `IDisposable` / `IAsyncLifetime`), фикстуры `IClassFixture<T>`, `ICollectionFixture<T>`, `ITestOutputHelper`, `TestContext.Current.CancellationToken`.
- Microsoft.Testing.Platform против VSTest — как запускаются тесты и почему тестовый проект теперь — исполняемый файл.
- Ассерты: встроенные `Assert` xUnit; Shouldly; AwesomeAssertions. ⚠ FluentAssertions с версии 8 платный для коммерческого использования — в старых примерах он везде.
- Тестовые двойники: NSubstitute (рекомендуется), Moq (⚠ история со SponsorLink в 2023). Ручные фейки часто лучше моков. ≈ В Scala вы скорее писали фейковую реализацию трейта — в .NET это тоже нормально.
- Property-based тестирование: FsCheck или CsCheck. ≈ ScalaCheck.
- Покрытие: `Microsoft.Testing.Extensions.CodeCoverage` или coverlet.
- Конвенции: проект `<Проект>.Tests`, имена `Метод_Условие_Результат`, Arrange/Act/Assert.

≈ munit / weaver: `test("...")` ↔ `[Fact]`; параметризованные тесты ↔ `[Theory]`.

### В проекте
1. Создать `tests/TheVenue.Domain.Tests` и `tests/TheVenue.AdminApi.Tests` на xUnit v3, добавить в `.slnx`.
2. Выбрать библиотеку ассертов и библиотеку фейков, зафиксировать в `Directory.Packages.props`.
3. Настроить сбор покрытия и запуск `dotnet test` из корня.

### Юнит-тесты
На существующем коде, чтобы освоить инструменты:
- `ZoneId`, `TableNumber`, `TableCapacity`: два экземпляра с одинаковым значением равны, с разными — не равны, `GetHashCode` совпадает у равных (`[Theory]` с `InlineData`).
- `Converters.ToZone`: запрос с наборами `{3×4, 2×5}` даёт 5 столов с номерами 1..5, первые три вместимостью 4, остальные — 5.
- `Converters.ToZone`: пустой список наборов даёт зону без столов (фиксирует текущее поведение — в блоке 2 тест поменяется).
- `Converters.ToResponse`: номера и вместимость столов переносятся в `ZoneTableResponse` один к одному.
- Тест, который **документирует баг** R2: отрицательный `Amount` бросает `ArgumentOutOfRangeException`. После блока 4 он заменится на тест правильного поведения.

### Готово, когда
`dotnet test` из корня запускает тесты обоих проектов, виден отчёт покрытия.

---

## Блок 2. Современный C# для доменной модели

### Теория
- ⟲ `record` / `record struct`, value equality, `with`-выражения, `init`, `required`, primary constructors (C# 12), collection expressions (C# 12), `field`-ключевое слово и extension members (C# 14).
- ⟲ Nullable reference types: аннотации, flow analysis, `!`, атрибуты `[NotNullWhen]` и др. Это проверка компилятора, а не рантайма — важно для блока 4.
- Pattern matching: switch expressions, property / list / relational patterns.
- Как выразить ADT: sealed-иерархия record'ов + switch expression; полноты проверки, как у `sealed trait`, нет — компилятор предупреждает только частично. ≈ `sealed trait` + `case class`. Следите за предложением unions в C#.
- Равенство record'ов и коллекции: record сравнивает поля через `EqualityComparer<T>.Default`, то есть коллекции — по ссылке.
- Неизменяемые коллекции: `IReadOnlyList` / `IReadOnlyDictionary` (только интерфейс), `ImmutableArray` / `ImmutableDictionary`, `FrozenDictionary` (.NET 8). ≈ `Vector` / `Map` из Scala, но с другими компромиссами.
- Умные конструкторы и инварианты: приватный конструктор + статическая фабрика; ошибки — исключения или Result. В .NET принято: исключения — для нарушения контракта, Result (свой тип или библиотека) — для ожидаемых бизнес-ошибок. ≈ `Either[DomainError, A]`; честно сравните, где Result в C# неудобен без for-comprehension.
- Strongly-typed ids как `readonly record struct`. Ловушка: `default(ZoneId)` — это `Guid.Empty`, конструктор по умолчанию обойти нельзя.

### В проекте
1. R7: `Zone.Tables` сделать неизменяемым и решить, как должно работать равенство зон (по содержимому или только по `Id` — как для сущности).
2. Инварианты value objects: `TableCapacity` > 0, `TableNumber` > 0, `ZoneName` не пустое и с ограничением длины. Через фабрики, которые нельзя обойти.
3. Перенести создание зоны из наборов столов в домен (фабрика зоны принимает наборы `количество × вместимость`), оставить в `Converters` только маппинг контракта.
4. Решить модель ошибок домена (исключения или Result) и записать решение в `docs/` с аргументами.
5. Ограничения на количество столов в наборе и в зоне (R5) — как инвариант домена.

### Юнит-тесты
`TheVenue.Domain.Tests`:
- `TableCapacity`: 0 и отрицательные значения отклоняются; 1 и типичные значения принимаются (`[Theory]`).
- `ZoneName`: пустая строка, пробелы, `null`, слишком длинная строка отклоняются; имя обрезается по пробелам, если вы так решили.
- Фабрика зоны: наборы `{3×4, 2×5}` → 5 столов, номера 1..5 подряд без пропусков, вместимость по наборам.
- Фабрика зоны: пустой список наборов отклоняется.
- Фабрика зоны: набор с количеством 0 отклоняется (или пропускается — зафиксируйте решение тестом).
- Фабрика зоны: превышение лимита на набор и на зону отклоняется, ровно лимит принимается (граничные значения).
- Равенство зон: две зоны с одинаковыми данными равны (или не равны, если равенство по `Id`) — тест фиксирует выбранную семантику.
- `with`-копия зоны не позволяет изменить столы оригинала.
- `default(ZoneId)` / `Guid.Empty` отклоняется там, где id обязателен.
- Property-based: для любого непустого списка корректных наборов число столов равно сумме количеств, номера — ровно `1..N`.

### Готово, когда
Невалидную зону нельзя создать в обход фабрики, R5 и R7 закрыты на уровне домена.

---

## Блок 3. Minimal API в деталях

### Теория
- ⟲ Вместо Web API 2 / MVC-контроллеров и `System.Web` — Kestrel, middleware-пайплайн, Minimal API.
- Маршрутизация: шаблоны, ограничения (`:guid`, `:int`, `:min()`), `MapGroup` для общих префиксов и метаданных.
- Привязка параметров: route → query → header → body → DI-сервисы, `[FromRoute]` / `[FromBody]` / `[AsParameters]`, `HttpContext`, `CancellationToken`. Причина R1 — именно здесь.
- `Results` против `TypedResults`, возвращаемый тип `Results<Created<T>, NotFound, ValidationProblem>` — даёт и тестируемость, и корректный OpenAPI.
- Обработчики как статические методы вместо лямбд — ради тестов и читаемости.
- Ошибки: `AddProblemDetails`, `IExceptionHandler`, `UseExceptionHandler`, `UseStatusCodePages`, RFC 9457.
- Endpoint filters (`IEndpointFilter`) — сквозная логика на уровне эндпоинта. ≈ tapir server interceptors; middleware ≈ http4s middleware.
- ≈ В tapir эндпоинт — это значение с описанием входов и выходов, а сервер — интерпретация. В Minimal API описание и обработчик слиты, OpenAPI выводится из сигнатуры и метаданных. Обсудите плюсы и минусы.

### В проекте
1. R1: исправить маршрут DELETE.
2. R6: ответ POST — контракт с id как Guid.
3. Сгруппировать эндпоинты зон через `MapGroup("/admin/venues/{venueId:guid}/zones")`.
4. Перевести обработчики в статические методы с `TypedResults` и явными `Results<...>`.
5. DELETE несуществующей зоны → 404, GET зон несуществующей площадки → 404 (сервису понадобится сообщать «не найдено»).
6. Подключить `AddProblemDetails` и `IExceptionHandler`, который превращает доменные ошибки из блока 2 в 400 / 404 / 409 с ProblemDetails.
7. R8: `UseHttpsRedirection` — решить для dev-профиля.

### Юнит-тесты
`TheVenue.AdminApi.Tests` — обработчики вызываются напрямую, без HTTP, с фейковым сервисом:
- GET: сервис вернул две зоны → результат `Ok<...>` с двумя элементами, поля смаплены.
- GET: площадка не найдена → `NotFound`.
- POST: корректный запрос → `Created<...>`, `Location` = `/admin/venues/{venueId}/zones/{zoneId}`, тело содержит тот же id.
- POST: в сервис передана зона с ожидаемыми столами (проверка через фейк, а не мок «был вызван»).
- DELETE: существующая зона → `NoContent`; несуществующая → `NotFound`.
- `IExceptionHandler`: каждое доменное исключение (или ошибка Result) → правильный статус и `type` / `title` в ProblemDetails (`[Theory]` по типам ошибок).
- Привязку маршрута (R1) юнит-тестом не поймать — отметьте, что её проверит интеграционный тест в блоке 9.

### Готово, когда
R1, R6, R8 закрыты, все обработчики покрыты юнит-тестами через `TypedResults`.

---

## Блок 4. JSON и валидация на границе API

### Теория
- System.Text.Json: ⟲ замена Newtonsoft.Json; `JsonSerializerOptions`, naming policies, `JsonStringEnumConverter`, `RespectNullableAnnotations` и `RespectRequiredConstructorParameters` (.NET 9), `UnmappedMemberHandling`, source generation (`JsonSerializerContext`) — нужна для AOT.
- Как настроить JSON для Minimal API (`ConfigureHttpJsonOptions`).
- Валидация: встроенная валидация Minimal API в .NET 10 (`AddValidation()` + DataAnnotations на контрактах), `IValidatableObject`, FluentValidation как альтернатива, `Results.ValidationProblem`.
- Где что проверять: формат и обязательность — на границе (контракт), бизнес-инварианты — в домене (блок 2). Не дублировать, а разделить ответственность.
- ≈ В tapir / circe некорректный JSON и отсутствующие поля отсекаются декодером, `Option` явный. В C# `string` без `?` не гарантирует отсутствие `null` в рантайме — отсюда R3.

### В проекте
1. R3: включить строгую обработку nullable / required в JSON или проверять явно; отсутствующие `name` / `tables` → 400.
2. R2, R4, R5: валидация `CreateZoneRequest` и `TableSetRequest` (`amount`, `capacity`, лимиты), ответ — ValidationProblem с указанием полей.
3. Перечисление `VenueKind` в JSON — строкой.
4. Неизвестные поля в запросе — решить: игнорировать или 400.
5. Лимиты валидации взять из конфигурации (связь с блоком 5).

### Юнит-тесты
- Десериализация `CreateZoneRequest`: JSON без `tables` → ошибка десериализации (или ошибка валидации — по выбранному подходу); JSON без `name` → то же; `"name": null` → то же.
- Сериализация ответа POST: `id` — строка-Guid, а не объект (регрессия R6).
- Сериализация `ZoneResponse`: имена полей в camelCase, порядок и формат как в контракте (сравнение с эталонной JSON-строкой).
- `VenueKind` сериализуется строкой и читается из строки; неизвестное значение → ошибка.
- Валидация `TableSetRequest`: `amount` ≤ 0, `amount` > лимита, `capacity` ≤ 0 → ошибка с ключом нужного поля (`[Theory]`).
- Валидация `CreateZoneRequest`: пустой `tables`, пустой `name` → ошибки; корректный запрос — ошибок нет.
- Тест-документация бага R2 из блока 1 заменён: отрицательный `amount` → ValidationProblem, а не исключение.

### Готово, когда
R2–R5 закрыты: ни один некорректный запрос не даёт 500, у каждого — понятный 400.

---

## Блок 5. DI, конфигурация, options, логирование

### Теория
- ⟲ Generic host (`WebApplication.CreateBuilder`) вместо `Global.asax` / OWIN `Startup`; встроенный DI вместо Unity / Autofac / Ninject (сторонние контейнеры всё ещё можно подключить).
- Lifetimes: Singleton / Scoped / Transient, captive dependency, `ValidateScopes` и `ValidateOnBuild`, keyed services (.NET 8), `TryAdd*`, методы расширения `AddXxx` для модулей.
- ≈ В Scala зависимости явные: `make` собирает граф в `Resource`, ошибки — на этапе компиляции. В .NET граф собирает контейнер в рантайме — поэтому важны `ValidateOnBuild` и тест на сборку графа. Обсудите, что вы теряете и что получаете.
- Конфигурация: ⟲ вместо `web.config` / `ConfigurationManager` — провайдеры (`appsettings.json`, `appsettings.{Environment}.json`, user secrets, переменные окружения, командная строка) и порядок их наложения.
- Options pattern: `IOptions` / `IOptionsSnapshot` / `IOptionsMonitor`, `ValidateDataAnnotations`, `ValidateOnStart`, source-generated валидаторы.
- Логирование: `ILogger<T>`, структурные логи (шаблоны, а не интерполяция), `LoggerMessage` source generator, scopes, уровни через конфигурацию. ≈ log4cats `Logger[F]`.
- `TimeProvider` (.NET 8) вместо `DateTime.UtcNow` — для тестируемости.

### В проекте
1. Заменить `StubVenueService` на сервис + in-memory репозиторий (singleton, потокобезопасный), с данными, переживающими запросы.
2. Разделить: сервис (бизнес-операции) и репозиторий (хранение) — интерфейсы, регистрация через `AddXxx`.
3. Options для лимитов зон (из блоков 2 и 4) с валидацией и `ValidateOnStart`.
4. Включить `ValidateScopes` и `ValidateOnBuild` во всех окружениях, не только в Development.
5. Логирование создания / удаления зон через `LoggerMessage`, без персональных данных.
6. Внедрить `TimeProvider`.

### Юнит-тесты
- Сервис зон с in-memory репозиторием: создать зону → она возвращается в GET этой площадки и не возвращается для другой площадки.
- Удаление: удалённая зона больше не возвращается; повторное удаление → «не найдено».
- Потокобезопасность репозитория: параллельное создание N зон (`Parallel.ForEachAsync`) → ровно N зон, без исключений.
- Граф DI: собрать `ServiceCollection` как в приложении, построить провайдер с `ValidateOnBuild` и `ValidateScopes` → без ошибок; каждый публичный сервис резолвится.
- Captive dependency: тест, который убеждается, что singleton не зависит от scoped (провайдер с `ValidateScopes` бросает исключение на специально неправильной регистрации — как учебный тест).
- Options: невалидные лимиты (0, отрицательные, лимит на набор больше лимита на зону) → `OptionsValidationException`.
- Логи: с `FakeLogger` из `Microsoft.Extensions.Diagnostics.Testing` — при создании зоны пишется одна запись нужного уровня со структурными полями `VenueId` и `ZoneId`.

### Готово, когда
Данные живут между запросами, граф DI проверяется тестом, лимиты — в конфигурации.

---

## Блок 6. Асинхронность и отмена

### Теория
- ⟲ `async` / `await`, `Task` против `ValueTask`, во что компилируется async-метод. В ASP.NET Core нет `SynchronizationContext` — `ConfigureAwait(false)` в коде приложения не нужен, но дедлоки от `.Result` / `.Wait()` всё ещё возможны в других местах. Забудьте рефлексы из ASP.NET на Framework.
- `CancellationToken`: передача по всей цепочке, `HttpContext.RequestAborted` и автоматическая привязка в Minimal API, `CancellationTokenSource.CancelAfter`, linked tokens.
- `IAsyncEnumerable<T>` и `await foreach`, стриминг ответов из Minimal API. ≈ `fs2.Stream`, но без ресурсной безопасности и комбинаторов из коробки (есть System.Linq.Async).
- `System.Threading.Channels` — ≈ `fs2.concurrent.Channel` / `Queue`.
- `IAsyncDisposable` и `await using` — ≈ `Resource.use`.
- ≈ `IO` — ленивое описание, `Task` — уже запущенная («горячая») операция. Это меняет подход к повторам, таймаутам и композиции. Сравните отмену файберов с кооперативной отменой через токен.

### В проекте
1. Протянуть `CancellationToken` через все методы сервиса и репозитория до обработчиков.
2. Убрать `Task.FromResult` там, где методы станут по-настоящему асинхронными; оставить там, где синхронная реализация оправдана — и понимать разницу.
3. Эндпоинт экспорта зон площадки, возвращающий `IAsyncEnumerable` (учебный — проверить, как сериализуется поток).

### Юнит-тесты
- Отменённый токен, переданный в сервис, → `OperationCanceledException`, данные не изменены.
- Отмена во время операции (фейковый репозиторий ждёт сигнала) → операция прерывается, исключение пробрасывается, а не глотается.
- Экспорт через `IAsyncEnumerable`: перечисление возвращает все зоны; отмена посреди перечисления прекращает его.
- Таймаут через `CancelAfter` с `FakeTimeProvider` — без реального ожидания.

### Готово, когда
Ни один асинхронный метод не теряет токен, тесты отмены не используют `Task.Delay` с реальным временем.

---

## Блок 7. Домен бронирования

Основная бизнес-логика проекта. Здесь .NET-специфики меньше — фокус на идиоматичном C# для богатой модели.

### Теория
- Время: `DateTime` против `DateTimeOffset`, `DateOnly` / `TimeOnly` (.NET 6), `TimeZoneInfo` и IANA-идентификаторы на Linux, переходы на летнее время. NodaTime как альтернатива — ≈ `java.time`, к которому вы привыкли.
- Стейт-машина на sealed-иерархии + switch expression или на enum + таблице переходов — сравните.
- Агрегаты и инварианты: где проверять пересечение броней (в агрегате или в хранилище — подготовка к блоку 8).
- ≈ Ваш опыт стейт-машин платежей напрямую переносится; новое здесь — только выражение средствами C#.

### В проекте
1. Домен: часы работы площадки (по дням недели, с часовым поясом площадки), бронь (стол, слот, число гостей, контакт, статус).
2. Статусы брони: Pending → Confirmed → Completed / Cancelled / NoShow, с запретом недопустимых переходов.
3. Правила: число гостей не больше вместимости стола; слот внутри часов работы; брони на один стол не пересекаются; нельзя бронировать в прошлом (через `TimeProvider`).
4. Поиск доступности: свободные столы зоны для заданного числа гостей и слота.
5. Эндпоинты AdminApi: просмотр броней площадки, отмена брони администратором.

### Юнит-тесты
- Пересечение слотов (`[Theory]`): полностью внутри, частично, вплотную (конец одного = начало другого — **не** пересечение), совпадающие, разные столы.
- Число гостей больше вместимости → ошибка; ровно вместимость → успех.
- Слот вне часов работы, слот через полночь (если площадка работает ночью), выходной день → ошибка / успех по правилам.
- Часовой пояс: слот в день перехода на летнее время для площадки в поясе с DST; несуществующее локальное время.
- Бронь в прошлом → ошибка (`FakeTimeProvider` задаёт «сейчас»).
- Переходы статусов: таблица всех пар (из → в), разрешённые проходят, запрещённые дают ошибку (`[Theory]` с `MemberData` / `TheoryData`).
- Поиск доступности: из трёх столов один занят, один мал → возвращается один подходящий.
- Property-based: для любого набора успешно созданных броней одного стола никакие две не пересекаются.

### Готово, когда
Бизнес-правила бронирования покрыты тестами и не зависят от реального времени.

---

## Блок 8. EF Core и PostgreSQL

### Теория
- ⟲ EF Core вместо EF6: другой провайдер-ориентированный дизайн, нет EDMX, только code-first с миграциями.
- `DbContext`, `IEntityTypeConfiguration<T>`, конвенции, `DbContextOptions` и регистрация (scoped), `AddDbContextPool`.
- Маппинг strongly-typed ids: value conversions; complex types (EF Core 8) против owned types; JSON-колонки.
- Миграции: `dotnet ef migrations add`, `migrations script`, идемпотентные скрипты, `has-pending-model-changes` (EF Core 8) для CI. ≈ Flyway, но миграции генерируются из модели — обсудите риски.
- Трекинг против `AsNoTracking`, проекции в DTO, N+1, split queries, compiled queries, `ExecuteUpdate` / `ExecuteDelete`.
- Конкурентность: optimistic concurrency (в Npgsql — системная колонка `xmin`), транзакции, уровни изоляции.
- PostgreSQL-специфика через Npgsql: `tstzrange` и exclusion constraint (`EXCLUDE USING gist`) — защита от пересечения броней на уровне БД.
- ≈ quill / doobie / skunk: там SQL явный и типизированный, здесь — LINQ и change tracker. Ваш опыт с PostgreSQL помогает видеть, какой SQL генерируется — включите логирование SQL.

### В проекте
1. Проект `TheVenue.Infrastructure` (или аналог) с `DbContext` и конфигурациями; репозитории из блока 5 получают EF-реализацию.
2. Маппинг всех value objects и ids без «протекания» EF-атрибутов в домен.
3. Миграции, локальный PostgreSQL (docker compose или Aspire в блоке 13).
4. Защита от пересечения броней: проверка в домене + exclusion constraint в БД; обработка нарушения constraint → 409.
5. Optimistic concurrency для изменения брони.
6. Чтение — через проекции с `AsNoTracking`.

### Юнит-тесты
Юнит-тесты здесь — на маппинг и модель; поведение с реальной БД — в блоке 9.
- Value converters: каждый strongly-typed id и value object проходит туда-обратно без потерь.
- Модель (`context.Model`): у сущностей ожидаемые ключи, у брони есть concurrency token, у value objects — ожидаемые типы колонок (тест на метаданные, без БД).
- Отсутствие несгенерированных миграций: тест или CI-шаг с `has-pending-model-changes`.
- Преобразование ошибки PostgreSQL о нарушении exclusion constraint в доменную ошибку «слот занят» (по коду ошибки `PostgresException`, на подготовленном исключении).
- ⚠ Не используйте EF InMemory provider для тестов репозиториев — он не повторяет поведение реальной БД. Объясните себе почему.

### Готово, когда
Данные хранятся в PostgreSQL, пересечение броней невозможно даже при гонке, миграции проверяются автоматически.

---

## Блок 9. Интеграционные тесты

### Теория
- `WebApplicationFactory<TEntryPoint>` (`Microsoft.AspNetCore.Mvc.Testing`), `public partial class Program` для top-level statements, `ConfigureTestServices` для подмены сервисов, `TestServer` и `HttpClient`.
- Testcontainers for .NET (модуль PostgreSQL), общий контейнер через `ICollectionFixture` / assembly fixture, Respawn для очистки БД между тестами.
- Snapshot-тестирование ответов и OpenAPI-документа (Verify). ≈ golden-тесты.
- ≈ Ваш опыт testcontainers в Scala переносится один к одному.

### В проекте
1. `tests/TheVenue.IntegrationTests` с фабрикой приложения и контейнером PostgreSQL.
2. Миграции применяются к контейнеру перед тестами.
3. Snapshot OpenAPI-документа AdminApi — изменение контракта видно в диффе.

### Тесты
Это интеграционные, а не юнит-тесты — они закрывают то, что юнит-тестами не поймать:
- R1-регрессия: `DELETE /admin/venues/{id}/zones/{zoneId}` → 204, повторный → 404.
- Полный цикл зоны: POST → GET содержит зону → DELETE → GET не содержит.
- Некорректные тела POST (из блока 4) → 400 с ProblemDetails, ни одного 500.
- Две параллельные брони одного стола на пересекающийся слот → одна 201, другая 409 (гонка — проверка exclusion constraint).
- Устаревшая версия при изменении брони → 409.
- OpenAPI-документ совпадает со snapshot.

### Готово, когда
`dotnet test` поднимает PostgreSQL сам, интеграционные тесты стабильны при повторных запусках.

---

## Блок 10. Публичный API, OpenAPI, HTTP-клиенты

### Теория
- OpenAPI в .NET 9+: встроенный `Microsoft.AspNetCore.OpenApi` (⟲ Swashbuckle убран из шаблонов), трансформеры документа и операций, UI через Scalar. ≈ tapir генерирует OpenAPI из описания эндпоинтов — сравните качество документа.
- Версионирование API (`Asp.Versioning`).
- Rate limiting middleware (.NET 7), output caching.
- ⟲ `HttpClient` и `IHttpClientFactory` вместо `new HttpClient()` в `using`: typed clients, `DelegatingHandler`.
- Устойчивость: `Microsoft.Extensions.Http.Resilience` (на Polly v8) — retry, timeout, circuit breaker. ≈ cats-retry / sttp backends.
- Общий код между двумя API: отдельный слой приложения (use cases) или разделяемые сервисы — выберите и обоснуйте.

### В проекте
1. `TheVenue.Api` (для гостей): поиск площадок, доступность столов, создание брони, отмена своей брони по коду.
2. Вынести общую логику бронирования в слой, используемый обоими API.
3. Rate limiting на создание броней.
4. Внешняя интеграция-заглушка через typed `HttpClient` (например, сервис уведомлений или геокодинг адреса площадки) с resilience-пайплайном.
5. Документ OpenAPI для обоих API, UI в Development.

### Юнит-тесты
- Typed client: с фейковым `HttpMessageHandler` — правильный метод, путь, заголовки и тело запроса; разбор успешного ответа; 4xx → доменная ошибка, а не исключение HTTP.
- Resilience: 5xx дважды, потом 200 → клиент возвращает успех, сделано 3 запроса; постоянные 5xx → ошибка после настроенного числа попыток.
- Обработчики `TheVenue.Api` через `TypedResults`, как в блоке 3: создание брони → `Created`, слот занят → `Conflict`, стол мал → `ValidationProblem`.
- Код брони для гостя: генерация даёт код нужного формата, отмена с чужим кодом отклоняется.

### Готово, когда
Гость может найти стол и забронировать его через публичный API, внешние вызовы устойчивы к сбоям.

---

## Блок 11. Аутентификация и авторизация

### Теория
- ⟲ Вместо WIF и `System.IdentityModel` — authentication handlers ASP.NET Core (`AddAuthentication().AddJwtBearer()`), `ClaimsPrincipal` остался — ваш опыт с claims напрямую применим.
- ⟲ IdentityServer стал Duende IdentityServer (коммерческая лицензия); альтернативы — Keycloak, OpenIddict, облачные провайдеры.
- Авторизация: политики, требования (`IAuthorizationRequirement`) и обработчики (`AuthorizationHandler<T>`), resource-based authorization, `RequireAuthorization` на группах эндпоинтов, `IClaimsTransformation`.
- Секреты в разработке: user secrets, переменные окружения; ничего секретного в `appsettings.json`.
- ≈ Вы делали JWT / JWE и PKCE — здесь новое только API платформы.

### В проекте
1. AdminApi: JWT bearer; роли «администратор платформы» и «менеджер площадки» (менеджер управляет только своими площадками).
2. Resource-based авторизация для операций с зонами и бронями площадки.
3. Api: публичные эндпоинты без аутентификации, отмена брони — по коду брони.
4. Локальный OIDC-провайдер (Keycloak в контейнере) или выпуск тестовых токенов через `dotnet user-jwts`.

### Юнит-тесты
- Обработчик авторизации: менеджер площадки A → доступ к площадке A разрешён, к площадке B — нет; администратор → доступ везде; пользователь без claims → отказ (`[Theory]` по сочетаниям).
- Политики: собрать `IAuthorizationService` из `ServiceCollection` с политиками приложения и проверить их на заранее построенных `ClaimsPrincipal`.
- `IClaimsTransformation`: из claims токена корректно извлекается список площадок менеджера; повторный вызов не дублирует claims.
- Интеграционно (дополнительно к блоку 9): без токена → 401, с токеном чужой площадки → 403.

### Готово, когда
AdminApi закрыт аутентификацией, менеджер не может трогать чужие площадки.

---

## Блок 12. Фоновая обработка и сообщения

### Теория
- `BackgroundService` / `IHostedService`, `PeriodicTimer`, graceful shutdown и `stoppingToken`. ⟲ Вместо Windows Services и Hangfire / Quartz «по умолчанию» — хост сам по себе.
- Kafka в .NET: Confluent.Kafka (низкоуровневый клиент), сериализация (JSON / Protobuf / Schema Registry), consumer groups, ручной коммит оффсетов. ≈ fs2-kafka — сравните модель: колбэки и цикл `Consume` против стрима.
- Transactional outbox, идемпотентные обработчики по ключу события — ваш опыт напрямую применим.
- Обзор фреймворков: MassTransit (⚠ v9 — коммерческая лицензия), Wolverine, Brighter — понимать, что они дают, но в учебном проекте начать с голого клиента.

### В проекте
1. События `BookingCreated`, `BookingCancelled` пишутся в outbox-таблицу в той же транзакции, что и бронь.
2. `BackgroundService`-публикатор outbox в Kafka.
3. Потребитель-уведомитель (логирует «отправку» уведомления), идемпотентный.
4. Фоновая задача: перевод неподтверждённых броней в NoShow после начала слота (через `TimeProvider`).
5. Kafka локально в контейнере.

### Юнит-тесты
- Публикатор outbox: с фейковым producer — непубликованные записи отправляются по порядку и помечаются отправленными; ошибка producer → запись остаётся неотправленной, следующий цикл повторяет.
- Идемпотентность потребителя: одно и то же событие дважды → эффект один раз.
- Контракт событий: сериализация `BookingCreated` совпадает с эталонным JSON (защита от случайного изменения схемы).
- NoShow-задача с `FakeTimeProvider`: до начала слота + допуск — ничего; после — неподтверждённые брони переведены, подтверждённые не тронуты.
- Graceful shutdown: отмена `stoppingToken` завершает цикл фоновой службы без исключения.

### Готово, когда
События о бронях надёжно доходят до Kafka, повторная доставка безопасна.

---

## Блок 13. Наблюдаемость, контейнеры, CI

### Теория
- OpenTelemetry в .NET: трейсы через `ActivitySource` (⟲ встроено в `System.Diagnostics`), метрики через `System.Diagnostics.Metrics` (`Meter`, `Counter`, `Histogram`), логи; экспортеры OTLP.
- Health checks (`AddHealthChecks`, проверки БД и Kafka, liveness против readiness).
- .NET Aspire: AppHost для локальной оркестрации (PostgreSQL, Kafka, оба API), ServiceDefaults (OTel, health checks, resilience), дашборд. ≈ docker compose + общие настройки, но на C#.
- Контейнеры без Dockerfile: `dotnet publish /t:PublishContainer`, chiseled-образы.
- Native AOT и trimming: что ломается (рефлексия, динамический JSON), source generators как решение. Где AOT оправдан, а где нет.
- CI: GitHub Actions — сборка, тесты с Testcontainers, `dotnet format --verify-no-changes`, проверка миграций, публикация образа.

### В проекте
1. ServiceDefaults и AppHost Aspire: `dotnet run` поднимает всю систему.
2. Метрики: созданные / отменённые брони, время поиска доступности; трейсы проходят от HTTP до Kafka-потребителя.
3. Health checks для обоих API.
4. Образы через `PublishContainer`.
5. GitHub Actions workflow для ветки и PR.
6. Эксперимент: собрать `TheVenue.Api` с Native AOT, записать, что пришлось поменять.

### Юнит-тесты
- Метрики: с `MetricCollector<T>` из `Microsoft.Extensions.Diagnostics.Testing` — создание брони увеличивает счётчик на 1 с тегом площадки; отмена — другой счётчик.
- Трейсинг: с `ActivityListener` — операция создания брони создаёт span с ожидаемым именем и тегами.
- Health check БД: при доступном фейковом соединении → Healthy, при исключении → Unhealthy с описанием.

### Готово, когда
Система поднимается одной командой, видны трейсы и метрики, CI зелёный на каждый push.

---

## Сквозная привязка находок ревью

| Находка | Блок |
|---------|------|
| R1 — маршрут DELETE | 3 (исправление), 9 (регрессионный тест) |
| R2 — отрицательный `amount` | 1 (тест-документация бага), 4 |
| R3 — null `tables` / `name` | 4 |
| R4 — capacity ≤ 0, зона без столов | 2, 4 |
| R5 — нет верхней границы `amount` | 2, 4, 5 (лимиты в конфигурации) |
| R6 — форма id в ответе POST | 3, 4 (тест сериализации) |
| R7 — изменяемый `Dictionary` в `Zone` | 2 |
| R8 — `UseHttpsRedirection` | 3 |
| R9 — неиспользуемые `using` | 0 |
