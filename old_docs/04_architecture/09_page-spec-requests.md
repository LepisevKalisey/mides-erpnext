# Page Spec: Мои заявки

**Маршрут:** `/requests`
**Слайс:** 1.1 — «Мои заявки» (Фаза 1)
**Агент:** Frontend Agent (see AGENTS.md §2)
**Статус:** Ready for Implementation

---

## Контекст и назначение

Страница `/requests` — личный рабочий стол каждого сотрудника.
Каждый пользователь видит **только свои** заявки (`created_by = current_user`).
Это не операционный реестр — это персональный трекер статусов.

> **ADR-42 инвариант:** `/requests` доступен **всем ролям**. Ни один пользователь не
> отправляется на другую страницу при открытии `/requests`.

---

## Route

`/requests`

## Agent

Frontend Agent (see AGENTS.md §2)

---

## Роли и доступ

| Роль | Видит страницу | Видит кнопку «+ Заявка» | Тип заявок при создании |
|---|:---:|:---:|---|
| `PM` | ✅ | ✅ | АВР субподряда (SUBCONTRACT), Аванс (ADVANCE) |
| `FOREMAN` (Прораб) | ✅ | ✅ | Запрос материалов (MATERIAL_REQUEST) |
| `DIRECTOR` | ✅ | ✅ | Платёжное поручение (PAYMENT_APPLICATION → авто-APPROVED) |
| `TREASURER` (Казначей) | ✅ | ✅ | Запрос оборудования, Аванс на услуги |
| `ACCOUNTANT` (Бухгалтер) | ✅ | ✅ | Запрос оборудования, Аванс на услуги |
| `PROCUREMENT` (Снабженец) | ✅ | ✅ | Запрос оборудования |
| Прочие офисные роли | ✅ | ✅ | Запрос оборудования, Аванс на услуги |

> **Слайс 1.1 фокус:** Реализуется только для роли `PM` (создание SUBCONTRACT/ADVANCE).
> Остальные типы заявок — в следующих слайсах. Кнопка «+ Заявка» показывается всем ролям,
> но Sheet отображает только поля, релевантные текущей роли.

---

## Layout

```
┌── Page Header ─────────────────────────────────────────┐
│ Заголовок: «Мои заявки»          [+ Заявка]            │
├── Filters Bar ─────────────────────────────────────────┤
│ [Статус ▼]  [Поиск по описанию...]                     │
├── AccordionGrid ───────────────────────────────────────┤
│ Описание  │  Проект / Объект  │ Подрядчик │ Сумма │Ст. │
│ ───────────────────────────────────────────────────── │
│ ▶ Строка 1 заявки (сворачивается / раскрывается)      │
│   └── Раскрытая панель: детали + трек утверждения      │
├── Empty State (если заявок нет) ───────────────────────┤
│                [иллюстрация]                           │
│          «Заявок пока нет»                             │
│      [Создать первую заявку]                           │
└────────────────────────────────────────────────────────┘
```

---

## Data Source

- **Server Action:** `getCommitmentsForPM(projectId?)`
- **Schema tables:** `purchase_items`, `commitment_approval_tasks`, `contracts`, `contractors`, `projects`, `project_objects`
- **Joins:**
  - `purchase_items` JOIN `commitment_approval_tasks` ON `purchase_item_id` (LEFT JOIN — может отсутствовать у Директора)
  - `purchase_items` JOIN `contracts` ON `contract_id`
  - `purchase_items` JOIN `contractors` ON `contractor_id`
  - `purchase_items` JOIN `projects` ON `project_id`
  - `purchase_items` LEFT JOIN `project_objects` ON `object_id`
- **Фильтр по умолчанию:** `created_by = current_user`
- **Сортировка:** `created_at DESC`

---

## AccordionGrid — Колонки

**gridTemplate:** `"2fr 1fr 1fr 140px 110px"`

