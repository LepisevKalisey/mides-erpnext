# MidesCloud — System Blueprint

**Тип:** Explanation  
**Статус:** Активный  
**Дата:** 2026-05-23  
**Версия:** 2.3  
**Актуально до фазы:** Ф1 (L2-COMMIT Subcontract)  
**Назначение:** Единый документ описания системы — цели, пользователи, модули, потоки, доменная модель, финансовый стержень

---

## 1. Продукт

### 1.1 Что это

MidesCloud — строительная ERP-система управления компанией МиДЭС.

**Эволюция продукта:**

```
Этап 1 (origin)   Платёжный реестр в Google Sheets + GAS-автоматизация
Этап 2 (текущий)   P2P модуль: заявки → снабжение → утверждение → оплата → документы
Этап 3 (next)      Доходная часть: договор заказчика → накопление работ → КС-2/КС-3 → выставление
Этап 4 (planned)   HR-контур: персонал, табелирование, контроль присутствия, начисление ЗП
Этап 5 (vision)    Полная строительная ERP: финконтроль, склад, аналитика, интеграция 1С по API
```

Ядро системы — **конвеерная архитектура** (Bid-to-Cash), где каждый бизнес-процесс
моделируется как вложенный конвеер (L1 → L2 → L3). Финансовые данные являются
**побочным продуктом** операционного потока, а не самоцелью. Оплата — шаг в конкретном
конвеере, а не запись в отдельном реестре.

**Полная карта конвееров:** `docs/02_research/03_value-stream-map.md`

**Бухгалтерский и налоговый учёт** остаётся в 1С. MidesCloud — операционный слой, который
постепенно берёт на себя всё больше функций ERP, оставляя 1С для регламентированной отчётности.

### 1.2 Реальность аналоговой стройки

> Стройка на 50-60% аналоговая. Система должна учитывать это, а не бороться с этим.

**Типичный сценарий (сегодня):**
Прорабу нужен кран на 40 минут. Он звонит знакомому крановщику, тот приезжает,
делает работу. Прораб платит наличными из своего кармана. Потом сообщает руководителю
факт выполнения. Руководитель компенсирует затраты, а казначей постфактум «сажает»
расход в систему, присоединяя к другому подтверждающему документу.

**Что это означает для системы:**
- Не все расходы проходят через полный цикл «заявка → утверждение → оплата»
- Должен существовать путь **постфактум-регистрации** расхода (ретроспективная заявка)
- Система не должна блокировать работу на площадке — она фиксирует реальность
- Со временем доля аналоговых операций снижается по мере роста доверия к системе
- Цель: не 100% цифровизация сразу, а **видимость** 100% расходов (включая ретроспективные)

### 1.3 Цели системы

#### A. Финансовое ядро (ERP-базис)

| # | Цель | Метрика | Фаза |
|---|------|---------|------|
| A1 | Единый реестр всех расходов | Казначей видит ВСЕ утверждённые расходы в одном месте | M1 |
| A2 | Прозрачность денежного потока | Директор знает: сколько должны мы, сколько должны нам | M4 |
| A3 | Cash flow прогнозирование | Прогноз: когда заканчиваются деньги на проекте | M4 |
| A4 | Budget vs Actual по проектам | Бюджет → committed → факт → остаток | M4 |
| A5 | Аудитный след | Каждое действие записано: кто, когда, что, почему | M1 |
| A6 | Выгрузка в 1С | Бухгалтер получает реестры платежей и АВР для проводки | M1 |
| A7 | Ретроспективная регистрация | Постфактум-расходы видны в системе наравне с плановыми | M1 |

#### B. Закупки и снабжение

| # | Цель | Метрика | Фаза |
|---|------|---------|------|
| B1 | Контроль закупочных цен | Каждая закупка проходит через сравнение поставщиков (Sourcing Workspace) | M1 |
| B2 | Скорость обработки заявок | SLA на каждый этап, автоэскалация при нарушении | M1 |
| B3 | Ценовая аналитика | История цен на материалы, сигнал «цена выше среднего на X%» | M1+ |
| B4 | Складской учёт | Поступление, выдача, остатки; расход при выдаче, не при закупке | M6 |
| B5 | Three-Way Match | PR = PO = GRN — автоматическая сверка | M1 |

#### C. Договоры и производство (доходная часть)

| # | Цель | Метрика | Фаза |
|---|------|---------|------|
| C1 | Контроль субподрядчиков | Оплата только после физической приёмки работ | M1 |
| C2 | Автонакопление выполненных работ | АВР → автоматический прогресс по строкам ВОР | M3 |
| C3 | Формирование КС-2/КС-3 заказчику | На основе накопленных АВР — генерация исполнительной документации | M3 |
| C4 | Маржинальность проекта | Revenue (КС-2 заказчику) минус Cost (АВР + закупки) в реальном времени | M3+M4 |
| C5 | Change Orders (допсоглашения) | Фиксация изменений объёмов/стоимости с обновлением бюджета | M2 |
| C6 | Управление гарантийными удержаниями | Retainage: автоматический расчёт и возврат при закрытии | M2 |
| C7 | Субподрядный лицевой счёт | Полная картина по подрядчику: авансы, АВР, долги, гарантии | M2 |

#### D. Персонал и трудовые ресурсы (планируемый контур)

| # | Цель | Метрика | Фаза |
|---|------|---------|------|
| D1 | Реестр персонала | Все сотрудники компании с должностями и проектными назначениями | M0 |
| D2 | Табелирование | Учёт рабочего времени по проектам и объектам | Planned |
| D3 | Контроль присутствия | Факт нахождения на объекте (GPS/QR/ручная отметка) | Planned |
| D4 | Начисление заработной платы | Расчёт ЗП на основе табеля, надбавок, вычетов | Planned |
| D5 | Управление нагрузкой | Руководитель видит загрузку подчинённых по проектам | M1 |

#### E. Специфика строительных рынков с высокой долей изменений

| # | Цель | Метрика | Фаза |
|---|------|---------|------|
| E1 | Терпимость к неточным проектам | Система не ломается при отклонении факта от плана на 30-50% | M1 |
| E2 | Быстрая адаптация к изменениям | Change Order создаётся за минуты, бюджет обновляется автоматически | M2 |
| E3 | Гибкий документооборот | Поддержка неполных пакетов документов (АВР без КС-2, только Р-1) | M1 |
| E4 | Пост-фактум-операции | Регистрация расходов задним числом с полным аудитным следом | M1 |
| E5 | Частичные приёмки | Принял 70 из 100 м2 — оплата только за принятое; остаток накапливается | M1 |
| E6 | Устные договорённости → цифра | Перевод устных договоров с крановщиками/мелкими подрядчиками в систему | M1 |
| E7 | Мобильность на площадке | Критические операции (приёмка, заявка) доступны с телефона | M1 |
| E8 | Дефектная ведомость | Фиксация замечаний с фото до устранения, блокировка оплаты | M1+ |
| E9 | Защита от завышения объёмов | Накопительный учёт: система показывает, сколько уже принято по позиции | M3 |
| E10 | Экономический контроль на лету | Маржа проекта видна в реальном времени, не постфактум через месяц | M3+M4 |

