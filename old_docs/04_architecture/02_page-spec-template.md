# Page Spec: [Page Name]

> **Шаблон.** Скопируйте этот файл и заполните для каждого экрана модуля.

## Route

`/dashboard/[module]`

## Agent

Frontend Agent (see AGENTS.md §2)

## Layout

[AccordionGrid | DataTable | CardGrid | Form]

## Data Source

- Server Action: `getItems(projectId)`
- Schema tables: `table_name`

## Components

| Component | Type | Props |
|---|---|---|
| ItemRow | AccordionGrid row | item: Item |
| CreateSheet | Sheet panel (right) | onSubmit: (data) => void |

## Interactions

| Action | Trigger | Result |
|---|---|---|
| Create | FAB button | Sheet opens from right |
| Edit | Row click → expand → edit button | Sheet opens from right |
| Delete | Row expand → delete icon | Confirmation dialog → Server Action |
| Filter | Toolbar selects | Re-fetch with params |

## Filters & Sorting

| Field | Type | Default |
|---|---|---|
| status | select | "all" |
| search | text input | "" |

## Status Badges

| Status | Color Token | Label (ru) |
|---|---|---|
| draft | `--status-neutral` | Черновик |
| pending | `--status-pending` | На согласовании |
| active | `--status-active` | Активен |
| rejected | `--status-error` | Отклонён |

## Invariants

- [list from Blueprint §8 that apply to this page]

## Related ADRs

- `docs/03_decisions/07_accordion-table-standard.md`
- `docs/03_decisions/34_ui-interaction-patterns.md`
