# Page Spec: Договоры

## Route

`/dashboard/contracts`

## Agent

Frontend Agent (see AGENTS.md §2)

## Layout

AccordionGrid — expandable rows showing contract details, warranty info, and parties

## Data Source

- Server Action: `getContracts(filters?)`
- Schema tables: `contracts`, `projects`, `project_objects`, `legal_entities`, `contractors`
- Joins:
  - `contracts` JOIN `projects` ON `project_id`
  - `contracts` JOIN `legal_entities` ON `legal_entity_id`
  - `contracts` JOIN `contractors` ON `contractor_id`
  - `contracts` LEFT JOIN `project_objects` ON `object_id`

## Components

| Component | Type | Props |
|---|---|---|
| ContractRow | AccordionGrid row | contract: Contract, project: Project, contractor: Contractor |
| ContractExpanded | Expand panel (tabs) | contract, legalEntity, warrantyInfo |
| DetailsTab | Tab content | contract: Contract |
| PartiesTab | Tab content | legalEntity: LegalEntity, contractor: Contractor |
| CreateContractSheet | Sheet panel (right) | onSubmit: (data) => void |
| EditContractSheet | Sheet panel (right) | contract: Contract, onSubmit |
| AdvanceStatusSheet | Sheet panel (right) | contract: Contract, onSubmit |

## Interactions

| Action | Trigger | Result |
|---|---|---|
| Create contract | FAB «+ Договор» | Sheet opens from right — выбор проекта, объекта, юрлица, контрагента |
| Edit contract | Row expand → edit icon | Sheet opens with prefilled data (только в статусе INTENT) |
| Advance status | Row expand → «Изменить статус» | Sheet: выбор нового статуса + валидация инварианта |
| View details | Row click → expand | Inline expand с вкладками |
| Filter by status | Toolbar select | Re-fetch с параметром status |
| Filter by project | Toolbar select | Re-fetch с параметром projectId |

## Filters & Sorting

| Field | Type | Default |
|---|---|---|
| status | select: INTENT / SIGNED / ACTIVE / CLOSED / TERMINATED / Все | «Все» |
| projectId | select: список проектов | «Все» |
| search | text input (по номеру договора) | «» |

## Status Badges

| Status | Color Token | Label (ru) |
|---|---|---|
| INTENT | `--status-pending` | Намерение |
| SIGNED | `--status-info` | Подписан |
| ACTIVE | `--status-active` | Активен |
| CLOSED | `--status-neutral` | Закрыт |
| TERMINATED | `--status-error` | Расторгнут |

## Warranty Block (в раскрытой строке)

Показывается в блоке DetailsTab, если `warrantyPercent != null`:

```
Гарантийное удержание: X%
Дата возврата: [если endDate задана — endDate + warranty_period_months]
```

Если `status = SIGNED | ACTIVE | CLOSED` и `warrantyPercent = null` — показать
предупреждение-badge: `⚠ Гарантийный % не задан`.

## Invariants

- Переход `INTENT → SIGNED` **блокируется** если `warrantyPercent` не заполнен
  — Server Action должен бросать ошибку, UI показывает inline-ошибку в Sheet
- Переход `SIGNED → ACTIVE` разрешён без дополнительных условий
- Переход в `CLOSED | TERMINATED` — только из `ACTIVE`
- Редактирование полей договора (сумма, стороны) разрешено ТОЛЬКО в статусе `INTENT`
- Статус контракта меняется через `AdvanceStatusSheet`, не inline
- `contractNumber` уникален в пределах юрлица (валидация на уровне Server Action)
- Удаление договора запрещено — только перевод в `TERMINATED`

## Related ADRs

- `docs/03_decisions/07_accordion-table-standard.md`
- `docs/03_decisions/17_warranty-retention.md`
- `docs/03_decisions/24_contract-closeout.md`
- `docs/03_decisions/34_ui-interaction-patterns.md`
- `docs/03_decisions/38_task-per-role-architecture.md`
