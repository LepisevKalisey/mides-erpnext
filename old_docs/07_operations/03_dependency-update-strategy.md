# Стратегия обновления зависимостей

**Тип:** How-to (task-oriented instructions)
**Дата:** 2026-05-17
**Статус:** Active

---

## Принцип

Зависимости — это долг. Чем дольше не обновляешь, тем дороже обновление. Стратегия: **маленькие частые обновления вместо больших редких**.

---

## Автоматика (Dependabot)

Настроен в `.github/dependabot.yml`:
- **Частота:** Еженедельно (понедельник)
- **Target branch:** `dev` (НЕ main)
- **Лимит:** 5 PR одновременно
- **Группировка:** next-ecosystem, supabase, testing, drizzle
- **Блокировка:** Major-версии Next.js, Drizzle, React требуют ADR

---

## Ручной процесс (ежеквартальный)

Каждые 3 месяца (январь, апрель, июль, октябрь):

### 1. Аудит

```bash
cd web
npm outdated
```

### 2. Оценка рисков

| Тип обновления | Действие |
|---|---|
| Patch (0.0.x) | Обновить автоматически |
| Minor (0.x.0) | Обновить, запустить `npm run test` |
| Major (x.0.0) | Создать ADR, спланировать миграцию |

### 3. Major-версии — процедура

1. Создать ADR: `docs/03_decisions/NN_upgrade-PACKAGE-vX.md`
2. Прочитать changelog и migration guide
3. Создать ветку `feat/upgrade-PACKAGE-vX`
4. Обновить код, запустить полный CI
5. Merge в `dev` → тестирование → merge в `main`

---

## Критические зависимости (требуют ADR для major bump)

| Пакет | Текущая | Почему критичен |
|---|---|---|
| next | 14.2.35 | App Router API, Server Actions, middleware |
| drizzle-orm | 0.45.2 | Схема, query builder, миграции |
| react | 18.x | Вся UI-логика |
| @supabase/ssr | 0.10.3 | Auth, сессии, middleware |
| tailwindcss | 3.4.1 | Все стили |

---

## Ротация Node.js

| Текущая | Поддержка до | Действие |
|---|---|---|
| Node 20 LTS | Апрель 2026 | Обновить .nvmrc и engines при переходе на 22 |
| Node 22 LTS | Апрель 2027 | Планировать переход в Q3 2026 |

---

## Связанные документы

- See: `.github/dependabot.yml` — автоматические обновления
- See: `web/package.json` — текущие версии
- See: `.nvmrc` — зафиксированная версия Node.js
