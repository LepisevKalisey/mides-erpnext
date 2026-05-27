# Phase 0 Frontend — План реализации UI

**Статус:** Ready for execution  
**Агент:** Frontend Agent (AGENTS.md §2)  
**Дата:** 2026-05-18  
**Phase:** Ф0 — Foundation (Walking Skeleton)

---

## Обязательный порядок чтения перед кодом

> Это не рекомендация. Это контракт. Читать в порядке 1→6 перед написанием любой строки кода.

1. `DESIGN.md` — все секции: токены, компоненты, do/don't
2. `docs/01_product/01_system-blueprint.md` — §2 (роли), §8 (инварианты)
3. `docs/03_decisions/07_accordion-table-standard.md` — паттерн AccordionGrid
4. `docs/03_decisions/34_ui-interaction-patterns.md` — правила взаимодействия
5. `web/src/app/globals.css` — текущие CSS-переменные
6. Page Spec целевого среза из `docs/04_architecture/`

---

## Граф зависимостей (почему такой порядок)

```
Slice 0: App Shell (layout, sidebar, routing)
    │
    ▼
Slice 1: Legal Entities  ──────────────────────────────┐
    │                                                   │
    ▼                                                   ▼
Slice 2: Contractors          Slice 3: Projects ← нужны legal_entities
    │                                   │
    └────────────────┬──────────────────┘
                     ▼
              Slice 4: Contracts (нужны все три выше)
                     │
    Slice 5: Employees (параллельно, нет UI-зависимостей от Contracts)
                     │
                     ▼
              Slice 6: Dashboard (агрегирует все модули)
```

**Правило Anti-Big Bang:** каждый срез — полностью функциональная фича end-to-end:
`Server Action → UI компонент → ручной тест в браузере → commit`

---

## Slice 0 — App Shell (ПЕРВЫЙ, блокирует всё)

**Page Spec:** нет — это инфраструктура, не модуль  
**Приоритет:** 🔴 Блокирует все остальные срезы

### Задача

Создать полноценный dashboard layout. Сейчас `/dashboard` возвращает 404 — нет route group.

### Файлы для создания

```
web/src/app/(dashboard)/
  layout.tsx          ← sidebar + header + main content area
  page.tsx            ← redirect → /dashboard/overview
web/src/components/layout/
  sidebar.tsx         ← навигация по всем модулям Ф0
  header.tsx          ← заголовок + имя пользователя + logout
  nav-item.tsx        ← одна ссылка в sidebar
```

### Sidebar навигация (фиксированный список)

```tsx
const NAV_ITEMS = [
  { href: '/dashboard/overview',       label: 'Обзор',              icon: LayoutDashboard },
  { href: '/dashboard/legal-entities', label: 'Юридические лица',   icon: Landmark },
  { href: '/dashboard/contractors',    label: 'Контрагенты',        icon: Building2 },
  { href: '/dashboard/projects',       label: 'Проекты',            icon: FolderOpen },
  { href: '/dashboard/contracts',      label: 'Договоры',           icon: FileText },
  { href: '/dashboard/employees',      label: 'Сотрудники',         icon: Users },
]
```

### Guard Rails Slice 0

- Layout читает `getCurrentUser()` из `lib/auth.ts` — redirect `/login` если null
- Sidebar: активная ссылка через `usePathname()` (клиентский компонент)
- Header показывает `user.fullName ?? user.email`
- MAX 150 строк на компонент

### Критерий готовности

- `GET /dashboard/overview` → 200 (не 404)
- Sidebar виден, все 6 пунктов кликабельны
- Логаут работает

---

## Slice 1 — Legal Entities

**Page Spec:** `docs/04_architecture/04_page-spec-legal-entities.md`  
**Приоритет:** 🔴 Высокий (от неё зависят Projects и Contracts)

### Файлы для создания

```
web/src/app/(dashboard)/legal-entities/
  page.tsx
  actions.ts
  _components/
    legal-entity-row.tsx
    legal-entity-expanded.tsx
    create-entity-sheet.tsx
    create-bank-account-sheet.tsx
```

### Server Actions

