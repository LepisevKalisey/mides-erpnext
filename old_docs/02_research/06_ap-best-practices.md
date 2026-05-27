# AP Best Practices — Строительный AP в мировых ERP

**Тип:** Research + Explanation  
**Дата:** 2026-05-21  
**Статус:** Финальный  
**Использован в:** ADR-45, ADR-21, docs/06_delivery/05_phase1-execution-plan.md

---

## 1. Мировой стандарт Four-Way Match

Во всех крупных строительных ERP (SAP S/4HANA, Oracle Primavera, Procore, Sage 300 CRE)
AP строится вокруг четырёхступенчатого сопоставления:

```
Contract / PO          →  Work Certificate / SES  →  Vendor Invoice      →  Payment Run
(Договор)                 (АВР / Приёмка работ)       (Счёт / Pay App)      (Оплата)
```

**Ключевой принцип:** Оплата — ПОСЛЕДНИЙ шаг цепочки, которая начинается с
физической приёмки работ. Никаких прямых оплат без подтверждённого объёма.

---

## 2. Два типа субподрядных платежей

### Advance Payment (Аванс)

Триггер: решение PM/ГИП до выполнения работ.

```
SAP:    Down Payment Request (F-47) → Down Payment (F-48) → Clearing при АВР (F-54)
Oracle: Advance Payment BP → workflow approve → clearing против Payment Requisition
Procore: Manual SOV line (no native module)
Sage:   AP Invoice + Debit Memo for recovery
```

Особенности:
- Создаёт дебиторский долг подрядчика перед компанией
- В SAP попадает в Special G/L (отдельный счёт, не основной AP)
- Требует банковской гарантии (10–15% договора)
- Погашается путём advance recovery при последующих АВР

### Progress Payment (Оплата по АВР)

Триггер: подтверждённый АВР (Application for Payment / Work Certificate).

```
SAP:    Service Entry Sheet (ML81N) → Invoice (MIRO) → Payment Run (F110)
Oracle: Payment Requisition BP → Certified Payment Certificate → AP Voucher
Procore: Payment Application → Invoice Admin approval → ERP export
Sage:   AP Invoice linked to Commitment → AP Check Run
```

---

## 3. Subcontractor Ledger (Лицевой счёт)

Центральный объект всех систем — баланс по договору:

```
CONTRACT: ТОО Монолит, Договор №123-2025, Объект А
──────────────────────────────────────────────────────
Сумма договора:                       10 000 000 ₸
──────────────────────────────────────────────────────
Авансы выплачено:                     -2 000 000 ₸
──────────────────────────────────────────────────────
АВР подтверждённые:                    3 500 000 ₸
  АВР #1 (апрель):       1 500 000 ₸
  АВР #2 (май):          2 000 000 ₸
──────────────────────────────────────────────────────
Гарантийное удержание (5%):             -175 000 ₸
──────────────────────────────────────────────────────
Оплачено по АВР:                      -1 200 000 ₸
──────────────────────────────────────────────────────
БАЛАНС К ВЫПЛАТЕ (AP):                 2 125 000 ₸
──────────────────────────────────────────────────────
Аванс непогашенный:                    1 300 000 ₸
```

**Формула:**
```
Net Payable = AVR_certified × (1 - retention%)
              - Advance_Recovery_to_date
              - Progress_Payments_Made
```

---

## 4. Advance Recovery

При каждом АВР автоматически вычитается часть аванса:

```
АВР #1: 1 500 000 ₸ (certified)
  − Гарантийное удержание (5%):   75 000 ₸
  − Аванс recovery (20% АВР):    300 000 ₸  ← автоматически
  = К выплате:                 1 125 000 ₸
```

Типичные условия (строительная норма):
- Аванс: 10–15% договора
- Recovery rate: 20% от каждого АВР
- Полное погашение: до 80% выполнения работ

**Автоматизация по системам:**

| Система | Автоматизация |
|---------|---------------|
| SAP S/4HANA | Автоматически через F-54 или Down Payment Chain |
| Oracle Unifier | Calculated Data Element в SOV (формула) |
| Oracle PCM | Manual deduction line на каждой Requisition |
| Procore | Manual SOV line — нет автоматизации |
| Sage 300 | Manual Debit Memo — нет автоматизации |

---

## 5. Оценка MidesCloud — соответствие и разрывы

### Полное соответствие ✅

| Мировой стандарт | MidesCloud |
|-----------------|------------|
| Thin anchor + task-per-role | `purchase_items` + task tables (ADR-38) |
| Payment type classification | `commitment_type: ADVANCE / SUBCONTRACT / RETENTION` |
| Retainage on contract | `contracts.warranty_percent` |
| Physical acceptance gate | `physical_acceptances` (Blueprint §5) |
| Approval → Payment chain | `commitment_approval_tasks` → `payment_tasks` |
| Partial payments | `payment_tasks PARTIAL` chain (ADR-43) |

### Разрывы ❌

| # | Разрыв | Приоритет | ADR |
|---|--------|-----------|-----|
| 1 | Нет contract_ledger VIEW | M2 | ADR-21 (расширить) |
| 2 | Форма аванса: договор вместо контрагента | **Slice 1.2** | ADR-45 |
| 3 | Аванс создаётся с SUBCONTRACT | **Slice 1.2** | ADR-45 |
| 4 | Баг: статус не обновляется у инициатора | **Slice 1.2** | ADR-45 |
| 5 | Нет advance recovery | M3 (с АВР-модулем) | Будущий ADR |
| 6 | Нет SOV (Schedule of Values) | M3 | Будущий ADR |
| 7 | Нет compliance gating (ЭСФ) | M2 | ADR-15 (расширить) |

---

## 6. Что MidesCloud делает лучше Procore и Sage

| Функция | SAP | Oracle | Procore | Sage | MidesCloud |
|---------|-----|--------|---------|------|------------|
| Task-per-role | ✅ | ✅ | ❌ | ❌ | ✅ |
| Ретроспективные операции | ❌ | ❌ | ❌ | ❌ | ✅ |
| Thin anchor + typed tasks | ✅ | ✅ | ❌ | ❌ | ✅ |
| Бенефициарный контроль | ✅ | ❌ | ❌ | ❌ | ✅ |
| Multi-entity (ТОО+ИП) | ✅ | ✅ | ❌ | ❌ | ✅ (план) |

---

## Источники

Исследование проведено 2026-05-21 путём анализа документации:
SAP Help Portal (MM/FI/PS модули), Oracle Primavera PCM/Unifier docs,
Procore Developer Portal, Sage 300 CRE Knowledge Base.
