# Дорожная карта: MidesCloud на ERPNext

**Статус:** ACTIVE  
**Дата:** 2026-05-26  
**Принцип:** Закон Голла — каждая сложная работающая система выросла из простой работающей системы

---

## Обзор фаз

| Фаза | Название | Длительность | Зависимости |
|------|----------|-------------|-------------|
| Ф0 | Environment & Foundation | 1-2 недели | — |
| Ф1 | Core Setup & Localization | 1-2 недели | Ф0 |
| Ф2 | Custom App: Foundation | 2-3 недели | Ф1 |
| Ф3 | Subcontract Pipeline (E2E) | 3-4 недели | Ф2 |
| Ф4 | Purchase Order Pipeline | 2-3 недели | Ф3 |
| Ф5 | Revenue & Billing | 2-3 недели | Ф4 |
| Ф6 | Financial Control & Reports | 2 недели | Ф5 |
| Ф7 | HR & Payroll | 2-3 недели | Ф2 |
| Ф8 | Integrations & Polish | 2-3 недели | Ф6 |

**Общий срок:** ~16-22 недели (~4-5 месяцев)

---

## Ф0: Environment & Foundation (1-2 недели)

### Цель
Рабочее окружение разработки ERPNext с кастомным приложением.

### Задачи
- [ ] Установить Docker + Dev Container для ERPNext v15
- [ ] Создать Frappe bench с ERPNext
- [ ] Создать custom app: `bench new-app mides_construction`
- [ ] Установить app на site: `bench --site site.local install-app mides_construction`
- [ ] Настроить Git-репозиторий для `mides_construction`
- [ ] Настроить `.editorconfig`, `.gitignore`
- [ ] Проверить hot-reload и developer mode
- [ ] Документировать setup-from-scratch

### Результат
ERPNext запущен локально, custom app создан и подключён.

---

## Ф1: Core Setup & Localization (1-2 недели)

### Цель
ERPNext настроен для работы строительной компании в Казахстане.

### Задачи
- [ ] Установить язык системы: Русский
- [ ] Создать компании: ТОО МиДЭС + ИП (3-5 штук)
- [ ] Настроить валюту KZT как base currency
- [ ] Настроить Chart of Accounts для каждой компании
- [ ] Настроить Fiscal Year (календарный год)
- [ ] Добавить custom fields к Company: BIN, legal_form
- [ ] Добавить custom fields к Supplier: BIN/IIN, contractor_type
- [ ] Настроить роли и User Permissions
- [ ] Импортировать переводы строительной терминологии (ru.csv)
- [ ] Создать тестовых пользователей (Директор, PM, Снабженец, Прораб, Казначей, ПТО)

### Результат
Можно войти в систему, переключаться между компаниями, видеть русский интерфейс.

---

## Ф2: Custom App — Foundation DocTypes (2-3 недели)

### Цель
Все базовые строительные DocTypes созданы и работают.

### Задачи
- [ ] Создать DocType: `Construction Object` (child of Project)
  - Поля: object_type (CIVIL/MEP), address, area_sqm, floors
- [ ] Создать DocType: `Construction Cost Code` (67 позиций)
  - Поля: section, category, work_type, tags
  - Импорт из `old_docs/08_reference/05_cost-codes.csv`
- [ ] Создать DocType: `Beneficial Owner` (link to Supplier)
  - Поля: full_name, ownership_pct, iin
- [ ] Создать DocType: `Contract Item` (SOV)
  - Поля: contract (Link), cost_code (Link), description, qty, unit, unit_price, total_amount
- [ ] Создать DocType: `Approval Matrix Rule`
  - Поля: company, amount_from, amount_to, approver_role, approver_user
- [ ] Добавить custom fields к Project: project_type, tolerance_pct
- [ ] Добавить custom fields к Contract: direction, warranty_pct, warranty_months
- [ ] Добавить custom fields к Purchase Order / Material Request: construction_object
- [ ] Настроить Workflow для Contract: INTENT → SIGNED → ACTIVE → CLOSED/TERMINATED
- [ ] Создать Fixtures для предустановленных данных
- [ ] Написать тесты для каждого DocType

### Результат
Справочники строительной компании полностью настроены. Можно создавать проекты с объектами, контрагентов с бенефициарами, договоры с позициями.

---

## Ф3: Subcontract Pipeline — End-to-End (3-4 недели)

### Цель
Полный субподрядный цикл: заявка → утверждение → оплата → приёмка → АВР → COMMITTED.

### Задачи

#### 3.1 Заявка и утверждение
- [ ] Настроить Material Request workflow для субподрядных заявок
- [ ] Реализовать Approval Matrix (валидация через server script)
- [ ] Создать Purchase Order из approved Material Request
- [ ] Настроить уведомления Директору об ожидающих заявках

#### 3.2 Платежи
- [ ] Настроить Payment Entry для авансов
- [ ] Реализовать расчёт гарантийного удержания (warranty_pct)
- [ ] Создать Payment Schedule в Purchase Order

#### 3.3 Физическая приёмка
- [ ] Создать DocType: `Physical Acceptance`
  - Поля: project, object, contractor, work_description, photos (Attach Many), status (ACCEPTED/DEFECTS), defect_notes, accepted_by, accepted_date
  - Workflow: DRAFT → ACCEPTED / DEFECTS_FOUND