```typescript
getLegalEntities(filters?: { entityType?: string; isOwn?: boolean; search?: string })
createLegalEntity(data: { name, bin, entityType, isOwn })
updateLegalEntity(id: string, data: Partial<...>)
createBankAccount(data: { legalEntityId, accountNumber, bankName, bankBik?, currency, purpose? })
toggleBankAccountActive(id: string)
```

### Инварианты

- БИН уникален — `{ error: 'БИН уже существует' }` при дублировании
- Банковский счёт — только soft delete (`isActive = false`)
- Нельзя удалить юрлицо если есть связанные `projects` или `contractors`

---

## Slice 2 — Contractors

**Page Spec:** `docs/04_architecture/06_page-spec-contractors.md`  
**Приоритет:** 🟠 Высокий (нужен для Slice 4)

### Файлы для создания

```
web/src/app/(dashboard)/contractors/
  page.tsx
  actions.ts
  _components/
    contractor-row.tsx
    contractor-expanded.tsx
    create-contractor-sheet.tsx
    edit-contractor-sheet.tsx
```

### Server Actions

```typescript
getContractors(filters?: { contractorType?: string; search?: string })
createContractor(data: { name, bin?, contractorType: 'COMPANY'|'INDIVIDUAL', beneficialOwnerId? })
updateContractor(id: string, data: Partial<...>)
linkBeneficialOwner(contractorId: string, beneficialOwnerId: string)
createBeneficialOwner(data: { fullName, phone?, iin? })
```

### Инварианты

- `contractorType` = `COMPANY | INDIVIDUAL` (НЕ SUBCONTRACTOR — это из старой схемы)
- JOIN: `contractors.beneficial_owner_id → beneficial_owners.id`
- `bin` nullable для INDIVIDUAL
- Запрет удаления если есть `contracts`

---

## Slice 3 — Projects

**Page Spec:** `docs/04_architecture/05_page-spec-projects.md`  
**Приоритет:** 🟠 Высокий (нужен для Slice 4)

### Файлы для создания

```
web/src/app/(dashboard)/projects/
  page.tsx
  actions.ts
  _components/
    project-row.tsx
    project-expanded.tsx
    tabs/
      objects-tab.tsx
      team-tab.tsx
      bank-tab.tsx
    create-project-sheet.tsx
    add-object-sheet.tsx
    assign-user-sheet.tsx
```

### Server Actions

```typescript
getProjects(filters?: { isActive?: boolean; search?: string })
createProject(data: { name, description? })
updateProject(id: string, data: Partial<...>)
toggleProjectActive(id: string)
addProjectObject(data: { projectId, name })
assignUserToProject(data: { projectId, userId, objectId?, projectRole, workStream? })
```

### Инварианты

- `workStream` допустим только при наличии `objectId`
- Фильтр по умолчанию: только активные (`isActive = true`)

---

## Slice 4 — Contracts ⭐ КРИТИЧНЫЙ

**Page Spec:** `docs/04_architecture/07_page-spec-contracts.md`  
**Приоритет:** 🔴 Ядро Фазы 0  
**Зависимости:** Slice 1 + Slice 2 + Slice 3 завершены

### Файлы для создания

```
web/src/app/(dashboard)/contracts/
  page.tsx
  actions.ts
  _components/
    contract-row.tsx
    contract-expanded.tsx
    tabs/
      details-tab.tsx
      parties-tab.tsx
    create-contract-sheet.tsx
    edit-contract-sheet.tsx
    advance-status-sheet.tsx   ← содержит lifecycle-логику
```

### Server Actions

```typescript
getContracts(filters?: { status?: ContractStatus; projectId?: string; search?: string })
createContract(data: { projectId, objectId?, legalEntityId, contractorId,
  contractNumber, contractDate, totalAmount, currency?, warrantyPercent?,
  startDate?, endDate?, description? })
updateContract(id: string, data: Partial<...>)
  // GUARD: только если contract.status === 'INTENT'

advanceContractStatus(id: string, newStatus: ContractStatus)
  // КРИТИЧЕСКИЙ ИНВАРИАНТ:
  // if (newStatus === 'SIGNED' && !contract.warrantyPercent)
  //   return { error: 'Необходимо указать гарантийный % перед подписанием' }
  //
  // Допустимые переходы:
  //   INTENT  → SIGNED      (только если warrantyPercent != null)
  //   SIGNED  → ACTIVE
  //   ACTIVE  → CLOSED
  //   ACTIVE  → TERMINATED
```

