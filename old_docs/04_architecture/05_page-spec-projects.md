# Page Spec: Проекты

## Route

`/dashboard/projects`

## Agent

Frontend Agent (see AGENTS.md §2)

## Layout

AccordionGrid — expandable rows showing project objects, assignments, and bank accounts

## Data Source

- Server Action: `getProjects()`
- Schema tables: `projects`, `project_objects`, `project_assignments`, `project_bank_accounts`, `bank_accounts`
- Joins: LEFT JOIN all child tables

## Components

| Component | Type | Props |
|---|---|---|
| ProjectRow | AccordionGrid row | project: Project |
| ProjectExpanded | Expand panel (tabs) | project, objects, assignments, bankAccounts |
| ObjectsTab | Tab content | objects: ProjectObject[] |
| TeamTab | Tab content | assignments: ProjectAssignment[] |
| CreateProjectSheet | Sheet panel (right) | onSubmit: (data) => void |
| AddObjectSheet | Sheet panel (right) | projectId: string, onSubmit |
| AssignUserSheet | Sheet panel (right) | projectId: string, onSubmit |

## Interactions

| Action | Trigger | Result |
|---|---|---|
| Create project | FAB "+ Проект" | Sheet opens from right |
| Edit project | Row expand → edit icon | Sheet opens with prefilled data |
| Add object | Expanded → Objects tab → "+ Объект" | Sheet opens from right |
| Assign user | Expanded → Team tab → "+ Участник" | Sheet: select user + role |
| Toggle active | Expanded → header switch | Server Action: toggleProjectActive |
| Link bank account | Expanded → Bank tab → "+ Счёт" | Sheet: select from existing bank_accounts |

## Filters & Sorting

| Field | Type | Default |
|---|---|---|
| isActive | select: Активные / Завершённые / Все | "Активные" |
| search | text input | "" |

## Status Badges

| Status | Color Token | Label (ru) |
|---|---|---|
| isActive=true | `--status-active` | Активен |
| isActive=false | `--status-neutral` | Завершён |

## Invariants

- Project must have at least one legal_entity as GI (Генеральный инвестор) before activation
- Project can have multiple objects (buildings/sections)
- User can be assigned to project-level OR object-level (objectId nullable)
- workStream is only valid at object level (CIVIL | MEP)

## Related ADRs

- `docs/03_decisions/07_accordion-table-standard.md`
- `docs/03_decisions/29_project-lifecycle.md`
- `docs/03_decisions/30_object-as-project-child.md`
- `docs/03_decisions/34_ui-interaction-patterns.md`