### 1.4 Технологический стек

| Компонент | Технология |
|-----------|-----------|
| Frontend | Next.js 14 (App Router), shadcn/ui, Tailwind CSS v3.4 |
| ORM | Drizzle ORM (PostgreSQL) |
| Auth | Supabase Auth (SSR, multi-role) |
| Database | PostgreSQL (Supabase dev / собственный сервер prod) |
| OCR | Gemini API (flash-lite для документов) |
| Шрифт | Plus Jakarta Sans |
| Иконки | Lucide React |
| Стиль | Trust & Authority (B2B enterprise) |

**Источник:** `docs/03_decisions/09_tech-stack.md`

---

## 2. Пользователи и роли

### 2.1 Постоянные роли (system_role)

```
DIRECTOR                    — Генеральный директор
DEPUTY_DIRECTOR [CIVIL]     — Зам по общестрою
DEPUTY_DIRECTOR [MEP]       — Зам по инженерным сетям
DEPUTY_DIRECTOR [GENERAL]   — Зам по общим вопросам
HEAD_OF_PROCUREMENT         — Начальник снабжения
BUYER                       — Снабженец
WAREHOUSE                   — Кладовщик
HEAD_OF_PTO                 — Начальник ПТО
PTO_ENGINEER                — Инженер ПТО
SITE_SUPERINTENDENT         — Прораб
ECONOMIST                   — Экономист (сквозная роль)
HEAD_OF_ACCOUNTANTS         — Главный бухгалтер
ACCOUNTANT                  — Бухгалтер
TREASURER                   — Казначей
```

### 2.2 Проектные роли (project_role через project_assignments)

```
GI              — Главный инженер проекта (технический gate)
PM              — Менеджер проекта (коммерческий gate)
SITE_MANAGER    — Начальник участка (физическая приёмка)
PTO_ENGINEER    — Инженер ПТО проекта
BUYER           — Снабженец проекта
ACCOUNTANT      — Бухгалтер проекта
WAREHOUSE       — Кладовщик проекта
```

### 2.3 User Stories (ключевые)

| Роль | User Story |
|------|-----------|
| SITE_SUPERINTENDENT | Создаю заявку на материалы и вижу статус: кто обрабатывает, когда будет |
| BUYER | Беру позицию из пула, сравниваю поставщиков, формирую PO |
| HEAD_OF_PROCUREMENT | Вижу нагрузку команды снабжения, назначаю позиции, контролирую SLA |
| SITE_MANAGER | Принимаю работы субподрядчика с фото, фиксирую дефекты |
| GI | Подтверждаю технические объёмы АВР перед оплатой |
| PM | Подтверждаю коммерческую сторону АВР: в рамках договора и бюджета |
| DIRECTOR | Утверждаю/отклоняю счета и АВР; вижу дашборд расходов по всем проектам |
| TREASURER | Оплачиваю утверждённые позиции; вижу единый реестр сгруппированный по контрагентам |
| ACCOUNTANT | Проверяю АВР, фиксирую ЭСФ, подтверждаю проводку в 1С |
| PTO_ENGINEER | Веду ВОР, маппирую АВР на строки ВОР, формирую КС-2 заказчику |
| ECONOMIST | Считаю маржу: Revenue (КС-2 заказчику) минус Cost (АВР + закупки) |

**Источник:** `docs/03_decisions/05b_matrix-org-and-pm-role.md`

---

## 3. Модули системы

### 3.1 Карта модулей

```
┌─────────────────────────────────────────────────────────┐
│                  M0: FOUNDATION (База)                   │
│  Auth · Employees · Contractors · Projects · Cost Codes  │
└─────────────────────────┬───────────────────────────────┘
                          │
         ┌────────────────┼──────────────────┐
         ▼                ▼                  ▼
  ┌────────────┐   ┌────────────┐    ┌─────────────────┐
  │  M1: P2P   │   │M2: Contract│    │ M3: Project     │
  │  (ПЕРВЫЙ)  │   │ Management │    │ Controls        │
  └─────┬──────┘   └─────┬──────┘    └───────┬─────────┘
        │                │                   │
        └───────┬────────┘                   │
                ▼                            │
       ┌─────────────────┐                   │
       │ M4: Financial   │◄──────────────────┘
       │  Management     │
       └────────┬────────┘
                │
       ┌────────┼──────────┐
       ▼        ▼          ▼
  ┌────────┐ ┌────────┐ ┌──────────┐
  │M5: CRM │ │M6:Whse │ │M7: Full  │
  │(легкий)│ │Inventory│ │Analytics │
  └────────┘ └────────┘ └──────────┘
```

### 3.2 Статус модулей

| Модуль | Оценка | Приоритет | Статус |
|--------|--------|-----------|--------|
| M0 Foundation | Done | Done | Частично построена |
| M1 P2P | 26-35 дней | ПЕРВЫЙ | В разработке |
| M2 Contract Management | 10-14 дней | После M1 | Базово существует |
| M3 Project Controls | 10-14 дней | После M1 | Частично в M1 |
| M4 Financial Management | 12-16 дней | После M1 | Не начат |
| M5 CRM | 6-8 дней | Низкий | Не начат |
| M6 Warehouse | 10-14 дней | Средний | Не начат |
| M7 Analytics Full | 6-8 дней | Низкий | Не начат |

**Источник:** `docs/06_delivery/12_master-system-roadmap.md`

---

## 4. Главный поток создания ценности (Value Stream)

> **Полная карта конвееров:** `docs/02_research/03_value-stream-map.md`

### 4.1 Конвеерная архитектура (Bid-to-Cash)

> **Архитектурный принцип:** Система моделируется как иерархия вложенных конвееров.
> L1 — главный конвеер (проект от тендера до закрытия). L2 — процессные группы.
> L3 — исполняемые workflow. Финансовые данные — побочный продукт операционного потока.
> Оплата — шаг в конкретном конвеере, а не запись в отдельном реестре.

```
L1: Тендер → Деньги (Bid-to-Cash)
│
├─ [0] Коммерческая подготовка  → L2-PRE
├─ [1] Запуск проекта           → L2-CON (контрактование субчиков)
├─ [2] Производство работ       → L2-A (снабжение), L2-B (субподряд), L2-FIELD, L2-HR
├─ [3] Сдача заказчику          → L2-D (биллинг)
├─ [4-5] Оплата / Закрытие
├─ [Сквозной] L2-FIN (финконтроль)
└─ [Сквозной] L2-ACC (бухгалтерия в 1С)
```

### 4.2 Единый финансовый стержень

> Атомарная единица связи — `cost_code × project`.
> Маржа = Revenue - Cost. Маржа — **вычисляемая величина (VIEW)**, не хранимая.

