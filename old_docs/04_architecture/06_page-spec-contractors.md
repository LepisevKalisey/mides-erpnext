# Page Spec: Контрагенты

## Route

`/dashboard/contractors`

## Agent

Frontend Agent (see AGENTS.md §2)

## Layout

AccordionGrid — expandable rows, в раскрытом виде: информация о бенефициаре и тип контрагента

## Data Source

- Server Action: `getContractors(filters?)`
- Schema tables: `contractors`, `beneficial_owners`
- Join: `contractors` LEFT JOIN `beneficial_owners` ON `contractors.beneficial_owner_id = beneficial_owners.id`

## Components

| Component | Type | Props |
|---|---|---|
| ContractorRow | AccordionGrid row | contractor: Contractor |
| ContractorExpanded | Expand panel | contractor: Contractor, beneficialOwner: BeneficialOwner \| null |
| CreateContractorSheet | Sheet panel (right) | onSubmit: (data) => void |
| EditContractorSheet | Sheet panel (right) | contractor: Contractor, onSubmit |

## Interactions

| Action | Trigger | Result |
|---|---|---|
| Create contractor | FAB «+ Контрагент» | Sheet opens from right |
| Edit contractor | Row expand → edit icon | Sheet opens with prefilled data |
| Link beneficial owner | Expanded → поле «Бенефициар» → select | Server Action: linkBeneficialOwner |
| Filter by type | Toolbar select | Re-fetch с параметром contractorType |

## Filters & Sorting

| Field | Type | Default |
|---|---|---|
| contractorType | select: Компания / Физлицо / Все | «Все» |
| search | text input (по названию / БИН) | «» |

## Status Badges

| Status | Color Token | Label (ru) |
|---|---|---|
| contractorType = COMPANY | `--status-info` | Компания |
| contractorType = INDIVIDUAL | `--status-neutral` | Физлицо |

## Beneficial Owner Block (в раскрытой строке)

Если `beneficialOwnerId != null`:
```
Бенефициар: Ернар Каратаев
ИИН:        123456789012
Телефон:    +7 777 000 00 00
```

Если `beneficialOwnerId = null`:
```
Бенефициар: не указан  [кнопка «+ Привязать»]
```

## Invariants

- `bin` уникален среди всех contractors (DB constraint, nullable для физлиц)
- Запрет удаления контрагента, если он привязан к `contracts` (проверка в Server Action)
- `INDIVIDUAL`-тип может не иметь `bin`
- Связь бенефициара: `contractors.beneficial_owner_id → beneficial_owners.id`
  (НЕ обратная — `beneficial_owners` не имеет `contractor_id`)

## Related ADRs

- `docs/03_decisions/04_contractor-hierarchy.md`
- `docs/03_decisions/07_accordion-table-standard.md`
- `docs/03_decisions/20_contractor-volume-limit.md`
- `docs/03_decisions/34_ui-interaction-patterns.md`
- `docs/03_decisions/37_beneficial-owner-visibility.md`
