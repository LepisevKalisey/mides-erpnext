# ADR-31: Оргструктура компании

> [!WARNING]
> **СТАТУС: ЧАСТИЧНО УСТАРЕЛО / SUPERSEDED**
> Принятая в Фазе 2 структура была пересмотрена при запуске v3:
> - Схема находится в файле [employees.ts](file:///c:/Projects/Mides/MidesCloud%20v3/web/src/db/schema/employees.ts) (вместо `core.ts`).
> - Junction-таблица `staff_assignments` отсутствует. Связь должностей и отделов с сотрудником реализована напрямую через поля `positionId` и `departmentId` в таблице `employees`.
> - Соответственно, совместительство в текущей версии схемы не поддерживается (один сотрудник имеет ровно одну должность и один отдел).

**Статус:** Частично устарело (Superseded) — упрощено в v3  
**Дата:** 2026-05-11

## Контекст

В системе существовали два изолированных слоя управления сотрудниками:
1. `user_roles` — глобальный RBAC (что можно делать в системе)
2. `project_assignments` — матричная команда проекта

Отсутствовал административный слой: в каком отделе работает сотрудник и какую должность занимает.

## Решение

Добавлены три таблицы: `departments`, `positions`, `staff_assignments`.

### Зафиксированные решения

| Вопрос | Решение |
|--------|---------|
| История назначений | Не ведётся. Только текущее состояние. |
| Авто-выдача ролей | При назначении на должность → автоматически выдаётся `user_roles.role = position.default_role`. При снятии → роль отзывается (если нет других должностей с той же ролью). |
| Совместительство | Разрешено. Один сотрудник может занимать несколько должностей. Каждая должность = отдельная роль. |

## Модель данных

```
departments
  id, name, code, sort_order

positions
  id, department_id → departments, title, default_role (roleEnum), sort_order

staff_assignments
  id, user_id → user, position_id → positions, assigned_at, assigned_by_id
  UNIQUE(user_id, position_id)
```

## Связь трёх слоёв

```
Оргструктура              →   user_roles          →   project_assignments
Кто я в компании?             Что мне доступно?        Что я делаю на проекте?
«Снабженец, отдел Снабжение»  role = BUYER             BUYER на MIRAS-2025
```

## Последствия

- Admin больше не управляет ролями вручную: достаточно назначить сотрудника на должность
- Пикер сотрудников в `AddAssignmentSheet` будет обогащён отделом/должностью (следующая фаза)
- Раздел «Оргструктура» доступен ADMIN, DIRECTOR, DEPUTY_DIRECTOR

## Ссылки

- `web/src/db/schema/core.ts` — таблицы `departments`, `positions`, `staffAssignments`
- `web/src/app/(main)/admin/org-structure/_actions.ts` — server actions
- `web/src/app/(main)/admin/org-structure/page.tsx` — страница