- [ ] Link Physical Acceptance → Purchase Order

#### 3.4 АВР (Акт выполненных работ)
- [ ] Создать DocType: `AVR Document` (Submittable)
  - Поля: contract, project, object, contractor, document_type (AVR/AVR_ADJUSTMENT), total_amount, data_status (DRAFT/SUBMITTED/PTO_VERIFIED/PM_APPROVED/ACCOUNTING_CHECKED/COMMITTED)
  - Child Table: `AVR Document Line` — cost_code, description, unit, qty, unit_price, amount, ocr_confidence, needs_manual_review, manually_reviewed
- [ ] Реализовать OCR Confidence Gate (порог 85%)
- [ ] Реализовать multi-step verification workflow:
  ```
  DRAFT → SUBMITTED (PM) → PTO_VERIFIED (ПТО) → 
  PM_APPROVED (PM) → ACCOUNTING_CHECKED (Бухг.) → COMMITTED
  ```
- [ ] Link AVR Document → Physical Acceptance → Payment Entry

#### 3.5 Лицевой счёт подрядчика
- [ ] Создать Custom Report: `Subcontractor Ledger`
  - Формула: Net Payable = AVR_certified × (1 - retention%) − Advance_Recovery − Payments_Made
  - Группировка: по проектам и глобально
- [ ] Создать Dashboard View для казначея

### Результат
Можно провести полный субподрядный цикл от заявки до оплаты. Казначей видит лицевой счёт.

---

## Ф4: Purchase Order Pipeline (2-3 недели)

### Цель
Полный закупочный цикл: Material Request → RFQ → PO → GRN → Payment.

### Задачи
- [ ] Настроить Material Request → RFQ → Supplier Quotation → PO
- [ ] Настроить складской учёт по проектам (Warehouse per Project)
- [ ] Настроить Purchase Receipt (GRN) с привязкой к project/object
- [ ] Реализовать Three-Way Match: PO ↔ Receipt ↔ Invoice
- [ ] Настроить ретроспективные закупки (прораб уже потратил наличные)
- [ ] Создать Expense Claim для ретро-расходов

### Результат
Стандартный P2P-цикл ERPNext настроен для строительной компании.

---

## Ф5: Revenue & Billing (2-3 недели)

### Цель
Биллинг заказчика: АВР → ВОР → КС-2 → КС-3.

### Задачи
- [ ] Создать DocType: `Bill of Quantities` (ВОР)
  - Поля: project, object, items (child table с cost_codes, volumes, prices)
- [ ] Создать DocType: `KS-2 Act` (Submittable)
  - Поля: contract (INCOMING), period_from, period_to, items, total_amount
  - Автозаполнение из AVR Documents за период
- [ ] Создать DocType: `KS-3 Certificate` (Submittable)
  - Поля: contract, ks2_acts (link), cumulative_total, current_period
- [ ] Связать КС-2 → Sales Invoice для биллинга
- [ ] Создать Print Format для КС-2 и КС-3 (казахстанская форма)
- [ ] Реализовать расчёт маржи: Revenue (КС-2) − Cost (AVR + PO)

### Результат
Можно выставлять заказчику КС-2/КС-3 на основе выполненных работ.

---

## Ф6: Financial Control & Reports (2 недели)

### Задачи
- [ ] Настроить Budget per Project / Cost Center
- [ ] Создать Custom Report: `Project Budget vs Actual`
- [ ] Создать Custom Report: `Project Margin Report`
- [ ] Создать Custom Report: `WIP Report` (Work in Progress)
- [ ] Настроить Dashboard для Директора (KPI карточки)
- [ ] Настроить алерты при превышении бюджета

---

## Ф7: HR & Payroll (2-3 недели, параллельно с Ф5-Ф6)

### Задачи
- [ ] Настроить Employee с привязкой к проекту
- [ ] Настроить Attendance для табелирования
- [ ] Настроить Timesheet с привязкой к cost_code
- [ ] Настроить Payroll с компонентами ЗП для Казахстана
- [ ] Поддержка сезонных рабочих (employment_type = Temporary)

---

## Ф8: Integrations & Polish (2-3 недели)

### Задачи
- [ ] Реализовать Gemini OCR интеграцию (Background Job)
- [ ] Реализовать 1С экспорт (XML/CSV)
- [ ] Настроить Email/WhatsApp уведомления
- [ ] Оптимизировать производительность
- [ ] Провести User Acceptance Testing
- [ ] Деплой на production (Frappe Cloud / Docker)

---

## Риски (Pre-Mortem)

| # | Риск | Вероятность | Митигация |
|---|------|-------------|-----------|
| 1 | ERPNext UI не подходит для строительной специфики | Средняя | Custom Print Formats + Client Scripts |
| 2 | Frappe Framework сложнее, чем ожидалось | Средняя | Документация + Community, поэтапное освоение |
| 3 | Русские переводы ERPNext неточные | Высокая | Custom translations в `mides_construction` |
| 4 | Multi-company усложняет отчёты | Средняя | Company-filtered reports, User Permissions |
| 5 | OCR интеграция сложна в Frappe | Низкая | Background Jobs + API, опыт из MidesCloud v3 |
| 6 | 1С интеграция требует специфических знаний | Высокая | Простой CSV-экспорт на первом этапе |