### Warranty Block в details-tab

```tsx
// Если warrantyPercent != null
<p>Гарантийное удержание: {warrantyPercent}%</p>

// Если status IN ['SIGNED','ACTIVE','CLOSED'] && warrantyPercent = null
<Badge variant="warning">Гарантийный % не задан</Badge>
```

### Инварианты

- Редактирование разрешено ТОЛЬКО в статусе `INTENT`
- Статус меняется ТОЛЬКО через `advance-status-sheet.tsx`
- Удаление запрещено — только `TERMINATED`

---

## Slice 5 — Employees

**Page Spec:** `docs/04_architecture/08_page-spec-employees.md`  
**Приоритет:** 🟡 Средний (без UI-зависимостей от Contracts)

### Файлы для создания

```
web/src/app/(dashboard)/employees/
  page.tsx
  actions.ts
  _components/
    department-row.tsx
    employee-leaf-row.tsx
    employee-expanded.tsx
    create-employee-sheet.tsx
    edit-employee-sheet.tsx
    create-department-sheet.tsx
```

### Server Actions

```typescript
getEmployees(filters?: { departmentId?: string; isActive?: boolean; search?: string })
createEmployee(data: { fullName, iin?, phone?, email?, positionId?, departmentId?, legalEntityId?, hiredAt? })
updateEmployee(id: string, data: Partial<...>)
fireEmployee(id: string)   // firedAt = NOW(), НЕ delete
createDepartment(data: { name, parentId? })
```

### Инварианты

- `firedAt != null` → badge «Уволен» (`--status-neutral`)
- `profileId != null` → иконка CheckCircle (есть доступ в систему)
- Уволенный НЕ удаляется из `project_assignments`

---

## Slice 6 — Dashboard / Overview

**Page Spec:** `docs/04_architecture/03_page-spec-dashboard.md`  
**Приоритет:** 🟢 Последний  
**Зависимости:** Все предыдущие срезы завершены

### Файлы для создания

```
web/src/app/(dashboard)/overview/
  page.tsx
  actions.ts
  _components/
    stat-card.tsx
    recent-projects-list.tsx
```

### Server Actions

```typescript
getDashboardStats()
  → {
    activeProjectsCount: number
    contractorsCount: number
    legalEntitiesCount: number
    activeContractsCount: number   // INTENT + SIGNED + ACTIVE
    recentProjects: Project[]      // 5 последних
  }
```

### KPI Cards

| Карточка | Icon | Key | Href |
|---|---|---|---|
| Активные проекты | `FolderOpen` | `activeProjectsCount` | `/dashboard/projects` |
| Контрагенты | `Building2` | `contractorsCount` | `/dashboard/contractors` |
| Юридические лица | `Landmark` | `legalEntitiesCount` | `/dashboard/legal-entities` |
| Активные договоры | `FileText` | `activeContractsCount` | `/dashboard/contracts` |

---

## Guard Rails (все срезы — без исключений)

| Правило | Нарушение |
|---|---|
| Формы — ТОЛЬКО Sheet | Никаких modal, никаких inline-форм |
| Таблицы — ТОЛЬКО AccordionGrid | Никаких plain table |
| Цвета — ТОЛЬКО `var(--token)` | Никакого `#hex` или `rgb()` |
| Деньги — `formatCurrency('ru-KZ', 'KZT')` | Никакого `toFixed(2)` |
| Даты — `formatDate('ru-KZ')` | Никакого `new Date().toLocaleDateString()` |
| Компонент — макс. 150 строк | Дробить на под-компоненты |
| Иконки — ТОЛЬКО Lucide React | Никаких emoji, никаких SVG вручную |
| Текст — ТОЛЬКО русский | Никакого английского в UI |

---

## Verification Checklist (после каждого среза)

```
✅ npm run lint          — 0 ошибок
✅ npm run test          — все тесты проходят
✅ npx tsc --noEmit      — 0 новых type errors
✅ Ручная проверка: список виден, создание работает, Sheet открывается
✅ Commit: feat(module): ... [QA-READY] module-name
```
