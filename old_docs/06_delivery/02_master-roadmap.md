# Master Delivery Roadmap — MidesCloud v3

**Date:** 2026-05-17
**Status:** SUPERSEDED  
**Superseded by:** `docs/06_delivery/03_anti-big-bang-roadmap.md`

> [!WARNING]
> Этот документ **больше не является источником правды**. Нумерация M0–M4 
> заменена на фазовую нумерацию Ф0–Ф6 в Anti-Big Bang Roadmap.
> Документ сохранён для исторической трассировки.

> Модульный рост в соответствии с Blueprint §7 (Modular Growth Path).

---

## Milestones

### M0: Foundation (Фундамент)
**Target:** 2026-05-31  
**Status:** 🔨 In Progress

| Deliverable | Page Spec | Schema Tables | ADRs |
|---|---|---|---|
| Auth (email+password) | — | user, session, account, user_roles | ADR-09 |
| Dashboard overview | `03_page-spec-dashboard.md` | projects, contractors, legal_entities | — |
| Legal entities CRUD | `04_page-spec-legal-entities.md` | legal_entities, bank_accounts | ADR-07 |
| Projects CRUD | `05_page-spec-projects.md` | projects, project_objects, project_assignments, project_bank_accounts | ADR-29, ADR-30 |
| Contractors CRUD | `06_page-spec-contractors.md` | contractors, beneficial_owners | ADR-20 |
| Cost codes reference | — | cost_codes | ADR-06b |
| CI/CD pipeline | — | — | ADR-08 |

**Exit criteria:** All 4 CRUD pages working, tests passing, CI green.

---

### M1: Procurement (Закупки — P2P)
**Target:** 2026-07-15  
**Status:** 📋 Planned

| Deliverable | Schema Tables | ADRs |
|---|---|---|
| Purchase requests | purchase_items (anchor) | ADR-38 |
| Purchase approval workflow | approval_tasks (task-per-role) | ADR-38 |
| Contracts registry | contracts | ADR-36 |
| Invoice matching | invoice_tasks | ADR-36, ADR-38 |
| Payment registry | payment_tasks | ADR-36, ADR-38 |
| Document flow | document_tasks | ADR-38 |
| SLA monitoring | — | — |

**Exit criteria:** Full P2P cycle: request → approve → contract → invoice → payment.

---

### M2: Auth Upgrade (WhatsApp OTP)
**Target:** 2026-08-15  
**Status:** 📋 Planned

| Deliverable | Schema Tables | ADRs |
|---|---|---|
| WhatsApp OTP plugin | verification | — |
| Phone-based login | user (phone field) | — |
| User invitation flow | — | — |

**Exit criteria:** Users can authenticate via WhatsApp number.

---

### M3: AI & Document Intelligence
**Target:** 2026-09-30  
**Status:** 📋 Planned

| Deliverable | Schema Tables | ADRs |
|---|---|---|
| Document OCR (Gemini) | document_extractions | ADR-35 |
| Auto-fill from scans | — | ADR-35 |
| AI material matching | — | ADR-35 |

**Exit criteria:** Documents auto-parsed into structured purchase data.

---

### M4: Budget & Analytics
**Target:** 2026-11-30  
**Status:** 📋 Planned

| Deliverable | Schema Tables | ADRs |
|---|---|---|
| Budget planning | budgets, budget_lines | — |
| Cost analysis by code | — | ADR-06b |
| Director analytics dashboard | — | — |
| Report generation | — | — |

**Exit criteria:** Director can see budget vs actual spend per project.

---

## Timeline

```
2026 May    Jun     Jul     Aug     Sep     Oct     Nov
  |---M0---|
            |------M1------|
                            |--M2--|
                                    |----M3----|
                                                |----M4----|
```

## Dependencies

```
M0 ──→ M1 (M1 needs Foundation tables)
M0 ──→ M2 (M2 needs auth infrastructure)
M1 ──→ M3 (M3 needs purchase_items to attach documents)
M1 ──→ M4 (M4 needs P2P data for analytics)
```

## Related

- See: `docs/01_product/01_system-blueprint.md` §7 (Modular Growth Path)
- See: `docs/03_decisions/38_task-per-role-architecture.md`
