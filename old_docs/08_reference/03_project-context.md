# Project Context Snapshot — MidesCloud v3

**Обновлено:** 2026-05-17
**Цель:** Вся ключевая информация о проекте в одном файле. Не заменяет ADR и Blueprint — дополняет их быстрым обзором для нового агента.

> При переносе проекта на другую машину или при запуске нового AI-агента — читайте этот файл после `.antigravityrules` и `AGENTS.md`.

---

## Идентификаторы проекта

| Параметр | Значение |
|---|---|
| GitHub | https://github.com/LepisevKalisey/MidesCloudv3 |
| Локальный путь | `c:\Projects\Mides\MidesCloud v3` |
| Supabase проект | `drtpvypzrwmodghqbqbe` |
| Supabase схема | `public` (стандартная Supabase) |
| Стадия | Ф1: L2-COMMIT Subcontract |
| Локаль | ru-KZ, валюта KZT, даты DD.MM.YYYY |

---

## Технологический стек (актуальный)

| Слой | Технология | Версия |
|---|---|---|
| Frontend | Next.js App Router | 14.2.35 |
| ORM | Drizzle ORM | 0.45.2 |
| Database | PostgreSQL (Supabase) | 16+ |
| Auth | Supabase Auth SSR | @supabase/ssr 0.10.3 |
| Styling | Tailwind CSS | 3.4.1 |
| Components | shadcn/ui | 4.7.0 |
| Icons | Lucide React | 1.16.0 |
| Fonts | Inter (body), Plus Jakarta Sans (headings) | Google Fonts |
| Testing | Vitest (unit), Playwright (E2E) | 4.1.6 / 1.60.0 |

> **ВАЖНО:** Drizzle ORM ИСПОЛЬЗУЕТСЯ в проекте (DDL + query builder). Ранние memory-записи о его удалении относятся к старому MidesCloud v1, НЕ к v3.

---

## Ключевые архитектурные решения

### ADR-38: Task-per-Role
- `purchase_items` = легковесный якорь (ПОТРЕБНОСТЬ)
- Каждая роль работает в своей таблице `*_tasks`
- `current_stage` = ВЫЧИСЛЯЕМЫЙ VIEW, НЕ хранимое поле
- Оркестрация: ОДИН `advance_workflow()`, НИКАКИХ каскадных триггеров

### Дизайн-система
- Файл: `DESIGN.md` в корне проекта
- Палитра: slate-blue (#1e3a5f primary), Notion-inspired
- Статусы: amber=PENDING, green=APPROVED, red=REJECTED, blue=ACTIVE, slate=DRAFT
- Кнопки: rounded-md (8px), карточки: rounded-lg (12px)
- НИКАКИХ модальных окон → только Sheet (сайдбар справа)
- НИКАКИХ emoji → только Lucide React иконки

### Модель данных (бизнес-сущности)

- **Contractors** — подрядчики. Роли через TEXT ARRAY (SUBCONTRACTOR, SUPPLIER, CLIENT). Статусы: NEW→ACTIVE→TRUSTED/SUSPICIOUS. BIN 12 цифр, уникальный.
- **Contracts** — договоры. Направление: INCOMING (клиент платит нам) / OUTGOING (мы платим). Тип закрывающего документа: SERVICES (АВР) / MATERIALS (Накладная) — на уровне договора. Статусы: DRAFT→ACTIVE→COMPLETED/TERMINATED.
- **Project Roles** — роли в проекте (НЕ системные): PROJECT_MANAGER, CHIEF_ENGINEER, SITE_MANAGER (назначается на объект), PROCUREMENT, PTO_ENGINEER.
- **Objects** — объекты проекта. Типы: Общестрой, Инженерные сети. Добавляются только к ACTIVE проектам.

### Процесс разработки
- **No Spec = No Code** — DESIGN.md + page-spec обязательны до написания UI
- **Sheet-based forms** — формы создания/редактирования ТОЛЬКО через Sheet (правый сайдбар)
- **AccordionGrid** — единственный паттерн для иерархических таблиц (ADR-07)
- **Git branching** — `main` = production, `dev` = рабочая ветка, merge через PR

---

## Page Specs (Phase 2)

6 спецификаций в `docs/04_architecture/`:
1. `03_page-spec-dashboard.md` — главная
2. `04_page-spec-legal-entities.md` — юрлица
3. `05_page-spec-projects.md` — проекты
4. `06_page-spec-contractors.md` — подрядчики
5. `07_page-spec-contracts.md` — договоры
6. `08_page-spec-objects.md` — объекты (если есть)

---

## Установленные shadcn/ui компоненты

badge, button, card, dialog, dropdown-menu, input, label, select, separator, sheet, table, tabs, textarea, tooltip

---

## CI/CD

- `.github/workflows/ci.yml` — lint → context:check → typecheck → schema push → seed → test → build → E2E
- `.github/workflows/preview.yml` — PR preview с E2E
- Postgres 16 service container в CI
- Триггеры: push/PR на `main` и `dev`

---

## Knowledge Items (KI)

4 файла в `.antigravity/knowledge/`:
1. `auth-patterns` — паттерны аутентификации (getCurrentUser, hasRole)
2. `workflow-patterns` — паттерны workflow (advanceWorkflow, transition map)
3. `ui-component-patterns` — UI паттерны (AccordionGrid, Sheet forms)
4. `testing-standards` — стандарты тестирования (Vitest, Playwright)

---

## Ключевые lib-файлы

| Файл | Назначение |
|---|---|
| `web/src/lib/auth.ts` | getCurrentUser(), hasRole(), requireUser() |
| `web/src/lib/workflow.ts` | advanceWorkflow(), WORKFLOW_TRANSITIONS |
| `web/src/lib/locale.ts` | Все UI-строки на русском |
| `web/src/lib/formatters.ts` | formatCurrency('ru-KZ', 'KZT'), formatDate() |
| `web/src/lib/utils.ts` | cn() (clsx + tailwind-merge) |

---

## Известные ограничения (актуальные)

1. `advance_workflow()` — stub (throw Error), требует реализации для Ф2
2. Нет Drizzle relations в схеме — relational query builder не работает
3. `contractor_type` — TEXT вместо pgEnum (нарушает собственное правило)
4. Покрытие тестами минимально: 3 unit-теста (formatters), 4 E2E smoke

---

## Связанные документы

- See: `.antigravityrules` — правила проекта
- See: `AGENTS.md` — контракты агентов
- See: `DESIGN.md` — дизайн-система
- See: `docs/01_product/01_system-blueprint.md` — полная доменная модель
- See: `docs/00_index/01_docs-index.md` — индекс всей документации
