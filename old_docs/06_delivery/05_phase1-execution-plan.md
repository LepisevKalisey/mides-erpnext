# Фаза 1: L2-COMMIT — Subcontract Slice. Детальный план v2

**Тип:** Delivery how-to  
**Дата:** 2026-05-22  
**Статус:** Активен  
**Версия:** 2.0 — риски Pre-Mortem интегрированы в слайсы  
**Ссылка:** `docs/06_delivery/03_anti-big-bang-roadmap.md` §Фаза 1  
**Замечает:** v1 (план без учёта Pre-Mortem рисков)

---

## Принцип этого плана

> Риск — это не отдельная задача. Риск — это **архитектурное требование**,
> встроенное в слайс, который его порождает. Если слайс создаёт точку,
> где риск может сработать — слайс обязан закрыть митигацию.

**Следствие:** порядок слайсов определяется **зависимостями между рисками**, а не порядком конвеера.

---

## Цель фазы

Провести жизнь субподрядной заявки end-to-end:

```
PM создаёт заявку
  → Директор утверждает (или auto-approve по матрице)
    → Казначей платит (warranty вычитается автоматически)
      → Прораб принимает физически
        → Документы (АВР + OCR с confidence gate)
          → ПТО проверяет → COMMITTED
            → Бухгалтерия (ЭСФ → проводка)
              → Лицевой счёт субподрядчика = корректный баланс
```

**Инвариант Gall's Law:** каждый Slice должен быть проходим в UI полностью до начала следующего.

---

## Матрица «Слайс → Риск → Митигация»

Каждый слайс отвечает за **конкретные митигации**. DoD слайса не закрыт, пока митигация не работает.

| Слайс | Функция | Риск | Митигация в этом слайсе |
|-------|---------|------|------------------------|
| 1.3 Казначей | Запись оплаты | **🔴#2** Warranty | `net = amount × (1 − warranty%/100)` авто-расчёт |
| 1.2 Директор | Утверждение | **🟠#3** Bottleneck | Approval Matrix проверяется в потоке |
| 2.1 Прораб | Физприёмка | **🟠#4** OCR | confidence field, обязательная ручная проверка |
| 3.1 ПТО | COMMITTED | **🟡#5** God Table | Ревью схемы перед добавлением task-таблиц |

> [!IMPORTANT]
> Риски #1 (договор-блокер) и #5 (God Table) уже закрыты архитектурно.  
> Риск #6 (прораб не вводит) — планово отложен до Ф3 с описанной митигацией.

---

## Human Acceptance Test (HAT) — обязательный протокол

Каждый слайс завершается **инструкцией для ручного тестирования**, которую агент создаёт в конце рабочего чата.

Формат HAT:
```
## Ручной тест: [название слайса]

**Предусловия:** [какие данные должны быть в системе]

### Сценарий 1: [название]
1. Зайди как [роль] (логин: ...)
2. Открой [страница]
3. Нажми [кнопка]
4. Ожидание: [что должно произойти]
✅ Пасс: [критерий]
❌ Фейл: [что считается ошибкой]
```

> [!IMPORTANT]
> **Слайс не считается завершённым**, пока агент не выдал HAT-инструкцию и человек не подтвердил прохождение.

---

## Текущее состояние (что уже реализовано)

| Слайс | Статус | Митигация |
|-------|:------:|:---------:|
| 1.1 PM создаёт заявку | ✅ Done | — |
| 1.2 Директор утверждает | ✅ Done + approval matrix | ✅ 🟠#3 закрыт |
| 1.3 Казначей платит | ✅ Done + warranty calc | ✅ 🔴#2 закрыт |
| 1.4 AP Advance Form | ✅ Done | — |
| current_stage VIEW | ✅ Done (2026-05-22) | Сквозной — `current_stage_view`, миграция 0011 |
| 2.1 Физприёмка | ❌ | 🟠#4 |
| 2.2 АВР + OCR | ❌ | 🟠#4 |
| 3.1 ПТО → COMMITTED | ❌ | — |
| 3.2 Бухгалтерия | ❌ | — |
| Ledger VIEW | ❌ | 🔴#2, 🟠#3 |

---

## Оставшиеся слайсы: 4 группы

### Принцип упорядочивания

```
Риски сначала → Конвеер потом → Баланс в конце
```

