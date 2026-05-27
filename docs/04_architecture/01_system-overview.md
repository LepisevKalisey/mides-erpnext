# Архитектура системы: MidesCloud на ERPNext

**Статус:** ACTIVE  
**Дата:** 2026-05-26  
**Версия:** 1.0

---

## 1. Общая архитектура

```
┌─────────────────────────────────────────────────────────┐
│                      ПОЛЬЗОВАТЕЛИ                       │
│  Директор · Снабженец · Прораб · ПТО · Казначей · Бухг. │
└──────────────────────┬──────────────────────────────────┘
                       │ HTTPS
┌──────────────────────▼──────────────────────────────────┐
│                   ERPNext (Frappe)                       │
│  ┌─────────────────────────────────────────────────┐    │
│  │              Standard Modules                    │    │
│  │  Accounts · Buying · Stock · Projects · HR      │    │
│  │  Payroll · Setup · Workflow                      │    │
│  └─────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────┐    │
│  │          Custom App: mides_construction          │    │
│  │  AVR Document · Physical Acceptance · KS-2/KS-3 │    │
│  │  Construction Cost Code · Bill of Quantities     │    │
│  │  Subcontractor Ledger · Construction Object      │    │
│  │  Beneficial Owner · Approval Matrix              │    │
│  └─────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────┐    │
│  │              Integrations                        │    │
│  │  1С Export · Gemini OCR · WhatsApp Notifications │    │
│  └─────────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────┤
│                MariaDB / PostgreSQL                      │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Стек технологий

| Слой | Технология | Примечание |
|------|-----------|------------|
| Платформа | ERPNext v15+ | Последняя стабильная версия |
| Фреймворк | Frappe Framework v15+ | Python + JS, Low-Code |
| База данных | MariaDB 10.6+ | Стандарт для ERPNext |
| Web-сервер | Nginx + Gunicorn | Production |
| Cache | Redis | Session + Queue |
| Queue | Redis Queue (RQ) | Background jobs |
| Файлы | Local / S3 | Uploads, OCR scans |
| Dev Environment | Docker (Dev Container) | VS Code integration |
| Кастомный App | `mides_construction` | Frappe App |
| OCR | Gemini API | Edge integration |
| Язык UI | Русский | Custom translations |
| Валюта | KZT (₸) | Base currency |

---

## 3. Custom App: `mides_construction`

### Структура приложения
```
apps/mides_construction/
├── mides_construction/
│   ├── __init__.py
│   ├── hooks.py                    # Хуки интеграции
│   ├── patches/                    # Миграции данных
│   ├── fixtures/                   # Предустановленные данные
│   │   ├── cost_codes.json         # 67 кодов затрат
│   │   ├── custom_fields.json      # Кастомные поля стандартных DocTypes
│   │   └── roles.json              # Строительные роли
│   ├── mides_construction/         # Модуль
│   │   ├── doctype/
│   │   │   ├── construction_object/     # Объект строительства
│   │   │   ├── construction_cost_code/  # Код затрат
│   │   │   ├── beneficial_owner/        # Бенефициарный владелец
│   │   │   ├── contract_item/           # Позиция договора (SOV)
│   │   │   ├── avr_document/            # Акт выполненных работ
│   │   │   ├── avr_document_line/       # Строка АВР (child)
│   │   │   ├── physical_acceptance/     # Физическая приёмка
│   │   │   ├── bill_of_quantities/      # ВОР
│   │   │   ├── ks2_act/                 # КС-2
│   │   │   ├── ks3_certificate/         # КС-3
│   │   │   └── approval_matrix_rule/    # Правило матрицы утверждений
│   │   ├── report/
│   │   │   ├── subcontractor_ledger/    # Лицевой счёт подрядчика
│   │   │   ├── project_budget_vs_actual/# Бюджет vs Факт
│   │   │   └── project_margin/          # Маржа проекта
│   │   └── api/
│   │       ├── ocr.py                   # Gemini OCR integration
│   │       └── one_c_export.py          # 1С export
│   ├── public/
│   │   └── js/
│   │       └── custom_scripts.js        # Client-side customizations
│   └── translations/
│       └── ru.csv                       # Строительная терминология
├── setup.py
└── requirements.txt
```

### Custom DocTypes (новые)

| DocType | Тип | Назначение |
|---------|-----|-----------|
| Construction Object | Standard | Объект строительства (Общестрой/Инж.сети), child of Project |
| Construction Cost Code | Standard | Код затрат (67 позиций), иерархия: Раздел → Категория → Вид работ |
| Beneficial Owner | Standard | Бенефициарный владелец контрагента (link to Supplier) |
| Contract Item | Standard | Позиция договора (SOV): qty, unit_price, total |
| AVR Document | Submittable | Акт выполненных работ с OCR Confidence Gate |
| AVR Document Line | Child Table | Строка АВР: cost_code, qty, unit_price, ocr_confidence |
| Physical Acceptance | Submittable | Физическая приёмка работ с фото |
| Bill of Quantities | Standard | Ведомость объёмов работ |
| KS-2 Act | Submittable | Акт о приёмке выполненных работ (казахстанская форма) |
| KS-3 Certificate | Submittable | Справка о стоимости выполненных работ |
| Approval Matrix Rule | Standard | Правило матрицы утверждений (сумма → уровень) |

### Custom Fields (в стандартные DocTypes)

| DocType | Поле | Тип | Назначение |
|---------|------|-----|-----------|
| Company | `bin_number` | Data | БИН юрлица (12 цифр) |
| Company | `legal_form` | Select | ТОО / ИП |
| Supplier | `bin_iin` | Data | БИН/ИИН контрагента |
| Supplier | `contractor_type` | Select | COMPANY / INDIVIDUAL |
| Project | `project_type` | Select | CONSTRUCTION / OFFICE |
| Project | `tolerance_pct` | Percent | Допустимое отклонение (30-50%) |
| Contract | `contract_direction` | Select | INCOMING / OUTGOING |
| Contract | `warranty_pct` | Percent | Гарантийное удержание % |
| Contract | `warranty_months` | Int | Срок гарантии (месяцы) |
| Purchase Order | `construction_object` | Link | Ссылка на объект строительства |
| Material Request | `construction_object` | Link | Ссылка на объект строительства |

---

## 4. Workflow (ERPNext стандартный механизм)

### Субподрядный workflow (переносим ADR-38 Task-per-Role)

```
[PM создаёт заявку]
     ↓
