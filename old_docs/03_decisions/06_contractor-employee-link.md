# ADR-06: Связь Контрагент ↔ Сотрудник и Дашборд Сотрудника

## Статус
В проектировании — 2026-05-04

---

## Контекст

Текущая схема имеет `managerId` (single FK) на таблице `contractors` — это не соответствует требованию «один холдинг может быть закреплён за несколькими сотрудниками». Нужна junction-таблица.

Также уточнена иерархия отображения в дашборде сотрудника:

```
Холдинг (contractors)
  └── Юридическое лицо (contractor_entities)
        └── Объект (objects)
              └── [+] Создать заявку
```

Назначение выполняет **Казначей** при создании или редактировании контрагента.

---

## Решение

### 1. Схема: замена managerId → junction table

**Удалить:**
```sql
-- contractors.manager_id (single FK)
ALTER TABLE midescloud.contractors DROP COLUMN manager_id;
```

**Добавить:**
```sql
-- Many-to-many: contractor (holding) ↔ employee
CREATE TABLE midescloud.contractor_managers (
  contractor_id UUID NOT NULL REFERENCES midescloud.contractors(id) ON DELETE CASCADE,
  user_id       TEXT NOT NULL REFERENCES midescloud.users(id) ON DELETE CASCADE,
  assigned_at   TIMESTAMP NOT NULL DEFAULT NOW(),
  assigned_by_id TEXT REFERENCES midescloud.users(id),  -- кто назначил (казначей)
  PRIMARY KEY (contractor_id, user_id)
);
```

### 2. Логика назначения

- Назначение и снятие — через Казначея в интерфейсе **Казначейство → Справочники → Контрагенты**.
- В Sheet при редактировании/создании холдинга: мультиселект сотрудников с флагом `worksWithContractors = true`.
- Server Action: `upsertContractorManagers(contractorId, userIds[])` — полная замена списка.

### 3. Dashboard сотрудника — вкладка «Мои контрагенты»

#### Условие показа вкладки
Пользователь имеет `worksWithContractors = true` И есть хотя бы одна запись в `contractor_managers` для него.

#### Иерархия данных (3 уровня)

```
▼ Холдинг «СтройГрупп»                                  [итоги по холдингу]
  ▼ ТОО «СтройГрупп-Монтаж»                             [итоги по юрлицу]
    • Объект «ГКБ 4»   | Договор | АВР | Баланс | Заявки | Прогноз  [+]
    • Объект «Школа 5» | ...                                          [+]
  ▼ ИП Иванов А.А.                                       [итоги по юрлицу]
    • Объект «ГКБ 4»   | ...                                          [+]
```

#### Колонки таблицы (по скриншотам)

| Колонка | Источник | Формула |
|---|---|---|
| Договор (сумма / % AVR) | `contracts` | SUM(amount) / AVR÷Contract% |
| % оплаты | `payments` | Paid÷Contract% |
| АВР | `avr` | SUM(amount) |
| Платежи | `payments` | SUM(amount) |
| Баланс | расчёт | AVR − Warranty − Paid |
| Гарантия | расчёт | SUM(avr.amount × contract.warrantyPercent/100) |
| Заявки | `requests` | SUM(amount) WHERE status=PENDING |
| Утверждено | `requests` | SUM(amount) WHERE status=APPROVED |
| Прогноз баланса | расчёт | Баланс − Утверждено |
| Действия | UI | [+] создать заявку |

#### Два режима группировки (URL param: `?group=contractor|object`)

- **По контрагентам** (default): Холдинг → Юрлицо → Объект
- **По объектам**: Объект → Холдинг → Юрлицо

#### Создание заявки (кнопка [+])

Нажатие на `+` у конкретного объекта открывает **Inline Sheet**:
- Объект — заблокирован (уже известен)
- Контрагент (юрлицо) — заблокирован
- Сумма — ввод
- Договор — выбор из привязанных к этой паре (объект + юрлицо)
- Примечание — опционально
- → Создаётся `request` со статусом `PENDING`, `authorId = currentUser`

### 4. Интерфейс назначения (Казначей)

В Sheet добавления/редактирования холдинга-контрагента:

```
┌─────────────────────────────────┐
│ Название холдинга               │
│ Примечание                      │
│ ─────────────────────────────── │
│ Ответственные сотрудники        │
│ [Иванов Иван ×] [Петров П. ×]  │
│ [+ Добавить сотрудника ▾]       │
└─────────────────────────────────│
```

Выпадающий список показывает только пользователей с `worksWithContractors = true`.

---

## Затрагиваемые файлы

### Schema
- `web/src/db/schema/core.ts` — удалить `managerId`, добавить `contractorManagers`

### Server Actions
- `web/src/app/(main)/treasury/_actions.ts` — `upsertContractorManagers`
- `web/src/app/(main)/dashboard/_actions.ts` — `getMyContractors`, `createRequest`

### UI Components
- `web/src/app/(main)/treasury/_components/contractor-sheet.tsx` — обновить форму
- `web/src/app/(main)/dashboard/_components/my-contractors-tab.tsx` — NEW
- `web/src/app/(main)/dashboard/_components/contractors-summary-table.tsx` — NEW
- `web/src/app/(main)/dashboard/_components/create-request-sheet.tsx` — NEW
- `web/src/app/(main)/dashboard/page.tsx` — подключить вкладку

---

## Последствия

- Нужен `drizzle-kit push` после изменения схемы.
- Существующие данные не затрагиваются (новая таблица, старый `managerId` пуст т.к. только добавлен).
- Вкладка «Мои контрагенты» появляется в дашборде автоматически при наличии назначений.
- При удалении сотрудника (`ON DELETE CASCADE`) — его назначения снимаются.

## Связанные документы

- `docs/03_decisions/04_contractor-hierarchy.md` (ADR-04)
- `docs/03_decisions/05_dashboard-workday-contractor-manager.md` (ADR-05)
- `docs/BUSINESS_LOGIC.md` §3.1, §7, §8
