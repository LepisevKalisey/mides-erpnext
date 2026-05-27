# ADR-07: Стандарт таблиц-аккордеонов

## Статус

**Обновлено — 2026-05-14** (заменяет версию от 2026-05-13)

## Решение

Все таблицы с иерархической группировкой (аккордеоны) реализуются через
единый переиспользуемый компонент:

```
src/components/accordion/
├── index.ts                 — barrel exports
├── accordion-grid.tsx       — компоненты + дизайн-токены уровней
└── use-accordion-state.ts   — хук состояния + sessionStorage
```

## Правила использования

### 1. Только этот компонент — никогда не создавать новый

Если нужна таблица-аккордеон → **всегда** брать из `@/components/accordion`.
Если текущего функционала недостаточно → **дорабатывать компонент**, а не создавать параллельный.

### 2. Импорты

```tsx
import {
  AccordionGridTable,    // обёртка со sticky header
  AccordionGridRow,      // раскрываемая строка (уровни 1–4)
  AccordionGridLeafRow,  // листовая строка без chevron (уровень 5)
  AccordionEmptyCell,    // плейсхолдер «—» для пустой ячейки
  ACCORDION_LEVEL_STYLES, // дизайн-токены всех уровней
  useAccordionState,     // хук expand-сета (+ sessionStorage)
} from '@/components/accordion'
```

### 3. Минимальный пример

```tsx
function MyTable({ rows }: { rows: Row[] }) {
  const { expanded, toggle } = useAccordionState('my-table-v1')

  return (
    <AccordionGridTable
      gridTemplate="2fr 1fr 1fr 120px"
      header={[
        { label: 'Сумма',    align: 'right' },
        { label: 'Баланс',   align: 'right' },
        { label: 'Действия', align: 'right' },
      ]}
    >
      {rows.map(row => (
        <AccordionGridRow
          key={row.id}
          id={row.id}
          level={1}
          label={row.name}
          expanded={expanded.has(row.id)}
          onToggle={() => toggle(row.id)}
          cells={[
            <span key="sum">{row.amount}</span>,
            <span key="bal">{row.balance}</span>,
            <ActionButton key="act" />,
          ]}
        >
          {/* вложенные строки */}
        </AccordionGridRow>
      ))}
    </AccordionGridTable>
  )
}
```

### 4. API компонентов

#### `AccordionGridTable`

| Prop | Тип | Описание |
|------|-----|----------|
| `gridTemplate` | `string` | CSS grid-template-columns |
| `header` | `AccordionGridHeaderDef[]` | Определения колонок (label, sublabel, align) |
| `labelColumnPrefix` | `ReactNode?` | Элемент перед названием в шапке (select-all checkbox) |
| `className` | `string?` | Дополнительные классы |

#### `AccordionGridRow`

| Prop | Тип | Описание |
|------|-----|----------|
| `id` | `string` | Уникальный ID (должен быть **глобально уникальным** в дереве) |
| `level` | `1\|2\|3\|4\|5` | Уровень вложенности (определяет цвет, отступ, размер шрифта) |
| `label` | `string` | Основной текст |
| `sublabel` | `string?` | Вторая строка под label |
| `expanded` | `boolean` | Управляется внешним состоянием |
| `onToggle` | `() => void` | Callback при клике |
| `cells` | `ReactNode[]` | Ячейки данных (кол-во = кол-ву header) |
| `checkbox` | `ReactNode?` | Чекбокс перед chevron |
| `children` | `ReactNode?` | Вложенные строки |
| `dimmed` | `boolean?` | Строка затемнена (opacity-55) |

#### `AccordionGridLeafRow`

Те же props, кроме `expanded/onToggle/children` (нет chevron, не раскрывается).
Добавлен `onLabelClick?: () => void` — открывает сайдбар.

#### `useAccordionState(storageKey?, defaultOpen?)`

```ts
const {
  expanded,    // Set<string>
  toggle,      // (id) => void
  isExpanded,  // (id) => boolean
  expandMany,  // (ids[]) => void
  collapseMany,// (ids[]) => void
  toggleGroup, // (ids[]) => void — если все открыты → закрывает, иначе → открывает
} = useAccordionState('my-key-v1')
```

### 5. Критичное правило: уникальность ID

Все `id` в дереве должны быть **глобально уникальными** в рамках одного аккордеона.
Если один и тот же контрагент или тип работ встречается в нескольких проектах/объектах —
необходимо использовать **составной ключ**:

```ts
// НЕПРАВИЛЬНО — одинаковый ID во всех проектах:
const key = row.contractorId   // UUID может повторяться в разных объектах

// ПРАВИЛЬНО — составной ключ:
const contractorKey = `${row.objectId}__${row.contractorId}`
const workTypeKey   = `${row.objectId}__${row.contractorId}__${row.workTypeId ?? row.flowType}`
```

Без этого правила клик «Свернуть» будет сворачивать одноимённые узлы во всех проектах.

### 6. Дизайн-токены уровней (`ACCORDION_LEVEL_STYLES`)

| Уровень | Фон | Indent Col1 | Текст |
|---------|-----|-------------|-------|
| 1 | `#f0f4f8` | `pl-3` | 13px semibold синий |
| 2 | `#f7f8fa` | `pl-8` | 12px medium серый |
| 3 | `#fafbfc` | `pl-12` | 12px semibold тёмный |
| 4 | `white` | `pl-[3.75rem]` | 11px серый |
| 5 (leaf) | `white` | `pl-[4.5rem]` | 12px тёмный |

**Не переопределять** эти токены в потребителях компонента — только через правку `accordion-grid.tsx`.

## Эталонная реализация

Реестр заявок (Финансы → Реестр оплат):

```
web/src/app/(main)/approvals/_components/registry/
├── registry-tree.tsx       — главный компонент (использует AccordionGridTable)
├── registry-agg-row.tsx    — утилиты (formatAmount, REGISTRY_GRID)
├── registry-leaf-row.tsx   — листовая строка (использует AccordionGridLeafRow)
└── registry-tree-utils.ts  — построение дерева + составные ключи
```

## Альтернативы (ОТКЛОНЕНЫ)

| Вариант | Причина отказа |
|---------|----------------|
| Кастомная реализация per-module | Дублирование кода, несогласованный UX |
| `<table>` + `<tr>` accordion | Плохая поддержка grid-выравнивания |
| Библиотечный DataGrid | Избыточность, конфликт с дизайн-кодом |
| `/requests/accordion-table.tsx` (старый эталон) | Устарел, заменён переиспользуемым модулем |

## Связанные файлы

- `web/src/components/accordion/` — сам компонент
- `web/src/app/(main)/approvals/_components/registry/registry-tree.tsx` — реализация
- `docs/03_decisions/06c_typography-fira-sans-fira-code.md`