```
  ┌─────── REVENUE (доход) ───────┐  ┌─────── COST (расход) ──────┐
  │ Договор заказчика → ВОР       │  │ L2-A: Снабжение            │
  │ → L2-FIELD: прогресс          │  │ L2-B: Субподряд             │
  │ → L2-D: КС-2 → Оплата $      │  │ L2-HR: Труд                 │
  └───────────────┬───────────────┘  └────────────┬───────────────┘
                  │        cost_code_id           │
                  └──────────┬────────────────────┘
                             ▼
                  MARGIN = Revenue - Cost (VIEW)
```

### 4.3 Расходная сторона: Конвееры L2-A и L2-B

Два основных расходных потока сходятся в шаге «оплата», но проходят разные маршруты:

| Конвеер | Триггер | Маршрут | Оплата |
|---------|---------|---------|--------|
| **L2-A** (Снабжение) | Заявка с объекта | Заявка → Sourcing → Утверждение → Оплата → Приёмка → Склад | Шаг A1.6 в Sourcing |
| **L2-B** (Субподряд) | Субчик выполнил объём | Физ.приёмка → Документы → Проверка → Утверждение → Оплата | Шаг B6 |

**Модель авансов (Subcontractor Ledger — AP Standard):**

Соответствует мировым ERP (SAP S/4HANA, Oracle, Procore). Подробно: `docs/02_research/01_ap-best-practices.md`

```
По каждому договору (contract_ledger VIEW — M2):
  Net Payable = AVR_certified × (1 - warranty_percent/100)
                − Advance_Recovery_to_date
                − Progress_Payments_Made

Где:
  ADVANCE      (commitment_type) = аванс до выполнения → создаёт долг подрядчика
  SUBCONTRACT  (commitment_type) = оплата по АВР → закрывает долг компании
  RETENTION    (commitment_type) = возврат гарантийного удержания
```

**Advance Recovery (M3, при внедрении АВР-модуля):**
При каждом АВР из суммы автоматически вычитается пропорциональная часть аванса:
`recovery_this_period = avr_gross × recovery_rate%` — до полного погашения аванса.

Аванс утверждается Директором. При закрытии долга документами — **повторное утверждение не нужно**.

**Нет «реестра казначея» как отдельной сущности.** Казначей видит оплаты как шаги
в конкретных конвеерах (A1.6, B6, B-ADV.3, HR.5). Группировка: Контрагент → Проект.

**ADR:** `docs/03_decisions/45_ap-advance-payment-form.md` (форма аванса, каскад выбора)


### 4.4 Доходная сторона: Revenue (L2-D)

```
ДОГОВОР ЗАКАЗЧИКА
  client_contracts → contract_items (ВОР = Schedule of Values)
                            │
                            ▼
ВЫПОЛНЕНИЕ (L2-FIELD → накопитель прогресса)
  progress_claims (КС-2 заказчику за период)
                            │
                            ▼
ОПЛАТА ОТ ЗАКАЗЧИКА
  client_payments: amount, payment_type
```

**Связь Revenue ↔ Cost:** `cost_code_id` — архитектурный мост.

### 4.5 Принцип «Плюс-минус» (Variation Netting)

> Стройка требует терпимости к отклонениям.
> «Плюс-минус» — балансировка: одни позиции перерасходованы, другие сэкономлены.

**Три сценария:**
- NET ≈ 0 → сходится, перераспределение внутри договора
- NET > порог → допсоглашение (Change Order)
- NET < 0 → экономия

`variation_status: UNCHANGED | OVERRUN | UNDERRUN | ELIMINATED`

### 4.6 Частицы в конвеерах

| Частица | Конвеер | Описание |
|---------|---------|----------|
| `purchase_item` | L2-A, L2-B | Атомарная единица расхода (якорь) |
| `physical_acceptance` | L2-B (шаг B2) | Физическая приёмка (gate) |
| `avr_document` | L2-B (шаг B3) | АВР субподрядчика |
| `payment` | L2-A/B/HR (шаги оплаты) | Факт оплаты |
| `contract_item` | L2-D | Строка ВОР заказчика (якорь Revenue) |
| `progress_claim` | L2-D (шаг D2) | КС-2 заказчику за период |
| `timesheet_entry` | L2-HR | Запись табеля |

### 4.7 Бухгалтерский конвеер (L2-ACC, в 1С)

L2-ACC — полноценный конвеер, но живёт в 1С. MidesCloud поставляет данные
и получает обратно **список выставленных ЭСФ**.

```
L2-A/B/HR/D → документы → БУХГАЛТЕРИЯ → проверка бумажных → сверка с ЭСФ → 1С → архив
```

### 4.8 Альтернативный выход: Ретро-операции

Не отдельный конвеер. Альтернативный **выход** из L2-A / L2-B / L2-HR.
Тот же маршрут утверждения, постфактум. `is_retrospective = true` + причина.

---

## 5. Маршрут АВР субподрядчика (Path B, детально)

### 5.1 Жизненный цикл

```
Субчик выполнил работы
    ↓
SITE_MANAGER: physical_acceptance (фото, объёмы, дефекты)
    ↓ REJECTED / PENDING_FIX → субчик устраняет
    ↓ ACCEPTED / PARTIAL
Загрузка документов (Р-1 / КС-2 / КС-3)
    ↓ OCR + Discrepancy Review (автосравнение)
    ↓ data_status = DRAFT (данные извлечены, не подтверждены)
IN_REVIEW: ПТО + Бухгалтерия параллельно
    ↓ REJECTED → data_status возвращается в DRAFT, данные корректируются
    ↓ оба одобрили → data_status = COMMITTED (данные заблокированы)
FULLY_APPROVED → Директор утверждает
    ↓ status = APPROVED
Казначей → PAID
    ↓
ESF_PENDING → ESF_RECEIVED → EXPENSE_POSTED (проводка 1С)
```

**Структурный запрет:** АВР не может существовать без `physical_acceptance_id NOT NULL`.
PM не может одобрить АВР без приёмки от SITE_MANAGER.

### 5.2 Два объекта документа: скан и данные

```
СКАН (файл) — immutable:
  ├── file_url + file_hash (SHA-256) — неизменяемый
  ├── version (автоинкремент) — новый файл = новая версия
  └── status: CURRENT | SUPERSEDED

ДАННЫЕ (извлечённые строки) — мутабельные до COMMITTED:
  ├── DRAFT — после OCR, корректируемые загрузившим
  ├── SUBMITTED — отправлены на проверку
  ├── COMMITTED — заблокированы, юридическая сила
  └── Финансовые расчёты используют ТОЛЬКО данные COMMITTED
```

**Правило:** Скан никогда не перезаписывается. Исправленный документ = новая версия файла.
Отклонение (REJECTED) не удаляет данные — возвращает `data_status` в DRAFT для корректировки.

### 5.3 Discrepancy Review (автосравнение при OCR)

