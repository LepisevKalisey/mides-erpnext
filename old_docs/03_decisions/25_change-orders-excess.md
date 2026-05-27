# ADR-025: Превышение объёма по договору и допсоглашения

**Status:** Accepted  
**Date:** 2026-05-08  
**Релиз:** M1 (P2P) + M2 (Contract Management)

## Context

В строительстве превышение объёма по договору — это норма, не исключение. Реальность:
- Проектная документация неточна, объёмы уточняются в процессе строительства
- Субподрядчик выполняет больше, чем было в договоре
- Допсоглашение подписывается постфактум, задним числом

Система не должна блокировать операции при превышении — она должна:
1. Чётко сигнализировать о факте превышения
2. Указывать кому и что нужно сделать
3. Позволить зафиксировать допсоглашение когда оно подписано

## Decision

### Механизм обнаружения превышения

Превышение фиксируется в двух измерениях:

```
По объёму:  avr_line_items.cumulative_quantity > contract_items.total_quantity
По деньгам: avr_line_items.cumulative_amount  > contract_items.total_amount
```

Расчёт происходит автоматически при добавлении строки АВР-справки.

### Пороги и сигналы

```
Выполнено 0–89% от договора     → 🟢 Норма
Выполнено 90–99% от договора    → 🟡 Предупреждение: «скоро исчерпан объём»
Выполнено 100% от договора      → 🟠 Сигнал: «объём исчерпан, нужно ДС»
Выполнено >100% от договора     → 🔴 Превышение: «выполнено сверх договора»
```

### Флоу при превышении: НЕ блокируем

АВР с превышением **принимается в пул и проходит обычный путь одобрения**.  
При этом система:

```
При загрузке АВР-справки:
  → Вычислить будет ли превышение после добавления этих строк
  → Если да: показать предупреждение начучастка/PM с деталями
    «Данный АВР превысит объём по позиции "Монолит" на 12% (+45 м³)»
  → Дать кнопки: [Продолжить с превышением] [Скорректировать объём]

При окунании в пуле:
  → Каждый окунающий видит бейдж «⚠️ Есть превышение» на АВР
  → Можно окунать несмотря на превышение

После ALL_APPROVED:
  → Уведомление PM + DIRECTOR:
    «АВР [номер] подписан. Позиция "Монолит": превышение 12% (+45 м³, +1 350 000 ₸).
     Необходимо оформить допсоглашение.»
  → Создаётся задача в системе: статус CONTRACT_NEEDS_AMENDMENT
```

### Допсоглашение (Change Order)

```sql
CREATE TABLE midescloud.change_orders (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contract_id     UUID NOT NULL REFERENCES midescloud.contracts(id),
  number          TEXT NOT NULL,          -- «ДС №3»
  signed_at       DATE,
  status          TEXT NOT NULL DEFAULT 'DRAFT',
  -- DRAFT | PENDING_APPROVAL | APPROVED | REJECTED

  -- Изменения по позициям
  description     TEXT,
  created_by      TEXT REFERENCES midescloud.user(id),
  approved_by     TEXT REFERENCES midescloud.user(id),
  approved_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE midescloud.change_order_items (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  change_order_id   UUID NOT NULL REFERENCES midescloud.change_orders(id) ON DELETE CASCADE,
  contract_item_id  UUID REFERENCES midescloud.contract_items(id),
  -- null = новая позиция в допсоглашении
  work_type         TEXT NOT NULL,
  unit              TEXT NOT NULL,
  delta_quantity    NUMERIC NOT NULL,    -- дополнительный объём (может быть отрицательным)
  unit_price        NUMERIC NOT NULL,
  delta_amount      NUMERIC GENERATED ALWAYS AS (delta_quantity * unit_price) STORED
);
```

### Применение допсоглашения

При `change_orders.status = 'APPROVED'`:

```sql
-- Автоматически обновляем contract_items
UPDATE midescloud.contract_items ci
SET
  total_quantity = total_quantity + coi.delta_quantity,
  updated_at = now()
FROM midescloud.change_order_items coi
WHERE coi.contract_item_id = ci.id
  AND coi.change_order_id = $change_order_id;

-- Обновляем сумму договора
UPDATE midescloud.contracts
SET amount = amount + (SELECT SUM(delta_amount) FROM change_order_items WHERE change_order_id = $id)
WHERE id = $contract_id;
```

После применения — превышение пересчитывается, сигнал снимается.

### UI: статус превышения в договоре

На странице договора — отдельная секция:

```
КОНТРОЛЬ ИСПОЛНЕНИЯ
────────────────────────────────────────────────
Позиция              Договор    Выполнено  Статус
────────────────────────────────────────────────
Монолитные работы   450 м³     504 м³     🔴 +12%  [Создать ДС]
Кирпичная кладка    1200 м²    890 м²     🟢  74%
Штукатурные работы   800 м²      0 м²     🟢   0%
────────────────────────────────────────────────
Открытые допсоглашения: ДС №1 — в работе [Подробнее]
```

### Кто создаёт допсоглашение

- PM нажимает [Создать ДС] прямо с экрана превышения
- Система предзаполняет: contractor, contract, позиции с превышением, delta
- PM указывает номер, дату подписания (когда бумага будет готова)
- Директор утверждает в системе → `change_orders.status = 'APPROVED'` → пересчёт

## Планирование реализации

| Релиз | Что реализуется |
|---|---|
| M1 P2P | Расчёт и отображение превышения в накопительной таблице + сигнал на дашборде |
| M2 Contract | Таблицы change_orders + change_order_items, UI создания ДС |
| M2 Contract | Применение ДС → обновление contract_items + contracts.amount |

## Consequences

- **+** Превышение видно всем участникам до/во время/после АВР
- **+** Директор не пропустит необходимость оформить ДС
- **+** Система не блокирует реальную работу (ДС часто подписывается позже факта)
- **−** Требует дисциплины PM для оформления ДС в системе

## Related

- See: `docs/03_decisions/23_avr-photo-recognition.md`
- See: `docs/04_architecture/03_director-dashboard-spec.md` (виджет W3)
- See: `docs/03_decisions/24_contract-closeout.md`
