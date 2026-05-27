# ADR-47: Contract Items (Schedule of Values) для субподрядных и заказчических договоров

**Статус:** Accepted  
**Дата:** 2026-05-23  
**Контекст:** Gap Analysis юзерстори выявил, что без позиций договора невозможны: прогресс по работам, отклонения, P&L, проверка объёмов ПТО  
**Supersedes:** Частично дополняет ADR-41 (cost_code_id at AVR line level)

---

## Контекст

Текущая схема хранит договор (`contracts`) как единую сумму `total_amount` без детализации по видам работ. Это делает невозможным:

1. **Прогресс** — PM не видит «выполнено 60% кладки, 30% электрики»
2. **Отклонения** — PM не знает, что субчик превысил объём по позиции
3. **Проверка ПТО** — инженер не может сравнить АВР с договором
4. **P&L** — экономист не может посчитать маржу по видам работ
5. **Бухгалтерия** — не может проверить соответствие сумм договору

## Мировая практика (Procore, SAP, Oracle)

Все ведущие строительные ERP используют **трёхслойную модель**:

```
Layer 1: Cost Codes         — справочник видов работ (компания)
Layer 2: Contract Items/SOV — позиции конкретного договора (qty, price)
Layer 3: Progress Claims    — выполнение за период по позициям договора
```

AIA G702/G703 (американский стандарт), FIDIC (международный), НК РК (Казахстан) — все требуют привязку АВР к позициям договора, не к справочнику.

### Ключевой инсайт

> **Contract Items ≠ Cost Codes.** Один cost_code может встречаться в договоре несколько раз с разными объёмами и расценками (разные секции здания, разные условия).

## Решение

### 1. Таблица `contract_items`

```
contract_items (SOV — позиции договора)
  ├── id (uuid PK)
  ├── contract_id → contracts       ← какой договор
  ├── cost_code_id → cost_codes     ← классификационный мост (nullable)
  ├── line_number (integer)         ← порядковый номер
  ├── description (text NOT NULL)   ← наименование работы (свободный текст)
  ├── unit (text)                   ← ед. измерения (м², м³, шт, т)
  ├── qty_contracted (numeric 18,3) ← объём по договору
  ├── unit_price (numeric 18,2)     ← расценка
  ├── total_amount (numeric 18,2)   ← qty × price
  ├── created_at, updated_at
  └── CONSTRAINT: contract_id + line_number UNIQUE
```

**Правила:**
- `cost_code_id` — nullable. При ручном вводе позиций может быть не заполнен. OCR или ПТО заполняет позже.
- `description` — свободный текст, может отличаться от `cost_codes.name` (субчики пишут по-разному)
- `qty_contracted` — исходный объём. Изменяется только через допсоглашение (Change Order)
- `total_amount` = `qty_contracted × unit_price` — вычисляется при создании, хранится для скорости

### 2. Связь `avr_document_lines` → `contract_items`

Добавить `contract_item_id` FK в `avr_document_lines`:

```
avr_document_lines
  ├── contract_item_id → contract_items  ← НОВЫЙ: привязка к позиции договора
  ├── cost_code_id → cost_codes          ← СОХРАНЯЕТСЯ: аналитический мост
  └── ... (остальные поля без изменений)
```

**Dual FK Pattern** (как в Procore/SAP):
- `contract_item_id` = операционная ссылка (прогресс, биллинг, вариации)
- `cost_code_id` = аналитическая ссылка (кросс-проектная отчётность, budget vs actual)
- Redundant, но оба нужны для разных целей

### 3. Computed Views

```sql
-- Прогресс по позиции договора
CREATE VIEW contract_item_progress AS
SELECT
  ci.id,
  ci.contract_id,
  ci.description,
  ci.qty_contracted,
  COALESCE(SUM(adl.quantity), 0) AS qty_completed,
  ci.qty_contracted - COALESCE(SUM(adl.quantity), 0) AS qty_remaining,
  CASE
    WHEN COALESCE(SUM(adl.quantity), 0) > ci.qty_contracted * 1.05 THEN 'OVERRUN'
    WHEN COALESCE(SUM(adl.quantity), 0) < ci.qty_contracted * 0.95 THEN 'UNDERRUN'
    ELSE 'ON_TRACK'
  END AS variation_status
FROM contract_items ci
LEFT JOIN avr_document_lines adl 
  ON adl.contract_item_id = ci.id
  AND adl.avr_task_id IN (
    SELECT id FROM avr_tasks WHERE data_status = 'COMMITTED'
  )
GROUP BY ci.id;
```

### 4. Ввод данных: ручной → OCR → Excel

Компонент ввода позиций — **один и тот же** для всех способов:

```
[Ручной ввод] → ContractItemsEditor (inline table)
[OCR]          → AI распознаёт → заполняет ContractItemsEditor → человек проверяет
[Excel import] → парсер → заполняет ContractItemsEditor → человек проверяет
```

Этот компонент используется:
- При создании договора с субчиком (расходная сторона)
- При создании договора с заказчиком (доходная сторона, Ф3)
- При допсоглашении (Change Order, Ф3)

### 5. Инвариант `contracts.total_amount`

```
contracts.total_amount = SUM(contract_items.total_amount)
```

При добавлении/изменении позиций — автопересчёт суммы договора.
Если позиции не заполнены — total_amount задаётся вручную (обратная совместимость).

## Альтернативы

### A. Только cost_codes (текущее состояние)
**Отклонено.** Один cost_code может быть в договоре несколько раз с разными ценами. Невозможен прогресс.

### B. JSONB позиции внутри contracts
**Отклонено.** Нет FK, нет JOIN, нет агрегации SQL. Противоречит паттерну нормализации.

### C. contract_items ТОЛЬКО для Revenue (заказчик)
**Отклонено.** Субподрядный договор тоже требует SOV для прогресса и отклонений.

## Последствия

1. Таблица `contract_items` создаётся в Ф1 (текущая фаза)
2. `avr_document_lines.contract_item_id` добавляется как nullable FK
3. UI: `ContractItemsEditor` компонент в `CreateContractSheet` / `EditContractSheet`
4. OCR при загрузке АВР пытается матчить строки → `contract_items` по описанию/cost_code
5. Page Spec для Contracts обновляется — добавляется вкладка «Позиции»
6. Разблокирует юзерстори: 1.5, 1.6, 1.7, 2.2, 4.1, 4.2
