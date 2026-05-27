# ADR-49: Project-Centric UI Navigation (двухуровневая навигация)

**Статус:** Accepted  
**Дата:** 2026-05-23  
**Контекст:** Анализ мировых лидеров строительных ERP (Procore, Autodesk Build, SAP) и gap analysis юзерстори показали необходимость перехода от плоской навигации к project-centric модели.

---

## Контекст

Текущая навигация — плоская:
```
/dashboard/overview
/dashboard/projects
/dashboard/contractors
/dashboard/contracts
/dashboard/requests
/dashboard/payments
```

Проблемы:
1. PM не видит «свой проект как единое целое» — данные разбросаны по страницам
2. Прораб не видит «мои приёмки по моему проекту»
3. ПТО не видит «объёмы по позициям договора в моём проекте»
4. Нет связи: проект → договоры → АВР → платежи → прогресс

## Мировая практика

**Procore, Autodesk Build, Oracle Aconex** используют:

1. **Hub-and-Spoke:** Выбираешь проект → внутри видишь модули
2. **Cross-project views:** Для директора — сводные данные по всем проектам
3. **"My Tasks" pattern:** Каждая роль видит свою очередь задач
4. **Role-based tab visibility:** В одном проекте PM видит одни вкладки, прораб — другие

## Решение

### Двухуровневая навигация

```
УРОВЕНЬ 1: Кросс-проектный (Директор, Казначей, Бухгалтерия)
  /dashboard/overview        ← KPI + финансовые метрики
  /dashboard/requests        ← "Мои задачи" (role-filtered)
  /dashboard/approvals       ← Очередь директора
  /dashboard/payments        ← Казначейский стол
  /dashboard/contractors     ← Все контрагенты + балансы
  /dashboard/contracts       ← Все договоры

УРОВЕНЬ 2: Внутри проекта (PM, Прораб, ПТО)
  /dashboard/projects/:id              ← Project Hub
  /dashboard/projects/:id/team         ← Команда проекта
  /dashboard/projects/:id/contracts    ← Договоры проекта + SOV
  /dashboard/projects/:id/avr          ← АВР по проекту
  /dashboard/projects/:id/progress     ← Прогресс (план vs факт)
  /dashboard/projects/:id/payments     ← Платежи по проекту
```

### Project Hub (детальная страница проекта)

Табы в `/dashboard/projects/:id`:

| Таб | Видимость | Содержание |
|-----|-----------|------------|
| Обзор | Все | KPI проекта, прогресс-бары, последняя активность |
| Команда | PM, Директор | project_assignments, назначение ролей |
| Договоры | PM, Директор | Список договоров + вложенные contract_items |
| АВР | PM, ПТО, Прораб, Бухгалтер | Список АВР с фильтром по статусу |
| Прогресс | PM, ПТО, Директор | Contract items: план vs факт, отклонения |
| Платежи | PM, Директор, Казначей | История платежей, баланс субчика |

### "Мои задачи" — role-filtered tabs на /requests

Вместо отдельных страниц для каждой роли — **табы** на `/dashboard/requests`:

```
/dashboard/requests
  ├── [Мои заявки]       — PM: заявки, которые я создал
  ├── [Физприёмка]       — Прораб: acceptance_tasks (PENDING)
  ├── [Проверка АВР]     — ПТО: avr_tasks (UPLOADED)
  ├── [Утверждение АВР]  — PM: avr_tasks (PTO_VERIFIED)
  ├── [Бухгалтерия]      — Бухгалтер: avr_tasks (PM_APPROVED)
```

Табы показываются/скрываются по роли пользователя. Каждый видит ТОЛЬКО свои табы.

### Sidebar: контекстная навигация

Когда пользователь находится внутри проекта (`/projects/:id/*`):
- Sidebar показывает **проектное меню** (табы проекта)
- Хлебные крошки: Проекты → Школа Мирас → Договоры
- Кнопка «← Все проекты» для возврата

### Dashboard Overview: финансовые KPI

Добавить на `/dashboard/overview`:

| Виджет | Формула | Для кого |
|--------|---------|----------|
| Выполнено работ | SUM(avr_tasks.total_amount WHERE data_status='COMMITTED') | Директор |
| Оплачено | SUM(payment_tasks.amount_paid) | Директор, Казначей |
| Субчики с переплатой | Контрагенты с отрицательным балансом | Директор |
| Ожидают согласования | COUNT(commitment_approval_tasks WHERE status='PENDING') | Директор |
| Ожидают оплаты | COUNT(payment_tasks WHERE status='PENDING') | Казначей |

## Альтернативы

### A. Отдельные страницы для каждой роли
**Отклонено.** Дублирование кода, сложность поддержки. Лидеры ERP используют filtered views.

### B. Оставить плоскую навигацию
**Отклонено.** Не масштабируется. При 10+ проектах PM тонет в данных.

### C. Мобильное приложение отдельно
**Отклонено на текущем этапе.** Responsive web + Quick Actions FAB достаточно для MVP.

## Последствия

1. `/dashboard/projects/:id` становится Project Hub с табами
2. `/dashboard/requests` получает role-filtered табы
3. Sidebar становится контекстным (глобальный vs проектный)
4. Dashboard Overview получает финансовые KPI виджеты
5. Хлебные крошки показывают контекст навигации
6. Закрывает юзерстори: 1.2, 1.3, 1.4, 2.2, 2.3, 4.1, 5.2
