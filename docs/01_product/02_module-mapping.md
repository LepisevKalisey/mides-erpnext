# Маппинг модулей: MidesCloud v3 → ERPNext

**Статус:** ACTIVE  
**Дата:** 2026-05-26

---

## Принцип маппинга

ERPNext покрывает ~80% потребностей из коробки. Оставшиеся 20% — кастомный Frappe-app `mides_construction` для строительной специфики Казахстана.

---

## 1. Foundation (M0) — Базовые справочники

| MidesCloud v3 | ERPNext (стандарт) | Кастомизация |
|---------------|-------------------|--------------|
| `legal_entities` | **Company** (multi-company) | Custom fields: BIN, legal_form (ТОО/ИП) |
| `bank_accounts` | **Bank Account** | Готово из коробки |
| `projects` | **Project** | Custom fields: project_type (CONSTRUCTION/OFFICE), tolerance_pct |
| `project_objects` | **Project** (child) или Custom DocType | **Custom DocType: `Construction Object`** (Общестрой/Инж.сети) |
| `contractors` | **Supplier** | Custom fields: BIN/IIN, contractor_type |
| `beneficial_owners` | Custom DocType | **Custom DocType: `Beneficial Owner`** (link to Supplier) |
| `employees` | **Employee** | Custom fields: system_role enum |
| `cost_codes` | **Cost Center** + Custom | **Custom DocType: `Construction Cost Code`** (раздел/категория/вид работ/теги) |
| `contracts` | **Contract** (ERPNext standard) | Custom fields: contract_direction (INCOMING/OUTGOING), warranty_pct, warranty_months |
| `project_assignments` | **Project** → members table | Custom fields: project_role enum |

### Выигрыш от ERPNext:
- ✅ Multi-company из коробки с консолидацией
- ✅ Chart of Accounts для каждой компании
- ✅ Bank Account management
- ✅ Employee с HR-модулем
- ✅ Supplier management с рейтингом

---

## 2. P2P / Procurement (M1) — Закупки

| MidesCloud v3 | ERPNext (стандарт) | Кастомизация |
|---------------|-------------------|--------------|
| `purchase_items` (thin anchor) | **Material Request** → **Purchase Order** → **Purchase Receipt** → **Purchase Invoice** | Workflow customization |
| `sourcing_tasks` | **Request for Quotation** → **Supplier Quotation** | Готово из коробки |
| `commitment_approval_tasks` | **Workflow** на Material Request / PO | Custom Approval Matrix |
| `payment_tasks` | **Payment Entry** | Custom fields: payment_schedule |
| `doc_collection_tasks` | Custom DocType | **Custom DocType: `Document Collection Task`** |
| `accounting_tasks` | Не нужен (ERPNext = бухгалтерия) | — |
| `advance_workflow()` | **Workflow** (Frappe built-in) | Настройка состояний и переходов |

### P2P конвейер в ERPNext:
```
Material Request → (Approval Workflow) → 
  Request for Quotation → Supplier Quotation → 
    Purchase Order → Purchase Receipt → 
      Purchase Invoice → Payment Entry
```

### Выигрыш от ERPNext:
- ✅ Полный P2P-цикл из коробки
- ✅ Three-Way Match (PO ↔ Receipt ↔ Invoice)
- ✅ Multi-currency purchasing
- ✅ Supplier Scorecard
- ✅ Approval Workflows с levels

---

## 3. Субподряд (часть M1)

| MidesCloud v3 | ERPNext (стандарт) | Кастомизация |
|---------------|-------------------|--------------|
| Subcontract commitment | **Subcontracting Order** | Адаптация под строительный субподряд |
| `acceptance_tasks` | Custom DocType | **Custom DocType: `Physical Acceptance`** |
| `avr_tasks` | Custom DocType | **Custom DocType: `AVR Document`** (Акт выполненных работ) |
| `avr_document_lines` | Child Table для AVR Document | С полями: cost_code, qty, unit_price, ocr_confidence |
| Гарантийное удержание | **Purchase Invoice** → deductions | Custom calculation logic |
| Лицевой счёт | Custom Report | **Custom Report: `Subcontractor Ledger`** |
| `contract_items` (SOV) | Custom DocType | **Custom DocType: `Contract Item`** (Schedule of Values) |

