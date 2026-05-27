# ADR-046: 4-уровневая иерархия реестра заявок и агрегации баланса субподрядчика

**Статус:** Принят  
**Дата:** 2026-05-21  
**Связан с:** ADR-07 (accordion table), ADR-21 (subcontractor ledger), ADR-38 (task-per-role), ADR-42 (requests registry), ADR-43 (payment tasks)

---

## Контекст

Текущая реализация дерева заявок `RequestsAccordionTree` в реестре `/dashboard/requests` использует 3-уровневую иерархию группировки:
1. **Уровень 1:** Проект (`projects.name`)
2. **Уровень 2:** Объект (`project_objects.name`)
3. **Уровень 3:** Заявка (Leaf, `purchase_items.description`)

**Проблема:** 
В строительном бизнесе критически важно отслеживать взаиморасчёты и текущий баланс по конкретным контрагентам (субподрядчикам) в разрезе каждого объекта. Без промежуточного уровня контрагента директор и проджект-менеджер видят плоский список заявок без понимания финансового состояния контрагента (сколько сдано по АВР, сколько выплачено, какой текущий баланс/задолженность). 

Также вычисление балансов в оперативной памяти сервера (в `injectContractorMetrics` в `actions.ts`) путем загрузки всей истории АВР и оплат не масштабируется и приводит к падению производительности на объемах более 1000 строк. Нам необходимо перенести расчеты на уровень базы данных с помощью SQL-представлений (SQL Views) и доработать интерфейс.

---

## Решение

### 1. 4-уровневая иерархия группировки

Реорганизовать дерево группировки в `RequestsAccordionTree`:
1. **Уровень 1 (Проект):** Группировка по `project.name`. Стиль: `bg-[#f0f4f8]`, отступ `pl-3`.
2. **Уровень 2 (Объект):** Группировка по `object.name` (внутри проекта). Стиль: `bg-[#f7f8fa]`, отступ `pl-8`.
3. **Уровень 3 (Контрагент):** Группировка по `contractor.name` (внутри объекта). Стиль: `bg-[#fafbfc]`, отступ `pl-12`.
4. **Уровень 4 (Заявка):** Листовая строка (Leaf) с описанием заявки. Стиль: `bg-white`, отступ `pl-[3.75rem]`.

Чтобы избежать конфликтов развертывания/свертывания, идентификатор строки Контрагента (Уровень 3) генерируется как композитный ключ:
`${projectKey}::${objectKey}::${contractorId}` (в соответствии с ADR-07 §5).

### 2. Оптимизация расчетов через SQL Views

Для оптимизации расчетов на бэкенде создаются два SQL-представления (SQL Views) со свойством `security_invoker = true`, чтобы они наследователи RLS-политики базовых таблиц.

#### А. Проектный баланс контрагента (`contractor_project_balances_view`)
Представление агрегирует суммы АВР и платежей в разрезе проектов и объектов. Во избежание дублирования из-за декартова произведения, агрегации AVR и оплат выполняются в независимых CTE перед объединением.

```sql
CREATE OR REPLACE VIEW contractor_project_balances_view 
WITH (security_invoker = true) AS
WITH avr_sums AS (
  SELECT
    pi.project_id,
    pi.object_id,
    pi.contractor_id,
    COALESCE(SUM(t.avr_amount), 0) AS avr_sum
  FROM avr_tasks t
  JOIN purchase_items pi ON t.purchase_item_id = pi.id
  WHERE t.status = 'APPROVED'
  GROUP BY pi.project_id, pi.object_id, pi.contractor_id
),
payment_sums AS (
  SELECT
    pi.project_id,
    pi.object_id,
    pi.contractor_id,
    COALESCE(SUM(t.amount_paid), 0) AS paid_sum
  FROM payment_tasks t
  JOIN purchase_items pi ON t.purchase_item_id = pi.id
  WHERE t.status IN ('PAID', 'PARTIAL')
  GROUP BY pi.project_id, pi.object_id, pi.contractor_id
)
SELECT
  comb.project_id,
  comb.object_id,
  comb.contractor_id,
  COALESCE(a.avr_sum, 0) AS avr_sum,
  COALESCE(p.paid_sum, 0) AS paid_sum,
  (COALESCE(a.avr_sum, 0) - COALESCE(p.paid_sum, 0)) AS balance
FROM (
  SELECT DISTINCT project_id, object_id, contractor_id
  FROM purchase_items
) comb
LEFT JOIN avr_sums a ON 
  comb.project_id = a.project_id 
  AND comb.contractor_id = a.contractor_id
  AND (comb.object_id IS NOT DISTINCT FROM a.object_id)
LEFT JOIN payment_sums p ON 
  comb.project_id = p.project_id 
  AND comb.contractor_id = p.contractor_id
  AND (comb.object_id IS NOT DISTINCT FROM p.object_id);
```

