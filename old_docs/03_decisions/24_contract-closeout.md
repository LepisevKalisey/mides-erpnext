# ADR-024: Закрытие договора (Contract Closeout)

**Status:** Accepted  
**Date:** 2026-05-08  
**Релиз:** M2 (Contract Management)

## Context

Договор завершён физически — все работы выполнены. Но в системе договор продолжает висеть как «активный». Нужен явный процесс закрытия с чеклистом, который защищает от:
- Закрытия при наличии неоплаченных АВР
- Потери гарантийного удержания (warranty_amount_held)
- Забытых возвратов гарантии по истечении срока

## Decision

### Статусы договора

```
DRAFT → ACTIVE → CLOSEOUT_INITIATED → CLOSED
                                    ↘ TERMINATED (расторжение)
```

### Флоу закрытия (штатное)

```
PM инициирует Closeout
    │
    ├── Система проверяет чеклист:
    │   □ Все contract_items: executed_quantity >= total_quantity × 0.95
    │   □ Нет АВР в статусе PHOTO_SUBMITTED / POOL_REVIEW / ALL_APPROVED
    │   □ Нет открытых заявок (purchase_items) по этому договору
    │   □ Нет платежей в статусе PENDING
    │
    ├── Если чеклист не пройден → показать список проблем, не давать закрыть
    │
    └── Если OK → status = 'CLOSEOUT_INITIATED'
            │
        Директор утверждает закрытие
            │
        status = 'CLOSED'
        warranty_start_date = now() (если не установлена)
        warranty_release_date = now() + warranty_period_months
        Уведомление бухгалтеру: «Договор закрыт. Гарантийное удержание X ₸ до [дата]»
```

### Флоу расторжения (досрочное)

```
PM или DIRECTOR инициирует расторжение
    │
    Обязательные поля:
    - termination_reason TEXT (причина)
    - termination_date DATE
    - termination_amount NUMERIC (сумма к финальному расчёту, может быть 0 или отрицательной)
    │
    Директор утверждает
    │
    status = 'TERMINATED'
    Уведомление бухгалтеру: «Договор расторгнут. Финальный расчёт: X ₸»
```

### Гарантийное удержание: напоминание о возврате

```sql
-- Фоновая задача (cron, раз в день):
SELECT * FROM contracts
WHERE status = 'CLOSED'
  AND warranty_released_at IS NULL
  AND warranty_release_date <= now() + INTERVAL '30 days'

-- Если нашлось → уведомление директору:
-- «Гарантийный срок по договору [номер] истекает через X дней.
--  Удержание: Y ₸. Необходимо проверить претензии и вернуть.»
```

### Поля в `contracts`

```sql
ALTER TABLE midescloud.contracts
  ADD COLUMN IF NOT EXISTS closeout_initiated_by  TEXT REFERENCES midescloud.user(id),
  ADD COLUMN IF NOT EXISTS closeout_initiated_at  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS termination_reason     TEXT,
  ADD COLUMN IF NOT EXISTS termination_date       DATE,
  ADD COLUMN IF NOT EXISTS termination_amount     NUMERIC;
```

## Планирование реализации

| Релиз | Что реализуется |
|---|---|
| M2 (Contract Management) | Кнопка «Закрыть договор», чеклист, статус CLOSED/TERMINATED |
| M2 | Поле warranty_release_date + уведомление бухгалтеру |
| M4 (Financial) | Cron-задача напоминания о возврате гарантии |

## Consequences

- **+** Договор не может быть закрыт с «хвостами» (незакрытые АВР, открытые заявки)
- **+** Гарантийное удержание не потеряется — система напомнит
- **+** Расторжение фиксируется с причиной и финальной суммой
- **−** Требует дисциплины от PM при инициации closeout

## Related

- See: `docs/03_decisions/17_warranty-retention.md`
- See: `docs/03_decisions/21_subcontractor-ledger.md`
- See: `docs/08_reference/01_roles-and-permissions.md`
