# Page Spec: Юридические лица

## Route

`/dashboard/legal-entities`

## Agent

Frontend Agent (see AGENTS.md §2)

## Layout

AccordionGrid — expandable rows showing bank accounts per entity

## Data Source

- Server Action: `getLegalEntities()`
- Schema tables: `legal_entities`, `bank_accounts`
- Join: `legal_entities` LEFT JOIN `bank_accounts` ON `legal_entity_id`

## Components

| Component | Type | Props |
|---|---|---|
| LegalEntityRow | AccordionGrid row | entity: LegalEntity |
| LegalEntityExpanded | Expand panel | entity: LegalEntity, bankAccounts: BankAccount[] |
| CreateEntitySheet | Sheet panel (right) | onSubmit: (data) => void |
| CreateBankAccountSheet | Sheet panel (right) | entityId: string, onSubmit: (data) => void |

## Interactions

| Action | Trigger | Result |
|---|---|---|
| Create entity | FAB "+ Юр. лицо" | Sheet opens from right |
| Edit entity | Row expand → edit icon | Sheet opens with prefilled data |
| Add bank account | Expanded row → "+ Счёт" button | Sheet opens from right |
| Toggle active | Expanded row → switch | Server Action: toggleBankAccountActive |

## Filters & Sorting

| Field | Type | Default |
|---|---|---|
| entityType | select: ТОО / ИП / Все | "Все" |
| isOwn | select: Свои / Контрагенты / Все | "Все" |
| search | text input | "" |

## Status Badges

| Status | Color Token | Label (ru) |
|---|---|---|
| isOwn=true | `--status-info` | Своя компания |
| isOwn=false | `--status-neutral` | Контрагент |
| ТОО | `--status-active` | ТОО |
| ИП | `--status-pending` | ИП |

## Invariants

- БИН must be unique across all legal_entities (DB constraint)
- Bank account deletion is soft (isActive=false), never hard delete
- Legal entity cannot be deleted if it has linked projects or contractors

## Related ADRs

- `docs/03_decisions/07_accordion-table-standard.md`
- `docs/03_decisions/34_ui-interaction-patterns.md`