#### Б. Глобальный баланс контрагента (`contractor_global_balances_view`)
Представление агрегирует финансовые показатели контрагента по всем проектам.

```sql
CREATE OR REPLACE VIEW contractor_global_balances_view 
WITH (security_invoker = true) AS
WITH avr_sums AS (
  SELECT
    pi.contractor_id,
    COALESCE(SUM(t.avr_amount), 0) AS avr_sum
  FROM avr_tasks t
  JOIN purchase_items pi ON t.purchase_item_id = pi.id
  WHERE t.status = 'APPROVED'
  GROUP BY pi.contractor_id
),
payment_sums AS (
  SELECT
    pi.contractor_id,
    COALESCE(SUM(t.amount_paid), 0) AS paid_sum
  FROM payment_tasks t
  JOIN purchase_items pi ON t.purchase_item_id = pi.id
  WHERE t.status IN ('PAID', 'PARTIAL')
  GROUP BY pi.contractor_id
)
SELECT
  c.id AS contractor_id,
  COALESCE(a.avr_sum, 0) AS avr_sum,
  COALESCE(p.paid_sum, 0) AS paid_sum,
  (COALESCE(a.avr_sum, 0) - COALESCE(p.paid_sum, 0)) AS balance
FROM contractors c
LEFT JOIN avr_sums a ON c.id = a.contractor_id
LEFT JOIN payment_sums p ON c.id = p.contractor_id;
```

### 3. Финансовые колонки и «двухэтажный» баланс контрагента

В строке уровня Контрагента (Уровень 3) в `CommitmentsGrid` и `ApprovalsGrid` отображается:
- **Верхняя строка (Крупно):** Локальный баланс по данному проекту/объекту (из `contractor_project_balances_view`).
- **Нижняя строка (Мелко, приглушенно):** Общий глобальный баланс контрагента по всей системе (из `contractor_global_balances_view`) в формате `всего: X ₸`.

```
+------------------------------------+
| 1 500 000 ₸                        |
| всего: 3 200 000 ₸                 |
+------------------------------------+
```

Колонки на уровне Листа (Заявки) отображают прочерки (`—`) для балансов контрагента, концентрируясь на деталях конкретной заявки. И наоборот, строка Контрагента показывает сводные финансовые метрики, оставляя поля описания и статуса пустыми или вспомогательными.

### 4. Компактные иконки действий с лоадерами в ApprovalsGrid

Заменить текстовые кнопки «Утв.» и «Откл.» на компактные квадратные кнопки (размер 32x32px, `h-8 w-8`) с Lucide иконками и всплывающими подсказками (`title` на русском языке):

1. **Кнопка утверждения:**
   - Иконка: `<Check className="h-4 w-4" />`
   - Цвета: `bg-[var(--status-green-bg)] text-[var(--status-green-text)] hover:bg-[color-mix(in_srgb,var(--status-green-bg)_90%,black)] border border-[color-mix(in_srgb,var(--status-green-text)_30%,transparent)]`
   - Tooltip: `title="Утвердить"`
   - Состояние загрузки: при выполнении экшена иконка меняется на `<RefreshCw className="h-4 w-4 animate-spin" />` с отключением кликабельности (`disabled`).

