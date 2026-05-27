# MidesCloud ERPNext — Тестовая сборка

## Требования

- Docker Desktop (Windows) с WSL2
- Минимум 8 ГБ RAM, 4 CPU
- 10 ГБ свободного места

## Быстрый старт

### 1. Запуск стека

```powershell
cd c:\Projects\Mides\ERPNext
docker compose up -d
```

Первый запуск займёт 3-5 минут (загрузка образов ~2 ГБ + создание сайта).

### 2. Проверка статуса

```powershell
# Все контейнеры должны быть Running (кроме configurator и create-site — они Exited 0)
docker compose ps

# Следить за созданием сайта:
docker compose logs create-site -f
```

### 3. Вход в систему

- **URL:** http://localhost:8080
- **Login:** Administrator
- **Password:** admin

### 4. Setup Wizard

При первом входе ERPNext покажет Setup Wizard. Заполнить:

| Поле | Значение |
|------|----------|
| Language | Русский |
| Country | Kazakhstan |
| Timezone | Asia/Almaty |
| Company Name | ТОО МиДЭС |
| Company Abbreviation | МИДЭС |
| Currency | KZT |
| Chart of Accounts | Standard |
| Financial Year | January-December |
| Your Name | Директор |

---

## Настройка после Setup Wizard

### Шаг 1: Создать второе юрлицо (ИП)

1. Awesomebar → **Company** → New
2. Заполнить:
   - Company Name: **ИП Калисей**
   - Abbreviation: **ИПК**
   - Default Currency: **KZT**
   - Parent Company: **ТОО МиДЭС**
   - Country: Kazakhstan

### Шаг 2: Создать тестовых пользователей

Awesomebar → **User** → New. Создать пользователей:

| Email | Full Name | Роль | Описание |
|-------|-----------|------|----------|
| director@mides.kz | Директор | System Manager, Projects Manager, Purchase Manager, Accounts Manager | Видит всё |
| pm@mides.kz | Менеджер проекта | Projects User, Projects Manager | Управляет проектами |
| procurement@mides.kz | Снабженец | Purchase User | Закупки |
| foreman@mides.kz | Прораб | Projects User | Заявки с площадки |
| treasurer@mides.kz | Казначей | Accounts User | Оплата |
| pto@mides.kz | Инженер ПТО | Projects User | Документация |
| accountant@mides.kz | Бухгалтер | Accounts User | Проводки |

> **Пароль для всех:** `test1234` (тестовое окружение)

### Шаг 3: Настроить Workflow для Material Request

1. Awesomebar → **Workflow** → New
2. Document Type: **Material Request**
3. States:
   - Draft → Pending Approval → Approved → Rejected
4. Transitions:
   - Draft → Pending Approval (Submit, allowed for: Projects User)
   - Pending Approval → Approved (Approve, allowed for: Projects Manager)
   - Pending Approval → Rejected (Reject, allowed for: Projects Manager)
   - Approved → (auto-transition to Purchase Order)

### Шаг 4: Создать тестовый проект

1. Awesomebar → **Project** → New
2. Заполнить:
   - Project Name: **ЖК Алатау Парк**
   - Company: ТОО МиДЭС
   - Expected Start Date: 01.06.2026
   - Expected End Date: 31.12.2026
   - Status: Open
   - Cost Center: Main - МИДЭС

### Шаг 5: Создать тестовых подрядчиков (Supplier)

1. Awesomebar → **Supplier** → New
2. Создать 2-3 подрядчика:

| Supplier Name | Supplier Group | Country |
|---------------|---------------|---------|
| ТОО СтройМонтаж | Services | Kazakhstan |
| ИП Иванов | Services | Kazakhstan |
| ТОО БетонМикс | Raw Material | Kazakhstan |

### Шаг 6: Создать номенклатуру (Item)

1. Awesomebar → **Item** → New
2. Создать примеры:

| Item Name | Item Group | UOM | Is Stock Item |
|-----------|-----------|-----|---------------|
| Бетон М300 | Raw Material | м³ | Yes |
| Арматура А500 ∅12 | Raw Material | тн | Yes |
| Монтаж металлоконструкций | Services | м² | No |
| Кладка кирпичная | Services | м³ | No |

