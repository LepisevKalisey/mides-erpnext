# ADR-018: Динамическая матрица полномочий на утверждение

> [!NOTE]
> **УТОЧНЕНИЕ ИМЕН ТАБЛИЦ ДЛЯ ВЕРСИИ V3**
> При реализации этой матрицы в БД версии v3 следует использовать актуальные названия таблиц проекта:
> - Вместо таблицы `user` (или `auth.users`) связывать с таблицей `profiles` (`profiles.id` имеет тип `uuid`).
> - Вместо таблицы `objects` связывать с таблицей `project_objects` (объекты проекта).

**Status:** Accepted  
**Date:** 2026-05-07  
**Заменяет:** хардкод `approval_threshold_*` в таблице `procurement_settings`

## Context

Ранее пороги утверждения хранились как константы в `procurement_settings`:
- `approval_threshold_deputy` = 1 000 000 ₸
- `approval_threshold_director` = 5 000 000 ₸

Это решение не позволяло:
- Назначать разные лимиты разным заместителям
- Ограничивать полномочия по конкретному объекту
- Изменять полномочия без изменения кода

Реальная практика: директор 2 раза в неделю утверждает весь реестр, потому что нет инструмента делегирования. У нескольких замов есть фактическая возможность утверждать заявки до определённой суммы, но система этого не поддерживает.

## Decision

### Таблица `approval_matrix`

```sql
CREATE TABLE approval_matrix (
  id          UUID PRIMARY KEY,
  user_id     TEXT NOT NULL REFERENCES user(id),   -- конкретный зам
  max_amount  NUMERIC NOT NULL,                     -- лимит утверждения
  object_id   UUID REFERENCES objects(id),         -- null = все объекты
  item_type   purchase_item_type,                  -- null = все типы
  is_active   BOOLEAN DEFAULT true,
  granted_by  TEXT REFERENCES user(id),            -- кто выдал право
  granted_at  TIMESTAMPTZ DEFAULT now()
);
```

### Правила системы

1. **Директор** — видит и может утверждать все заявки без ограничений. Его список всегда полный, сгруппированный по статусу.

2. **Зам** — видит и может утверждать заявки, для которых выполнены условия:
   - `request.amount <= approval_matrix.max_amount`
   - `approval_matrix.object_id IS NULL` ИЛИ `request.object_id = approval_matrix.object_id`
   - `approval_matrix.item_type IS NULL` ИЛИ `request.item_type = approval_matrix.item_type`
   - `approval_matrix.is_active = true`

3. **Алгоритм роутинга на утверждение:**
   ```
   Есть активная запись в approval_matrix для этого пользователя + сумма + объект?
     ДА → зам может утвердить
     НЕТ → только директор
   ```

4. **Директор всегда видит утверждённые замом заявки** — в своём реестре они помечены «Утверждено [имя зама]».

### Управление через настройки

Директор (или ADMIN) через страницу настроек:
- Выдаёт право утверждения конкретному пользователю
- Устанавливает лимит суммы
- Опционально ограничивает по объекту или типу позиции
- Деактивирует (`is_active = false`) без удаления истории

### Сценарий использования

```
Зам по строительству: лимит 2 000 000 ₸, объект = ЖК Мирас
Зам по снабжению:     лимит 500 000 ₸, все объекты, тип = MATERIALS
Финансовый директор:  лимит 10 000 000 ₸, все объекты

Заявка 300 000 ₸, материалы, ЖК Мирас:
  → могут утвердить: зам по строительству, зам по снабжению, финдиректор, директор

Заявка 3 000 000 ₸, услуги, ЖК Парк:
  → может утвердить: финдиректор, директор
```

## Alternatives Considered

- **Хардкод в settings** → гибкость ноль, удалено
- **Role-based без лимитов** → DEPUTY роль одна, нельзя дифференцировать
- **Approval workflow (chain)** → последовательное согласование → избыточно для текущего масштаба

## Consequences

- **+** Директор разгружен от микро-согласований
- **+** Полномочия настраиваются без изменения кода
- **+** Ограничение по объекту позволяет дать полномочия прорабу только по его объекту
- **+** Директор всегда в курсе — видит всё, включая утверждённое замами
- **−** Требует первоначального заполнения матрицы при запуске системы

## Related

- See: `docs/03_decisions/11_dual-path-p2p-workflow.md`
- See: `docs/03_decisions/12_purchase-item-lifecycle.md`

---

## Реализация — Слайс [A.2] Ф1

**Дата реализации:** 2026-05-22  
**Миграция:** `0010_massive_mole_man.sql`

### Что реализовано

1. **`createCommitment` (actions.ts)**  
   - Заменён хардкод DIRECTOR на вызов `getApproverForAmount(legalEntityId, amount)`  
   - Если матрица содержит правило с конечным `amount_to >= amount` → `isAutoApprove = true`  
   - Авто-задача: `commitment_approval_tasks.status = APPROVED`, `auto_approved = true`  
   - Вызов `advance_workflow()` сразу — заявка уходит к казначею без участия директора  
   - Уведомление казначею (не директору) при авто-утверждении

2. **`batchApproveCommitments` (actions.ts)**  
   - Принимает `string[]` purchaseItemId  
   - Последовательно вызывает `approveCommitment` для каждой  
   - Возвращает `{ approved, failed, errors }`

3. **Схема `commitment_approval_tasks`**  
   - Новое поле: `auto_approved BOOLEAN DEFAULT false NOT NULL`  
   - Заполняется при создании заявки (не при ручном утверждении)

4. **`ApprovalsGrid.tsx`**  
   - Чекбоксы выбора на каждой строке  
   - «Выбрать все» внизу списка  
   - Панель «Утвердить выбранные» при наличии выбора

5. **`CommitmentsGrid.tsx`**  
   - Бейдж «⚡ авто» рядом со `StatusBadge(APPROVED)` для авто-утверждённых заявок  
   - Семантика: `isAutoApproved(item) = task.status=APPROVED AND task.auto_approved=true`

### Инварианты

- Авто-утверждение **только при наличии** активного правила с конечным `amount_to`  
- Если матрица пустая или нет подходящего правила → fallback DIRECTOR (PENDING)  
- `auto_approved` — иммутабельный флаг: ставится только в `createCommitment`, не в `approveCommitment`