Мы **не** продвигаемся по конвееру, пока не закрыты митигации в уже реализованных слайсах.

```
[A] Усиление 1.2 + 1.3     — закрытие 🔴#2 и 🟠#3  (2 дня)
[B] current_stage VIEW       — сквозной компонент      (0.5 дня)
[C] Слайс 2.1–2.2           — физприёмка + АВР + 🟠#4 (4 дня)
[D] Слайс 3.1–3.2 + Ledger  — COMMITTED + Ledger       (3 дня)
```

> [!IMPORTANT]
> **[A] идёт ПЕРЕД [C]** — потому что Ledger [D.2] зависит от `warranty_retention_amount`,
> который создаётся в [A.1]. Без этого порядка Ledger будет неправильным — 
> а это именно тот сценарий, который описывает 🔴 Риск #2.

---

### [A] Усиление существующих слайсов (2 дня)

> Не новые функции — **достройка митигаций** в уже реализованном коде.

#### A.1: Warranty Calculation (Слайс 1.3) — закрывает 🔴 Риск #2

**Точка вставки:** `RecordPaymentSheet` → `recordPayment` action

Сейчас:
```
казначей вводит сумму → сумма уходит целиком → warranty_percent игнорируется
```

Должно быть:
```
казначей вводит полную сумму →
  система автоматически рассчитывает:
    warranty_retention = amount × (contract.warranty_percent / 100)
    net_payment = amount − warranty_retention
  → в payment_task записываются ОБА значения
  → в UI отображается: «Оплата: X ₸, Удержание: Y ₸ (Z%), К выплате: W ₸»
```

Изменения:
- `recordPayment` action: query `contract.warranty_percent`, рассчитать, записать
- `payment_tasks` schema: добавить `warranty_retention_amount NUMERIC`
- `RecordPaymentSheet`: отображение расчёта перед подтверждением
- Default `warranty_percent = 5%` при создании договора

**DoD A.1:** ✅ Done (2026-05-22)
- [x] При записи оплаты warranty рассчитывается автоматически
- [x] Казначей видит разбивку ДО подтверждения
- [x] `payment_tasks.warranty_retention_amount` заполняется
- [x] 🔴 Риск #2: **ЗАКРЫТ**

#### A.2: Approval Matrix Integration (Слайс 1.2) — закрывает 🟠 Риск #3

**Точка вставки:** `approveCommitment` action + `createCommitment` action

Сейчас:
```
PM создаёт → всегда летит к Директору → Директор утверждает
approval_matrix страница существует, но не подключена к потоку
```

Должно быть:
```
PM создаёт →
  система проверяет approval_matrix:
    if (сумма <= pm_limit для данного проекта) → auto-approve, skip директора
    if (сумма > pm_limit) → PENDING в очереди Директора
  → PM видит: «Утверждена автоматически (лимит PM: X ₸)» или «На утверждении»
```

Изменения:
- `createCommitment` action: после создания, query `approval_matrix` для проекта + роль PM
- Если сумма ≤ лимита → `approval_task.status = APPROVED`, автоматически
- `ApprovalsGrid`: показать авто-утверждённые отдельным бейджом
- Пакетное утверждение: кнопка «Утвердить выбранные» в `ApprovalsGrid`

**DoD A.2:** ✅ Done (2026-05-22)
- [x] Заявки в пределах лимита PM проходят без Директора
- [x] Пакетное утверждение работает
- [x] 🟠 Риск #3: **ЗАКРЫТ**

---

### [B] current_stage VIEW (0.5 дня)

> Сквозной компонент, необходимый ДО физприёмки.