### Шаг 7: Создать склад для проекта

1. Awesomebar → **Warehouse** → New
2. Warehouse Name: **Склад ЖК Алатау Парк**
3. Company: ТОО МиДЭС

---

## Тестовые сценарии

### Сценарий 1: Закупка материалов (P2P)

```
Прораб создаёт Material Request
  → Директор утверждает
    → Снабженец создаёт Purchase Order
      → Складовщик принимает (Purchase Receipt)
        → Бухгалтер создаёт Purchase Invoice
          → Казначей оплачивает (Payment Entry)
```

**Шаги:**
1. Войти как **foreman@mides.kz**
2. Awesomebar → **Material Request** → New
3. Type: Purchase, Purpose: For project ЖК Алатау Парк
4. Добавить: Бетон М300, 100 м³
5. Submit → Статус меняется на "Pending Approval"
6. Войти как **director@mides.kz**
7. Открыть Material Request → Approve
8. Войти как **procurement@mides.kz**
9. Из Material Request → Create → Purchase Order
10. Выбрать поставщика ТОО БетонМикс, указать цену
11. Submit Purchase Order
12. Create → Purchase Receipt (приёмка на склад)
13. Create → Purchase Invoice (счёт)
14. Войти как **treasurer@mides.kz**
15. Из Purchase Invoice → Create → Payment Entry
16. Submit Payment

### Сценарий 2: Субподряд (упрощённый)

```
PM создаёт Purchase Order (subcontracting)
  → Директор утверждает
    → Казначей оплачивает аванс
      → Прораб подтверждает выполнение
        → Бухгалтер фиксирует
```

**Шаги:**
1. Войти как **pm@mides.kz**
2. Material Request → New → Type: Purchase
3. Добавить: Монтаж металлоконструкций, 500 м²
4. Submit
5. Войти как **director@mides.kz** → Approve
6. Войти как **procurement@mides.kz**
7. Create Purchase Order → Supplier: ТОО СтройМонтаж
8. Submit
9. Войти как **treasurer@mides.kz**
10. Payment Entry (аванс 30%)

### Сценарий 3: Бюджет проекта

1. Войти как **director@mides.kz**
2. Awesomebar → **Budget** → New
3. Budget Against: Project, Project: ЖК Алатау Парк
4. Fiscal Year: 2026
5. Добавить строки бюджета по Cost Centers
6. Проверить: при превышении бюджета система блокирует или предупреждает

### Сценарий 4: Отчёты

1. Войти как **director@mides.kz**
2. Проверить доступные отчёты:
   - **Accounts Payable** — кому должны
   - **Project Billing Summary** — биллинг по проекту
   - **Purchase Analytics** — аналитика закупок
   - **Stock Balance** — остатки на складе
   - **Gross Profit** — маржинальность
   - **Budget Variance** — отклонение от бюджета

---

## Полезные команды

```powershell
# Перезапуск
docker compose restart

# Логи backend
docker compose logs backend -f

# Зайти в контейнер (bench команды)
docker compose exec backend bash

# Из контейнера:
bench --site mides.localhost console
bench --site mides.localhost migrate
bench --site mides.localhost clear-cache
bench --site mides.localhost set-config developer_mode 1

# Остановить всё
docker compose down

# Удалить всё (включая данные!)
docker compose down -v
```

---

## Оценка после тестирования

После прогона сценариев оцените:

| Критерий | Вопрос |
|----------|--------|
| **UI/UX** | Удобно ли работать? Информация доступна без десятков кликов? |
| **P2P** | Цикл закупки проходит полностью? |
| **Субподряд** | Можно ли управлять субподрядчиками? |
| **Отчёты** | Есть ли нужные отчёты? |
| **Multi-Company** | Переключение между ТОО и ИП работает? |
| **Роли** | Разграничение доступа корректное? |
| **Скорость** | Система отзывчива? |
| **Локализация** | Русский язык достаточен? |

Результат → решение: **ERPNext + Custom App** или **возврат к MidesCloud v3**.
