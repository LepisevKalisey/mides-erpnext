# Docker Architecture — MiDES ERPNext

## Принцип

Один Docker-образ содержит **весь код и скомпилированные assets**.
Все контейнеры используют один и тот же образ — разница только в `command`.

## Схема

```
┌─────────────── Docker Image ──────────────────┐
│  bench build → /home/frappe/.../assets/       │
│  apps/ (frappe, erpnext, hrms, ...)          │
│  env/ (python venv)                           │
└───────────────────────────────────────────────┘
        ↓ один образ → все контейнеры

┌── configurator ──┐  ┌── create-site ────────┐
│ apps.txt          │  │ bench new-site        │
│ common_site_config│  │ GRANT user@'%'        │
│ assets → symlink  │  │ migrate + install-app │
└───────────────────┘  └───────────────────────┘
         ↘                   ↙
    ┌── Shared Volume (sites) ──┐
    │ assets → /home/../assets  │  ← symlink, НЕ копия
    │ frontend/site_config.json │
    │ common_site_config.json   │
    │ apps.txt                  │
    └───────────────────────────┘
         ↗        ↑        ↖
  ┌─────────┐ ┌───────┐ ┌───────────┐
  │ backend │ │ nginx │ │ scheduler │ ...workers
  │ gunicorn│ │ :8080 │ │ bench sched│
  └─────────┘ └───────┘ └───────────┘
```

## Контейнеры

| Контейнер | Тип | Что делает |
|-----------|-----|-----------|
| configurator | init (одноразовый) | Пишет config, создаёт symlink assets |
| create-site | init (одноразовый) | Создаёт сайт, GRANT, migrate, install-app |
| backend | runtime | Gunicorn — обрабатывает API запросы |
| frontend | runtime | Nginx — проксирует к backend, отдаёт assets |
| websocket | runtime | Socket.IO для realtime |
| scheduler | runtime | Фоновые задачи по расписанию |
| queue-short | runtime | Быстрые фоновые задачи |
| queue-long | runtime | Длительные фоновые задачи |
| db | data | MariaDB 11.8 |
| redis-cache | data | Кеш |
| redis-queue | data | Очередь задач |

## Volumes

| Volume | Что хранит | Критичность |
|--------|-----------|-------------|
| `db-data` | Данные MariaDB | **КРИТИЧНО** — вся БД |
| `sites` | site_config, assets symlink | Пересоздаётся автоматически |
| `logs` | Логи приложений | Не критично |

## Почему symlink, а не копия assets

- **Все контейнеры = один образ** → путь `/home/frappe/frappe-bench/assets/` существует в каждом
- Symlink `sites/assets → /home/.../assets` резолвится в каждом контейнере одинаково
- Копирование 200+ МБ assets при каждом старте — бессмысленная трата времени
- При обновлении образа assets обновляются автоматически

## Деплой с нуля

1. Создать Docker Compose сервис в Coolify
2. Указать repo + docker-compose.coolify.yml
3. Coolify создаёт volumes автоматически
4. configurator → config + symlink
5. create-site → новый сайт + все приложения
6. backend/frontend/... стартуют и подключаются

## Обновление

1. Push в develop → GitHub Actions собирает новый образ
2. Coolify webhook → pull нового образа
3. Coolify перезапускает контейнеры
4. create-site видит что сайт существует → только migrate + install-app новых