| # | Колонка | Тип | Источник | Выравнивание | Сортируемая |
|---|---|---|---|---|---|
| 1 | **Описание** | text (основная, раскрывает row) | `purchase_items.description` | left | нет |
| 2 | **Проект / Объект** | text (две строки) | `projects.name` / `project_objects.name` | left | нет |
| 3 | **Подрядчик** | text | `contractors.name` | left | нет |
| 4 | **Сумма** | currency | `purchase_items.amount_requested` | right | нет |
| 5 | **Статус** | badge | `commitment_approval_tasks.status` | center | нет |

### Заголовки AccordionGrid

```
header={[
  { label: 'Описание' },
  { label: 'Проект / Объект' },
  { label: 'Подрядчик' },
  { label: 'Сумма', align: 'right' },
  { label: 'Статус', align: 'center' },
]}
```

---

## Статусные badge (колонка «Статус»)

Статус определяется из `commitment_approval_tasks.status` (ADR-38 pattern).

| Значение `approval_task.status` | Badge Label | CSS Token | Значение для пользователя |
|---|---|---|---|
| `null` / task отсутствует | «Черновик» | `--status-slate-bg` / `--status-slate-text` | Заявка создана, ещё не на утверждении |
| `PENDING` | «На утверждении» | `--status-amber-bg` / `--status-amber-text` | Ожидает решения Директора |
| `APPROVED` | «Утверждена» | `--status-green-bg` / `--status-green-text` | Прошла утверждение |
| `REJECTED` | «Отклонена» | `--status-red-bg` / `--status-red-text` | Отклонена с комментарием |

> **Guard Rail:** Никогда не хардкодить цвета. Только CSS custom properties из `globals.css`.
> Никогда не использовать emoji — только Lucide React иконки.

---

## Раскрытая строка (AccordionGrid expand panel)

При клике на строку открывается панель под ней. Показывает:

### Блок: Детали заявки

```
Договор:       №СД-2025-001 от 15.01.2025
Тип заявки:    АВР субподряда (SUBCONTRACT)
Сумма:         1 500 000 ₸
Дата создания: 19.05.2026
Ретроспективная: Нет / Да (+ причина если Да)
```

### Блок: Трек утверждения

Показывается всегда — даже если задача ещё не создана.

```
● Создана      19.05.2026 10:30 — Иванов А.П.
● На утверждении  19.05.2026 10:31 — ожидает Директора  [SLA: 3 р/дня]
○ Утверждена   (ожидается)
○ Оплачена     (ожидается)
```

Если задача `REJECTED`:
```
● Создана      19.05.2026 10:30 — Иванов А.П.
✕ Отклонена    20.05.2026 11:15 — Директор Петров С.И.
  Комментарий: «Недостаточно обоснований»
```

---

## Кнопка «+ Заявка»

- Расположение: правый верхний угол страницы (Page Header actions)
- Иконка: `Plus` из Lucide React
- При нажатии: открывается `CreateCommitmentSheet` (Sheet справа)
- Показывается: **всем авторизованным пользователям**
- В Слайсе 1.1: форма создаёт только `SUBCONTRACT` или `ADVANCE` (для роли PM)

---

## Sheet: CreateCommitmentSheet

**Компонент:** `CreateCommitmentSheet.tsx`
**Ширина:** 480px desktop, full-width mobile
**Заголовок:** «Новая заявка»

### Обязательные guard rails для Sheet
- `useSheetEsc(open, onClose)` из `@/hooks/use-sheet-esc` — ОБЯЗАТЕЛЕН
- Все суммы: `formatCurrency('ru-KZ', 'KZT')` из `lib/formatters.ts`
- Форма ТОЛЬКО внутри Sheet, никогда — отдельная страница

### Поля формы (Слайс 1.1 — роль PM, типы SUBCONTRACT/ADVANCE)

