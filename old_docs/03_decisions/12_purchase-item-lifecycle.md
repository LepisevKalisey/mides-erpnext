# ADR-12: Жизненный цикл позиции закупки (Purchase Item Lifecycle)

> [!WARNING]
> **СТАТУС: УСТАРЕЛО / SUPERSEDED**
> Это решение было принято во время Фазы 2 и полностью отменено в версии v3. 
> Оно заменено на [ADR-38 (Task-per-Role Architecture)](file:///c:/Projects/Mides/MidesCloud%20v3/docs/03_decisions/38_task-per-role-architecture.md).
> В версии v3 таблица `purchase_items` не имеет колонки `status`, а таблица `purchase_item_status_history` не создавалась. Вместо этого статусы хранятся распределённо в специализированных таблицах задач для каждой роли (`sourcing_tasks`, `commitment_approval_tasks`, `payment_tasks` и т.д.), а общий статус и текущий этап рассчитываются динамически с помощью SQL-представлений (VIEW).

**Статус:** Устарело (Superseded) — заменено на ADR-38  
**Дата:** 2026-05-07  
**Связано с:** ADR-11 (dual-path-p2p), ADR-13 (routing)

---

## Контекст

Без формального определения состояний (states) и переходов (transitions) невозможно:
- Определить «следующий шаг» для каждой роли
- Роутировать автоматически
- Строить дашборды и SLA-мониторинг
- Уведомлять о блокировках

Текущее поле `status` в `purchase_items` содержит неформальный набор значений без чёткой машины состояний.

---

## Решение

Определяются два конечных автомата — по одному для каждого пути из ADR-11.

---

### Путь A: Procurement (Закупка)

```
DRAFT
  │  (сотрудник заполнил и отправил)
  ▼
SUBMITTED
  │  (авто-роутинг сработал ИЛИ менеджер пула назначил)
  ▼
ROUTING
  │  (снабжению назначена позиция)
  ▼
IN_SOURCING
  │  (снабжение нашло поставщика, создаёт PO)
  ▼
PO_PENDING_APPROVAL
  │  (директор утвердил PO)
  ▼
PO_APPROVED
  │  (поставщик доставил, приёмщик подтвердил)
  ▼
DELIVERED (GRN confirmed)
  │  (three-way match прошёл)
  ▼
INVOICE_MATCHED
  │  (казначей выпустил платёж)
  ▼
PAID ✓

Из любого состояния:
  → REJECTED (с комментарием и указанием причины)
  → CANCELLED (инициатором до SUBMITTED включительно)
```

### Путь B: Payment Application (Заявка на оплату)

```
DRAFT
  │  (менеджер заполнил и отправил)
  ▼
SUBMITTED
  │  (ответственный менеджер проверил объём)
  ▼
WORK_CONFIRMED
  │  (директор утвердил сумму)
  ▼
PAYMENT_APPROVED
  │  (АВР подписан)
  ▼
AVR_SIGNED
  │  (казначей выпустил платёж)
  ▼
PAID ✓

Из любого состояния:
  → REJECTED (с комментарием)
  → ON_HOLD (недостаточно документов, нужно уточнение)
```

---

### Схема статусов в БД

```sql
-- Обновить тип статуса
ALTER TABLE purchase_items
  DROP COLUMN IF EXISTS status;

ALTER TABLE purchase_items
  ADD COLUMN status TEXT NOT NULL DEFAULT 'DRAFT',
  ADD COLUMN status_changed_at TIMESTAMPTZ,
  ADD COLUMN status_changed_by UUID REFERENCES auth.users(id),
  ADD COLUMN rejection_reason  TEXT;

-- Допустимые значения status:
-- DRAFT | SUBMITTED | ROUTING | IN_SOURCING
-- PO_PENDING_APPROVAL | PO_APPROVED | DELIVERED
-- INVOICE_MATCHED | WORK_CONFIRMED | PAYMENT_APPROVED
-- AVR_SIGNED | PAID | REJECTED | CANCELLED | ON_HOLD
```

### История переходов (Audit Trail)

```sql
CREATE TABLE purchase_item_status_history (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_item_id UUID REFERENCES purchase_items(id) ON DELETE CASCADE,
  from_status     TEXT,
  to_status       TEXT NOT NULL,
  changed_by      UUID REFERENCES auth.users(id),
  comment         TEXT,
  created_at      TIMESTAMPTZ DEFAULT now()
);
```

---

### Правила переходов

| Текущий статус | Следующий статус | Кто может перевести |
|---|---|---|
| DRAFT | SUBMITTED | Инициатор (любой сотрудник) |
| SUBMITTED | ROUTING | Система (авто) / менеджер пула |
| ROUTING | IN_SOURCING | Снабженец (принял задачу) |
| IN_SOURCING | PO_PENDING_APPROVAL | Снабженец (создал PO) |
| PO_PENDING_APPROVAL | PO_APPROVED | Директор / финансы |
| PO_APPROVED | DELIVERED | Приёмщик (подтвердил GRN) |
| DELIVERED | INVOICE_MATCHED | Система (Three-Way Match) |
| INVOICE_MATCHED | PAID | Казначей |
| SUBMITTED | WORK_CONFIRMED | Ответственный менеджер (путь B) |
| WORK_CONFIRMED | PAYMENT_APPROVED | Директор |
| PAYMENT_APPROVED | AVR_SIGNED | Менеджер (зафиксировал подписание АВР) |
| AVR_SIGNED | PAID | Казначей |
| Любой | REJECTED | Утверждающий на текущем шаге |
| DRAFT, SUBMITTED | CANCELLED | Инициатор |

---

### UI-индикация статуса

Каждый статус имеет:
- **Цвет** (gray/yellow/blue/green/red)
- **Иконку** (состояние "ball in court")
- **Сообщение** «Ожидает: [роль]» — всегда ясно кто задерживает

```
DRAFT          → gray    → «Черновик»
SUBMITTED      → yellow  → «Ожидает роутинга»
ROUTING        → yellow  → «Назначается снабжению»
IN_SOURCING    → blue    → «В обработке у снабжения»
PO_PENDING_*   → yellow  → «Ожидает утверждения директора»
PO_APPROVED    → blue    → «Ожидает поставки»
DELIVERED      → blue    → «Ожидает сверки счёта»
INVOICE_MATCHED→ yellow  → «Ожидает оплаты»
PAID           → green   → «Оплачено ✓»
REJECTED       → red     → «Отклонено: [причина]»
CANCELLED      → gray    → «Отменено»
```

---

## Альтернативы, которые не были выбраны

- **Единый lifecycle для обоих путей:** приводит к неиспользуемым состояниям и путанице (зачем снабжению Payment Application?)
- **Хранить историю в JSON-поле:** теряем возможность запросов, уведомлений и аудита

---

## Последствия

**Положительные:**
- Чёткий "Ball in Court" для каждой роли
- Основа для SLA и уведомлений
- Полный аудит-трейл изменений статуса
- Дашборд «что у меня в работе» становится тривиальным запросом

**Отрицательные / риски:**
- Нужна server-action валидация на каждый переход (не дать перепрыгнуть шаги)
- Текущие данные в таблице имеют неформальные статусы → нужна разовая миграция данных (но данных пока нет)
