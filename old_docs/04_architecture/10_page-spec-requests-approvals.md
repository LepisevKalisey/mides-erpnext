# Page Spec: Очередь Директора — Утверждения заявок

**Маршрут:** `/dashboard/requests/approvals`
**Слайс:** 1.2-R — «Очередь Директора» (редизайн по референсу)
**Агент:** Frontend Agent (see AGENTS.md §2)
**Статус:** Ready for Implementation

> **Предыстория редизайна:** Первая реализация (AccordionGrid с раскрывающимися панелями)
> нечитаема при 20+ заявках — много пустого пространства, клики для просмотра деталей.
> Референс показывает компактную строчную модель с инлайн-кнопками решения.

---

## Контекст и назначение

Операционная очередь утверждений для Директора и Заместителя.
Показывает **только PENDING** заявки. Директор принимает решения без раскрытия строк.

> **ADR-42:** `/requests/approvals` доступен **только** `DIRECTOR` и `DEPUTY_DIRECTOR`.
> **ADR-42:** Директор **не видит здесь своих заявок** — они автоматически APPROVED.

---

## Layout

```
┌── Page Header ─────────────────────────────────────────────────────────────┐
│ «На согласовании»                                                          │
│ N заявок ожидают решения                                                   │
├── Controls Bar ────────────────────────────────────────────────────────────┤
│ [🔍 Поиск: объект или подрядчик...]    [По объектам▼]  [По подрядчикам▼] │
├── Compact Table ───────────────────────────────────────────────────────────┤
│ Объект / Подрядчик  │ SLA  │ Тип  │ Сумма  │ Договор  │ Решение          │
│ ─────────────────────────────────────────────────────────────────────────  │
│ ▾ Школа Мирас  (2)  │      │      │        │          │                   │
│   · ИП Дархан       │  2ч  │ АВР  │400 000 │  №СД-001 │ [✓]  [✗]         │
│   · ИП Дархан       │ 50ч  │ Аванс│200 000 │  №СД-002 │ [✓]  [✗]         │
│ ─────────────────────────────────────────────────────────────────────────  │
│ ▾ ЖК Горизонт  (1)  │      │      │        │          │                   │
│   · ТОО СтройПодряд │ 25ч  │ АВР  │800 000 │  №СД-007 │ [✓]  [✗]         │
├── Empty State (если нет PENDING) ──────────────────────────────────────────┤
│            [✓ CheckCircle2]                                                │
│        «Нет заявок на рассмотрении»                                        │
└────────────────────────────────────────────────────────────────────────────┘
```

---

## Controls Bar

### Поиск

- `<input type="text">` placeholder: `«Поиск: объект или подрядчик...»`
- Позиция: right, ширина `240px`
- Поиск **client-side** по полям `objectName`, `contractorName`
- Фильтрует как группы (объекты), так и строки (подрядчики) одновременно

### Группировка

Два режима, переключаются кнопками-тоглом (как TabList):

| Режим | Описание |
|---|---|
| **По объектам** | L1 = объект строительства, L2 = подрядчик / заявка |
| **По подрядчикам** | L1 = подрядчик (contractor), L2 = объект / заявка |

- По умолчанию: **По объектам**
- State: `groupBy: 'object' | 'contractor'` в `useState`
- Кнопки: `button` с `aria-pressed`, стиль как у `TabsTrigger`

---

## Compact Table — Структура

### gridTemplate

```css
/* Desktop ≥1280px */
grid-template-columns: 2fr 80px 130px 150px 140px 100px;

/* Tablet 768–1279px */
grid-template-columns: 2fr 80px 120px 140px 1fr 90px;
```

### Заголовки колонок

| # | Колонка | Align | Описание |
|---|---|---|---|
| 1 | **Объект / Подрядчик** | left | Группа L1 + имя L2 |
| 2 | **SLA** | center | Часов ожидания |
| 3 | **Тип** | center | Badge типа заявки |
| 4 | **Сумма** | right | `formatCurrency` |
| 5 | **Договор** | left | Номер договора |
| 6 | **Решение** | center | Кнопки [✓] [✗] |

---

## Строки таблицы

### L1 — Группа (объект или подрядчик)

```
▾ [имя объекта]   (N)
```

- Раскрывается/сворачивается кликом на всю строку
- Шеврон: `ChevronDown` / `ChevronRight` (8×8, `--text-secondary`)
- Badge `(N)` — количество PENDING заявок в группе
- `background: var(--surface-elevated)` (чуть темнее строк L2)
- `font-weight: 600`, `font-size: 13px`
- Колонки 2–6 пустые на L1 строке

### L2 — Строка заявки

```
  · [имя подрядчика / объекта]   [SLA]   [Тип]   [Сумма]   [Договор]   [✓] [✗]
```