| Поле | Тип | Обязательность | Валидация | Зависимость |
|---|---|---|---|---|
| **Тип заявки** | `select` (radioGroup) | Обязательно | `SUBCONTRACT` или `ADVANCE` | — |
| **Проект** | `select` | Обязательно | must select | Фильтрует Договор |
| **Объект** | `select` | Необязательно | — | Зависит от Проекта |
| **Договор** | `select` | Обязательно | Должен быть ≥ `INTENT` | Фильтруется по Проекту + Подрядчику |
| **Описание** | `textarea` | Обязательно | min 5 символов | — |
| **Сумма** | `number input` | Обязательно | > 0, числовое | — |
| **Валюта** | скрытое поле | — | `KZT` default | — |
| **Ретроспективная** | `checkbox` | Необязательно | — | Показывает поле «Причина» |
| **Причина ретроспективности** | `textarea` | Условно обязательно | Обязательно если checkbox=true | Скрыто если checkbox=false |

### Зависимые select: логика каскада

```
1. Пользователь выбирает Проект
   → фильтрует список Объектов (project_objects WHERE project_id = selected)
   → фильтрует список Договоров (contracts WHERE project_id = selected AND status IN ['INTENT','SIGNED','ACTIVE'])
   → очищает выбранный Объект и Договор

2. Пользователь выбирает Договор
   → contractorId и legalEntityId заполняются автоматически из contract
   → эти поля НЕ показываются в форме (hidden, передаются в Server Action)
```

> **ADR-41 инвариант:** Поле `cost_code` **НЕ появляется** в этой форме.
> `cost_code_id` существует только в строках АВР (`avr_document_lines`).
> Добавление этого поля в форму заявки — нарушение ADR-41.

### Footers Sheet

```
[Отмена]                     [Создать заявку →]
(button-secondary)           (button-primary, disabled if invalid)
```

### Server Action вызов

```typescript
await createCommitment({
  projectId,
  objectId,
  contractId,
  contractorId,     // из выбранного договора
  legalEntityId,    // из выбранного договора
  description,
  amountRequested,  // string, числовая строка
  currency: 'KZT',
  isRetrospective,
  retrospectiveReason,
})
```

### Обработка ошибок формы

| Ошибка | Отображение |
|---|---|
| Сумма ≤ 0 | Inline ошибка под полем: «Введите корректную сумму» |
| Описание пустое | Inline: «Описание обязательно» |
| Договор не выбран | Inline: «Выберите договор» |
| Причина не введена при ретроспективной | Inline: «Укажите причину» |
| Server Action вернул ошибку | Toast (error) с текстом ошибки из ActionResult |

---

## Пустое состояние

Показывается когда `getCommitmentsForPM()` возвращает пустой массив.

```
[иконка: FileText, 64px, цвет --status-slate-text]

Заявок пока нет

У вас ещё не создано ни одной заявки.
Создайте первую — это займёт меньше минуты.

[+ Создать заявку]   ← button-primary, открывает Sheet
```

---

## Фильтры

**Слайс 1.1:** минимальный набор фильтров.

| Фильтр | Тип | По умолчанию | Поведение |
|---|---|---|---|
| **Статус** | `select` | «Все» | Фильтрует по `approval_task.status` |
| **Поиск** | `text input` | «» | Client-side по `description` |

---

## Компоненты для реализации

| Компонент | Тип | Путь | Описание |
|---|---|---|---|
| `page.tsx` | Server Component | `web/src/app/(dashboard)/requests/page.tsx` | Загружает данные, рендерит заголовок + `CommitmentsGrid` |
| `CommitmentsGrid.tsx` | Client Component | `web/src/app/(dashboard)/requests/_components/CommitmentsGrid.tsx` | AccordionGrid с expand + фильтры |
| `CreateCommitmentSheet.tsx` | Client Component | `web/src/app/(dashboard)/requests/_components/CreateCommitmentSheet.tsx` | Sheet с формой создания заявки |

### page.tsx — зона ответственности

```typescript
// Server Component — загружает данные на сервере
const commitments = await getCommitmentsForPM()
// Передаёт данные в CommitmentsGrid как props (ADR-40 pattern)
```

### CommitmentsGrid.tsx — зона ответственности

- Принимает `initialData` от `page.tsx`
- Управляет состоянием фильтров (useState)
- Управляет состоянием expand (useAccordionState)
- Управляет открытием Sheet (useState boolean)
- Рендерит AccordionGrid + EmptyState
- Max 150 строк — при необходимости вынести логику expand в отдельный компонент

