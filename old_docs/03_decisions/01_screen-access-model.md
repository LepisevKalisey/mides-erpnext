# ADR-01: Модель доступа к экранам

**Статус:** Accepted  
**Дата:** 2026-05-04  
**Автор:** Архитектор системы

---

## Контекст

MidesCloud — корпоративная система управления строительными процессами. В системе несколько функциональных ролей (позиций), каждая из которых работает с определённым набором экранов. Требования:

- Один сотрудник может временно взять на себя задачи другого отдела
- Доступ к экранам настраивается только Администратором
- Экран — это страница целиком (не отдельное действие)
- Экраны привязаны к процессам, а не к отделам. Экран может быть передан в другой отдел

## Решение

Использовать **Permission-Based Access Control** с управлением через БД.

### Структура таблиц

```sql
-- Реестр всех экранов системы
screens (
  key         TEXT PRIMARY KEY,     -- 'treasury.workday', 'contracts.list'
  label       TEXT NOT NULL,        -- 'Рабочий день (Казначей)'
  department  TEXT,                 -- 'Финансы'
  path        TEXT NOT NULL         -- '/treasury?tab=workday'
)

-- Какая роль/позиция имеет доступ к какому экрану
screen_access (
  role        TEXT NOT NULL,        -- 'TREASURER', 'ADMIN'
  screen_key  TEXT NOT NULL REFERENCES screens(key),
  PRIMARY KEY (role, screen_key)
)
```

### Принцип работы

1. При загрузке страницы сервер проверяет: есть ли у текущего пользователя роль, у которой есть доступ к данному `screen_key`
2. Сайдбар строится динамически из записей `screen_access` для ролей текущего пользователя
3. Администратор управляет `screen_access` через UI (`/admin/screens`)

### Хелпер

```ts
async function requireScreen(screenKey: string): Promise<void> {
  const roles = await getUserRoles()
  const allowed = await db.select().from(screenAccess)
    .where(inArray(screenAccess.role, roles))
  if (!allowed.some(a => a.screenKey === screenKey)) redirect('/dashboard')
}
```

## Альтернативы

| Вариант | Плюсы | Минусы | Решение |
|---|---|---|---|
| Hardcoded в коде | Просто | Изменение = деплой | ❌ Отклонено |
| RBAC (роль → страница) | Знакомо | Жёсткая связь | ❌ Отклонено |
| **Permission-Based (БД)** | Гибко, UI-управляемо | +2 таблицы | ✅ Принято |

## Последствия

- Добавляется миграция: таблицы `screens` и `screen_access`
- Каждый новый экран должен быть зарегистрирован в `screens`
- Сайдбар становится данными, а не кодом
- Спринт по admin/screens: UI для управления правами

## Связанные документы

- [docs/03_decisions/02_department-navigation.md](02_department-navigation.md)
- [docs/03_decisions/03_role-as-position.md](03_role-as-position.md)
