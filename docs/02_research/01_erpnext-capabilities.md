# Исследование: Возможности ERPNext для строительной компании

**Статус:** ACTIVE  
**Дата:** 2026-05-26  
**Тип:** explanation

---

## 1. Что даёт ERPNext из коробки

### Модули, релевантные для строительства

| Модуль | Готовность | Примечание |
|--------|-----------|------------|
| **Accounts** | ✅ 95% | Chart of Accounts, GL, AP/AR, Bank Reconciliation |
| **Buying** | ✅ 90% | Material Request → RFQ → PO → Receipt → Invoice |
| **Stock** | ✅ 95% | Warehouse, Stock Entry, Inventory, Valuation |
| **Projects** | ⚠️ 70% | Project, Task, Timesheet — но нет строительной специфики |
| **HR** | ✅ 85% | Employee, Attendance, Leave, Payroll |
| **Payroll** | ✅ 80% | Salary Structure, Payroll Entry — нужна адаптация |
| **Subcontracting** | ⚠️ 50% | Есть, но для manufacturing, не для строительства |
| **Workflow** | ✅ 90% | States, Transitions, Actions — мощный механизм |
| **Permissions** | ✅ 95% | Role-Based + User Permissions per Company/Project |

### Ключевые преимущества ERPNext

1. **Double-Entry Accounting** — полноценный бухучёт, журнал проводок, баланс
2. **Multi-Company** — несколько юрлиц в одной системе с консолидацией
3. **Workflow Engine** — визуальное проектирование бизнес-процессов
4. **Print Format** — кастомные формы печати (Jinja2 + HTML)
5. **Report Builder** — конструктор отчётов без кода
6. **REST API** — полный API для интеграций
7. **Background Jobs** — Redis Queue для фоновых задач (OCR, экспорт)
8. **Notification Framework** — Email, SMS, системные уведомления

---

## 2. Что нужно создать кастомно

### Строительная специфика Казахстана (не существует в мире ERPNext)

| Функция | Причина | Решение |
|---------|---------|---------|
| АВР (Акт выполненных работ) | Казахстанская форма, нет аналога | Custom DocType |
| КС-2 / КС-3 | Казахстанская отчётность, нет аналога | Custom DocType + Print Format |
| ВОР | Специфика строительного учёта | Custom DocType |
| Физическая приёмка работ | Нет в стандарте | Custom DocType |
| БИН/ИИН | Казахстанская идентификация | Custom Fields |
| Строительные коды затрат | Специфика отрасли | Custom DocType |
| Лицевой счёт подрядчика | Строительная практика | Custom Report |
| Гарантийное удержание (%) | Строительная практика | Custom Logic |
| OCR Confidence Gate | AI-фича из MidesCloud v3 | Custom Integration |

### Оценка объёма кастомной разработки

| Компонент | Объём | Сложность |
|-----------|-------|-----------|
| Custom Fields (стандартные DocTypes) | ~15 полей | Низкая |
| Custom DocTypes (новые) | ~11 DocTypes | Средняя |
| Workflows | ~3 workflow | Низкая |
| Custom Reports | ~4 отчёта | Средняя |
| Print Formats (КС-2, КС-3) | ~2 формата | Средняя |
| Server Scripts | ~5 скриптов | Средняя |
| Integrations (OCR, 1С) | ~2 интеграции | Высокая |
| Translations | ~200 строк | Низкая |

---

## 3. Сравнение: Custom Dev vs ERPNext

| Критерий | MidesCloud v3 (Custom) | ERPNext + Custom App |
|----------|----------------------|---------------------|
| Время до MVP | 12-18 месяцев | 4-5 месяцев |
| Бухучёт | С нуля (~3 мес) | Из коробки |
| Склад | С нуля (~2 мес) | Из коробки |
| HR/Payroll | С нуля (~2 мес) | Из коробки |
| P2P Закупки | Частично (1.5 мес ещё) | Из коробки + настройка |
| Субподряд | Частично (2 мес ещё) | Custom App (~1 мес) |
| КС-2/КС-3 | С нуля (~1 мес) | Custom App (~2 нед) |
| Отчёты | С нуля (~2 мес) | Report Builder + Custom |
| UI гибкость | ✅ Полная (React) | ⚠️ Ограниченная (Frappe UI) |
| Масштабируемость | ⚠️ Один разработчик | ✅ Сообщество ERPNext |
| Обновления | ❌ Вручную | ✅ `bench update` |

---

## 4. Frappe Framework — ключевые концепции

### DocType = Модель данных + UI + API
- Определение через JSON (или UI)
- Автоматическое создание таблицы БД
- Автоматическая генерация REST API
- Автоматическая генерация формы
- Permission Rules встроены

### Hooks = Расширение без изменения ядра
```python
# hooks.py
doc_events = {
    "Purchase Order": {
        "on_submit": "mides_construction.api.warranty.calculate_warranty"
    }
}
```

### Workflow = Визуальные состояния
- States → Transitions → Actions
- Role-based transitions
- Условия (if amount > X → require Y)

### Fixtures = Предустановленные данные
- Custom Fields, Property Setters, Roles
- Экспортируются в JSON
- Устанавливаются автоматически при `bench install`

---

## 5. Ограничения ERPNext (что учесть)

1. **UI Framework** — Frappe UI менее гибкий, чем React. Нельзя создать AccordionGrid или Sheet-формы из MidesCloud v3
2. **Subcontracting** — стандартный модуль заточен под manufacturing, не строительство
3. **Казахстанская локализация** — нет готового country-pack. Нужны свои налоговые шаблоны
4. **Print Formats** — Jinja2 мощный, но требует знания HTML/CSS для КС-2/КС-3
5. **Mobile** — PWA работает, но нативного мобильного приложения нет
6. **1С Integration** — нет готовых коннекторов, нужна разработка
