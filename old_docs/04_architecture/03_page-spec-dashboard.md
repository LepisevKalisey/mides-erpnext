# Page Spec: Обзор Директора (Dashboard)

## Route

`/dashboard`

## Agent

Frontend Agent (see AGENTS.md §2)

## Layout

CardGrid (2×2) — сводные KPI + последние проекты + статусы договоров

## Data Source

- Server Action: `getDashboardStats()`
- Schema tables: `projects`, `contractors`, `legal_entities`, `contracts`, `project_assignments`
- Aggregations:
  - `activeProjectsCount` — COUNT(`projects` WHERE `is_active = true`)
  - `contractorsCount` — COUNT(`contractors`)
  - `legalEntitiesCount` — COUNT(`legal_entities`)
  - `activeContractsCount` — COUNT(`contracts` WHERE `status IN ('INTENT','SIGNED','ACTIVE')`)
  - `recentProjects` — SELECT 5 последних по `created_at`

## Components

| Component | Type | Props |
|---|---|---|
| StatCard | Card | title: string, value: number, icon: LucideIcon, href: string |
| ContractStatusMini | Badge group | counts: Record<ContractStatus, number> |
| RecentProjectsList | List (5 строк) | projects: Project[] |

## KPI Cards (фиксированный набор)

| Карточка | Icon | Источник | Href |
|---|---|---|---|
| Активные проекты | `FolderOpen` | `activeProjectsCount` | `/dashboard/projects` |
| Контрагенты | `Building2` | `contractorsCount` | `/dashboard/contractors` |
| Юридические лица | `Landmark` | `legalEntitiesCount` | `/dashboard/legal-entities` |
| Активные договоры | `FileText` | `activeContractsCount` | `/dashboard/contracts` |

## Interactions

| Action | Trigger | Result |
|---|---|---|
| Перейти в модуль | Клик на StatCard | Navigate по `href` карточки |
| Открыть проект | Клик на строку в RecentProjectsList | Navigate to `/dashboard/projects` |

## Filters & Sorting

None — Dashboard показывает только агрегированные данные.

## Status Badges

| Status | Color Token | Label (ru) |
|---|---|---|
| INTENT | `--status-pending` | Намерение |
| SIGNED | `--status-info` | Подписан |
| ACTIVE | `--status-active` | Активен |
| CLOSED | `--status-neutral` | Закрыт |
| TERMINATED | `--status-error` | Расторгнут |

## Invariants

- DIRECTOR видит данные по всем проектам без фильтрации
- Остальные роли видят только проекты, в которых есть запись в `project_assignments`
- `activeContractsCount` считает статусы INTENT + SIGNED + ACTIVE вместе

## Related ADRs

- `docs/03_decisions/34_ui-interaction-patterns.md`
- `docs/03_decisions/29_project-lifecycle.md`
