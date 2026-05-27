# ADR-07: Жизненный цикл контрагента и пороговый триггер договора

**Статус:** Принято (v2 — финальные решения)
**Дата:** 2026-05-05
**Авторы:** Product + Engineering

---

## Контекст

Любой сотрудник компании может вступить во внешнее взаимодействие с контрагентом — закупить материалы, оплатить услугу, привлечь субподрядчика. Нужна модель, которая не создаёт бюрократического трения при первой операции, но обеспечивает юридический и документальный контроль по мере роста оборотов.

---

## Решения

### 1. Кто создаёт контрагентов

**Решение:** Любой аутентифицированный сотрудник.

**Отменено:** флаг `worksWithContractors` больше не используется как условие доступа.
Оставляется в схеме для обратной совместимости, но раздел `/contractors`
доступен всем ролям без проверки флага.

---

### 2. Категория контрагента

**Решение:** Два типа — `SUBCONTRACTOR` / `SUPPLIER`.

| Категория | Описание | Типичные операции |
|-----------|----------|-------------------|
| `SUBCONTRACTOR` | Выполняет работы по договору подряда | Заявка → Платёж → АВР (закрывающий) |
| `SUPPLIER` | Поставляет товары или услуги | Заявка → Платёж → Счёт-фактура / Накладная (закрывающий) |

Поле обязательно при создании. Влияет на то, какой тип закрывающих документов ожидается.

---

### 3. Ответственность за контрагента

- Инициатор (создатель записи) автоматически добавляется в `contractorManagers`
- Казначей / Администратор могут добавлять дополнительных ответственных
- Все ответственные видят полную карточку с историей

---

### 4. Пороговый триггер для Юриста — 7-дневный дедлайн

**Правило:** Когда **фактические платежи** (`SUM(payments.amount)`) по контрагенту
впервые превышают **1 000 000 ₸**, система:
1. Записывает событие в `contractor_contract_deadlines`
2. Устанавливает дедлайн: `due_at = triggered_at + 7 дней`
3. Контрагент появляется в списке Юриста с обратным отсчётом

**Почему payments, а не requests:**
Заявки могут быть отменены — порог отражает реальный финансовый оборот.
Договор нужен для отчётности, и на его оформление даётся 7 дней с момента
превышения порога по факту.

**Ключевое ограничение:** отсутствие договора **НЕ блокирует** никакие операции.
Это advisory workflow, не approval gate.

**Закрытие задачи:** Юрист прикрепляет подписанный PDF к контрагенту →
`contractor_contract_deadlines.status = 'RESOLVED'`.

---

### 5. Обязательство по закрывающим документам

**Правило:** каждый фактический платёж создаёт у ответственного сотрудника
обязательство получить закрывающие документы от контрагента на общую сумму оплат.

**Закрывающие документы по типу контрагента:**
- `SUBCONTRACTOR` → АВР (Акт выполненных работ) — уже есть таблица `avr`
- `SUPPLIER` → Счёт-фактура, Накладная, Акт приёма-передачи

**Вычисление обязательства (computed, без отдельной таблицы):**
```
Обязательство = SUM(payments.amount) - SUM(закрывающих документов)
```
- Для SUBCONTRACTOR: `SUM(payments) - SUM(avr.amount)` по `contractorId`
- Для SUPPLIER: `SUM(payments) - SUM(supplier_docs.amount)` → нужна таблица `supplier_docs`

Если `обязательство > 0` → у ответственного в карточке контрагента и на главной
появляется индикатор «Ожидаются документы на N ₸».

---

### 6. Карточка контрагента — два уровня

| Уровень | Где | Содержимое |
|---------|-----|------------|
| **Quick Panel** (правый сайдбар) | С любой страницы где есть имя контрагента | Баланс, обязательство по документам, последние 3 операции, ответственные |
| **Full Card** `/contractors/[id]` | Отдельная страница | Полная история: заявки, платежи, договоры, АВР, юрлица, документы |

---

## Схема данных — изменения

### 2.1 Расширение таблицы `contractors`

```sql
-- Новые enum-ы
CREATE TYPE mc.contractor_category AS ENUM ('SUBCONTRACTOR', 'SUPPLIER');
CREATE TYPE mc.contractor_status   AS ENUM ('ACTIVE', 'INACTIVE');

-- Новые поля
ALTER TABLE mc.contractors
  ADD COLUMN category      mc.contractor_category NOT NULL DEFAULT 'SUPPLIER',
  ADD COLUMN initiator_id  text REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN status        mc.contractor_status   NOT NULL DEFAULT 'ACTIVE';
```

### 2.2 Новая таблица: `contractor_contract_deadlines`

