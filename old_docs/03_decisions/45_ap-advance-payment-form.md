# ADR-045: Форма запроса аванса субподрядчику — AP Best Practices

**Статус:** Принят  
**Дата:** 2026-05-21  
**Связан с:** ADR-38 (task-per-role), ADR-42 (requests registry), ADR-43 (payment tasks), ADR-21 (subcontractor ledger)

---

## Контекст

Исследование мировых ERP-систем (SAP S/4HANA, Oracle Primavera, Procore, Sage 300 CRE)
показало: в строительном AP существует два принципиально разных типа платежей субподрядчику:

| Тип | commitment_type | Триггер | Экономический смысл |
|-----|-----------------|---------|---------------------|
| Аванс | `ADVANCE` | Решение PM/ГИП/Прораба | Деньги вперёд → создаёт дебиторский долг подрядчика |
| Оплата по АВР | `SUBCONTRACT` | Подтверждённый АВР | Деньги за факт → закрывает кредиторский долг компании |
| Возврат удержания | `RETENTION` | Истечение гарантийного срока | Разблокировка удержанных средств |

**Проблемы, которые решает этот ADR:**

1. Кнопка «+ Выплата» создавала `commitment_type = SUBCONTRACT` — неверная семантика.
2. Форма показывала поле «Договор» — пользователь должен знать номер договора заранее.
   В мировой практике (Procore, SAP) пользователь выбирает **контрагента** в контексте проекта/объекта.
3. Список проектов не фильтровался по роли пользователя.

---

## Решение

### 1. commitment_type = ADVANCE для формы выплаты аванса

Кнопка «+ Выплата» в `/requests` создаёт заявку с:

```
flow_type      = PAYMENT_APPLICATION
commitment_type = ADVANCE
```

`SUBCONTRACT` — только для оплаты подтверждённого АВР (будущий Слайс 2.2).

### 2. Каскад полей формы (AP-standard cascade)

```
Проект       → только те где user_id имеет project_role IN (GI, PM, SITE_MANAGER)
  ↓
Объект        → project_objects проекта
                Формат label: "Название (Бенефициар)" или "Название"
                Бенефициар: contractors.beneficial_owner.full_name через contracts
  ↓
Контрагент    → уникальные contractors, у которых есть contract WHERE
                  contract.project_id = выбранный_проект
                  AND (contract.object_id = выбранный_объект OR object_id IS NULL)
  ↓ [AUTO-FILL]
Наша компания → contracts.legal_entity_id (auto)
contract_id   → скрытый технический ID (auto)
  ↓
Назначение    → free text (аванс / погашение задолженности / другое)
Описание      → free text
Сумма         → numeric, KZT
```

**Почему объект перед контрагентом:**
На крупных проектах один подрядчик может иметь несколько договоров (на разные объекты).
Выбор объекта сужает список контрагентов до тех, у кого есть договор именно на этом объекте.

### 2.5 Информационный блок баланса контрагента

После выбора контрагента на форме динамически отображается блок с финансовыми показателями (`data-testid="contractor-balance-card"`):
- **Локальный баланс подр.** по выбранному проекту или объекту.
- **Сдано (АВР)**: общая сумма выполненных и подтверждённых АВР (`avr_sum`).
- **Выплачено**: общая сумма всех оплаченных заявок (`paid_sum`).
- **Всего (общий баланс)**: глобальный баланс контрагента по всем проектам и объектам в системе (`balanceGlobal`).

Это решает проблему создания избыточных авансов при наличии неиспользованных средств или непогашенного долга субподрядчика. Данные запрашиваются напрямую из представлений СУБД в режиме реального времени.

### 3. Новые Server Actions (requests/actions.ts)

```typescript
// Фильтр проектов по ролям PM/GI/SITE_MANAGER
getProjectsForCommitmentForm(): Promise<Project[]>

// Объекты проекта с бенефициарами
getObjectsForProject(projectId: string): Promise<{
  id: string;
  name: string;
  beneficialOwnerName: string | null;
}[]>

// Контрагенты, у которых есть договор на этом проекте/объекте
getContractorsForProjectObject(
  projectId: string,
  objectId?: string
): Promise<{
  contractorId: string;
  contractorName: string;
  contractId: string;
  legalEntityId: string;
  legalEntityName: string;
}[]>

// Live-fetch для CommitmentDetailsSheet (fix стагнации статуса)
getCommitmentById(id: string): Promise<CommitmentItem | null>
```

### 4. Исправление бага "статус не обновляется у инициатора"

**Корневая причина:** `CommitmentsGrid` хранит `useState(initialItems)`.
При `revalidatePath` SSR-кэш обновляется, но клиент уже смонтирован — state устарел.

**Решение:** В `CommitmentDetailsSheet` при каждом открытии (`open === true`)
вызывать `getCommitmentById(item.id)` и показывать живые данные.

---

## Инварианты

1. Форма «+ Выплата» → всегда `commitment_type = ADVANCE`
2. Список проектов → всегда фильтруется по `project_role IN (GI, PM, SITE_MANAGER)`
3. Список контрагентов → только те, у кого есть договор на выбранном проекте/объекте
4. `contract_id` → автозаполняется из выбора контрагента (не выбирается вручную)
5. Тип выплаты → free text (не enum), не ограничивать заранее

---

## Последствия

### Положительные
- Соответствует AP-стандарту SAP/Oracle/Procore (contractor-first selection)
- `ADVANCE` семантически правильно описывает бизнес-операцию
- Директор при утверждении видит правильный тип → понимает, что это аванс, а не оплата за факт
- Stateful баг статуса устранён

### Отрицательные
- Требует 3 новых Server Action в `requests/actions.ts`
- Форма становится 3-шаговым каскадом вместо 2-шагового

---

## Связанные документы

- `docs/03_decisions/21_subcontractor-ledger.md` — лицевой счёт субподрядчика
- `docs/03_decisions/38_task-per-role-architecture.md` — task-per-role
- `docs/03_decisions/42_requests-registry-view-model.md` — /requests экран
- `docs/03_decisions/43_payment-tasks-schema.md` — payment tasks
- `docs/02_research/01_ap-best-practices.md` — исходное исследование AP
