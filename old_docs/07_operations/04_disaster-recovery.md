# План восстановления после аварии (Disaster Recovery)

**Тип:** How-to (task-oriented instructions)
**Дата:** 2026-05-17
**Статус:** Active

---

## Сценарии

### Сценарий 1: Supabase Free Tier недоступен / проект удалён

**Риск:** Средний (Free Tier может быть остановлен после 7 дней неактивности)

**Процедура:**
1. Создать новый Supabase проект (см. `docs/07_operations/02_setup-from-scratch.md`)
2. Применить схему: `npx drizzle-kit push`
3. Засеять данные: `npm run db:seed`
4. Обновить `.env.local` с новыми URL и ключами
5. Обновить `docs/08_reference/03_project-context.md` с новым project ref

**Потери данных:** Все production-данные. Seed восстановит тестовые.

**Митигация:**
- Регулярный pg_dump (еженедельно):
  ```bash
  pg_dump "postgresql://..." > backup_$(date +%Y%m%d).sql
  ```
- Хранить бэкапы в отдельном месте (не в Supabase)

### Сценарий 2: GitHub недоступен

**Риск:** Очень низкий

**Процедура:**
1. Код есть локально — продолжить работу
2. Создать зеркало на GitLab / Bitbucket
3. Обновить remote: `git remote set-url origin NEW_URL`

**Митигация:**
- Хотя бы одна локальная копия всегда актуальна
- `git push --mirror` на альтернативный remote (опционально)

### Сценарий 3: Потеря локальной машины

**Риск:** Низкий

**Процедура:**
1. Клонировать из GitHub: `git clone https://github.com/LepisevKalisey/MidesCloudv3.git`
2. Следовать `docs/07_operations/02_setup-from-scratch.md`
3. Восстановить `.env.local` из Supabase Dashboard (Settings → API)

**Потери:** .env.local, .antigravity/brain/ (conversation history). Критический контекст сохранён в `docs/08_reference/03_project-context.md`.

### Сценарий 4: Смена AI-инструмента (Antigravity → другой)

**Риск:** Средний (AI-инструменты быстро развиваются)

**Процедура:**
1. Всё критичное уже в git:
   - `.antigravityrules` → адаптировать под новый инструмент
   - `AGENTS.md` → агностичен к инструменту
   - `docs/` → полностью портативен
2. KI в `.antigravity/knowledge/` — скопировать в формат нового инструмента
3. Memory graph — уже экспортирован в `docs/08_reference/03_project-context.md`

---

## Бэкап-чеклист (еженедельный)

- [ ] `git push` на GitHub выполнен
- [ ] Supabase проект активен (не paused)
- [ ] `.env.local` значения записаны в безопасном месте

---

## Связанные документы

- See: `docs/07_operations/02_setup-from-scratch.md` — полная настройка
- See: `docs/08_reference/03_project-context.md` — контекст проекта
- See: `.github/dependabot.yml` — автообновление зависимостей
