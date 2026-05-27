# Руководство по инструментам разработки (AI Skills)

**Статус:** Актуально
**Дата:** 2026-05-17
**Контекст:** Рекомендации по использованию AI-скилов для MidesCloud v3.

---

## Назначение документа

При разработке с AI-ассистентом доступен набор специализированных скилов — инструкций, расширяющих возможности агента для конкретных технических задач. Этот документ фиксирует, какие скилы применять на каждой фазе и почему.

---

## Стек проекта

| Слой | Технология |
|---|---|
| Frontend | Next.js 14 App Router + TypeScript |
| ORM | Drizzle ORM (DDL + query builder) |
| Database | Supabase PostgreSQL (16+) |
| Auth | Supabase Auth SSR (@supabase/ssr) |
| Styling | Tailwind CSS 3.4.1 + CSS custom properties |
| Components | shadcn/ui (14 компонентов) |
| Fonts | Inter (body), Plus Jakarta Sans (headings) |
| Icons | Lucide React |
| Testing | Vitest (unit), Playwright (E2E) |

---

## Рекомендуемые скилы по фазам

### Ф0: Foundation (завершена)

| Скилл | Применение |
|---|---|
| `nextjs-best-practices` | App Router, Server Components, Server Actions, data fetching |
| `react-patterns` | Hooks, composition, state для сложных форм |
| `drizzle-orm-expert` | Схема, миграции, relations, query builder |
| `tdd-workflow` | Тесты до реализации |
| `systematic-debugging` | Диагностика Supabase + RLS проблем |

### Ф1–Ф2: Закупки (P2P)

| Скилл | Применение |
|---|---|
| `zustand-store-ts` | Локальный стейт сайдбара при создании заявок |
| `fp-async` | Цепочки OCR: upload → parse → validate → save |
| `fp-errors` | Обработка ошибок через Either/TaskEither |
| `postgres-best-practices` | Индексы, оптимизация запросов |

### Ф3+: Расширенные модули

| Скилл | Применение |
|---|---|
| `security-auditor` | Аудит RLS-политик перед production |
| `react-component-performance` | Оптимизация dashboard-виджетов |

### Сквозные (весь цикл)

| Скилл | Применение |
|---|---|
| `systematic-debugging` | Баги Supabase RLS + Realtime |
| `code-reviewer` | Code review критических модулей |
| `security-auditor` | Аудит безопасности |
| `concise-planning` | Атомарные чеклисты задач |

---

## Что НЕ применять

| Скилл | Причина |
|---|---|
| `vercel-deployment` | Деплой пока не настроен (будет позже) |
| `crewai`, `multi-agent-patterns` | Система не LLM-heavy |

---

## Связанные документы

- See: `docs/04_architecture/01_system-overview.md` — архитектура
- See: `docs/08_reference/03_project-context.md` — контекст проекта
- See: `DESIGN.md` — дизайн-система
