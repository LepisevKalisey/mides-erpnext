# 32 Contractor Financial Summary — Trigger-Maintained Ledger

## Status
Accepted — реализовано 2026-05-12

## Context

При подаче заявки на оплату услуг пользователю необходима финансовая сводка по выбранному контрагенту:
- Сумма заключённых договоров
- Объём сданных АВР и % от суммы договоров
- Сумма произведённых оплат и % от АВР
- Гарантийное удержание (AVR × warranty_percent)
- Баланс = AVR − Гарантия − Оплачено (отрицательный → контрагент нам должен)
- Сумма и количество заявок в работе (все авторы, статусы PENDING / APPROVED / PARTIALLY_PAID)

Сводка нужна во множестве мест системы: сайдбар заявки на услуги, карточка контрагента, дашборд директора, отчёты казначея.

Прямые агрегирующие запросы (`SELECT SUM ... GROUP BY contractor_id`) на 5 таблицах давали бы деградацию при масштабе:

| Объём | 5 запросов | Trigger-maintained |
|---|---|---|
| 1k строк | ~50ms | <1ms |
| 100k строк | ~500ms | <1ms |
| N контрагентов | N×5 запросов | 1 запрос |

## Decision

Реализована таблица `contractor_summaries` с предвычисленными агрегатами, поддерживаемая триггерами PostgreSQL.

**Принципы:**
1. Таблица — только читается приложением, пишется исключительно триггерами.
2. Пересчёт — полный для конкретного `contractor_id` при каждом изменении, а не инкрементальный дельтами (надёжнее, нет накопления погрешностей).
3. Запрос в приложении — `SELECT * FROM contractor_summaries WHERE contractor_id = $1 LIMIT 1` (O(1), PK lookup).

## Schema

```sql
CREATE TABLE midescloud.contractor_summaries (
  contractor_id   uuid PRIMARY KEY REFERENCES contractors(id) ON DELETE CASCADE,
  contracts_total numeric(15,2) NOT NULL DEFAULT 0,
  avr_total       numeric(15,2) NOT NULL DEFAULT 0,
  warranty_total  numeric(15,2) NOT NULL DEFAULT 0,  -- AVR × warranty_pct%
  paid_total      numeric(15,2) NOT NULL DEFAULT 0,
  balance         numeric(15,2) GENERATED ALWAYS AS
                    (avr_total - warranty_total - paid_total) STORED,
  pending_total   numeric(15,2) NOT NULL DEFAULT 0,
  pending_count   integer       NOT NULL DEFAULT 0,
  updated_at      timestamptz   NOT NULL DEFAULT now()
);
```

## Trigger Coverage

| Источник | Триггер | Что обновляет |
|---|---|---|
| `avr` | `tg_avr_summary` | `avr_total`, `warranty_total` |
| `payments` | `tg_payments_summary` | `paid_total` |
| `requests` | `tg_requests_summary` | `pending_total`, `pending_count` |
| `purchase_items` | `tg_purchase_items_summary` | `pending_total`, `pending_count` |
| `contracts` | `tg_contracts_summary` | `contracts_total` + пересчёт warranty при изменении `warranty_percent` |

Все триггеры вызывают единую функцию `recalculate_contractor_summary(contractor_id uuid)`.

## Business Rules

### Гарантийное удержание
```
warranty_total = SUM(avr.amount × COALESCE(contract.warranty_percent, 5) / 100)
```
Default 5% если договор не привязан или `warranty_percent` не заполнен.

### Баланс
```
balance = avr_total - warranty_total - paid_total
```
Отрицательный баланс = контрагент больше получил, чем закрыл АВР за вычетом гарантии.

### Заявки "в работе" (`pending_total`)
Включаются все заявки всех авторов в статусах:
- `requests`: `PENDING`, `APPROVED`, `PARTIALLY_PAID`
- `purchase_items`: всё кроме `DRAFT`, `CANCELLED`, `COMPLETED`, `REJECTED_APPROVAL`

Цель: видеть общую нагрузку на контрагента при создании новой заявки, чтобы не запрашивать сумму сверх обязательств.

## Indexes Applied

```sql
idx_avr_contractor_id
idx_avr_contractor_contract
idx_payments_contractor_id
idx_requests_contractor_status
idx_requests_contractor_author_status
idx_contracts_contractor_id
idx_purchase_items_contractor_status
```

## Alternatives Considered

**Materialized View с pg_cron-рефрешем** — отклонено: допускает staleness (неприемлемо для финансовой системы). При изменении warranty_percent в договоре все связанные AVR строки пересчитываются некорректно.

**Прямые агрегирующие запросы** — реализованы как временное решение Phase 1, заменены данным подходом.

## Consequences

- Добавление новых исторических записей (AVR, платёж) требует наличия `contractor_id` — FK уже существует на всех таблицах.
- При откате (DELETE) платежа или AVR триггер автоматически пересчитывает итоги.
- Изменение `warranty_percent` в договоре немедленно пересчитывает `warranty_total` для всех AVR этого договора.
- Таблица содержит по одной строке на каждого контрагента (backfill выполнен при миграции).

## Related Documents

- `docs/03_decisions/17_warranty-retention.md` — правила гарантийного удержания
- `docs/03_decisions/21_subcontractor-ledger.md` — концепция субподрядного учёта
- `docs/04_architecture/08_project-controls-architecture.md` — общая финансовая архитектура
