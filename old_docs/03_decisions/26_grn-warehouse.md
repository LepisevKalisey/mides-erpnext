# ADR-026: Приёмка материалов (GRN), Складской учёт и Перемещения

**Status:** Accepted  
**Date:** 2026-05-08  
**Релиз:** M1 P2P Phase 4 (GRN) + M6 Warehouse (складской учёт)

## Context

Каждый участок имеет свой склад. Кладовщик или начучастка (на небольших участках) принимают материалы от поставщика. Поставщик привозит накладную. Принятый материал идёт на склад, затем выдаётся в работу. Возможны перемещения между участками — сейчас это рукописная накладная, сфотографированная в общий чат WhatsApp.

## Decision

### Схема жизненного цикла GRN

```
Purchase Order (PO) создан снабженцем
    │
    ▼
Поставщик привозит материал + накладную
    │
    ▼
Кладовщик / Начучастка — SITE_MANAGER или WAREHOUSE_KEEPER
    │
    ├── Принимает (полностью или частично) → создаёт GRN
    │   status = CONFIRMED
    │   → Остаток на складе увеличивается
    │   → Уведомление снабженцу
    │
    └── Не принимает (брак, ошибка) → GRN не создаётся
        → Снабженец получает уведомление об отклонении (вручную)
```

### Особые случаи

**Частичная поставка (наиболее частый сценарий):**
```
PO: 100 мешков цемента
Поставка 1: 60 мешков → GRN-001, purchase_item status → PARTIALLY_RECEIVED
Поставка 2: 40 мешков → GRN-002, purchase_item status → FULLY_RECEIVED
```

**Сверхпоставка (привезли больше заказанного):**
```
PO: 100 мешков
Поставка: 120 мешков → GRN создаётся на 120
received_quantity > ordered_quantity → флаг OVER_DELIVERY
→ Снабженец уведомляется: «Получено на 20 мешков больше PO»
→ Принято: всё равно 120 (кладовщик подтвердил)
→ Оплата: согласно договорённости (снабженец решает)
```

### Схема данных

```sql
-- Акт приёмки (GRN header)
CREATE TABLE midescloud.goods_receipts (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_order_id    UUID REFERENCES midescloud.purchase_orders(id),
  -- null = внеплановая поставка (без PO)
  site_id              UUID NOT NULL REFERENCES midescloud.objects(id),
  supplier_id          UUID REFERENCES midescloud.contractors(id),
  received_by          TEXT NOT NULL REFERENCES midescloud.user(id),
  delivery_note_number TEXT,              -- номер накладной от поставщика
  delivery_note_url    TEXT,              -- фото/скан накладной
  received_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  status               TEXT NOT NULL DEFAULT 'CONFIRMED',
  -- CONFIRMED | DISPUTED (если после приёмки обнаружили проблему)
  is_over_delivery     BOOLEAN DEFAULT false,
  notes                TEXT,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Строки GRN
CREATE TABLE midescloud.goods_receipt_items (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  grn_id               UUID NOT NULL REFERENCES midescloud.goods_receipts(id) ON DELETE CASCADE,
  purchase_item_id     UUID REFERENCES midescloud.purchase_items(id),
  item_name            TEXT NOT NULL,
  unit                 TEXT NOT NULL,
  ordered_quantity     NUMERIC,           -- из PO (для сравнения)
  received_quantity    NUMERIC NOT NULL,  -- фактически принято
  unit_price           NUMERIC,
  notes                TEXT
);
```

### Складской учёт

```sql
-- Остатки на складе (агрегат)
CREATE TABLE midescloud.warehouse_stock (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id       UUID NOT NULL REFERENCES midescloud.objects(id),
  item_name     TEXT NOT NULL,
  unit          TEXT NOT NULL,
  quantity      NUMERIC NOT NULL DEFAULT 0,
  last_updated  TIMESTAMPTZ DEFAULT now(),
  UNIQUE(site_id, item_name, unit)
);

-- Выдача материала в работу
CREATE TABLE midescloud.material_issues (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stock_id      UUID NOT NULL REFERENCES midescloud.warehouse_stock(id),
  site_id       UUID NOT NULL REFERENCES midescloud.objects(id),
  issued_by     TEXT NOT NULL REFERENCES midescloud.user(id),
  issued_to     TEXT,                 -- кому выдано (прораб, бригадир)
  quantity      NUMERIC NOT NULL,
  issued_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  work_type_id  UUID REFERENCES midescloud.work_types(id),
  -- для job costing: какой вид работ этот материал обслуживает
  notes         TEXT
);
```

