# ADR-023: Жизненный цикл АВР — Пул, Справка, Накопительный учёт

**Status:** Accepted  
**Date:** 2026-05-07  
**Version:** 3 (финальная после уточнений)

## Context

АВР — это два документа в одном физическом пакете:
1. **Основной лист** — бухгалтерский акт (сумма, стороны, период)
2. **Справка** — детализация по видам работ (как в договоре, но с фактическими объёмами)

Справка — это не просто приложение. Это основа для:
- Накопительного учёта исполнения договора по объёмам
- Контроля не переплаты (выполнено ≤ договорного объёма)
- Оценки прогресса на объекте не только в деньгах, но и в м², м³, пог.м

## Decision

### Структура данных

```
contracts
  └── contract_items[]          ← спецификация (Schedule of Values)
        │  work_type | unit | total_quantity | unit_price
        │
        └── avr_line_items[]    ← строки справки каждого АВР
              quantity_this_period | cumulative_quantity

avr
  └── avr_line_items[]          ← справка этого АВР
  └── avr_approvals[]           ← цифровые окунания
```

#### `contract_items` — Спецификация договора

```sql
CREATE TABLE contract_items (
  id              UUID PRIMARY KEY,
  contract_id     UUID NOT NULL REFERENCES contracts(id),
  sort_order      INT DEFAULT 0,
  work_type       TEXT NOT NULL,          -- «Монолитные работы», «Кирпичная кладка»
  unit            TEXT NOT NULL,          -- м², м³, пог.м, т, шт
  total_quantity  NUMERIC NOT NULL,       -- объём по договору
  unit_price      NUMERIC NOT NULL,
  total_amount    NUMERIC GENERATED ALWAYS AS (total_quantity * unit_price) STORED,
  executed_quantity NUMERIC DEFAULT 0,    -- накопленно по принятым АВР
  executed_amount   NUMERIC DEFAULT 0     -- накопленная сумма
);
```

#### `avr_line_items` — Справка к конкретному АВР

```sql
CREATE TABLE avr_line_items (
  id                   UUID PRIMARY KEY,
  avr_id               UUID NOT NULL REFERENCES avr(id),
  contract_item_id     UUID REFERENCES contract_items(id),  -- null = доп.работы
  work_type            TEXT NOT NULL,
  unit                 TEXT NOT NULL,
  quantity_this_period NUMERIC NOT NULL,    -- объём в этом АВР
  unit_price           NUMERIC NOT NULL,
  amount_this_period   NUMERIC GENERATED ALWAYS AS (quantity_this_period * unit_price) STORED,
  cumulative_quantity  NUMERIC,             -- нарастающим итогом включая этот АВР
  cumulative_amount    NUMERIC,
  ocr_extracted        BOOLEAN DEFAULT false
);
```

### Накопительная таблица исполнения договора

Автоматически строится из `avr_line_items` по принятым АВР:

```sql
SELECT
  ci.work_type,
  ci.unit,
  ci.total_quantity                              AS "По договору",
  COALESCE(SUM(ali.quantity_this_period), 0)    AS "Выполнено",
  ci.total_quantity - COALESCE(SUM(ali.quantity_this_period), 0) AS "Остаток",
  ROUND(COALESCE(SUM(ali.quantity_this_period), 0) / ci.total_quantity * 100, 1) AS "% выполнения",
  ci.total_amount                                AS "Сумма по договору",
  COALESCE(SUM(ali.amount_this_period), 0)      AS "Оплачено"
FROM contract_items ci
LEFT JOIN avr_line_items ali ON ali.contract_item_id = ci.id
  AND ali.avr_id IN (
    SELECT id FROM avr WHERE pool_status IN ('AVR_RECOGNIZED', 'AVR_APPROVED', 'ESF_RECEIVED', 'EXPENSE_POSTED')
  )
WHERE ci.contract_id = $1
GROUP BY ci.id
ORDER BY ci.sort_order;
```

**Вид в UI:**
```
Договор №15 — ООО «Монолит» — ЖК Мирас корп. А
──────────────────────────────────────────────────────────────────────
Вид работ            Ед.   Договор   Выполнено  Остаток   %     Сумма
──────────────────────────────────────────────────────────────────────
Монолитные работы    м³    450.0     310.5      139.5    69%  3 105 000₸
Кирпичная кладка     м²    1 200     890        310      74%  2 670 000₸
Штукатурные работы   м²    800       0          800       0%          0₸
──────────────────────────────────────────────────────────────────────
ИТОГО                                                    51%  5 775 000₸
Сумма договора:                                               9 200 000₸
```

