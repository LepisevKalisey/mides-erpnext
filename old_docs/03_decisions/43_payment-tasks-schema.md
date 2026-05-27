# ADR-43: Схема таблицы `payment_tasks` и конвейер оплат

**Статус:** Утверждён  
**Дата:** 2026-05-20  
**Участники:** Казначей, Архитектор  
**Связан с:** ADR-38 (задачи ролей), ADR-36 (реестр платежей), ADR-11 (P2P-workflow)

---

## Контекст

В рамках внедрения финансового конвейера (Слайс 1.3: Казначейский стол) необходимо фиксировать оплату утверждённых заявок (`purchase_items`). 
Согласно ADR-38 (Task-per-Role), статус оплаты не должен храниться в виде флага на самом якоре `purchase_items`, а должен вычисляться на основе дочерних задач.

Также бизнес-логика требует поддержки **частичной оплаты (PARTIAL)** с возможностью отслеживания истории платежей (дата, номер платежного поручения, сумма) и сохранения остатка в очереди казначея до полного закрытия заявки.

## Решение

### 1. Проектирование таблицы `payment_tasks`

Каждая запись в `payment_tasks` представляет собой либо ожидающую оплату (PENDING), либо уже совершённую транзакцию/оплату (PARTIAL или PAID).

Применяется **паттерн цепочки задач**:
- Когда заявка утверждается Директором, создаётся первая задача `payment_tasks` в статусе `PENDING` на полную сумму заявки.
- При проведении полной оплаты казначей заполняет реквизиты платежа, и статус этой задачи меняется на `PAID`.
- При проведении частичной оплаты казначей указывает сумму платежа (которая должна быть строго меньше остатка к оплате). Текущая задача обновляется: статус меняется на `PARTIAL`, фиксируются дата, номер ПП и выплаченная сумма. Одновременно автоматически (или через Server Action) создаётся **новая** задача `payment_tasks` в статусе `PENDING` на оставшуюся сумму.
- Этот процесс повторяется до тех пор, пока сумма платежа не закроет остаток полностью (тогда финальный таск переводится в `PAID`).

### 2. Структура таблицы в Drizzle ORM

```typescript
import { pgTable, uuid, text, numeric, timestamp, pgEnum } from "drizzle-orm/pg-core";
import { purchaseItems } from "./purchase-items";

export const paymentStatusEnum = pgEnum("payment_status", [
  "PENDING", // Ожидает оплаты казначеем
  "PARTIAL", // Частично оплачено (историческая запись)
  "PAID"     // Полностью оплачено / финальный платёж
]);

export const paymentTasks = pgTable("payment_tasks", {
  id: uuid("id").primaryKey().defaultRandom(),
  
  // Связь с якорем
  purchaseItemId: uuid("purchase_item_id")
    .notNull()
    .references(() => purchaseItems.id),
    
  // Казначей, зафиксировавший оплату (Supabase Auth ID)
  treasurerId: text("treasurer_id"), // Nullable пока статус PENDING
  
  status: paymentStatusEnum("status").default("PENDING").notNull(),
  
  // Сумма, выплаченная по данной задаче/транзакции
  amountPaid: numeric("amount_paid", { precision: 18, scale: 2 }), // Nullable пока PENDING
  
  // Дата совершения платежа
  paymentDate: timestamp("payment_date"), // Nullable пока PENDING
  
  // Номер платежного поручения (ПП) — обязателен для PAID/PARTIAL
  paymentRef: text("payment_ref"), // Nullable пока PENDING

  // Гарантийное удержание (ADR-17, Слайс A.1)
  warrantyRetentionAmount: numeric("warranty_retention_amount", { precision: 18, scale: 2 }), // Nullable пока PENDING
  
  // Чистая сумма к оплате: amountPaid - warrantyRetentionAmount
  netPaymentAmount: numeric("net_payment_amount", { precision: 18, scale: 2 }), // Nullable пока PENDING
  
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});
```

### 3. Вычисление статуса оплаты для `purchase_items`

Статус оплаты заявки вычисляется через агрегацию связанных `payment_tasks`:

- **PENDING**: Существует активная задача `payment_tasks` в статусе `PENDING`, при этом суммарный `amountPaid` по историческим задачам (`PARTIAL`) равен `0` (или задач `PARTIAL` нет).
- **PARTIAL**: Существует активная задача `payment_tasks` в статусе `PENDING`, при этом по историческим задачам (`PARTIAL`) уже есть выплаченные суммы (`SUM(amountPaid) > 0`).
- **PAID**: Все связанные задачи `payment_tasks` имеют статус `PAID` или `PARTIAL` (нет ни одной задачи `PENDING`), и суммарный `amountPaid` равен `amountRequested` якоря.

## Альтернативы

### Альтернатива А: Хранение массива транзакций в JSONB на `purchase_items`
- **Почему отклонена:** Нарушает принцип Task-per-Role (ADR-38), усложняет индексацию и поиск по номерам ПП, ломает концепцию единой очереди задач казначея.

### Альтернатива Б: Отдельная таблица `payment_transactions` + флаг статуса в `payment_tasks`
- **Почему отклонена:** Создаёт избыточность. Объединение роли таска (очередь казначея) и транзакции (история оплат) в одной таблице с цепочечной структурой экономит таблицы и идеально ложится на Next.js Server Actions без усложнения схемы.

## Последствия

### Положительные
- Полная история оплат сохраняется непосредственно в `payment_tasks` (каждый частичный платёж — это строка с метаданными).
- Очередь казначея строится простым запросом: `SELECT * FROM payment_tasks WHERE status = 'PENDING'`.
- Легко вычисляется остаток к оплате для следующей транзакции.

### Отрицательные
- Логика Server Action при `recordPayment` усложняется: нужно проверять остаток и при необходимости генерировать новый таск.