### Субподрядный конвейер в ERPNext:
```
Contract (OUTGOING) → Contract Items (SOV) →
  [PM создаёт заявку] → Approval (Director) →
    Payment Entry (Advance) →
      Physical Acceptance (Прораб) →
        AVR Document (+ OCR Gate) →
          PTO Verification → PM Approval →
            Accounting Check → COMMITTED →
              Payment Entry (Progress - Retention%)
```

### Что нужно создать:
- `AVR Document` — Custom DocType с OCR
- `Physical Acceptance` — Custom DocType с фото
- `Contract Item` — SOV (Schedule of Values)
- `Subcontractor Ledger` — Custom Report

---

## 4. Revenue / Биллинг заказчика (M3)

| MidesCloud v3 | ERPNext (стандарт) | Кастомизация |
|---------------|-------------------|--------------|
| Incoming Contract | **Contract** (direction=INCOMING) | Custom fields |
| ВОР (Bill of Quantities) | Custom DocType | **Custom DocType: `Bill of Quantities`** |
| КС-2 (Work Completion Act) | Custom DocType | **Custom DocType: `KS-2 Act`** |
| КС-3 (Cost Certificate) | Custom DocType | **Custom DocType: `KS-3 Certificate`** |
| Biллинг | **Sales Invoice** | Настройка для строительного биллинга |

---

## 5. Financial Management (M4)

| MidesCloud v3 | ERPNext (стандарт) | Кастомизация |
|---------------|-------------------|--------------|
| Budget vs Actual | **Budget** module | Project-based budgets |
| WIP Report | **Project** → P&L | Custom Report |
| Маржинальность | **Gross Profit** report | Custom строительный отчёт |
| 1С интеграция | Custom Integration | **Frappe Integration** (API/export) |

### Выигрыш от ERPNext:
- ✅ Полноценный бухучёт из коробки
- ✅ Budget management per Cost Center
- ✅ Project Profitability reports
- ✅ Multi-company consolidation

---

## 6. HR (M6)

| MidesCloud v3 | ERPNext (стандарт) | Кастомизация |
|---------------|-------------------|--------------|
| Табелирование | **Attendance** + **Timesheet** | Custom fields: project, cost_code |
| Зарплата | **Payroll Entry** | Настройка компонентов ЗП |
| Сезонные рабочие | **Employee** (temporary) | Employment type customization |

---

## 7. Склад (M5)

| MidesCloud v3 | ERPNext (стандарт) | Кастомизация |
|---------------|-------------------|--------------|
| Не реализовано | **Stock** module (полностью) | Warehouse per Project/Object |
| — | **Stock Entry** (Material Transfer) | Transfer between project sites |
| — | **Stock Reconciliation** | Инвентаризация |

### Выигрыш от ERPNext:
- ✅ Полноценный складской учёт из коробки
- ✅ Склады по проектам
- ✅ Серийные номера, партии
- ✅ Автоматический учёт себестоимости

---

## Сводная таблица: что из коробки vs что кастомить

| Категория | ERPNext Standard | Custom App |
|-----------|-----------------|------------|
| Multi-company | ✅ | Custom fields (BIN, legal_form) |
| Справочники | ✅ 90% | Construction Object, Cost Code, Beneficial Owner |
| P2P Закупки | ✅ 95% | Approval Matrix, retro-expenses |
| Субподряд | ⚠️ 40% | AVR, Physical Acceptance, SOV, Ledger |
| Revenue/Биллинг | ⚠️ 30% | КС-2, КС-3, ВОР |
| Бухучёт | ✅ 90% | 1С интеграция |
| HR | ✅ 80% | Строительная табель |
| Склад | ✅ 95% | Warehouse per project |
| OCR/AI | ❌ 0% | Gemini OCR Edge Function |
| Отчёты | ✅ 60% | Строительные отчёты |