### Перемещения между участками

**Текущее состояние:** рукописная накладная → фото → WhatsApp-чат.  
**Решение:** оцифровать тот же процесс:

```
Инициатор (SITE_MANAGER / WAREHOUSE_KEEPER участка А):
  → Создаёт накладную на перемещение в системе
  → Указывает: откуда, куда, что, сколько
  → status = IN_TRANSIT
  → Уведомление кладовщику участка Б

Принимающий (участок Б):
  → Подтверждает получение (или сообщает о расхождении)
  → status = RECEIVED
  → Остаток участка А уменьшается, участка Б увеличивается
```

```sql
-- Перемещения между участками
CREATE TABLE midescloud.material_transfers (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_site_id  UUID NOT NULL REFERENCES midescloud.objects(id),
  to_site_id    UUID NOT NULL REFERENCES midescloud.objects(id),
  initiated_by  TEXT NOT NULL REFERENCES midescloud.user(id),
  received_by   TEXT REFERENCES midescloud.user(id),
  transfer_date DATE NOT NULL DEFAULT CURRENT_DATE,
  status        TEXT NOT NULL DEFAULT 'IN_TRANSIT',
  -- IN_TRANSIT | RECEIVED | CANCELLED
  notes         TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE midescloud.material_transfer_items (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transfer_id   UUID NOT NULL REFERENCES midescloud.material_transfers(id) ON DELETE CASCADE,
  stock_id      UUID NOT NULL REFERENCES midescloud.warehouse_stock(id),
  item_name     TEXT NOT NULL,
  unit          TEXT NOT NULL,
  quantity      NUMERIC NOT NULL
);
```

### Влияние GRN на статус Purchase Item

```
purchase_items.status обновляется при каждом GRN:

  Σ(grn_items.received_quantity) = 0          → AWAITING_DELIVERY
  Σ(grn_items.received_quantity) < ordered    → PARTIALLY_RECEIVED
  Σ(grn_items.received_quantity) >= ordered   → FULLY_RECEIVED (готово к оплате)
```

### Mobile UX для кладовщика и начучастка

Операция должна быть выполнима с телефона за 2–3 минуты:

```
Шаг 1: Выбрать PO из списка «Ожидаемых поставок» (по объекту)
Шаг 2: Указать количество по каждой позиции (с клавиатуры)
Шаг 3: Сфотографировать накладную поставщика
Шаг 4: [Подтвердить приёмку] → GRN создан, склад обновлён
```

Если PO нет в списке → можно создать внеплановую поставку без PO (PM разберётся постфактум).

## Планирование реализации

| Релиз | Что реализуется |
|---|---|
| M1 P2P Phase 4 | `goods_receipts` + `goods_receipt_items` + Three-Way Match статус |
| M1 P2P Phase 4 | Mobile-friendly GRN форма (браузер, responsive) |
| M6 Warehouse | `warehouse_stock` + `material_issues` (выдача в работу) |
| M6 Warehouse | `material_transfers` (перемещения между участками) |

## Consequences

- **+** Конец «WhatsApp-накладных» для перемещений
- **+** Three-Way Match: система видит что заказано, подтверждено, оплачено
- **+** Кладовщик работает с мобильного — минимальный ввод
- **+** Сверхпоставки и частичные поставки явно отражены
- **−** Требует дисциплины: GRN должен быть создан в день поставки

## Related

- See: `docs/02_research/01_construction-industry-workflow.md` §2.4 (GRN)
- See: `docs/03_decisions/11_dual-path-p2p-workflow.md`
- See: `docs/08_reference/01_roles-and-permissions.md` (WAREHOUSE_KEEPER)
