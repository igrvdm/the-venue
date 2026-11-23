# The Venue — цель проекта

Учебный проект: вернуться в разработку на .NET и освоить современный стек (.NET 8+/C# 12+, ASP.NET Core, Minimal API, встроенный DI, EF Core, async, тестирование, контейнеризация) на примере системы бронирования площадок.

## Опыт разработчика

- 20+ лет в бэкенд-разработке, senior.
- Последние 7+ лет — Scala и экосистема Typelevel: Scala 2/3, Cats Effect, fs2, Akka Streams, Tapir, Kafka, PostgreSQL, Cassandra, Redis, Protobuf, OpenAPI. Event-driven, CQRS, микросервисы, стриминговые пайплайны; платёжные флоу и стейт-машины, планировщики задач, трекинг локаций, документооборот национального масштаба.
- Auth: JWT/JWE, OAuth 2.0 (Authorization Code + PKCE), claims-based авторизация.
- До 2018 года — .NET: .NET Framework, .NET Compact Framework (мобильное приложение, синхронизация локальной БД с MSSQL), enterprise-системы, интеграции, highload, миграции legacy-архитектур, федеративная аутентификация на Thinktecture IdentityServer/WIF (Google, Facebook, claims).
- Пишет с Claude Code в spec-driven подходе: спецификации задач в Markdown как контекст для ассистента.

То есть .NET знаком, но в версии до .NET Core/.NET 5+; современную платформу и идиомы нужно освоить заново, а архитектура и бэкенд-практики уже на уровне senior.

## Как помогать

- Делать акцент на том, что изменилось с эпохи .NET Framework: .NET Core → .NET 5+, SDK-style проекты и `dotnet` CLI, generic host, встроенный DI и конфигурация, Minimal API вместо Web API 2/MVC-контроллеров, Kestrel вместо IIS/System.Web, EF Core вместо EF6, `IOptions`, `ILogger`, `HttpClientFactory`, source generators, nullable reference types, records, pattern matching, primary constructors, collection expressions.
- Сравнивать с привычным из Scala/Typelevel, где это помогает: явная передача зависимостей и `make` vs DI-контейнер и lifetimes, `IO`/`Resource` vs `Task`/`IAsyncDisposable`/`CancellationToken`, fs2 vs `IAsyncEnumerable`/Channels, case class/ADT/`Option`/`Either` vs records/sealed-иерархии/nullable/Result, tapir vs Minimal API + OpenAPI, Kafka-клиенты и стриминг в .NET.
- Не разжёвывать общие вещи (HTTP, REST, слои, SOLID, тестирование, Kafka/БД как концепции) — фокус на идиомах, инструментах и экосистеме .NET.
- Показывать современный идиоматичный C# и отмечать устаревшие подходы, которые часто встречаются в примерах из интернета и в памяти с прошлого опыта.
- Когда в .NET принято иначе, чем в функциональной Scala, говорить об этом прямо и объяснять, почему, а не подгонять код под Scala-стиль.
