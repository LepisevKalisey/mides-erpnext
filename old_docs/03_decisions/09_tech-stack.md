# ADR-009: Tech Stack

**Status:** Accepted
**Date:** 2026-05-04
**Updated:** 2026-05-15

## Context

Исходная система — Google Sheets + Google Apps Script. Нужна миграция на масштабируемый стек с типобезопасностью, RBAC, WhatsApp OTP и нормальной CI/CD-цепочкой.

Вся разработка ведётся через AI (нет требования к знакомости стека).

Дополнительные требования, выявленные в архитектурном ревью (2026-05-07):
- P2P workflow — сложная state machine с audit trail и уведомлениями
- Интеграция с 1С через файловый/webhook обмен (Phase 2–3)
- Мобильное приложение планируется, срок не определён

Обновление 2026-05-15:
- Переход с Better Auth на Supabase Auth (см. раздел Auth)
- База данных: Cloud Supabase (dev), Coolify + Self-hosted Supabase (prod)
- Drizzle ORM оставлен для строгой типизации схемы и миграций
- Добавлен advance_workflow() как единый Edge Function оркестратор (ADR-38)

## Decision

### Frontend

**Next.js (App Router)**

- Server Components по умолчанию → меньше клиентского JS
- File-based routing → предсказуемая структура
- Vercel — нативная платформа, zero-config deploy

### Гибридный API: Server Actions + Edge Functions

| Тип операции | Механизм |
|---|---|
| Простые CRUD (create/read/update) | Server Actions |
| Переходы статусов (state transitions) | `advance_workflow()` Edge Function |
| AI-обработка (OCR, маппинг) | Supabase Edge Functions |
| Файловый экспорт (CSV для 1С) | API Routes `GET /api/exports/*` |
| Внешние вебхуки (1С, WhatsApp) | API Routes `POST /api/webhooks/*` |
| Мобильный API (будущее) | API Routes `/api/v1/*` с Bearer token |

### Авторизация: Supabase Auth + RLS

**Изменение (2026-05-15):** Переход с Better Auth (app-level only) на **Supabase Auth**.

Причины перехода:
1. **Единая платформа** — Auth, DB, Storage в одном сервисе (Self-hosted ready via Coolify)
2. **Нативная RLS-интеграция** — `auth.uid()` доступен в PostgreSQL policies
3. **Phone OTP из коробки** — без кастомной интеграции
4. **Готовый клиент** — `@supabase/ssr` для Next.js App Router

Гибридный подход к авторизации:
- **RLS** — включён на всех таблицах, базовая защита от прямого доступа
- **App-level `requireRole()`** — бизнес-логика доступа (матрица полномочий, ADR-18)
- **advance_workflow()** — единственный оркестратор state transitions (ADR-38)

### Асинхронные уведомления

**`notification_queue` таблица + Supabase Edge Function (cron)**

Уведомления не выполняются в request cycle. Паттерн:
1. Server Action/API Route → `INSERT INTO notification_queue`
2. Edge Function запускается по расписанию → читает очередь → отправляет (WhatsApp/Email)

### UI

**shadcn/ui + Tailwind CSS v3.4**

- Компоненты копируются в проект (не npm-зависимость) — полный контроль
- Radix UI под капотом — доступность из коробки
- Лёгкая кастомизация под корпоративный стиль
- Визуальная система задокументирована в DESIGN.md

### Data Access

**Drizzle ORM + Supabase Client (`@supabase/supabase-js`)**

- **Drizzle ORM** используется для строгой типизации схемы базы данных в коде (`web/src/db/schema`) и управления миграциями (`npm run db:push` / `npm run db:generate`). Это позволяет иметь единый источник истины о структуре БД.
- **Supabase Client** используется для RLS-зависимых операций (через `@supabase/ssr`) или где удобнее использовать встроенные функции Supabase.
- Drizzle подключается через `DATABASE_URL` (direct connection, обходит RLS) для системных операций и миграций.

### Auth

**Supabase Auth** ~~Better Auth~~

- Supabase-native — сессии, JWT, refresh tokens управляются платформой
- `@supabase/ssr` — серверный и клиентский клиент для Next.js
- Phone OTP — встроенная поддержка (SMS provider: Twilio/MessageBird)
- Multi-role — через junction-таблицу `user_roles` в schema `public`
- RLS-интеграция — `auth.uid()` доступен в PostgreSQL policies нативно
- Service Role Key — для серверных операций (Edge Functions, Server Actions)

### Database

**PostgreSQL (Supabase)**

- Schema: `public` (плюс `auth` для Supabase)
- Миграции: Drizzle Kit
- RLS: может быть включён на чувствительных таблицах, но Drizzle (по default connection) его обходит, что приемлемо для SSR-first архитектуры с проверкой прав на уровне App (`user_roles`).

### WhatsApp OTP (планируется)

**Meta Cloud API** или **Twilio WhatsApp Business**

- Интеграция через Supabase Auth Phone Provider
- Выбор провайдера — отдельное ADR после тестирования

## Alternatives Considered

| Компонент | Альтернатива | Почему отклонена |
|---|---|---|
| Next.js | Remix, SvelteKit | Ecosystem, Vercel integration |
| Server Actions only | + API Routes | API Routes добавлены для transitions/webhooks/mobile |
| Better Auth | **→ Supabase Auth** | Supabase Auth — Self-hostable, нативная интеграция с БД |
| Prisma | Drizzle ORM | Prisma тяжеловесен и хуже работает с Edge/Serverless |
| shadcn/ui | MUI, Ant Design | Тяжёлые, сложно кастомизировать |
| tRPC | Plain API Routes | Добавляет сложность без критической необходимости |

## Consequences

- **+** Всё в одном репозитории, единый язык (TypeScript)
- **+** Единый data layer (Supabase client) для browser, server, Edge Functions
- **+** Server Actions для CRUD, Edge Functions для orchestration
- **+** Supabase Auth + RLS — двойная защита (app + DB level)
- **+** Мобильное приложение: добавить React Native клиент без переписывания backend
- **+** `notification_queue` решает async уведомления без внешних сервисов
- **−** Supabase Auth — vendor coupling (смягчается тем, что Supabase — OSS)
- **−** Нет ORM query builder — сложные JOIN-ы через rpc() менее ergonomичны
- **−** WhatsApp OTP требует верифицированного бизнес-аккаунта Meta

## Related

- See: `docs/03_decisions/08_deployment-environments.md`
- See: `docs/04_architecture/02_system-overview.md`
- See: `docs/03_decisions/16_1c-integration-pattern.md`
- See: `docs/03_decisions/38_task-per-role-architecture.md`