ОСR извлекает строки → система автоматически сравнивает с 4 источниками:

| Источник | Что проверяется | Кому нужно |
|----------|----------------|------------|
| `physical_acceptance` | qty в документе ≤ qty принятого? | ПТО |
| `contract_items` | цена в документе = цена по договору? | Бухгалтерия |
| Накопительная история | total accumulated ≤ лимит договора? | ПТО + PM |
| Предыдущий период | нет ли дублирования строк? | Бухгалтерия |

**Результат:** Экран проверки показывает расхождения автоматически.
Но расхождение — **не всегда ошибка**. Если объём превышен — это может быть
легитимный OVERRUN (см. принцип «Плюс-минус», раздел 4.4). ПТО принимает решение.

**Источники:** `docs/03_decisions/05b_matrix-org-and-pm-role.md`, `docs/03_decisions/35_avr-module-architecture.md`, `docs/03_decisions/15_avr-lifecycle-esf.md`

---

## 6. Иерархия данных

### 6.1 Три уровня: Проект → Объект → Направление

```
ПРОЕКТ "Школа Мирас"        ← весь договор с заказчиком
  ├── ОБЪЕКТ "Блок А"        ← физическое подразделение
  │     ├── CIVIL (общестрой) ← SITE_MANAGER: Иванов
  │     └── MEP (инж.сети)   ← SITE_MANAGER: Петров
  └── ОБЪЕКТ "Блок Б"
        ├── CIVIL             ← SITE_MANAGER: Сидоров
        └── MEP               ← SITE_MANAGER: Петров (тот же)
```

АВР всегда содержит: `project_id` + `object_id` + `work_stream`
→ система находит нужного SITE_MANAGER автоматически.

### 6.2 Контрагенты: юрлица, бенефициары, типы

**Классификация контрагентов:**

```
contractor_type:
  SUBCONTRACTOR    — субподряд (выполняет работы на объекте)
  SUPPLIER         — поставщик товаров (материалы, оборудование)
  SERVICE_PROVIDER — поставщик услуг (аренда техники, курьеры, интернет, охрана)
  CLIENT           — заказчик (входящие платежи)
```

**Бенефициарная связь (1:M):**

Одно физлицо может стоять за несколькими юрлицами, но **у каждого юрлица один ответственный бенефициар**. M:M создаёт безответственность.

```
Ернар Каратаев (бенефициар)
  ├── ИП Монолит        → Объект А → оплата со счёта проекта А
  └── ТОО Бетонозаливка → Объект Б → оплата со счёта проекта Б
```

Казначей платит юрлицу. Но при утверждении директор видит **суммарную ответственность
бенефициара** по всем юрлицам и проектам — включая замороженные объекты.

```
beneficial_owners (физлицо-бенефициар)
  ├── id, full_name, phone, iin
  └── (Ернар Каратаев)

contractors (юрлицо)
  ├── contractor_type: SUBCONTRACTOR | SUPPLIER | SERVICE_PROVIDER | CLIENT
  ├── bin (БИН/ИИН)
  ├── beneficial_owner_id → beneficial_owners
  │     NOT NULL для: SUBCONTRACTOR, SUPPLIER, SERVICE_PROVIDER
  │     NULL для: CLIENT
  └── (ИП Монолит, ТОО Бетонозаливка)
```

Обратный запрос: `SELECT * FROM contractors WHERE beneficial_owner_id = :ernar_id`

**Источник:** `docs/03_decisions/04_contractor-hierarchy.md` (требует обновления → ADR-37)

### 6.3 Группа юрлиц (Multi-Entity)

> Компания — это не одно юрлицо, а **группа**: основное ТОО + несколько ИП.
> Расходы всех юрлиц ведёт один и тот же сотрудник в MidesCloud.
> ИП — это фактически **ещё один расчётный счёт** в системе.

```
Пример:
  ТОО МиДЭС (основное) — заключает договоры, принимает оплату от заказчиков
    ├── ИП Рахимов — обналичивание для выплаты ЗП наличными (дешевле чем через ТОО)
    ├── ИП Сервис — аренда техники, внутренние услуги
    └── ИП Логистика — транспортные расходы

  Перевод ТОО → ИП Рахимов = НЕ расход.
  Это внутригрупповой трансфер. Но налог ИПН + комиссия банка = реальные расходы.
```

**Архитектурные правила:**

1. Все юрлица группы зарегистрированы в `legal_entities`
2. `legal_entities.is_own = true` — наши юрлица (ТОО + ИП)
3. Каждое юрлицо имеет `bank_accounts` — ИП операционно = ещё один счёт
4. Перевод между своими юрлицами = `intercompany_transfers` (НЕ расход)
5. Налоги и комиссии при переводе = обычные `purchase_items` (РАСХОД)
6. Директор видит **единый контур**: все юрлица как одна компания
7. Бухгалтерия видит **раздельно**: каждое юрлицо отдельно для 1С и налогов

```
legal_entities (наши юрлица)
  ├── id, name, bin, entity_type (TOO | IP)
  └── is_own: true (наш контур)

bank_accounts
  ├── account_number, bank_name, bank_bik
  ├── legal_entity_id → legal_entities
  ├── currency (KZT по умолчанию)
  ├── is_active: boolean
  └── purpose (nullable): "объект Ақ-Бұлақ", "ЗП наличные", "основной"

project_bank_accounts (junction: счёт ↔ проект)
  ├── project_id → projects
  └── bank_account_id → bank_accounts

intercompany_transfers (перевод внутри группы — НЕ расход)
  ├── from_account_id → bank_accounts (счёт ТОО)
  ├── to_account_id → bank_accounts (счёт ИП)
  ├── amount
  ├── purpose: "ЗП наличными за май"
  ├── project_id (nullable)
  ├── status: DRAFT → APPROVED → EXECUTED
  ├── approved_by → users (Директор или делегат)
  └── tax_rate (справочное, для расчёта)

  При EXECUTED → авто-создание purchase_items:
    {"ИПН 3%", amount=налог, cost_code=налоги, source_transfer_id=...}
    {"Комиссия банка", amount=комиссия, cost_code=банк_расходы, source_transfer_id=...}
```

**Маржа проекта (консолидированная):**
```
Маржа = Revenue − SUM(purchase_items)
  intercompany_transfer сам → НЕ в формуле (деньги внутри)
  Налог + комиссия при переводе → обычные purchase_items → В формуле ✓
```

**WIP-отчёт директора:** Консолидированный по всем `legal_entities WHERE is_own = true`.

---

## 7. Доменная модель (ключевые таблицы)

### 7.1 Ядро