- `background: var(--surface-base)` при hover: `var(--surface-hover)`
- `border-bottom: 1px solid var(--border-subtle)`
- Padding: `10px 12px` (компактно)
- `font-size: 13px`

---

## Колонка 1 — «Объект / Подрядчик»

### L1 (группа)

```
▾  Школа Мирас   (2)
```

### L2 (строка-заявка)

```
   ИП Дархан
   [описание заявки, truncate, max 1 строка]
```

- Первая строка: имя подрядчика (`contractors.name`), `font-weight: 500`
- Вторая строка: `purchase_items.description`, `font-size: 12px`, `color: var(--text-secondary)`, `white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 300px`

---

## Колонка 2 — «SLA»

**SLA = 72 рабочих часа** (ADR-27). Отображает время ожидания.

| Elapsed | Отображение | CSS token |
|---|---|---|
| < 24ч | `Xч` | `--status-green-text` |
| 24–48ч | `Xч` + `Clock` (12px) | `--status-amber-text` |
| > 48ч | `Xч` + `AlertTriangle` (12px) | `--status-red-text` |
| > 72ч | `Xч ⚠ ПРОСРОЧЕНО` | `--status-red-text`, bold |

```typescript
const elapsedH = Math.floor((Date.now() - new Date(task.createdAt).getTime()) / 3_600_000);
```

---

## Колонка 3 — «Тип»

Compact badge, `font-size: 11px`, `border-radius: var(--rounded-sm)`, `padding: 2px 6px`.

| `commitment_type` | Метка | Цвет |
|---|---|---|
| `SUBCONTRACT` | «АВР субподряда» | `--status-blue-bg` / `--status-blue-text` |
| `ADVANCE` | «Аванс» | `--status-amber-bg` / `--status-amber-text` |
| `MATERIAL_REQUEST` | «Материалы» | `--status-slate-bg` / `--status-slate-text` |

---

## Колонка 4 — «Сумма»

- `formatCurrency('ru-KZ', 'KZT')(item.amountRequested)`
- `font-weight: 500`, right-align
- `font-size: 13px`

---

## Колонка 5 — «Договор»

- Номер договора: `contracts.contractNumber`
- Truncate если длинный: `max-width: 120px`, ellipsis
- `color: var(--text-primary)`, `font-size: 12px`

---

## Колонка 6 — «Решение» (inline action buttons)

```
[✓]  [✗]
```

| Кнопка | Icon | Стиль | Действие |
|---|---|---|---|
| **Утвердить** | `Check` (14px) | `background: var(--status-green-bg)`, `color: var(--status-green-text)`, `border: 1px solid var(--status-green-text)`, `border-radius: var(--rounded-sm)`, `padding: 4px 8px` | Вызов `approveCommitment(id)` inline |
| **Отклонить** | `X` (14px) | `background: var(--status-red-bg)`, `color: var(--status-red-text)`, `border: 1px solid var(--status-red-text)`, `border-radius: var(--rounded-sm)`, `padding: 4px 8px` | Открытие `RejectSheet` |

**Состояния кнопки Утвердить:**
- `idle` → `loading` (spinner, disabled) → исчезает из списка (optimistic)
- Loading state: `opacity: 0.6`, spinner `Loader2` 12px вместо `Check`

**Hover tooltip:**
- `[✓]` tooltip: `«Утвердить заявку»`
- `[✗]` tooltip: `«Отклонить заявку»`

---

## Sheet: RejectSheet

> Без изменений vs. текущая спека. Sheet обязателен — форма только внутри.

**Ширина:** `420px` desktop, full-width mobile
**Заголовок:** `«Отклонить заявку»`
**Контент:**
- Краткая сводка заявки: подрядчик + сумма (read-only)
- `<textarea>` «Причина отклонения», обязательно, `min 5 символов`

**Footer:**
```
[Отмена]              [Отклонить заявку]
(secondary)           (destructive, disabled if empty)
```

**Guard rails:**
- `useSheetEsc(open, onClose)` — обязателен
- Сервер также валидирует комментарий (ADR-42)

---

## Оптимистичное удаление строк

После `approveCommitment(id)` или успешного `rejectCommitment(id, comment)`:
1. Строка мгновенно убирается из локального state (`setItems(prev => prev.filter(...))`)
2. Счётчик группы уменьшается — если группа опустела, скрывается
3. `revalidatePath` в Server Action синхронизирует данные в фоне
4. Если все заявки обработаны — показывается Empty State

---

## Empty State

```
[CheckCircle2, 48px, color: var(--status-green-text)]

Нет заявок на рассмотрении

Все заявки обработаны.
Новые появятся здесь по мере поступления.
```