Отслеживает момент пересечения порога и 7-дневный дедлайн.

```sql
CREATE TABLE mc.contractor_contract_deadlines (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  contractor_id  uuid NOT NULL REFERENCES mc.contractors(id) ON DELETE CASCADE,
  triggered_at   timestamptz NOT NULL DEFAULT now(),
  due_at         timestamptz NOT NULL,  -- triggered_at + 7 days
  total_paid     numeric(15,2) NOT NULL, -- сумма на момент триггера
  status         text NOT NULL DEFAULT 'PENDING',  -- PENDING | RESOLVED
  resolved_at    timestamptz,
  resolved_by_id text REFERENCES auth.users(id) ON DELETE SET NULL,
  UNIQUE(contractor_id)  -- один активный дедлайн на контрагента
);
```

**Логика триггера:**
- При каждом новом платеже вызывается server action `checkContractDeadline(contractorId)`
- Если `SUM(payments) > 1_000_000` И записи в `contractor_contract_deadlines` нет → INSERT
- Если запись уже есть (status=RESOLVED) и новые платежи снова превысили порог → новая запись

### 2.3 Новая таблица: `supplier_docs`

Закрывающие документы для поставщиков (у субподрядчиков роль закрывающего = АВР).

```sql
CREATE TABLE mc.supplier_docs (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  contractor_id  uuid NOT NULL REFERENCES mc.contractors(id),
  payment_id     uuid REFERENCES mc.payments(id),
  doc_type       text NOT NULL,  -- 'INVOICE' | 'WAYBILL' | 'ACT'
  amount         numeric(15,2) NOT NULL,
  doc_number     text,
  doc_date       date,
  file_url       text,           -- S3 via Supabase Storage
  uploaded_by_id text REFERENCES auth.users(id),
  created_at     timestamptz NOT NULL DEFAULT now()
);
```

### 2.4 Файловое хранилище

- PDF договоров и закрывающих документов → **Supabase Storage + S3**
- Поле `file_url` хранит публичный / presigned URL
- Upload через Supabase Storage SDK на клиенте, URL сохраняется в БД

### 2.5 Глобальный UI-стейт

- **Zustand** для `contractorPanelStore` — управляет открытием Quick Panel
- Store: `{ isOpen: boolean, contractorId: string | null, open(id), close() }`

---

## Итоговая карта домена

```
contractors
  ├── category: SUBCONTRACTOR | SUPPLIER
  ├── initiatorId → contractorManagers (auto)
  ├── status: ACTIVE | INACTIVE
  │
  ├── contractorEntities (юрлица)
  ├── contractorManagers (ответственные)
  ├── contractorContractDeadlines (7-дневные дедлайны → Юрист)
  │
  ├── contracts (договоры с fileUrl)
  ├── requests → payments
  │                 └── checkContractDeadline() при каждом платеже
  │
  ├── avr (закрывающие для SUBCONTRACTOR)
  └── supplier_docs (закрывающие для SUPPLIER)
```

---

## Алгоритм вычисления обязательства сотрудника

```typescript
// На карточке контрагента и в Quick Panel:
const obligation = await computeDocObligation(contractorId)

// Для SUBCONTRACTOR:
obligation = SUM(payments.amount) - SUM(avr.amount)

// Для SUPPLIER:
obligation = SUM(payments.amount) - SUM(supplier_docs.amount)

// Если obligation > 0:
// → показываем индикатор «Ожидаются документы на {obligation} ₸»
// → ответственный должен получить и загрузить документы от контрагента
```

---

## Альтернативы, которые отклонили

| Альтернатива | Почему отклонили |
|--------------|-----------------|
| Порог по requests | Заявки могут быть отменены; договор нужен для отчётности реального оборота |
| Computed view без таблицы для дедлайна | Нельзя знать когда именно был первый раз пересечён порог — нет точки отсчёта 7 дней |
| Блокировка платежа при отсутствии договора | Создаёт операционный тупик |
| Redux / React Context вместо Zustand | Zustand проще, уже принято командой |

---

## Последствия

1. **1 миграция БД:** 2 новых enum + 3 поля в `contractors` + 2 новых таблицы
2. **1 server action:** `checkContractDeadline()` вызывается при каждом платеже
3. **Zustand store:** первый глобальный UI-стейт в проекте
4. **S3 upload:** нужна настройка Supabase Storage bucket
5. Порог 1 000 000 — хардкод на первом этапе, конфигурируемый в будущем

---

## Связанные документы

- `docs/03_decisions/04_contractor-hierarchy.md`
- `docs/03_decisions/05_dashboard-workday-contractor-manager.md`
- `docs/04_architecture/02_contractor-domain-map.md` (создать)