Material Request (DRAFT → Pending Approval)
     ↓
[Директор утверждает] ← Approval Matrix Rule
     ↓
Purchase Order (APPROVED → To Receive)
     ↓
[Казначей оплачивает аванс]
     ↓
Payment Entry (ADVANCE)
     ↓
[Прораб принимает работы]
     ↓
Physical Acceptance (DRAFT → ACCEPTED/DEFECTS)
     ↓
[Прораб создаёт АВР]
     ↓
AVR Document (DRAFT → SUBMITTED)
     ↓
[ПТО проверяет] → PTO_VERIFIED
[PM утверждает] → PM_APPROVED  
[Бухгалтерия проверяет] → ACCOUNTING_CHECKED
     ↓
AVR Document → COMMITTED
     ↓
[Казначей оплачивает]
     ↓
Payment Entry (PROGRESS) = AVR_amount × (1 - warranty_pct)
```

---

## 5. Permissions (RBAC)

ERPNext использует встроенную систему ролей. Маппинг:

| Наша роль | ERPNext Roles | Доступ |
|-----------|--------------|--------|
| Директор | System Manager, All | Всё |
| Зам. директора | Projects Manager, Purchase Manager | Своё направление |
| Начальник снабжения | Purchase Manager | Все закупки |
| Снабженец | Purchase User | Свои закупки |
| Прораб | Projects User | Свои проекты |
| Инженер ПТО | Projects User | ВОР, АВР, КС-2 |
| Казначей | Accounts User | Платежи |
| Бухгалтер | Accounts User | Проводки |
| Экономист | Accounts User | Отчёты, бюджеты |

Дополнительно: User Permissions для ограничения по Company / Project.

---

## 6. Интеграции

### 6.1 Gemini OCR
- Вызов через Frappe Background Job
- Вход: скан/фото счёта или АВР
- Выход: структурированные данные + confidence score
- Confidence Gate: ≥85% = auto-fill, <85% = manual review

### 6.2 1С Экспорт
- Периодическая выгрузка проводок в формате 1С
- Frappe Scheduled Job (ежедневно/еженедельно)
- Формат: XML или CSV по стандарту 1С:Бухгалтерия

### 6.3 WhatsApp Notifications (будущее)
- Frappe Notification framework
- Уведомления о заявках, утверждениях, платежах

---

## 7. Deployment

### Development
```
Docker Dev Container (VS Code)
  → frappe-bench
    → ERPNext v15
    → mides_construction (custom app)
```

### Production (варианты)
1. **Coolify** (self-hosted PaaS) — как в MidesCloud v3
2. **Frappe Cloud** — managed hosting от Frappe
3. **Docker Compose** на VPS — самостоятельный деплой