---

## Data Source

**Server Action:** `getCommitmentsForDirector()`

```typescript
// Возвращает:
interface DirectorCommitmentItem {
  id: string;                    // purchase_items.id
  taskId: string;                // commitment_approval_tasks.id
  taskCreatedAt: string;         // ISO — для SLA расчёта
  description: string;
  commitmentType: CommitmentType;
  amountRequested: number;
  objectId: string | null;
  objectName: string | null;     // project_objects.name
  projectName: string;           // projects.name
  contractorName: string;        // contractors.name
  contractNumber: string;        // contracts.contractNumber
  authorName: string;            // profiles.full_name (создатель)
}
```

**Группировка** выполняется **client-side** через `useMemo`:

```typescript
const grouped = useMemo(() => {
  const filtered = items.filter(/* search */);
  return groupBy === 'object'
    ? groupByKey(filtered, i => i.objectName ?? i.projectName)
    : groupByKey(filtered, i => i.contractorName);
}, [items, search, groupBy]);
```

---

## Компоненты

| Компонент | Тип | Путь | LOC |
|---|---|---|---|
| `page.tsx` | Server | `approvals/page.tsx` | < 50 |
| `ApprovalsTable.tsx` | Client | `approvals/_components/ApprovalsTable.tsx` | < 150 |
| `ApprovalsTableRow.tsx` | Client | `approvals/_components/ApprovalsTableRow.tsx` | < 80 |
| `RejectSheet.tsx` | Client | `approvals/_components/RejectSheet.tsx` | < 100 |

> **Удаляется:** `ApprovalsGrid.tsx`, `ApprovalDetailPanel.tsx` — заменяются на `ApprovalsTable.tsx` + `ApprovalsTableRow.tsx`.

### page.tsx — ответственность

```typescript
const user = await getCurrentUser();
if (!['DIRECTOR', 'DEPUTY_DIRECTOR'].some(r => user.roles.includes(r)))
  redirect('/dashboard/requests');

const items = await getCommitmentsForDirector();
return <ApprovalsTable initialItems={items} />;
```

### ApprovalsTable.tsx — ответственность

- State: `items`, `search`, `groupBy`, `rejectingItemId`, `expandedGroups`
- `useMemo` группировки
- Рендер: Controls Bar + заголовки + L1 + L2 строки
- Optimistic remove
- Открытие `RejectSheet`

### ApprovalsTableRow.tsx — ответственность

- Принимает один `item: DirectorCommitmentItem`
- Рендерит 6 колонок
- Управляет `approving: boolean` (local state для spinner)
- Вызывает `onApprove(id)` / `onReject(id)` колбэки

---

## Инварианты

1. **PENDING only** — только задачи со статусом PENDING
2. **Роль guard** — проверка в `page.tsx`, не-директора → redirect
3. **ADR-42** — Директор не видит своих заявок
4. **Inline approval** — утверждение без Sheet, без дополнительных кликов
5. **Reject → Sheet** — обязательный комментарий только через Sheet
6. **useSheetEsc** — обязателен в `RejectSheet`
7. **Optimistic UI** — строка исчезает сразу, не ждёт revalidatePath
8. **Client-side grouping** — группировка и поиск в useMemo, не перезагрузка страницы
9. **Форматирование** — `formatCurrency` везде, `formatDate` для SLA tooltip
10. **Max 150 строк** — каждый компонент; `ApprovalsTableRow` выделен именно для этого
11. **Только CSS custom properties** — никаких hardcoded цветов
12. **Только Lucide React** — `Check`, `X`, `ChevronDown`, `ChevronRight`, `Clock`, `AlertTriangle`, `Loader2`, `CheckCircle2`

---

## Связанные ADR

- `docs/03_decisions/42_requests-registry-view-model.md` — маршруты, роли, инварианты
- `docs/03_decisions/27_sla-framework.md` — SLA нормативы
- `docs/03_decisions/38_task-per-role-architecture.md` — task pattern
- `docs/03_decisions/34_ui-interaction-patterns.md` — Sheet, интеракции
- `docs/03_decisions/40_client-component-initial-data-loading.md` — ADR-40 pattern

---

## Фаза 2+ (не реализовывать сейчас)

Следующие колонки добавляются когда будет доступна финансовая аналитика:

| Колонка | Источник | Описание |
|---|---|---|
| **Договор % АВР / % оплаты** | `avr_documents` | Процент освоения договора |
| **АВР / Платежи** | `avr_documents`, `payment_orders` | Суммы подписанных АВР и платежей |
| **Баланс / Гарантия** | computed | Остаток по договору |
| **Прогноз баланса** | computed | Баланс после утверждения заявки (может быть красным) |