2. **Кнопка отклонения:**
   - Иконка: `<X className="h-4 w-4" />`
   - Цвета: `bg-[var(--status-red-bg)] text-[var(--status-red-text)] hover:bg-[color-mix(in_srgb,var(--status-red-bg)_90%,black)] border border-[color-mix(in_srgb,var(--status-red-text)_30%,transparent)]`
   - Tooltip: `title="Отклонить"`

### 5. Сжатые относительные даты

Для экономии места в колонке «Создано» заменить полное время на краткие относительные интервалы через хелпер `formatRelativeDateCompressed`:
- Отклонение `< 5 минут` → `< 5 мин`
- Отклонение `< 1 часа` → `X мин` (например, `12 мин`)
- Отклонение `< 24 часов` → `X ч. назад` (например, `3 ч. назад`)
- Отклонение `< 7 дней` → `X дн. назад` (например, `2 дн. назад`)
- В остальных случаях → fallback к стандартному формату `DD.MM.YYYY` (например, `15.05.2026`).

---

## Инварианты

1. Строка уровня 3 (Контрагент) всегда отображает локальный и глобальный баланс в валюте KZT.
2. Сумма `Сдано АВР` включает только АВР со статусом `APPROVED`.
3. Сумма `Выплачено` включает только платежи со статусами `PAID` или `PARTIAL`.
4. Удаление разрешено только для заявок в статусе `DRAFT` или `PENDING`, у которых нет связанных оплат и одобренных этапов.

---

## Последствия

### Положительные
- **Высокая масштабируемость:** База данных выполняет агрегацию за миллисекунды, сетевой payload и Node.js RAM освобождены.
- **Финансовый контроль:** Директор видит общий баланс контрагента на других объектах перед утверждением нового аванса.
- **Премиальный UX:** Компактные иконки действий с лоадерами и аккуратные относительные даты делают интерфейс чистым и профессиональным.

### Отрицательные
- Необходимость управления миграциями для создания SQL-представлений.
- Дополнительный API-запрос на получение глобального баланса при рендеринге реестра (выполняется параллельно).нцентрируясь на деталях конкретной заявки. И наоборот, строка Контрагента показывает сводные финансовые метрики, оставляя поля описания и статуса пустыми или вспомогательными.

### 3. Добавление удаления заявок (Уровень 4)

Добавить в листовые строки (Уровень 4) кнопку быстрого удаления (destructive-стиль, красная иконка мусорной корзины `Trash2` из Lucide React) при соблюдении условий:
- Заявка находится в статусе `DRAFT` или `PENDING` (т.е. ещё не утверждена директором, `commitment_approval_tasks.status = 'PENDING'` или отсутствует).
- Удаление производится создателем заявки (PM) либо администратором/бухгалтером.
- При удалении каскадно удаляется соответствующая задача на согласование `commitment_approval_tasks` и связанные уведомления.

---

## Инварианты

1. Строка уровня 3 (Контрагент) всегда отображает баланс в формате `formatCurrency(balance)`.
2. Сумма `Сдано АВР` включает только АВР со статусом `APPROVED`.
3. Сумма `Выплачено` включает только платежи со статусами `PAID` или `PARTIAL`.
4. Удаление разрешено только для заявок, у которых нет утвержденной задачи согласования и не было оплат.

---

## Последствия

### Положительные
- Повышение финансовой прозрачности реестра для Директора и бухгалтерии.
- Возможность быстро оценить задолженность перед конкретным субподрядчиком прямо из дерева заявок.
- Устранение проблемы с «зависшими» черновиками благодаря кнопке удаления.

### Отрицательные
- Увеличение глубины вложенности до 4 уровней (требует аккуратных отступов на мобильных экранах).
- Необходимость дополнительных джойнов/запросов для вычисления балансов.