```
legal_entities (юрлица группы)
  ├── name, bin, entity_type (TOO | IP)
  └── is_own: true (наш финансовый контур)

bank_accounts
  ├── account_number, bank_name, bank_bik
  ├── legal_entity_id → legal_entities
  ├── currency, is_active
  └── purpose (nullable)

users ──────────── user_roles (junction, multi-role)
  │
  └── project_assignments
        ├── project_id → projects
        ├── object_id → project_objects
        ├── work_stream (CIVIL | MEP)
        └── project_role (GI | PM | SITE_MANAGER | ...)

projects
  └── project_objects (Блок А, Блок Б)

beneficial_owners (физлица-бенефициары)

contractors
  ├── contractor_type (SUBCONTRACTOR | SUPPLIER | SERVICE_PROVIDER | CLIENT)
  ├── beneficial_owner_id → beneficial_owners (NULL для CLIENT)
  └── contractor_employees

approval_delegations (делегирование утверждений)
  ├── from_user_id → users (кто делегирует)
  ├── to_user_id → users (кому)
  ├── valid_from, valid_until — период действия
  ├── max_amount (nullable = без лимита)
  └── scope: ALL | PROJECT_SPECIFIC | FLOW_TYPE
```

### 7.2 Единый реестр расходов — архитектура «Тонкий якорь + задачи ролей»

> **ADR-38.** purchase_items = лёгкий якорь (ПОТРЕБНОСТЬ).
> Каждая роль работает в своей task-таблице. Статус якоря — ВЫЧИСЛЯЕМЫЙ.
> Подробное обоснование: `docs/03_decisions/38_task-per-role-architecture.md`

#### 7.2.1 Якорь (purchase_items)

```
purchase_items (ЯКОРЬ — потребность, минимум полей)
  ├── flow_type (PROCUREMENT | PAYMENT_APPLICATION)
  ├── project_id → projects
  ├── object_id → project_objects
  ├── contractor_id → contractors (nullable — появляется после sourcing)
  ├── contract_id → contracts (обязательно для PAYMENT_APPLICATION)
  ├── cost_code_id → cost_codes (МОСТ Revenue ↔ Cost, обязательное)
  ├── description, qty, unit
  ├── amount_estimated
  ├── currency (ISO 4217, default KZT)
  ├── exchange_rate (nullable)
  ├── amount_base (nullable, сумма в KZT при инвалюте)
  ├── legal_entity_id → legal_entities (чей расход: ТОО или ИП)
  ├── source_transfer_id → intercompany_transfers (nullable)
  └── current_stage: VIEW (вычисляемый из состояния задач, НЕ хранимый)
```

**Правило:** purchase_items НЕ хранит данные, специфичные для одной роли.
Никаких полей снабженца, казначея, бухгалтера — всё в task-таблицах.

#### 7.2.2 Задачи ролей (Cost side)

```
sourcing_tasks (СНАБЖЕНЕЦ: поиск, КП, сравнение, выбор)
  ├── purchase_item_id → purchase_items
  ├── assigned_to → users (снабженец)
  ├── status: OPEN → IN_PROGRESS → COMPLETED
  ├── reassigned_from → users (nullable, предыдущий ответственный)
  ├── reassigned_at (nullable)
  └── result_id → sourcing_results (nullable, появляется при завершении)

sourcing_results (артефакт снабженца)
  ├── sourcing_task_id → sourcing_tasks
  ├── quotes[] (полученные КП от поставщиков)
  ├── comparison_data (таблица сравнения)
  ├── selected_supplier_id → contractors
  ├── selected_price, justification
  └── po_number

approval_tasks (УТВЕРЖДЕНИЕ: GI → PM → Director)
  ├── purchase_item_id → purchase_items
  ├── approver_id → users
  ├── status: PENDING → APPROVED | REJECTED
  ├── decided_at, comment
  └── delegation_id → approval_delegations (nullable)

payment_tasks (КАЗНАЧЕЙ: оплата)
  ├── purchase_item_id → purchase_items
  ├── treasurer_id → users (казначей)
  ├── status: PENDING → PARTIAL → PAID
  ├── amount_paid (выплаченная сумма)
  ├── payment_date (дата платежа)
  ├── payment_ref (номер ПП)
  ├── warranty_retention_amount (гарантийное удержание по этому платежу)
  └── net_payment_amount (сумма к выплате подрядчику = amount_paid - warranty_retention_amount)

doc_collection_tasks (СБОР ДОКУМЕНТОВ после оплаты)
  ├── purchase_item_id → purchase_items
  ├── responsible_id → users
  │     Path A: снабженец, Path B: PM — назначается авто по flow_type
  ├── status: PENDING → SUBMITTED → ACCEPTED
  ├── document_files[] (привязка к сканам)
  └── sla_deadline (N дней после PAID, потом уведомление)

accounting_tasks (БУХГАЛТЕРИЯ: ЭСФ, сверка, проводка)
  ├── purchase_item_id → purchase_items
  ├── assigned_to → users (бухгалтер)
  ├── esf_matched: boolean
  ├── amounts_verified: boolean
  ├── posted_to_1c: boolean
  ├── posted_at
  └── status: PENDING → MATCHED → POSTED

pto_tasks (ПТО: маппинг на ВОР, Discrepancy Review)
  ├── purchase_item_id → purchase_items (или avr_document_id)
  ├── assigned_to → users (ПТО)
  ├── vor_mapping_status: PENDING → MAPPED → VERIFIED
  ├── discrepancy_notes
  └── discrepancy_review_id (nullable)
```

#### 7.2.3 current_stage — вычисляемый VIEW

```sql
-- Статус НЕ хранится. Определяется из состояния дочерних задач.
CREATE VIEW purchase_items_with_stage AS
SELECT pi.*,
  CASE
    WHEN st.status IS NULL OR st.status = 'OPEN'     THEN 'DRAFT'
    WHEN st.status = 'IN_PROGRESS'                    THEN 'SOURCING'
    WHEN at.status = 'PENDING'                        THEN 'APPROVAL'
    WHEN at.status = 'APPROVED' AND pt.status IS NULL THEN 'APPROVED'
    WHEN pt.status = 'PAID' AND dc.status = 'PENDING' THEN 'DOCS_PENDING'
    WHEN dc.status = 'SUBMITTED'                      THEN 'DOCS_REVIEW'
    WHEN act.status = 'POSTED'                        THEN 'POSTED'
    WHEN act.status = 'POSTED' AND dc.status = 'ACCEPTED' THEN 'CLOSED'
    ELSE 'DRAFT'
  END AS current_stage
FROM purchase_items pi
LEFT JOIN sourcing_tasks st    ON st.purchase_item_id = pi.id
LEFT JOIN approval_tasks at    ON at.purchase_item_id = pi.id
LEFT JOIN payment_tasks pt     ON pt.purchase_item_id = pi.id
LEFT JOIN doc_collection_tasks dc ON dc.purchase_item_id = pi.id
LEFT JOIN accounting_tasks act ON act.purchase_item_id = pi.id;
```

#### 7.2.4 Оркестратор — ОДИН Edge Function

