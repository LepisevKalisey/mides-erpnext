# Page Spec: АВР Документ + OCR Gate [C.2]

**Status:** IMPLEMENTED  
**Slice:** [C.2] — АВР + OCR Gate  
**Component:** `AvrDocumentSheet.tsx`  
**Actions:** `avr-ocr-actions.ts`  
**Schema:** `avr-acceptance.ts` (расширен)  
**Migration:** `0013_avr_documents_ocr_gate.sql`

## Назначение

AvrDocumentSheet — Sheet-панель (slide from right) для создания и редактирования АВР документа с OCR confidence gate. Открывается из CommitmentDetailsSheet при SUBCONTRACT заявках, прошедших утверждение Директора.

## Роли и доступ

| Роль | Действие |
|------|----------|
| PROJECT_MANAGER | Создать АВР, добавить строки, подтвердить данные → SUBMITTED |
| PTO_ENGINEER | Просмотреть строки, утвердить → COMMITTED или отклонить |
| DIRECTOR / ADMIN | Все действия |

## Lifecycle данных (Blueprint §5.2)

```
DRAFT → [пользователь заполняет строки + проверяет low-confidence] →
confirmAvrData() → SUBMITTED → [ПТО проверяет] →
approveAvrDocument() → COMMITTED (данные заблокированы)
```

## OCR Confidence Gate (Митигация Риска #4)

| Confidence | Отображение | Блокировка |
|-----------|-------------|------------|
| ≥ 85% | 🟢 Зелёный бейдж "OCR XX% ✅" | Нет |
| < 85% | 🔴 Красный бейдж "OCR XX% ⚠️ Проверьте" + красный фон строки | Да — кнопка "Подтвердить данные" заблокирована |

- Пользователь ОБЯЗАН нажать "Проверено" на каждой low-confidence строке
- Только после этого кнопка "Подтвердить данные" разблокируется
- **Нет автоматического SUBMITTED** — всегда ручное подтверждение

## ADR-41 Инвариант

`cost_code_id` ТОЛЬКО в `avr_document_lines`. NOT NULL.  
Каждая строка АВР обязательно содержит код затрат из справочника `cost_codes`.

## UI Элементы

### Заголовок Sheet
- Иконка FileText + "АВР — Акт выполненных работ"
- Описание заявки (purchaseItemDescription)
- Loading spinner

### Статус бейджи
- `DRAFT` — серый бейдж "DRAFT — редактирование"
- `SUBMITTED` — синий бейдж "SUBMITTED — ждёт ПТО"
- `COMMITTED` — зелёный бейдж "COMMITTED — данные заблокированы" + Shield иконка

### OCR Gate Banner
Показывается когда `linesRequiringAttention > 0`:
- Красный блок с AlertTriangle
- Текст: "Требуется ручная проверка: N строк"
- Инструкция про порог 85%

### Сводка
- Сумма заявки (if amountRequested)
- Итог по АВР (SUM строк)
- Дата COMMITTED (if committed)

### Строки АВР (AvrLineRow)
Каждая строка — expandable card:
- Заголовок: OCR confidence badge + номер строки + название + cost code
- Сумма строки
- Детали (при expand): единица, кол-во, цена/ед
- Если requiresAttention: красный блок + кнопка "Проверено"

### Форма добавления строки (AddLineForm)
- Dropdown: код затрат из `cost_codes` (ADR-41 — обязательно)
- Текст: описание работ
- Единица измерения, Количество, Цена/ед
- Сумма (автовычисляется qty × price)

### OCR Demo
Кнопка для тестирования без реального OCR. Создаёт 3 строки с confidence 92% / 71% / 88%.  
Строка с 71% требует ручной проверки (наглядно демонстрирует OCR gate).

### Действия

**ПМ (DRAFT)**:
- Кнопка "Добавить строку"
- Кнопка "OCR Demo"
- Кнопка "Подтвердить данные → Отправить на проверку ПТО" (заблокирована если есть непроверенные строки)

**ПТО (SUBMITTED)**:
- Кнопка "Утвердить АВР → COMMITTED"
- Кнопка "Вернуть" (→ textarea для причины → "Отклонить")

**COMMITTED**:
- Зелёный блок со Shield: "Данные заблокированы. АВР утверждён ПТО."

## Database Schema (C.2 расширения)

### avr_tasks (новые колонки)
| Колонка | Тип | Описание |
|---------|-----|----------|
| `data_status` | `avr_data_status` ENUM | DRAFT / SUBMITTED / COMMITTED |
| `document_type` | `avr_document_type` ENUM | AVR / AVR_ADJUSTMENT |
| `parent_avr_id` | uuid FK → self | Для корректировочных АВР |
| `total_amount` | numeric(18,2) | Кешированный итог строк |
| `submitted_at` | timestamptz | Когда нажали "Подтвердить данные" |
| `confirmed_by` | text | user_id кто подтвердил |
| `committed_at` | timestamptz | Когда данные заблокированы |
| `physical_acceptance_id` | uuid FK → acceptance_tasks | Привязка к физической приёмке |

### avr_document_lines (новые колонки)
| Колонка | Тип | Описание |
|---------|-----|----------|
| `ocr_confidence` | numeric(5,2) CHECK | OCR уверенность 0–100, NULL = ручной ввод |
| `needs_manual_review` | boolean | true если confidence < 85 |
| `manually_reviewed` | boolean | Пользователь подтвердил строку |
| `line_number` | integer | Порядковый номер из документа |
| `cost_code_id` | uuid FK NOT NULL | ADR-41 ОБЯЗАТЕЛЬНО |

## current_stage_view (обновление)

Добавлены новые стадии в иерархию:
1. `COMMITTED` — avr_tasks.data_status = 'COMMITTED' (высший приоритет после PAID)
2. `AVR_SUBMITTED` — avr_tasks.data_status = 'SUBMITTED'
3. Остальные стадии без изменений

## Связанные документы

- `docs/03_decisions/41_cost-code-at-avr-line-level.md` — ADR-41
- `docs/06_delivery/05_phase1-execution-plan.md` — секция [C.2]
- `docs/01_product/01_system-blueprint.md` — §5.2, §8 инвариант #3