```sql
CREATE VIEW current_stage AS
SELECT
  pi.id,
  CASE
    WHEN EXISTS (SELECT 1 FROM accounting_tasks at
      WHERE at.purchase_item_id = pi.id AND at.status = 'DONE'
      AND at.task_type = 'POSTING_CONFIRM') THEN 'POSTED'
    WHEN pi.data_status = 'COMMITTED' THEN 'COMMITTED'
    WHEN EXISTS (SELECT 1 FROM avr_documents ad
      WHERE ad.purchase_item_id = pi.id AND ad.status = 'APPROVED') THEN 'AVR_APPROVED'
    WHEN EXISTS (SELECT 1 FROM avr_documents ad
      WHERE ad.purchase_item_id = pi.id AND ad.status = 'SUBMITTED') THEN 'AVR_SUBMITTED'
    WHEN EXISTS (SELECT 1 FROM physical_acceptance_tasks pat
      WHERE pat.purchase_item_id = pi.id AND pat.status = 'ACCEPTED') THEN 'PHYSICALLY_ACCEPTED'
    WHEN EXISTS (SELECT 1 FROM payment_tasks pt
      WHERE pt.purchase_item_id = pi.id AND pt.status = 'PAID') THEN 'PAID'
    WHEN EXISTS (SELECT 1 FROM commitment_approval_tasks cat
      WHERE cat.purchase_item_id = pi.id AND cat.status = 'APPROVED') THEN 'APPROVED'
    WHEN EXISTS (SELECT 1 FROM commitment_approval_tasks cat
      WHERE cat.purchase_item_id = pi.id AND cat.status = 'PENDING') THEN 'PENDING_APPROVAL'
    ELSE 'DRAFT'
  END AS stage
FROM purchase_items pi;
```

**DoD B:**
- [x] VIEW создан и работает (`current_stage_view` — миграция 0011)
- [x] `CommitmentsGrid` использует `currentStage` из VIEW вместо `getEffectiveStatus` ad-hoc
- [x] `getCommitmentsForAll` и `getCommitmentsForPM` обогащены через `injectCurrentStage()`
- [x] Инвариант #21: статус никогда не хранится, всегда вычисляется ✅ Done (2026-05-22)


---

### [C] Физприёмка + АВР (4 дня)

> Новый функционал. Риск #4 встроен в DoD.

#### C.1: Физприёмка (Прораб) — 2 дня

Schema: `physical_acceptance_tasks` (описана в v1 плана)  
UI: `PhysicalAcceptanceSheet` в `/requests` для FOREMAN  
Action: `recordPhysicalAcceptance(id, data)`

Page Spec: `docs/04_architecture/12_page-spec-physical-acceptance.md`

**DoD C.1:**
- [ ] Прораб видит PAID заявки своих объектов
- [ ] Отмечает приёмку с фото и датой

#### C.2: АВР + OCR Gate — 2 дня — закрывает 🟠 Риск #4

Schema: `avr_documents` + `avr_document_lines` (описана в v1 плана)

**Митигация Риска #4 встроена в дизайн:**

```
OCR-скан →
  если confidence >= 85%: поля заполнены, ПТО видит «✅ Высокая уверенность»
  если confidence < 85%: поля подсвечены красным, ОБЯЗАТЕЛЬНА ручная правка
  всегда: ПТО видит кнопку «Подтвердить данные» перед SUBMITTED
```

- `avr_document_lines.ocr_confidence` — обязательное поле при OCR
- Нет автоматического SUBMITTED — только после ручного подтверждения
- Корректировочный документ: `avr_documents.parent_avr_id` для AVR_ADJUSTMENT

Page Spec: `docs/04_architecture/13_page-spec-avr-form.md`

**DoD C.2:**
- [ ] АВР создаётся с cost_code по строкам (ADR-41)
- [ ] OCR заполняет поля + confidence badge
- [ ] confidence < 85% → ручная правка обязательна
- [ ] 🟠 Риск #4: **ЗАКРЫТ** (митигация в дизайне, не пост-фактум)

---

### [D] COMMITTED + Ledger + Бухгалтерия (3 дня)

#### D.1: ПТО → COMMITTED — 1 день

Action: `approveAVR` → `data_status = COMMITTED`  
UI: в `/requests` для PTO — видит SUBMITTED АВР, принимает/отклоняет

Page Spec: `docs/04_architecture/14_page-spec-pto-review.md`

#### D.2: Ledger VIEW — 1 день

```sql
CREATE VIEW contractor_ledger AS
SELECT
  c.id AS contractor_id,
  c.name,
  con.id AS contract_id,
  SUM(pt.amount_paid) AS total_paid,
  SUM(pt.warranty_retention_amount) AS total_retained,  -- из [A.1]
  SUM(CASE WHEN pi.data_status = 'COMMITTED'
    THEN avr.total_amount ELSE 0 END) AS total_committed,
  SUM(pt.amount_paid) - SUM(pt.warranty_retention_amount) - SUM(...) AS balance
FROM contractors c
JOIN contracts con ON ...
JOIN purchase_items pi ON ...
LEFT JOIN payment_tasks pt ON ...
LEFT JOIN avr_documents avr ON ...
GROUP BY c.id, c.name, con.id;
```