```
advance_workflow(purchase_item_id, completed_task_type, payload)

  'sourcing_completed'   → INSERT INTO approval_tasks
  'approval_approved'    → INSERT INTO payment_tasks
  'payment_paid'         → INSERT INTO doc_collection_tasks (responsible по flow_type)
  'docs_accepted'        → INSERT INTO accounting_tasks
  'accounting_posted'    → финал (позиция → CLOSED)

Правило: ВСЯ логика «что происходит дальше» — в ОДНОМ месте.
Никаких каскадных триггеров.
```

#### 7.2.5 Рабочее пространство каждой роли

```
Снабженец:  SELECT * FROM sourcing_tasks    WHERE assigned_to = :me AND status IN ('OPEN','IN_PROGRESS')
Казначей:   SELECT * FROM payment_tasks     WHERE status = 'PENDING'
Бухгалтер:  SELECT * FROM accounting_tasks  WHERE status IN ('PENDING','MATCHED')
ПТО:        SELECT * FROM pto_tasks         WHERE status = 'PENDING'
Директор:   SELECT * FROM approval_tasks    WHERE approver_id = :me AND status = 'PENDING'

Каждая роль видит СВОЙ экран, СВОИ данные, СВОИ действия.
purchase_items — общий якорь, но никто не работает с ним напрямую.
```

#### 7.2.6 Документы и платежи (общие таблицы)

```
invoices (Path A: счета поставщиков)
  ├── contractor_id → contractors
  ├── data_status: DRAFT | SUBMITTED | COMMITTED
  └── invoice_items → purchase_items (M:M маппинг)

physical_acceptances (обязательна перед АВР)
  ├── project_id, object_id, work_stream
  ├── accepted_by → users (SITE_MANAGER)
  └── status (ACCEPTED | PARTIAL | REJECTED | PENDING_FIX)

avr_documents (Path B: акты выполненных работ)
  ├── physical_acceptance_id NOT NULL → physical_acceptances
  ├── r1_rows, ks2_rows, ks3_rows (три формы документов)
  ├── data_status: DRAFT | SUBMITTED | COMMITTED
  └── status (lifecycle)

document_files (сканы)
  ├── entity_type, entity_id — к чему привязан (avr, invoice, doc_collection_task)
  ├── file_url, file_hash (SHA-256)
  ├── version (автоинкремент)
  ├── uploaded_by → users, uploaded_at
  ├── status: CURRENT | VOIDED
  ├── detected_type (nullable) — ИИ-классификация: INVOICE | AVR | KP | ESF | ACT_SVERKI | OTHER
  └── ai_result_id → ai_results (nullable, ссылка на результат распознавания)
  Правило: VOIDED → каскадное DELETE связанных DRAFT/SUBMITTED данных
  Правило: COMMITTED данные нельзя VOIDED без утверждения Директора (сторно)

payments (факт оплаты — НЕ задача, а запись)
  ├── purchase_item_id → purchase_items
  ├── amount, payment_date
  ├── payment_type: ADVANCE | PROGRESS | FINAL | RETENTION_RELEASE
  ├── from_bank_account_id → bank_accounts
  ├── currency, exchange_rate (nullable)
  ├── paid_by → users (TREASURER)
  └── accounting_status: PENDING | POSTED | DISCREPANCY (nullable, шов 1С)

intercompany_transfers (переводы внутри группы — НЕ расход)
  ├── from_account_id → bank_accounts
  ├── to_account_id → bank_accounts
  ├── amount, purpose
  ├── project_id (nullable)
  ├── status: DRAFT → APPROVED → EXECUTED
  ├── approved_by → users (Директор/делегат)
  └── tax_rate (справочное)
  При EXECUTED → advance_workflow() создаёт purchase_items для налога + комиссии
```

### 7.3 Project Controls (M3) + Revenue — якорь `contract_items`

> **ADR-38.** contract_items = якорь ДОХОДНОЙ стороны.
> Task-таблицы Revenue side (progress_claim_tasks, client_invoicing_tasks,
> variation_tasks) проектируются при старте M3 по тому же паттерну что и Cost side.
> Мост между якорями: `cost_code_id`.

```
client_contracts (договоры заказчика — доходная сторона)
  ├── client_id → contractors (type=CLIENT)
  ├── project_id → projects
  ├── total_contract_sum
  └── retention_rate (% гарантийного удержания, nullable)

contract_items (ВОР заказчика = Schedule of Values)
  ├── client_contract_id → client_contracts
  ├── cost_code_id → cost_codes              ← МОСТ к расходам
  ├── description, unit, qty_original, unit_price_original
  ├── qty_revised (nullable, корректировка ПТО)
  ├── unit_price_revised (nullable)
  ├── qty_actual (вычисляемый из АВР)
  ├── variation_status: UNCHANGED | OVERRUN | UNDERRUN | ELIMINATED
  └── variation_reason (текстовое пояснение ПТО)

progress_claims (КС-2 заказчику за период)
  ├── client_contract_id → client_contracts
  ├── period_from, period_to
  ├── status: DRAFT | SUBMITTED | ACCEPTED | PAID
  └── total_claim_amount

progress_claim_items (строки КС-2 заказчику)
  ├── progress_claim_id → progress_claims
  ├── contract_item_id → contract_items
  └── qty_current_period, amount_current_period

client_payments (входящие платежи от заказчика)
  ├── client_contract_id → client_contracts
  ├── progress_claim_id → progress_claims (nullable)
  ├── amount, payment_date
  └── payment_type: ADVANCE | PROGRESS | FINAL | RETENTION_RELEASE

avr_vor_mappings (M:M маппинг АВР → ВОР)
  ├── avr_line_id
  ├── vor_item_id
  └── mapped_qty, allocation_percent
```

**WIP-отчёт** (Work in Progress, VIEW): маржа = SUM(contract_items по cost_code) − SUM(purchase_items по cost_code) на уровне project × cost_code.

**Плюс-минус VIEW**: SUM(OVERRUN amounts) vs SUM(UNDERRUN amounts) → NET. При NET > порога → сигнал на допсоглашение.

### 7.4 Справочники

