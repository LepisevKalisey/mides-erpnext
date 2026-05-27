# ADR-022: Рабочее место снабженца — Sourcing Workspace

**Status:** Accepted  
**Date:** 2026-05-07

## Context

Работа снабженца с позицией сейчас происходит вне системы.
Нет видимости процесса, нет истории, нет рекомендаций.

Задача: сделать системную «рабочую среду» снабженца без усложнения — 
вместо принудительных форм — удобный сайдбар с возможностью загружать 
полученные счета/КП и автоматически извлекать из них данные.

## Decision

### 1. Два вида: Table и Kanban

Снабженец переключается между видами:

**Table view** — для фильтрации и анализа (срочность, объект, тип):
```
| Позиция        | Объект      | Срок    | Кол-во котировок | Статус      |
|----------------|-------------|---------|------------------|-------------|
| Арматура д12   | ЖК Мирас    | 15.05   | 2/3              | IN_SOURCING |
| Цемент М400    | ЖК Парк     | 12.05   | 0                | IN_SOURCING |
```

**Kanban view** — по этапам `sourcing_stage`:
```
[INITIAL]        [QUOTES_COLLECTING]      [COMPARISON]       [SELECTED]
  Цемент М400      Арматура д12              ...                 ...
```

### 2. Сайдбар (Sidebar) при нажатии на позицию

Сайдбар открывается поверх основного вида. Содержит:

```
┌─────────────────────────────────────────────┐
│ 📦 Арматура д12 — 5 тонн                    │
│ Объект: ЖК Мирас | Срок: 15.05.2026         │
│ Инициатор: Иванов А. | Примечание: «срочно»  │
│                                             │
│ ─── КОТИРОВКИ ──────────────────────────── │
│ [+ Загрузить счёт/КП]                       │
│                                             │
│  ТОО МеталлСталь  4 500 000₸  7 дней ◉     │
│  ИП Серикбаев     4 800 000₸  5 дней ○     │
│  [Ещё не распознан...]          loading...  │
│                                             │
│ ─── ОБОСНОВАНИЕ ВЫБОРА ─────────────────── │
│ «МеталлСталь — есть наличие, проверенный»   │
│ [редактировать]                             │
│                                             │
│ ─── 💡 РЕКОМЕНДАЦИЯ СИСТЕМЫ ─────────────── │
│ Эта позиция заказывалась 3 мес. назад       │
│ Поставщик: ТОО МеталлСталь, цена 4 100₸/т  │
│ [Использовать того же поставщика]           │
│                                             │
│ ─── ИСТОРИЯ ───────────────────────────── │
│  02.05  Загружен счёт ИП Серикбаев         │
│  02.05  Загружен счёт МеталлСталь          │
│  01.05  Позиция принята в работу           │
└─────────────────────────────────────────────┘
```

### 3. Загрузка счёта/КП с OCR-распознаванием

**Процесс:**
1. Снабженец получил КП/счёт (фото, PDF, WhatsApp) → загружает в систему
2. Файл сохраняется в Supabase Storage
3. Edge Function вызывает OCR API (Google Document AI / Azure Form Recognizer)
4. Из документа извлекаются: название поставщика, позиции, цены, сроки, контакт
5. Снабженец видит предзаполненную карточку котировки → подтверждает или правит
6. Данные сохраняются в `sourcing_quotes`

**Если OCR не справился** — снабженец заполняет вручную. OCR — ускорение, не замена.

**Поддерживаемые форматы:** JPG/PNG (фото со стола), PDF, DOCX.

#### Схема `sourcing_quotes`

```sql
CREATE TABLE midescloud.sourcing_quotes (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_item_id UUID NOT NULL REFERENCES midescloud.purchase_items(id),
  
  -- Поставщик
  contractor_id    UUID REFERENCES midescloud.contractors(id),
  contractor_name  TEXT NOT NULL,           -- из OCR или ввод вручную
  
  -- Данные котировки
  amount           NUMERIC,
  unit_price       NUMERIC,
  delivery_days    INT,
  payment_terms    TEXT,
  valid_until      DATE,
  
  -- Файл и OCR
  file_url         TEXT,                   -- Supabase Storage URL
  ocr_raw          JSONB,                  -- сырой ответ OCR для аудита
  ocr_confidence   NUMERIC,               -- 0–1, уровень уверенности
  ocr_status       TEXT DEFAULT 'PENDING', -- PENDING | DONE | FAILED | MANUAL
  
  -- Выбор
  is_selected      BOOLEAN DEFAULT false,
  
  created_by       TEXT REFERENCES midescloud.user(id),
  created_at       TIMESTAMPTZ DEFAULT now(),
  updated_at       TIMESTAMPTZ DEFAULT now()
);
```

### 4. Обоснование выбора

Простое текстовое поле `selection_reason` в `purchase_items`.
Обязательно для заполнения перед переводом в `PO_PENDING_APPROVAL`.

```sql
ALTER TABLE midescloud.purchase_items
  ADD COLUMN selection_reason      TEXT,
  ADD COLUMN selected_quote_id     UUID REFERENCES midescloud.sourcing_quotes(id),
  ADD COLUMN sourcing_stage        TEXT DEFAULT 'INITIAL',
  ADD COLUMN quotes_count          INT DEFAULT 0;
```

### 5. История сравнения

Все загруженные котировки (включая невыбранные) хранятся постоянно.
Сайдбар показывает вкладку «История котировок» — side-by-side таблица по всем вариантам.
При утверждении PO директор видит ту же таблицу.

### 6. Система рекомендаций (Purchase History Intelligence)

Когда позиция переходит в `IN_SOURCING`, система ищет:

```sql
-- Похожие позиции из прошлых закупок
SELECT 
  sq.contractor_name,
  sq.amount,
  sq.unit_price,
  sq.delivery_days,
  pi.name as item_name,
  pi.created_at as ordered_at
FROM midescloud.sourcing_quotes sq
JOIN midescloud.purchase_items pi ON pi.id = sq.purchase_item_id
WHERE sq.is_selected = true
  AND sq.created_at > now() - INTERVAL '12 months'
  AND (
    pi.name ILIKE '%' || $search_term || '%'
    OR pi.category = $category
  )
ORDER BY sq.created_at DESC
LIMIT 3;
```

Рекомендация отображается в сайдбаре как информационный блок, не принуждение.
Снабженец может нажать «Использовать того же поставщика» → предзаполнится карточка.

### Технические компоненты

| Компонент | Решение |
|---|---|
| Хранение файлов | Supabase Storage, bucket `quotes` |
| OCR | Supabase Edge Function → Google Document AI (Русский язык) |
| Kanban UI | `@hello-pangea/dnd` или `dnd-kit` |
| Sidebar | Radix UI Sheet (shadcn/ui) |
| Рекомендации | SQL полнотекстовый поиск (pg_trgm) |

## Consequences

- **+** Снабженец работает в системе, а не в телефоне
- **+** Директор при утверждении видит обоснование и альтернативы
- **+** История закупок накапливается и работает как база знаний
- **+** OCR устраняет ручной ввод для большинства случаев
- **−** OCR требует отдельного API (стоимость за вызовы), нужен выбор провайдера
- **−** Качество OCR зависит от качества фото счёта (обучение пользователей)

## Related

- See: `docs/03_decisions/12_purchase-item-lifecycle.md`
- See: `docs/03_decisions/11_dual-path-p2p-workflow.md`
