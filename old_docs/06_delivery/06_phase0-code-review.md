# Code Review — Фаза 0 (Walking Skeleton)

**Дата:** 2026-05-19  
**Ревьювер:** Frontend + Backend Agent  
**Статус:** ✅ Фаза 0 ПОЛНОСТЬЮ ЗАВЕРШЕНА — Все блокирующие дефекты устранены

---

## Сводка по плану

| Элемент Фазы 0 | Статус | Комментарий |
|---|---|---|
| **Schema: auth** | ✅ | `profiles`, `user_roles` — готово |
| **Schema: legal-entities** | ✅ | Готово |
| **Schema: contractors** | ✅ | `COMPANY` / `INDIVIDUAL` через `contractorType` |
| **Schema: employees** | ✅ | `departments`, `positions`, `employees` — готово |
| **Schema: projects** | ✅ | `projects`, `project_objects` (CIVIL/MEP), `project_assignments` |
| **Schema: contracts** | ✅ | Lifecycle `INTENT→SIGNED→ACTIVE→CLOSED/TERMINATED` |
| **Schema: cost-codes** | ✅ | `cost_codes` + `legal_work_types` — готово |
| **Schema index.ts** | ✅ | Все таблицы экспортированы в правильном порядке |
| **UI: legal-entities** | ✅ | Модуль присутствует |
| **UI: contractors** | ✅ | Модуль присутствует |
| **UI: employees** | ✅ | Модуль присутствует |
| **UI: projects** | ✅ | AccordionGrid + Objects tab (CIVIL/MEP) + Team picker |
| **UI: contracts** | ✅ | AccordionGrid + lifecycle workflow |
| **UI: overview (dashboard)** | ✅ | Модуль присутствует |
| **Auth middleware** | ✅ | Session refresh + MOCK_AUTH для тестов |
| **Dashboard layout** | ✅ | Auth guard + Sidebar/Header |
| **warranty_percent guard** | ✅ | `INTENT→SIGNED` блокируется без %  |
| **TypeScript (src/)** | ✅ | **0 ошибок** (Все ошибки устранены) |
| **TypeScript (tests/)** | ✅ | **0 ошибок** (Все ошибки устранены) |

---

## 🔴 УСТРАНЕННЫЕ БЛОКЕРЫ (Исправлено перед переходом к Фазе 1)

### Блокер 1: `WorkStream` не экспортировался из `actions.ts`
- **Проблема:** Тип `WorkStream = "CIVIL" | "MEP"` использовался во frontend-компонентах, но не имел явного экспорта из Server Actions, что приводило к circular refs и ошибкам TS2304.
- **Исправление:** Добавлен явный `export type WorkStream = "CIVIL" | "MEP"` в начале [actions.ts](file:///c:/Projects/Mides/MidesCloud%20v3/web/src/app/dashboard/projects/actions.ts).

### Блокер 2: Небезопасный `as` cast в `actions.ts`
- **Проблема:** Попытка приведения сложной структуры Supabase-выборки к `Record<string, unknown>` вызывала ошибку компиляции TS2352.
- **Исправление:** Применён безопасный промежуточный каст `as unknown as Record<string, unknown>[]` и уточнена типизация возвращаемых данных в `getAvailableUsers`.

### Блокер 3: `project-expanded.tsx` — implicit `any`
- **Проблема:** Обращение к `WORK_STREAM_LABELS` по ключу `WorkStream` выдавало ошибку TS7053 из-за неполной типизации констант.
- **Исправление:** Объект `WORK_STREAM_LABELS` явно типизирован как `Record<WorkStream, string>` в файле констант.

### Блокер 4: Ошибки Vitest в `phase0-schema.test.ts`
- **Проблема:** Ошибки доступа к внутренним свойствам Drizzle-колонок через `drizzle-symbol` индексы при проверке FK/PK.
- **Исправление:** Тесты полностью переписаны на использование официальных публичных API Drizzle (таких как `getTableColumns` и проверка свойств конфигурации колонок напрямую).

---

## 🟡 РЕКОМЕНДАЦИИ И ЗАМЕЧАНИЯ (Запланировано к Фазе 1)

### Рекомендация 1: Добавление `warranty_period_months`
- **Суть:** Для полноценной работы Subcontractor Ledger в Фазе 1 необходим автоматический расчёт даты возврата гарантийного удержания (WARRANTY_RELEASE).
- **Решение:** В Фазе 1 добавить поле `warrantyPeriodMonths: integer("warranty_period_months")` в схему `contracts`.

### Рекомендация 2: Контакты подрядчиков (`phone`, `email`)
- **Суть:** По ADR-20 контрагенты должны содержать контактную информацию для отправки уведомлений и счетов.
- **Решение:** Добавить соответствующие колонки в таблицу `contractors` в начале Фазы 1.

### Рекомендация 3: Вынос констант контрактов
- **Суть:** В `advance-status-sheet.tsx` и `contract-row.tsx` дублировались маппинги статусов.
- **Решение:** Создать `contracts/constants.ts` и импортировать статусы оттуда (по аналогии с проектами).

### Рекомендация 4: FK для `project_bank_accounts`
- **Суть:** В таблице `project_bank_accounts` поле `bank_account_id` не связано внешним ключом с `bank_accounts`. Это необходимо исправить к Фазе 4 (L2-FIN).

---

## ✅ ЧТО ВЫПОЛНЕНО НА ВЫСШЕМ УРОВНЕ

1. **AccordionGrid:** Интерактивное сворачивание/разворачивание строк для проектов и контрактов реализовано строго по ADR-07.
2. **Интерфейс на Sheet:** Отсутствуют модальные окна (modals) для создания/редактирования, вместо них используются выдвижные панели (Sheet) согласно гайдлайну AGENTS.md.
3. **Esc-кнопка:** Все выдвижные компоненты используют хук `useSheetEsc(open, onClose)` для поддержки закрытия кнопкой Escape.
4. **Стилизация:** 100% отсутствие хардкода цветов, цвета завязаны на CSS переменные из `globals.css` (согласно DESIGN.md).
5. **Форматирование:** Суммы выводятся через `formatCurrency('ru-KZ', 'KZT')`, даты — через `formatDate('ru-KZ')`.