```
cost_codes (операционные — 1001 позиция)
  ├── code, name, section
  └── tags (для RAG-поиска)
  Роль: МОСТ между Revenue (contract_items) и Cost (purchase_items)

legal_work_types (перечень РК — официальный)
  └── Для КС-2 и договоров

contracts (субподрядные договоры — расходная сторона)
  ├── contractor_id → contractors
  ├── project_id → projects
  ├── penalty_clause_json (nullable, шов M2 — штрафы/неустойки)
  └── total_amount — SUM(contract_items.total_amount) при наличии позиций

contract_items (SOV — позиции договора, ADR-47)
  ├── contract_id → contracts
  ├── cost_code_id → cost_codes (nullable, классификационный мост)
  ├── line_number (integer, порядковый номер)
  ├── description (text, свободный — субчики пишут по-разному)
  ├── unit (text: м², м³, шт, т)
  ├── qty_contracted (numeric 18,3 — объём по договору)
  ├── unit_price (numeric 18,2)
  ├── total_amount (numeric 18,2 = qty × price)
  └── CONSTRAINT: contract_id + line_number UNIQUE
  Правило: Один cost_code может быть в договоре несколько раз (разные секции, цены)
  Правило: Ввод: ручной → OCR → Excel import (один и тот же ContractItemsEditor)
  Правило: Используется для субподрядных И заказчических договоров
  Правило: contracts.total_amount = SUM(contract_items.total_amount) при автопересчёте
  Связь с АВР: avr_document_lines.contract_item_id → contract_items (Dual FK + cost_code_id)

contractor_compliance (лицензии, страховки, допуски)
  ├── contractor_id → contractors
  ├── document_type: LICENSE | INSURANCE | SRO_PERMIT | TAX_CERT
  ├── valid_from, valid_until
  ├── file_url
  └── status: ACTIVE | EXPIRING_SOON | EXPIRED
  Правило: автоуведомление за 30 дней до истечения

sla_norms (7 нормативов загружены)
routing_rules (правила авто-маршрутизации)
```

### 7.5 AI Infrastructure (фундамент для M2+)

> Минимальный слой, который закладывается СЕЙЧАС, чтобы AI-фичи
> подключались без рефакторинга существующих таблиц.
> Подробное обоснование: `docs/02_research/02_ai-strategy-practical.md`

```
ai_results (единый журнал ВСЕХ результатов ИИ)
  ├── id (uuid)
  ├── task_type: OCR_INVOICE | OCR_AVR | OCR_KS2 | CLASSIFY_DOC |
  │              MAP_INVOICE_TO_PI | MAP_AVR_TO_VOR | COMPARE_QUOTES |
  │              PARSE_DAILY_LOG | ANOMALY_PRICE | ANOMALY_DUPLICATE
  ├── source_file_id → document_files (nullable, если входом был файл)
  ├── source_text (nullable, если входом был текст — daily log)
  ├── model_used: 'gemini-2.5-flash-lite' | 'gemini-2.5-flash' | ...
  ├── input_tokens, output_tokens (для контроля расходов на API)
  ├── result_json (JSONB — структурированный результат)
  ├── confidence (0.0–1.0, nullable)
  ├── status: DRAFT → ACCEPTED | REJECTED
  ├── reviewed_by → users (nullable, кто подтвердил/отклонил)
  ├── reviewed_at (nullable)
  ├── created_at
  └── processing_time_ms

  Правило: ИИ создаёт запись со status = DRAFT
  Правило: Только ACCEPTED результаты используются для записи в бизнес-таблицы
  Правило: Запись в бизнес-таблицы — через advance_workflow(), НЕ напрямую
  Правило: REJECTED результаты сохраняются для обучения и аналитики качества

price_history (история цен — основа для аномалий)
  ├── material_name (нормализованное название)
  ├── unit
  ├── unit_price
  ├── contractor_id → contractors
  ├── source_type: INVOICE | KP | MANUAL
  ├── source_id (nullable, ссылка на документ-источник)
  ├── recorded_at
  └── project_id → projects (nullable)
  Заполняется автоматически при COMMITTED invoice/sourcing_result
```

**Зачем это сейчас:**

| Таблица | Что даёт | Без неё потом |
|---------|----------|---------------|
| `ai_results` | Единый журнал всех AI-вызовов, аудит, контроль расходов API | Каждая AI-фича будет хранить результаты по-своему → хаос |
| `price_history` | Накопление данных для обнаружения аномалий цен | В M4 не будет данных для сравнения → фича бесполезна |
| `detected_type` на document_files | Автоклассификация при загрузке → маршрутизация | Придётся менять document_files позже → миграция |
| `ai_result_id` на document_files | Связь скан ↔ результат распознавания | Не будет traceability: «что ИИ извлёк из этого файла?» |

---

## 8. Ключевые инварианты

Правила, которые **не могут быть нарушены** без создания нового ADR:

| # | Инвариант | ADR |
|---|-----------|-----|
| 1 | Единый реестр расходов: `purchase_items` = тонкий якорь. Каждая роль работает в своей `*_tasks` таблице. Нет God Table | ADR-36, ADR-38 |
| 2 | Группировка: Контрагент → Проект → Позиция (на всех стадиях) | ADR-36 |
| 3 | АВР требует `physical_acceptance_id NOT NULL` | ADR-05 |
| 4 | PM не может одобрить АВР без приёмки SITE_MANAGER | ADR-05 |
| 5 | Маршрут АВР: SITE_MANAGER → ПТО → PM → Бухгалтерия (ADR-48, обновлено 2026-05-23) | ADR-05, ADR-48 |
| 6 | PM утверждает АВР ПОСЛЕ проверки ПТО (коммерческая сторона: бюджет + договор) | ADR-48 |
| 7 | Суммы: `formatCurrency` (ru-KZ, Intl) | Design System |
| 8 | Таблицы: только AccordionGridTable | ADR-07 |
| 9 | Авторизация на уровне приложения, без RLS | ADR-09 |
| 10 | Уведомления через `notification_queue` + Edge Function | ADR-09 |
| 11 | При утверждении платежа директор видит суммарную ответственность бенефициара по всем юрлицам и проектам | ADR-37 (pending) |
| 12 | `cost_code_id` — обязательное поле, МОСТ между Revenue и Cost. Маржа = VIEW, не хранимая | Blueprint |
| 13 | Баланс по контрагенту/договору = SUM(payments) - SUM(accepted docs). Вычисляемый VIEW | Blueprint |
| 14 | Финансовые расчёты используют ТОЛЬКО данные со статусом `data_status = COMMITTED` | Blueprint |
| 15 | Скан: VOIDED → каскадное DELETE DRAFT/SUBMITTED данных. COMMITTED аннулирует только Директор | Blueprint |
| 16 | Отклонение от договора — не ошибка, а вариация. Допсоглашение только при NET > порога (плюс-минус) | Blueprint |
| 17 | Делегирование: утверждение заместителем только в рамках `approval_delegations` (период + лимит) | Blueprint |
| 18 | Маржа = консолидированная по всем `legal_entities WHERE is_own = true`. Intercompany transfer ≠ расход, но налог + комиссия = расход | Blueprint |
| 19 | Позиция не может перейти в POSTED без закрывающих документов. Ответственный: снабженец (Path A) / PM (Path B) | Blueprint |
| 20 | Бенефициар: 1 юрлицо = 1 ответственный. `beneficial_owner_id` FK, NOT NULL кроме CLIENT | Blueprint |
| 21 | `current_stage` — ВЫЧИСЛЯЕМЫЙ VIEW из состояния `*_tasks`. Не хранить статус в `purchase_items` | ADR-38 |
| 22 | Оркестрация: ОДИН `advance_workflow()` Edge Function. Никаких каскадных триггеров | ADR-38 |
| 23 | Два якоря: `purchase_items` (Cost) + `contract_items` (Revenue). Мост = `cost_code_id` | ADR-38 |
| 24 | AI результат = ВСЕГДА `ai_results` с `status: DRAFT`. Человек подтверждает → ACCEPTED. ИИ не пишет в бизнес-таблицы напрямую | Blueprint |