> [!NOTE]
> Ledger корректен ТОЛЬКО потому, что в [A.1] мы уже заложили `warranty_retention_amount`.  
> Без [A.1] Ledger показывал бы неправильный баланс → 🔴 Риск #2.

**DoD D.2:**
- [ ] VIEW показывает: оплачено / удержано / committed / баланс
- [ ] UI: таблица Ledger на карточке контрагента

#### D.3: Бухгалтерский стол — 1 день

Schema: `accounting_tasks` (описана в v1 плана)  
Триггер: `avr APPROVED` → auto-create 3 tasks  
UI: `/accounting` для ACCOUNTANT

Page Spec: `docs/04_architecture/15_page-spec-accounting.md`

**DoD D.3:**
- [ ] Бухгалтер видит задачи по COMMITTED заявкам
- [ ] Отмечает ЭСФ, проводку

---

## Сводная таблица: Слайс → Риск → Статус

| Слайс | Риск | Митигация | Когда закрыт |
|-------|:----:|-----------|:------------:|
| **[A.1]** Warranty Calc | 🔴#2 | Auto-calc + default 5% + UI preview | DoD A.1 |
| **[A.2]** Approval Matrix | 🟠#3 | Matrix → auto-approve < limit + batch | DoD A.2 |
| **[C.2]** АВР + OCR | 🟠#4 | confidence gate + manual confirm | DoD C.2 |
| — (ADR-38) | 🟡#5 | task-per-role, уже закрыт | ✅ Ф0 |
| — (INTENT) | 🔴#1 | Мягкий статус, уже закрыт | ✅ Ф0 |
| — (Ф3) | 🟡#6 | Отложен планово | ⏳ Ф3 |

---

## Порядок выполнения

```
[A.1] Warranty Calc ─────────────────── 1 день
[A.2] Approval Matrix Integration ───── 1 день
[B]   current_stage VIEW ────────────── 0.5 дня
[C.1] Физприёмка ────────────────────── 2 дня
[C.2] АВР + OCR Gate ───────────────── 2 дня
[D.1] ПТО → COMMITTED ──────────────── 1 день
[D.2] Ledger VIEW ───────────────────── 1 день
[D.3] Бухгалтерский стол ───────────── 1 день
                                        ────────
                                        ~9.5 дней
```

---

## Definition of Done — Фаза 1

### Функциональные
- [ ] Full E2E: PM → Директор → Казначей → Прораб → АВР → ПТО → COMMITTED → Бухгалтерия
- [ ] Ledger VIEW показывает корректный баланс
- [ ] current_stage VIEW заменяет все ad-hoc вычисления

### Риски
- [ ] 🔴#2 **ЗАКРЫТ**: warranty вычитается автоматически при каждой оплате
- [ ] 🟠#3 **ЗАКРЫТ**: заявки ≤ лимита PM проходят без директора
- [ ] 🟠#4 **ЗАКРЫТ**: OCR confidence < 85% → обязательная ручная проверка
- [ ] 🟡#5 **КОНТРОЛИРУЕМ**: ни одна таблица > 15 колонок

### Технические
- [ ] `npm run lint` — 0 ошибок
- [ ] `npx tsc --noEmit` — 0 новых ошибок
- [ ] `npm run context:check` — 0 ошибок
- [ ] `docs-index` обновлён
- [ ] `git tag v0.2.0-F1`

---

## Связанные документы

- `docs/06_delivery/03_anti-big-bang-roadmap.md` — источник Фазы 1 + Pre-Mortem риски
- `docs/03_decisions/38_task-per-role-architecture.md` — task таблицы
- `docs/03_decisions/42_requests-registry-view-model.md` — маршруты и роли
- `docs/03_decisions/41_cost-code-at-avr-line-level.md` — ADR-41 инвариант
- `docs/03_decisions/21_subcontractor-ledger.md` — лицевой счёт
- `docs/03_decisions/17_warranty-retention.md` — гарантийные удержания
- `docs/04_architecture/02_page-spec-template.md` — шаблон спека
