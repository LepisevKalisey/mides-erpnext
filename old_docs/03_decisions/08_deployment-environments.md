# ADR-001: Deployment Environments (Dev vs Prod)

**Status:** Accepted  
**Date:** 2026-05-04

## Context

MidesCloud — управленческий учёт для строительства. Нужна среда для разработки (быстрый цикл, облако) и производственная среда (приватный сервер, полный контроль).

У разработчика уже есть:
- Supabase Free Tier (shared PostgreSQL) — используется для нескольких проектов
- Собственный сервер — планируется для prod-развёртывания

## Decision

### Dev Environment

| Компонент | Решение |
|---|---|
| **Frontend** | Vercel (GitHub → auto-deploy preview) |
| **Database** | Supabase Cloud (Free Tier) |
| **Auth** | Supabase Auth (Cloud) |
| **CI/CD** | GitHub Actions → Vercel Preview URL |
| **Secrets** | Vercel Environment Variables |

**Почему Cloud Supabase:**  
Быстрый цикл разработки, управляемая инфраструктура, идеальная интеграция с Vercel.

### Prod Environment

| Компонент | Решение |
|---|---|
| **Frontend** | Coolify |
| **Database** | Supabase (Self-hosted) |
| **Auth** | Supabase Auth (Self-hosted) |
| **CI/CD** | GitHub Actions → Coolify Webhook |
| **Secrets** | Coolify Environment Variables |

**Почему Coolify и Self-Hosted Supabase:**  
Полный контроль над данными, отсутствие vendor lock-in, бесплатное масштабирование базы данных и ресурсов. Supabase дает нативный Auth и RLS на всех средах.

## Code Infrastructure Agnosticism

Drizzle ORM настроен с `schemaFilter: ['midescloud']`.  
Управление схемой осуществляется через миграции (перешли с небезопасного `drizzle-kit push` на версионированные файлы через `npm run db:generate` и `npm run db:migrate`).
Код не меняется между средами — только `DATABASE_URL` в переменных окружения:

```
# Dev (.env.local)
DATABASE_URL=postgresql://postgres:[pass]@aws-0-REGION.pooler.supabase.com:6543/postgres

# Prod (.env на сервере)
DATABASE_URL=postgresql://midescloud_user:[pass]@localhost:5432/midescloud
```

## Автоматизация CI/CD

Разработка ведётся автономно, пайплайн управляется тремя GitHub Actions:

| Workflow | Файл | Триггер | Описание |
|---|---|---|---|
| **Quality Gate** | `ci.yml` | Push/PR (main, dev) | Проверяет код (Lint, Typecheck, Unit Tests). Поднимает временный голый Postgres для тестирования миграций. |
| **Preview** | `preview.yml` | PR (main) с лейблом `preview` | E2E тестирование (Playwright) с Mock Auth в голом `postgres:16`. Загружает артефакты отчета в PR. |
| **Production** | `deploy-prod.yml` | Push (main) | Выполняет накат миграций на Prod-базу (через pooler) и дёргает вебхук Coolify. |

### Реестр GitHub Secrets

| Секрет | Описание | Используется в |
|---|---|---|
| `PROD_DATABASE_URL` | Строка подключения к Prod Supabase (pooler, порт 6543) | `deploy-prod.yml` |
| `COOLIFY_WEBHOOK_URL` | URL вебхука деплоя из Coolify Dashboard | `deploy-prod.yml` |
| `CI_JWT_SECRET` | Строка для генерации моковых JWT в E2E тестах | `preview.yml` |

## Alternatives Considered

| Вариант | Отклонён, потому что |
|---|---|
| Supabase отдельный проект для prod | Платный тариф, vendor lock-in |
| NocoBase | Требует отдельной инфраструктуры, нет TypeScript API |
| Prisma вместо Drizzle | Менее производительный, нет нативной поддержки PostgreSQL schemas |

## Consequences

- **+** Один кодовый репозиторий для обеих сред
- **+** Miграции Drizzle применимы к обеим средам без изменений
- **+** Prod изолирован от других проектов на сервере на уровне database
- **−** На dev нет полной изоляции от других схем в Supabase (но это dev, данные тестовые)

## Related

- See: `docs/04_architecture/01_system-overview.md`
- See: `docs/03_decisions/02_tech-stack.md`
