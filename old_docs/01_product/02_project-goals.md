# Project Goals

**Date:** 2026-05-17
**Status:** Active

## What This Project Is

This project is a **purpose-built autonomous agent pipeline** for creating and maintaining a construction management ERP for Mides Group (Kazakhstan).

The pipeline consists of: rules, agent contracts, architectural decisions, verification tools, a knowledge graph, and a design system — all configured specifically for the ERP domain described in `docs/01_product/01_system-blueprint.md`.

The ERP application (`web/`) is the **artifact** this pipeline produces. The pipeline is the project; the ERP is its output.

## Primary Goal

**Maintain a pipeline that enables any AI agent to autonomously build, evolve, and operate a production-grade construction ERP.**

"Autonomously" means: any AI agent (Antigravity, Claude, Cursor, or future systems) can open this repository on any machine, at any point in time, with zero prior context, and:
1. Understand the full system within 5 minutes by reading the Context Loading Protocol
2. Know exactly what to build next by reading the roadmap and page specs
3. Know exactly how to build it by reading agent contracts and guard rails
4. Verify its own work before committing via automated checks
5. Not break anything that exists via CI enforcement

---

## Pipeline Goals (The Project)

These goals define the quality of the conveyor itself — its ability to reliably produce and maintain the artifact.

### G1: Self-Sufficiency
The repository contains 100% of the context needed to continue development. No external memory, no tribal knowledge, no human onboarding. Everything an agent needs is in-repo.

**Verification:** Clone repo → run `npm run context:check` → read `.antigravityrules` → start coding. If any step fails, the pipeline is broken.

### G2: Drift Resistance
The pipeline detects its own decay. When code changes but documentation doesn't update, the system catches it. When tokens diverge, patterns are violated, or schemas become orphaned — automated checks fail.

**Verification:** `npm run context:check` returns 0 failures. Warnings are reported in the CI console for developer attention but do not block the pipeline.

### G3: Agent Interchangeability
No agent is special. The pipeline works identically for any AI model. Context is loaded via file reads, not memory. Contracts are in markdown, not prompts. Rules are enforced by scripts, not by trust.

**Verification:** Delete all `.antigravity/` local state → new agent session → agent produces correct output by reading only repo files.

### G4: Architectural Integrity
Every decision is recorded (38 ADRs). Every pattern is enforced (9 forbidden patterns). Every contract is testable (36 unit tests). The artifact cannot drift from its architecture because the architecture is machine-verified.

**Verification:** `npx tsc --noEmit` + `npm run test` + `npm run context:check` = 0 errors.

### G5: 10-Year Maintainability
Dependencies are gated (Dependabot + ADR for majors). Node version is locked. Disaster recovery is documented. The pipeline can survive machine loss, team changes, and technology shifts without losing context.

**Verification:** `docs/07_operations/` covers setup, dependencies, and DR. `.nvmrc` + `engines` lock runtime.

### G6: Iterative Delivery (Anti-Big Bang)
The pipeline strictly follows Gall's Law: complex systems evolve from simple working systems. The agent never attempts to build multiple modules at once. Development proceeds via "Vertical Slices" — building one tiny feature end-to-end (DB → API → UI) and deploying it for immediate closed-loop feedback.

**Verification:** Changes are scoped to a single Vertical Slice. E2E tests and CI confirm the slice works independently.

---

## Artifact Goals (The ERP)

These goals define what the pipeline is configured to produce. The artifact specification lives in `docs/01_product/01_system-blueprint.md`. When development is in active feature-building phase, these goals drive the agent's daily work.

### Current Phase: Ф1 — L2-COMMIT Subcontract
**Roadmap:** `docs/06_delivery/03_anti-big-bang-roadmap.md`
**Exit criteria:** Полный цикл субподрядной заявки: создание → утверждение → оплата → физприёмка → АВР → COMMITTED → Ledger.

### A1: Domain Coverage
Build a construction management ERP covering: projects, contractors, legal entities, procurement (P2P), payments, budgets, and document intelligence.

**Phase path:** Ф0 (Foundation) → Ф1 (Subcontract) → Ф2 (PO+Sourcing) → Ф3 (Service+Field+Revenue) → Ф4 (Finance+1С) → Ф5 (Pre-construction) → Ф6 (HR)
**Full spec:** `docs/01_product/01_system-blueprint.md`

### A2: Locale & Jurisdiction
All UI text in Russian. All currencies in KZT. All dates in DD.MM.YYYY. Kazakhstan legal entities (BIN/IIN). Tax compliance with Kazakhstan regulations.

**Enforced by:** `web/src/lib/locale.ts`, `web/tests/unit/locale.test.ts`

### A3: Role-Based Access
Director → sees everything. Project Manager → sees assigned projects. Procurement Officer, Accountant, Engineer — scoped by role + project assignment.

**Enforced by:** `web/src/lib/auth.ts`, `docs/08_reference/01_roles-and-permissions.md`

### A4: Design Language
Premium ERP aesthetic: white canvas, dark navy auth, Inter typeface, status-first color system, AccordionGrid for hierarchical data, Sheet panels for forms. Not a template — a control room.

**Enforced by:** `DESIGN.md`, `web/src/app/globals.css`, `docs/03_decisions/34_ui-interaction-patterns.md`

### A5: Technical Stack
Next.js 14 + Supabase Auth + Drizzle ORM + PostgreSQL + Tailwind CSS 3.4 + Shadcn/ui. Server Components + Server Actions. No API routes for mutations.

**Enforced by:** `web/package.json`, `docs/03_decisions/09_tech-stack.md`

---

## How Goals Map to Files

### Pipeline enforcement
| Goal | Enforced By |
|---|---|
| G1 Self-Sufficiency | `docs/08_reference/03_project-context.md`, `docs/07_operations/02_setup-from-scratch.md` |
| G2 Drift Resistance | `scripts/context-health.ts`, `.github/workflows/ci.yml` |
| G3 Interchangeability | `.antigravityrules` §4, `AGENTS.md`, `.agent/rules/graphify.md` |
| G4 Integrity | `AGENTS.md` §0, `web/tests/unit/`, `docs/03_decisions/` (38 ADRs) |
| G5 Maintainability | `.github/dependabot.yml`, `docs/07_operations/03-04`, `.nvmrc` |
| G6 Iterative Delivery | `AGENTS.md` §0 (Anti-Big Bang), `.antigravityrules` §3 |

### Artifact specification
| Goal | Specified In | Enforced By |
|---|---|---|
| A1 Domain | `01_system-blueprint.md`, Anti-Big Bang Roadmap | Page specs in `docs/04_architecture/` |
| A2 Locale | `01_system-blueprint.md` §locale | `locale.ts` + `locale.test.ts` |
| A3 Roles | `01_system-blueprint.md` §2 | `auth.ts` + `01_roles-and-permissions.md` |
| A4 Design | `DESIGN.md` | `globals.css` + `context:check` token sync |
| A5 Stack | `09_tech-stack.md` | `package.json` + `01_system-overview.md` |
