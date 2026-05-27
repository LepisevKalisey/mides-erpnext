# Page Spec: Сотрудники

## Route

`/dashboard/employees`

## Agent

Frontend Agent (see AGENTS.md §2)

## Layout

AccordionGrid — двухуровневый: Отдел → Сотрудники отдела (expandable rows)

## Data Source

- Server Action: `getEmployees(filters?)`
- Schema tables: `employees`, `departments`, `positions`, `legal_entities`
- Joins:
  - `employees` LEFT JOIN `departments` ON `department_id`
  - `employees` LEFT JOIN `positions` ON `position_id`
  - `employees` LEFT JOIN `legal_entities` ON `legal_entity_id`

## Components

| Component | Type | Props |
|---|---|---|
| DepartmentRow | AccordionGrid row (L1) | department: Department, employeeCount: number |
| EmployeeRow | AccordionGrid leaf row (L2) | employee: Employee, position: Position? |
| EmployeeExpanded | Expand panel | employee: Employee, department, position, legalEntity |
| CreateEmployeeSheet | Sheet panel (right) | onSubmit: (data) => void |
| EditEmployeeSheet | Sheet panel (right) | employee: Employee, onSubmit |
| CreateDepartmentSheet | Sheet panel (right) | onSubmit: (data) => void |

## Interactions

| Action | Trigger | Result |
|---|---|---|
| Add employee | FAB «+ Сотрудник» | Sheet opens from right — выбор отдела, должности, юрлица |
| Edit employee | Leaf row expand → edit icon | Sheet opens with prefilled data |
| Add department | Toolbar «+ Отдел» | Sheet opens from right |
| Filter by department | Toolbar select | Collapse/filter по department_id |
| Search by name | Text input | Фильтрация по `full_name` (client-side) |
| Fire employee | Leaf row expand → «Уволить» | Confirmation → Server Action: setFiredAt(today) |

## Filters & Sorting

| Field | Type | Default |
|---|---|---|
| departmentId | select: список отделов / Все | «Все» |
| isActive | select: Работает / Уволен / Все | «Работает» |
| search | text input (по имени) | «» |

## Status Badges

| Status | Color Token | Label (ru) |
|---|---|---|
| firedAt = null | `--status-active` | Работает |
| firedAt != null | `--status-neutral` | Уволен |

## Employee Card (в раскрытой строке)

```
ФИО:         Иванов Иван Иванович
ИИН:         123456789012
Телефон:     +7 777 123 45 67
Email:       ivanov@mides.kz
Отдел:       Строительный департамент
Должность:   Начальник участка
Юрлицо:      ТОО «МиДЭС»
Принят:      01.01.2024
Доступ в системе: [иконка CheckCircle если profileId != null | иконка XCircle]
```

## Invariants

- `iin` уникален (DB constraint) — валидация на уровне Server Action при создании
- Сотрудник без `firedAt` считается активным
- «Уволить» не удаляет запись — только устанавливает `firedAt = NOW()`
- Уволенные сотрудники не удаляются из `project_assignments` автоматически
  — это ответственность бизнес-логики (будущая фаза)
- `profileId` — опционален: сотрудник может существовать без доступа в систему
- Если `profileId != null` — показывать иконку «Есть доступ» (CheckCircle, `--status-active`)

## Related ADRs

- `docs/03_decisions/03_role-as-position.md`
- `docs/03_decisions/07_accordion-table-standard.md`
- `docs/03_decisions/31_org-structure-and-roles.md`
- `docs/03_decisions/34_ui-interaction-patterns.md`
