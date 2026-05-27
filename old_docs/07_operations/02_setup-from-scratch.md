# Настройка проекта с нуля

**Тип:** How-to (task-oriented instructions)
**Дата:** 2026-05-17

---

## Предусловия

- Node.js 20+ (см. `.nvmrc`)
- npm 10+
- Git
- Supabase аккаунт (или self-hosted Supabase)

---

## Шаг 1: Клонировать репозиторий

```bash
git clone https://github.com/LepisevKalisey/MidesCloudv3.git
cd MidesCloudv3
```

---

## Шаг 2: Установить зависимости

```bash
cd web
npm ci
```

> `npm ci` использует `package-lock.json` для детерминированной установки.

---

## Шаг 3: Создать Supabase проект

1. Зайти на https://supabase.com/dashboard
2. **New project** → регион `eu-central-1` (или ближайший)
3. Записать:
   - **Project URL** (формат: `https://XXXXX.supabase.co`)
   - **anon key** (из Settings → API)
   - **Database password** (задаётся при создании)
   - **Connection string** (из Settings → Database → URI, формат: `postgresql://postgres.XXXXX:PASSWORD@aws-0-REGION.pooler.supabase.com:6543/postgres`)

---

## Шаг 4: Настроить переменные окружения

```bash
cp .env.example .env.local
```

Заполнить `.env.local`:

```env
DATABASE_URL=postgresql://postgres.XXXXX:PASSWORD@aws-0-REGION.pooler.supabase.com:6543/postgres
NEXT_PUBLIC_SUPABASE_URL=https://XXXXX.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGci...ваш_anon_key
```

---

## Шаг 5: Применить схему БД и миграции

```bash
npm run db:migrate
```

Эта команда:
- Создаст все таблицы из `web/src/db/schema/`
- Настроит триггер автоматического создания профиля в Supabase (`handle_new_user`)
- Зафиксирует все текущие `.sql` миграции

---

## Шаг 6: Настроить GitHub Secrets (Для CI/CD)

Перед пушем в репозиторий, добавьте следующие секреты в **Settings → Secrets and variables → Actions**:

- `PROD_DATABASE_URL`: строка подключения к продакшен базе с пулером
- `COOLIFY_WEBHOOK_URL`: вебхук деплоя из Coolify
- `CI_JWT_SECRET`: любая строка для моковой авторизации в CI

---

## Шаг 7: Создать первого пользователя

Вы можете создать пользователя:
1. Через UI приложения по адресу `http://localhost:3000/register` (если включена открытая регистрация)
2. Или вручную через Supabase Dashboard → Authentication → Users → **Add User**.

Затем назначить роль DIRECTOR через SQL Editor:

```sql
INSERT INTO public.user_roles (user_id, role)
SELECT id, 'DIRECTOR' FROM public.profiles
WHERE email = 'ваш@email.com';
```

---

## Шаг 8: Засеять тестовые данные

```bash
npm run db:seed
```

Скрипт `scripts/seed.ts` создаст юрлица, банковские счета, проекты, объекты, подрядчиков и коды затрат.

---

## Шаг 9: Проверить контекст

```bash
npm run context:check
```

Должен выдать `PASSED` (возможно с warnings). Если FAILED — исправить указанные проблемы.

---

## Шаг 10: Запустить dev-сервер

```bash
npm run dev
```

Открыть http://localhost:3000, войти созданным пользователем.

---

## Проверка работоспособности

| Проверка | Ожидание |
|---|---|
| http://localhost:3000 | Редирект на /login или /dashboard |
| Вход по email/password | Dashboard загружается |
| Список юрлиц | Данные из seed видны |
| `npm run lint` | 0 ошибок |
| `npm run test` | Все тесты проходят |
| `npm run context:check` | PASSED |

---

## Связанные документы

- See: `web/.env.example` — шаблон переменных окружения
- See: `docs/04_architecture/01_system-overview.md` — архитектура
- See: `docs/08_reference/03_project-context.md` — контекст проекта
