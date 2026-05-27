# ADR-38: Архитектура «Тонкий якорь + задачи ролей» (Task-per-Role)

**Статус:** Утверждён  
**Дата:** 2026-05-15  
**Участники:** Директор, Архитектор  
**Связан с:** ADR-36 (реестр → реестр расходов), ADR-11 (dual-path P2P)

---

## Контекст

В процессе разработки M1 (P2P) таблица `purchase_items` превратилась в God Table:
- Поля снабженца, казначея, бухгалтера, ПТО — всё в одной таблице
- Каждая новая фича = новое поле
- Статистика по ролям — костыли
- Переназначение задач между снабженцами — каша из полей
- Потеря контекста между сессиями разработки приводила к добавлению полей,
  которые потом не используются

Это классический anti-pattern ERP-разработки: одна таблица пытается быть
потребностью, рабочей очередью, платёжным поручением, карточкой бухгалтера
и карточкой ПТО одновременно.

## Решение

### Паттерн: Document-Flow + Task Queue

Вдохновлено: SAP (PR→PO→GR→IV→Payment), Procore (Commitment→Invoice→Payment),
Saga Pattern из DDD/BPM.

**Принцип:** Core entity = лёгкий якорь. Каждая роль работает в своей таблице задач.
Статус якоря — вычисляемый из состояния дочерних задач.

### Два якоря

| Якорь | Сторона | Что хранит |
|-------|---------|-----------|
| `purchase_items` | COST (расходы) | Потребность: что нужно купить/оплатить |
| `contract_items` | REVENUE (доходы) | Строка ВОР: что мы продаём заказчику |
| **Мост:** | `cost_code_id` | На обоих якорях. Маржа = VIEW |

### Задачи ролей (Cost side)

```
purchase_items (ЯКОРЬ — минимум полей)
  │
  ├── sourcing_tasks         Снабженец: поиск, КП, сравнение, выбор
  │     └── sourcing_results   Артефакт: таблица КП, обоснование выбора
  │
  ├── approval_tasks         Утверждение: GI → PM → Director
  │
  ├── payment_tasks          Казначей: привязка к payments, выбор счёта
  │
  ├── doc_collection_tasks   Сбор документов после оплаты
  │
  ├── accounting_tasks       Бухгалтерия: ЭСФ, сверка, проводка в 1С
  │
  └── pto_tasks              ПТО: маппинг на ВОР, Discrepancy Review
```

### Задачи ролей (Revenue side)

```
contract_items (ЯКОРЬ — строки ВОР)
  │
  ├── progress_claim_tasks   Менеджер: формирование КС-2 за период
  │
  ├── client_invoicing_tasks Бухгалтерия: выставление счёта заказчику
  │
  ├── client_payment_tasks   Казначей: контроль входящей оплаты
  │
  └── variation_tasks        ПТО: плюс-минус, пересмотр объёмов
```

### current_stage — ВЫЧИСЛЯЕМЫЙ (VIEW)

```sql
-- Не хранится. Определяется из состояния дочерних задач.
purchase_items.current_stage = CASE
  WHEN NOT EXISTS(sourcing_task)            → 'DRAFT'
  WHEN sourcing_task.status IN ('OPEN','IN_PROGRESS') → 'SOURCING'
  WHEN approval_task.status = 'PENDING'     → 'APPROVAL'
  WHEN approval_task.status = 'APPROVED'
   AND payment_task.status = 'PENDING'      → 'APPROVED'
  WHEN payment_task.status = 'PAID'
   AND doc_task.status = 'PENDING'          → 'DOCS_PENDING'
  WHEN doc_task.status = 'SUBMITTED'        → 'DOCS_REVIEW'
  WHEN accounting_task.status = 'POSTED'    → 'POSTED'
  WHEN ALL tasks COMPLETED                  → 'CLOSED'
END
```

### Оркестрация — ОДИН Edge Function

```
advance_workflow(purchase_item_id, completed_task_type)
  CASE 'sourcing_completed'   → INSERT approval_task
  CASE 'approval_approved'    → INSERT payment_task
  CASE 'payment_paid'         → INSERT doc_collection_task
  CASE 'docs_accepted'        → INSERT accounting_task
  CASE 'accounting_posted'    → UPDATE purchase_item stage cache
```

**Правило:** ВСЯ логика «что происходит дальше» — в ОДНОМ месте.
Никаких каскадных триггеров.

### Распределение ответственности

```
Postgres:
  ├── Таблицы, FK, CHECK constraints (целостность)
  ├── Views (current_stage, маржа, баланс)
  └── pg_cron (SLA-мониторинг)

Edge Functions:
  ├── advance_workflow()     — ЕДИНЫЙ оркестратор переходов
  ├── create_transfer()      — авто-создание purchase_items при intercompany
  ├── ocr_process()          — OCR + Discrepancy Review
  └── notify()               — уведомления

Next.js (Server Actions):
  ├── UI-логика (формы, валидация)
  ├── Аутентификация, сессии
  └── SSR/RSC рендеринг
```

## Альтернативы

| Альтернатива | Почему отклонена |
|-------------|-----------------|
| Оставить God Table | Рост сложности экспоненциальный. Каждая фича — новое поле. Потеря контекста = мусор в схеме |
| Microservices per role | Overkill для текущего масштаба. Supabase + Edge Functions достаточно |
| Event Sourcing | Сложность не оправдана. Task Queue даёт 90% пользы при 10% сложности |
| Триггерная каскадная оркестрация | Логика размазана, невозможно отладить, невозможно понять порядок |

## Последствия

### Положительные
- **Изоляция ролей:** каждая роль = свой модуль, свои данные, своя очередь
- **Устойчивость к потере контекста:** новый разработчик/AI-агент работает с одной task-таблицей
- **Статистика ролей:** тривиальные запросы к task-таблицам
- **Параллельная работа:** ПТО и Бухгалтерия могут работать одновременно
- **Supabase-native:** таблицы, views, Edge Functions — всё стандартное

### Отрицательные
- **Миграция:** текущий код требует рефакторинга (purchase_items худеет, появляются *_tasks)
- **Больше таблиц:** ~12 новых task-таблиц
- **Joins:** запросы с участием нескольких task-таблиц сложнее

### План миграции
1. Создать task-таблицы рядом с purchase_items
2. Начать с `sourcing_tasks` (самая болезненная часть)
3. Перенести UI снабженца на sourcing_tasks
4. Далее: `payment_tasks`, `doc_collection_tasks`, `accounting_tasks`
5. Последний шаг: убрать из purchase_items лишние поля, current_stage → VIEW