**Автоматическая защита от переплаты:**  
При создании строки AVR: если `cumulative_quantity > contract_item.total_quantity` →  
предупреждение: «Превышение объёма по договору. Требуется доп. соглашение».

---

### Пул АВР: механика роутинга (идентично пулу заявок)

Три способа назначения:

| Способ | Кто | Как |
|---|---|---|
| Авто-роутинг | Система | По `contracts.responsible_id` или `objects.responsible_id` |
| Назначение руководителем | Начальник ПТО / Главный инженер | Видят весь пул, назначают конкретному сотруднику |
| Самостоятельный захват | Любой сотрудник ПТО/ГИ | «Взять в работу» из общего пула |

```
АВР появился в пуле
    │
    ├─ Есть ответственный за объект в ПТО/ГИ?
    │     ДА → авто-назначение на него
    │     НЕТ → в общий пул
    │
    ├─ Начальник ПТО/ГИ видит весь пул и может:
    │     → назначить конкретному сотруднику
    │     → переназначить если занят
    │
    └─ Любой сотрудник ПТО/ГИ:
          → «Взять АВР» из общего пула (если не назначен)
```

Поле в `avr`: `pool_assigned_to` — конкретный исполнитель (или null = общий пул).

### Полный флоу АВР (финальная версия)

```
[Субподрядчик] → физически передаёт АВР с справкой начучастка
      │
[Начальник участка] — на объекте
      ├── Не ОК → возвращает субчику (pool_status = RETURNED_TO_CONTRACTOR)
      └── ОК → фотографирует обе страницы → загружает в систему
                    │
            pool_status = PHOTO_SUBMITTED
                    │
            Авто-роутинг → ПТО, ГИ, Бухгалтерия (параллельно, Этап 2)
                    │
            pool_status = POOL_REVIEW
                    │
            Директор (Этап 3, после Этапа 2)
                    │
            pool_status = ALL_APPROVED
                    │
            OCR запускается автоматически:
              - Страница 1: сумма, контрагент, период, подписи
              - Страница 2: виды работ, объёмы, цены → avr_line_items
                    │
            pool_status = AVR_RECOGNIZED
            avr_line_items созданы
            contract_items.executed_quantity обновлены
                    │
            Уведомление начучастка → водитель везёт бумагу в офис
            physical_status = IN_TRANSIT
                    │
            Бухгалтерия получает бумагу → physical_status = DELIVERED
                    │
            avr.status → AVR_APPROVED
                    │
            ESF_PENDING → ESF_RECEIVED → EXPENSE_POSTED ✓
```

### OCR многостраничного документа

Две страницы = два вызова OCR (или один с multi-page):

```typescript
// Edge Function при ALL_APPROVED
const page1 = await ocr(avr.scan_file_urls[0])  // основной лист
const page2 = await ocr(avr.scan_file_urls[1])  // справка (может быть несколько)

// Из страницы 2 парсим таблицу работ
const lineItems = parseWorkTable(page2)

// Создаём avr_line_items
for (const item of lineItems) {
  const contractItem = await matchToContractItem(item, avr.contract_id)
  await db.insert(avr_line_items).values({
    avr_id: avr.id,
    contract_item_id: contractItem?.id ?? null,
    work_type: item.work_type,
    unit: item.unit,
    quantity_this_period: item.quantity,
    unit_price: item.unit_price,
    ocr_extracted: true
  })
}

// Обновляем накопительные данные в contract_items
await updateCumulatives(avr.contract_id)
```

Если OCR не смог распознать строки справки → PM заполняет вручную.  
Основной лист (сумма) важнее — его OCR приоритет выше.

## Последствия

- **+** Накопительный учёт объёмов работ из коробки — сравнение план/факт
- **+** Контроль переплаты: система видит что объём исчерпан
- **+** Одна механика пула для заявок и АВР — меньше UX-паттернов
- **+** Файлы хранятся отдельно для каждой страницы → OCR точнее
- **−** Требует заполнения `contract_items` при создании договора (новая обязанность PM)
- **−** OCR справки с таблицей работ сложнее чем OCR первой страницы

## Related

- See: `docs/03_decisions/15_avr-lifecycle-esf.md`
- See: `docs/03_decisions/21_subcontractor-ledger.md`
- See: `docs/03_decisions/13_routing-model.md` — та же механика пула
