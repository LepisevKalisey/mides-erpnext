# ADR-041: Атрибуция cost_code — на уровне строки АВР, не заявки

**Статус:** Утверждён  
**Дата:** 2026-05-19  
**Связан с:** ADR-38 (task-per-role), ADR-21 (subcontractor-ledger), Blueprint §4.2, §8 инвариант #12

---

## Контекст

При проектировании Фазы 1 (L2-COMMIT — Subcontract Slice) возник вопрос:
где хранить `cost_code_id` — на якоре `purchase_items` или на строках АВР?

### Случаи, которые нужно поддержать

```
Случай A: Аванс (commitment_type = ADVANCE)
  PM создаёт заявку на 5 000 000 ₸
  cost_code НЕИЗВЕСТЕН — деньги ещё не за конкретные работы
  Позже: 3 АВР закрывают аванс, каждое по своим cost_codes

Случай B: Заявка по АВР с несколькими cost_codes
  PM создаёт заявку на 1 000 000 ₸ по АВР
  АВР строки:
    600 000 ₸ → cost_code "Монолит" (3010)
    400 000 ₸ → cost_code "Отделка" (3020)
  → Один purchase_item — много cost_codes

Случай C: Заявка по АВР с одним cost_code
  Частный случай Случая B. Те же правила.
```

### Проблема с cost_code_id на purchase_items

Если добавить `cost_code_id` на `purchase_items` (даже nullable):
- Для аванса (Случай A) — поле пустое. PM не знает и не должен знать.
- Для Случая B — поле не может содержать два значения одновременно.
- Возникает соблазн "заполнить сейчас, уточним потом" → два источника правды.
- Реальный cost_code в АВР может не совпасть с тем, что PM указал в заявке.
- Рассинхронизация обнаруживается только при аудите.

## Решение

### Принцип: cost_code атрибутируется ТОЛЬКО в момент появления АВР

```
purchase_items (якорь — заявка на оплату)
  ├── НЕТ cost_code_id
  └── amount_requested: сколько просим заплатить

avr_document_lines (строки АВР — ТУТ живёт cost_code)
  ├── avr_document_id → avr_documents
  ├── cost_code_id    NOT NULL → cost_codes   ← МОСТ Revenue↔Cost
  └── amount (разбивка по cost_code)
```

### Финансовый мост Revenue↔Cost

```
Revenue: contract_items.cost_code_id (строки ВОР заказчика)
Cost:    avr_document_lines.cost_code_id (строки АВР субподрядчика)

Маржа (VIEW) = JOIN через cost_code_id:
  Revenue.amount_per_code - Cost.amount_per_code
  WHERE avr_document_lines.data_status = 'COMMITTED'
```

До появления АВР — позиция учитывается в балансе субподрядчика,
но **не участвует в марже**. Это корректно: обязательство есть,
но конкретных работ ещё нет.

### Аванс и его закрытие (Срез #3+)

```
advance_closure_links
  ├── advance_purchase_item_id → purchase_items (commitment_type=ADVANCE)
  ├── avr_document_id          → avr_documents
  └── closing_amount           — сколько этого АВР закрывает аванс

Долг по авансу = advance.amount_requested
               - SUM(advance_closure_links.closing_amount)
```

### Субподрядный Лицевой Счёт (уточнение ADR-21)

```
Баланс по договору:
  = SUM(payments.amount)                                          -- все выплаты
  - SUM(payments.warranty_held)                                   -- удержания
  - SUM(avr_document_lines.amount WHERE data_status='COMMITTED')  -- принятые работы

payments.warranty_held = payment.amount × contract.warranty_percent / 100
```

## Альтернативы

| Альтернатива | Почему отклонена |
|---|---|
| `purchase_items.cost_code_id` nullable | PM не знает cost_code при авансе. Два источника правды при расхождении с АВР |
| `purchase_items.cost_code_id` обязательный | Невозможно создать аванс. Нарушает реальность стройки |
| Отдельная таблица `cost_allocations` на purchase_items | Избыточная структура. Cost allocation — это уже АВР |

## Последствия

### Положительные
- **Нет рассинхронизации:** единственный источник truth для cost_code — строки АВР
- **Аванс работает корректно:** заявка создаётся без cost_code, атрибуция происходит при приёмке
- **M:M cost_codes естественно:** одно АВР = много строк = много cost_codes
- **Маржа честная:** только из реально принятых (COMMITTED) работ

### Отрицательные
- **До АВР:** позиция не отражена в марже по cost_code. Это корректно, но требует объяснения пользователю
- **JOIN сложнее:** маржа требует join через avr_documents → avr_document_lines

## Правила для агентов

1. **НИКОГДА** не добавлять `cost_code_id` в `purchase_items`
2. `avr_document_lines.cost_code_id` — NOT NULL, обязательное поле
3. Маржа строится ТОЛЬКО через `avr_document_lines WHERE data_status='COMMITTED'`
4. Баланс субподрядчика считается через `payments` − `avr_document_lines.COMMITTED`

## Связанные документы

- `docs/03_decisions/38_task-per-role-architecture.md` — паттерн якоря
- `docs/03_decisions/21_subcontractor-ledger.md` — формула баланса (требует обновления)
- `docs/03_decisions/15_avr-lifecycle-esf.md` — lifecycle АВР
- `docs/01_product/01_system-blueprint.md` — §4.2 финансовый стержень, §8 инвариант #12