### CreateCommitmentSheet.tsx — зона ответственности

- Получает `open` и `onClose` от родителя
- Использует `useSheetEsc(open, onClose)` — обязательно
- Управляет состоянием формы (useState или react-hook-form)
- Вызывает `createCommitment()` из `actions.ts`
- После успеха: закрывает Sheet + показывает Toast
- Max 150 строк — при необходимости вынести поля в sub-компоненты

---

## Ролевые различия (детали)

### PM видит:
- Все свои SUBCONTRACT и ADVANCE заявки
- Кнопка «+ Заявка»: открывает Sheet с типами SUBCONTRACT / ADVANCE
- В Sheet: доступны проекты, на которых он назначен как PM

### FOREMAN видит:
- Все свои MATERIAL_REQUEST заявки (Слайс 2.x)
- Кнопка «+ Заявка»: Слайс 1.1 — форма отображает заглушку «Тип запросов материалов — в следующем обновлении»
- ИЛИ (предпочтительно): кнопка показывается, Sheet отображает только поля типа Material Request

### DIRECTOR видит:
- Все свои PAYMENT_APPLICATION заявки (авто-APPROVED)
- В статусном треке: нет шага «Ожидает утверждения» — сразу «Утверждена»

### TREASURER / ACCOUNTANT / прочие:
- Видят только свои заявки соответствующих типов
- В Слайсе 1.1: кнопка «+ Заявка» показывается, но Sheet — заглушка

> **Прагматичное решение Слайса 1.1:** Кнопка «+ Заявка» показывается всем, но
> `CreateCommitmentSheet` в Слайсе 1.1 реализует только поля для PM (SUBCONTRACT/ADVANCE).
> Остальные типы добавляются в следующих слайсах без изменения структуры страницы.

---

## Инварианты

1. **created_by = current_user** — страница НИКОГДА не показывает чужие заявки (ADR-42)
2. **cost_code_id** — НИКОГДА не появляется в форме создания заявки (ADR-41)
3. **contractId обязателен** — заявка не создаётся без привязки к договору
4. **Статус договора** — только `INTENT`, `SIGNED`, `ACTIVE` (не CLOSED/TERMINATED)
5. **Sheet only** — форма создания ТОЛЬКО в Sheet, никогда в отдельной странице (DESIGN.md)
6. **useSheetEsc** — обязателен в каждом Sheet компоненте (AGENTS.md §2)
7. **Суммы** — `formatCurrency('ru-KZ', 'KZT')` везде без исключений (AGENTS.md §2)
8. **Max 150 строк** — каждый компонент не превышает 150 строк (AGENTS.md §2)
9. **Только Lucide React** — никаких emoji, никаких других иконок (DESIGN.md)
10. **Только CSS custom properties** — никаких hardcoded цветов (AGENTS.md §2)

---

## Связанные ADR

- `docs/03_decisions/42_requests-registry-view-model.md` — маршруты и роли
- `docs/03_decisions/41_cost-code-at-avr-line-level.md` — инвариант cost_code
- `docs/03_decisions/38_task-per-role-architecture.md` — commitment_approval_tasks паттерн
- `docs/03_decisions/07_accordion-table-standard.md` — AccordionGrid паттерн и компонент
- `docs/03_decisions/34_ui-interaction-patterns.md` — Sheet, фильтры, интеракции
- `docs/03_decisions/40_client-component-initial-data-loading.md` — ADR-40 pattern (initialData)
- `docs/03_decisions/36_unified-payment-registry.md` — единый реестр purchase_items
- `docs/03_decisions/14_overhead-project-type.md` — OFFICE_PROJECT по умолчанию

---

## Связанные файлы реализации

- `web/src/app/(dashboard)/requests/actions.ts` — готовые Server Actions
- `web/src/components/accordion/` — AccordionGrid компонент
- `web/src/hooks/use-sheet-esc.ts` — хук Escape-close для Sheet
- `web/src/lib/formatters.ts` — `formatCurrency`, `formatDate`
- `web/src/app/globals.css` — CSS custom properties
