# ADR-021: Субподрядный лицевой счёт — модель с несколькими договорами

**Status:** Accepted  
**Date:** 2026-05-07

## Context

У одного контрагента может быть:
- Несколько договоров одновременно (на разные объекты)
- Один договор, но АВР разделяются по разным объектам

Карточка контрагента должна давать полную картину финансовых отношений
с учётом этой сложности.

## Decision

### Структура карточки контрагента

#### Уровень 1: Сводка по контрагенту (все договоры)

```
ТОО «СтройМонтаж»
──────────────────────────────────────────────
Договоров активных:    3
Общая сумма договоров: 45 000 000 ₸
Выплачено всего:       18 000 000 ₸
Удержано (гарантия):    1 500 000 ₸
Посаженные расходы:    15 000 000 ₸ (АВР + ЭСФ)
Ожидают ЭСФ:           2 000 000 ₸
```

#### Уровень 2: Разбивка по договорам

Каждый договор раскрывается отдельным блоком:

```
📄 Договор №15 «ЖК Мирас — Монолитные работы»
   Сумма договора:         20 000 000 ₸
   Доп. соглашения:         2 000 000 ₸
   Текущая сумма:          22 000 000 ₸
   Выплачено:               8 000 000 ₸
     из них аванс:          3 000 000 ₸
     из них по АВР:         5 000 000 ₸
   Гарантийное удержание 5%:  400 000 ₸
   Чистые выплаты:          7 600 000 ₸
   Долг по авансу:              0 ₸ (аванс покрыт АВР)
   Остаток к выполнению:   14 000 000 ₸
   Гарантия до:            01.03.2028

📄 Договор №22 «ЖК Парк — Отделка»
   ...
```

#### Уровень 3: АВР в рамках договора

АВР всегда привязаны к договору, но могут относиться к разным объектам:

```
АВР №1 от 01.03.2026   500 000 ₸  Объект: ЖК Мирас корп. А   ✅ АВР+ЭСФ
АВР №2 от 01.04.2026   800 000 ₸  Объект: ЖК Мирас корп. Б   ⏳ Ожидает ЭСФ
АВР №3 от 15.04.2026   300 000 ₸  Объект: ЖК Мирас корп. А   ❌ Отказано
```

### Модель данных

Существующая структура уже поддерживает это:

```
contractors (контрагент)
  └── contracts[] (договоры, каждый с object_id)
        └── avr[] (АВР, каждый с собственным object_id)
              └── payments[] (через requests и payment_allocations)
```

Запрос для сводки:
```sql
-- Все договоры контрагента с агрегатами
SELECT
  c.id, c.number, c.amount, c.warranty_percent, c.warranty_amount_held,
  COALESCE(SUM(p.amount), 0) AS total_paid,
  COALESCE(SUM(CASE WHEN r.is_advance THEN r.amount END), 0) AS advance_paid,
  COALESCE(SUM(a.amount) FILTER (WHERE a.status = 'ESF_RECEIVED'), 0) AS expense_posted,
  COALESCE(SUM(a.amount) FILTER (WHERE a.status = 'AVR_APPROVED'), 0) AS pending_esf
FROM contracts c
LEFT JOIN avr a ON a.contract_id = c.id
LEFT JOIN requests r ON r.contract_id = c.id
LEFT JOIN payments p ON p.contract_id = c.id
WHERE c.contractor_id = $1
GROUP BY c.id;
```

### Что означает «объект» в АВР

Поле `avr.object_id` позволяет разбить работы по договору на физические участки.
Пример: договор на «Отделку корпусов» может иметь АВР по каждому корпусу отдельно.

## Consequences

- **+** Полная картина финансовых отношений в одном месте
- **+** Существующая схема уже поддерживает нужные связи
- **+** Нет необходимости в изменении схемы БД — только запросы и UI
- **−** Сложный агрегирующий SQL — требует индексов на FK колонках

## Индексы (добавить в миграцию)

```sql
CREATE INDEX IF NOT EXISTS idx_contracts_contractor_id ON midescloud.contracts(contractor_id);
CREATE INDEX IF NOT EXISTS idx_avr_contract_id ON midescloud.avr(contract_id);
CREATE INDEX IF NOT EXISTS idx_avr_contractor_id ON midescloud.avr(contractor_id);
CREATE INDEX IF NOT EXISTS idx_requests_contract_id ON midescloud.requests(contract_id);
CREATE INDEX IF NOT EXISTS idx_payments_contractor_id ON midescloud.payments(contractor_id);
CREATE INDEX IF NOT EXISTS idx_payments_contract_id ON midescloud.payments(contract_id);
```

## Related

- See: `docs/03_decisions/15_avr-lifecycle-esf.md`
- See: `docs/03_decisions/17_warranty-retention.md`
- See: `docs/03_decisions/04_contractor-hierarchy.md`