---

## 9. Границы системы (текущие → целевые)

### MidesCloud делает (сейчас, M1) — частично реализован

> **Статус:** Функционально работает, но потеря контекста между сессиями разработки
> привела к рассогласованию подходов. Требуется:
> - End-to-end тестирование всех сценариев
> - Приведение кода к единому архитектурному подходу (blueprint v2.1)
> - Валидация соответствия текущей реализации утверждённой архитектуре

- Операционное управление проектами, объектами, командами
- P2P: заявки → PO → приёмка → оплата
- Платежи субподрядчикам: авансы, АВР, контроль долгов
- Реестр контрагентов
- Учёт ЭСФ до проводки

### MidesCloud будет делать — порядок реализации

> **Детальный план реализации:** `docs/06_delivery/03_anti-big-bang-roadmap.md`  
> Принцип: Gall's Law — каждая фаза = законченный рабочий функционал.

Функциональные области (без привязки к порядку реализации):
- Field Operations — daily logs, табелирование, учёт техники
- Revenue — КС-2/КС-3 заказчику, progress claims, маржа
- Financial Control — Budget vs Actual, WIP Report, сверка с банком
- Scheduling — Gantt, критический путь, cash flow прогноз
- Mobile + Portal — PWA, портал субподрядчика
- Warehouse — складской учёт
- HR — ЗП, отпуска, кадровый учёт

Порядок, Exit Criteria и трассировка к целям → см. Anti-Big Bang Roadmap.

### Остаётся в 1С

- Бухгалтерский и налоговый учёт
- Регламентированная отчётность
- Начисление налогов и взносов
- Клиентские платежи (входящие) — данные дублируются в `client_payments` для WIP-отчёта

### Интеграция с 1С

| Фаза | Механизм |
|------|---------|
| Фаза 1 (сейчас) | Ручной реестр + роль ACCOUNTANT |
| Фаза 2 | Файловый обмен CSV + сверка (`accounting_status`: PENDING → POSTED / DISCREPANCY) |
| Фаза 3 | REST API (1С HTTP-сервисы) |

---

## 10. Архитектурные швы (Seams for Future Modules)

> Решения, которые нужно заложить в текущей фазе сейчас, чтобы не переделывать потом.
> Стоимость: минуты. Экономия: недели.

### 10.1 Для M3 — Revenue + Плюс-минус

**Шов:** `cost_code_id` в purchase_items — обязательное. `contract_items` с `variation_status` заложены.

**Что заложить в M1:**
- `ks2_rows.work_description` и `ks2_rows.unit` — текстовые, не enum (субчики пишут по-разному)
- `ks2_rows.qty_current_period` и `ks2_rows.amount_current_period` — обязательные поля
- В `contract_items` предусмотреть `qty_total` (по договору) — сравнение с накоплением

**Что НЕ делать в M1:** маппинг ks2_rows → contract_items. Это M3 (PTO_ENGINEER делает вручную).

### 10.2 Для M4 — Financial Management

**Шов:** `purchase_items.cost_code_id` уже существует. Budget vs Actual = SUM по cost_code.

**Что заложить в M1:**
- `cost_codes.parent_id` — иерархия для агрегации по разделам (уже в роадмапе)
- `purchase_orders` — индекс `(project_id, status) WHERE status='APPROVED'` для committed costs
- В `payments` хранить `cost_code_id` (копировать из purchase_item при оплате)
- `projects.budget_total` — поле для общего бюджета (null допустим, заполняется позже)

### 10.3 Для M6 — Warehouse

**Шов:** GRN (приёмка товара) в M1 фиксирует `qty_received`. Склад = GRN + выдача.

**Что заложить в M1:**
- В `grn_items`: `location_id` (nullable) — куда приняли. Пока null = «основной склад»
- Не привязывать GRN жёстко к одному PO — один GRN может покрывать несколько PO

### 10.4 Для M8 — HR / Payroll

**Шов:** `users` + `project_assignments` уже содержат основу.

**Что заложить в M1:**
- `users.employment_type` — enum: `STAFF | CONTRACT | SEASONAL` (nullable, заполняется позже)
- `users.hourly_rate` или `users.monthly_salary` — nullable, нужно для расчёта себестоимости часа
- `project_assignments.hours_per_week` — nullable; M8 использует для планирования нагрузки
- **НЕ** создавать таблицу `timesheets` сейчас — это M8

### 10.5 Для постфактум-операций (аналоговая стройка)

**Шов:** `purchase_items.is_retrospective` — boolean flag.

**Что заложить в M1:**
- `purchase_items.is_retrospective DEFAULT false` — отличает плановые от постфактум
- `purchase_items.retrospective_reason` — text, nullable; почему расход не прошёл штатный путь
- `purchase_items.compensated_to` — FK → users; кому компенсировали наличные
- Ретроспективная заявка проходит **тот же** маршрут утверждения (без bypass)
- В UI: badge «Ретро» на таких позициях, фильтр в реестре

### 10.6 Принцип: Nullable сейчас, Required потом

Все «швы» — это **nullable поля** или **индексы**. Они не ломают текущий код,
не требуют миграции данных, но когда модуль M3/M4/M6/M8 стартует — структура уже готова.

```
M1 (сейчас): поле nullable, UI не показывает, код игнорирует
M3 (потом):  поле required для новых записей, UI показывает, код использует
```

---

## 11. Связанные документы

| Тема | Документ |
|------|---------|
| Бизнес-логика закупок | `docs/01_product/02_procurement-request-business-logic.md` |
| Двухпутевой P2P | `docs/03_decisions/11_dual-path-p2p-workflow.md` |
| Единый реестр казначея | `docs/03_decisions/36_unified-payment-registry.md` |
| Матричная оргструктура | `docs/03_decisions/05b_matrix-org-and-pm-role.md` |
| АВР-модуль | `docs/03_decisions/35_avr-module-architecture.md` |
| АВР lifecycle + ЭСФ | `docs/03_decisions/15_avr-lifecycle-esf.md` |
| Project Controls | `docs/04_architecture/08_project-controls-architecture.md` |
| Дизайн-система | `docs/04_architecture/03_design-system.md` |
| Tech Stack | `docs/03_decisions/09_tech-stack.md` |
| Экраны M1 | `docs/04_architecture/07_m1-screen-specs.md` |
| Роадмап реализации | `docs/06_delivery/03_anti-big-bang-roadmap.md` |
| **Contract Items (SOV)** | `docs/03_decisions/47_contract-items-sov.md` |
| **PM утверждает АВР** | `docs/03_decisions/48_pm-avr-approval-step.md` |
| **Project-Centric UI** | `docs/03_decisions/49_project-centric-ui-navigation.md` |
