# Agent-First 10/10 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Довести MidesCloud v3 с текущего Agent-First score 4/10 до 10/10.

**Architecture:** 5 фаз, каждая поднимает score на ~1.2 пункта. Фазы выполняются строго последовательно. Каждая фаза завершается коммитом.

**Tech Stack:** Next.js 14, Drizzle ORM, Supabase Auth, Tailwind CSS v3.4, shadcn/ui, Vitest, Playwright, GitHub Actions

**Current Score:** 4/10 | **Target:** 10/10

---

## Phase 1: Documentation Integrity (Score 4→6)

> Цель: устранить все broken references, коллизии и дубли. После этой фазы любой агент может навигировать по документации без ошибок.

### Task 1.1: Fix ADR Numbering Collisions

**Files:**
- Rename: `docs/03_decisions/05_matrix-org-and-pm-role.md` → `05b_matrix-org-and-pm-role.md`
- Rename: `docs/03_decisions/06_cost-codes-dual-structure.md` → `06b_cost-codes-dual-structure.md`
- Rename: `docs/03_decisions/06_typography-fira-sans-fira-code.md` → `06c_typography-fira-sans-fira-code.md`
- Rename: `docs/03_decisions/07_contractor-lifecycle-payment-threshold.md` → `07b_contractor-lifecycle-payment-threshold.md`
- Rename: `docs/03_decisions/28_triple-hierarchy-p2p.md` → `28b_triple-hierarchy-p2p.md`

**Steps:**
1. Rename each file using `git mv`
2. Grep all docs for old filenames, update cross-references
3. Commit: `fix(docs): resolve ADR numbering collisions`

### Task 1.2: Rebuild Docs Index

**Files:**
- Modify: `docs/00_index/01_docs-index.md`

**Steps:**
1. Replace ALL `$path` placeholders with real paths
2. Update titles to match actual file headings
3. Add `Linked Docs` cross-references where applicable
4. Add missing entries (AGENTS.md, .antigravityrules)
5. Verify every path exists with a script
6. Commit: `fix(docs): rebuild docs-index with real paths`

**Expected result:** Every row has a valid relative path, no `$path` remains.

### Task 1.3: Delete .agents/references/docs Duplicate

**Files:**
- Delete: `.agents/references/docs/` (entire directory)
- Delete: `.agents/references/` if empty after

**Steps:**
1. Verify `.agents/references/docs/` is a stale copy of `docs/`
2. Check if any file in `.agents/` is unique (not in `docs/` or root)
3. If unique files exist → move them to proper location in `docs/`
4. Delete `.agents/references/docs/`
5. Commit: `fix: remove duplicate docs from .agents/references`

### Task 1.4: Update System Overview

**Files:**
- Modify: `docs/04_architecture/01_system-overview.md`

**Steps:**
1. Update version to 2.0, date to today
2. Replace old schema diagram with current 8-table Drizzle schema
3. Replace old roles (5) with current Blueprint roles structure
4. Fix cross-references: `01_deployment-environments` → `08_deployment-environments`, `02_tech-stack` → `09_tech-stack`
5. Remove references to non-existent files (`middleware.ts`)
6. Add note: "For full domain model see `docs/01_product/01_system-blueprint.md`"
7. Commit: `fix(docs): update system-overview to v3 reality`

### Task 1.5: Commit & Verify Phase 1

**Steps:**
1. Run: `Get-ChildItem -Recurse docs/03_decisions/*.md | Group-Object { $_.Name.Substring(0,2) } | Where-Object { $_.Count -gt 1 }` — expect 0 collisions
2. Run: grep for `$path` in docs/ — expect 0 results
3. Verify `.agents/references/docs/` does not exist
4. Tag: `git tag agent-first-phase1`

---

## Phase 2: AGENTS.md & Context Loading (Score 6→7.5)

> Цель: превратить AGENTS.md из декларации в исполняемый контракт. Каждый агент знает что читать, что делать, что запрещено.

### Task 2.1: Rewrite AGENTS.md

**Files:**
- Modify: `AGENTS.md` (root)

**Steps:**
1. Replace entire content with executable agent contracts
2. Each agent gets: Trigger, Mandatory Pre-read (ordered), Workspace, Output Contract, Guard Rails, Verification Steps
3. Add 2 new agents: DevOps/Infra Agent, Data/Migration Agent
4. Total: 6 agents (Product, Frontend, Backend, QA, DevOps, Data)

**New structure per agent (example Frontend):**

```markdown
## 2. Frontend Agent

### Trigger
UI tasks, component building, page implementation, UI refactoring

### Mandatory Pre-read (in order)
1. `DESIGN.md` — ALL sections (tokens, components, do/don't)
2. `docs/01_product/01_system-blueprint.md` — §2 (roles), §8 (invariants)
3. `docs/03_decisions/07_accordion-table-standard.md`
4. `docs/03_decisions/34_ui-interaction-patterns.md`
5. Target page spec from `docs/04_architecture/`

### Workspace
`web/src/app/`, `web/src/components/`, `web/src/lib/`

### Output Contract
- Working page matching page spec
- New components in `web/src/components/ui/` or `web/src/components/`
- Server Actions in `web/src/app/(dashboard)/[module]/actions.ts`

### Guard Rails
- NEVER create modals for create/edit → Sheet panels ONLY
- NEVER hardcode colors → CSS custom properties from globals.css
- NEVER use Geist/Arial → Inter only (via next/font/google)
- NEVER use emoji as status indicators → Lucide React icons
- ALL tables → AccordionGrid component pattern
- ALL amounts → formatCurrency('ru-KZ', 'KZT')
- ALL dates → formatDate('ru-KZ') with relative time
- ALL forms → Sheet panel sliding from right
- Font: Plus Jakarta Sans for headings, Inter for body
```

5. Commit: `feat(agents): rewrite AGENTS.md as executable contracts`

### Task 2.2: Enhance .antigravityrules

**Files:**
- Modify: `.antigravityrules`

**Steps:**
1. Add section 4: "Context Loading Protocol" — mandatory file read order for any agent
2. Add section 5: "Verification Checklist" — what to check before committing
3. Add section 6: "Forbidden Patterns" — explicit anti-patterns list

```markdown
## 4. Context Loading Protocol
Any agent MUST read these files before writing code:
1. `.antigravityrules` (this file)
2. `AGENTS.md` (find your agent section)
3. `DESIGN.md` (if touching UI)
4. `docs/01_product/01_system-blueprint.md` §8 Invariants
5. Relevant ADRs from `docs/03_decisions/`

## 5. Pre-Commit Verification
Before committing, verify:
- [ ] No hardcoded colors (use CSS vars)
- [ ] No new tables without ADR
- [ ] Docs index updated if new doc created
- [ ] TypeScript strict mode passes

## 6. Forbidden Patterns
- God Tables (all fields in one table)
- Cascade triggers for workflow orchestration
- Modals for create/edit flows (use Sheets)
- Direct SQL outside Drizzle ORM
- Storing computed status (use VIEWs)
```

4. Commit: `feat(rules): add context loading protocol and forbidden patterns`

### Task 2.3: Create .env.example

**Files:**
- Create: `web/.env.example`

**Steps:**
1. Create file with all required env vars and descriptions:

```env
# Database
DATABASE_URL=postgresql://user:pass@host:5432/midescloud

# Auth
BETTER_AUTH_SECRET=generate-with-openssl-rand-base64-32

# WhatsApp OTP (Phase M2+)
# WHATSAPP_API_TOKEN=
# WHATSAPP_PHONE_NUMBER_ID=

# AI/OCR (Phase M3+)
# GEMINI_API_KEY=

# App
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

2. Commit: `feat: add .env.example for agent context`

### Task 2.4: Create Root README.md

**Files:**
- Create: `README.md` (project root)

**Steps:**
1. Write README with: project description, tech stack, quick start, project structure, docs navigation, agent instructions
2. Link to AGENTS.md, DESIGN.md, Blueprint
3. Commit: `feat: add root README.md as agent entry point`

---

## Phase 3: Code ↔ DESIGN.md Alignment (Score 7.5→8.5)

> Цель: устранить разрыв между DESIGN.md спецификацией и реальным кодом. После этой фазы агент, читающий DESIGN.md, получит consistent codebase.

### Task 3.1: Install Core Dependencies

**Files:**
- Modify: `web/package.json`

**Steps:**
1. Run in `web/`:

```bash
npm install lucide-react class-variance-authority clsx tailwind-merge
npm install -D @tailwindcss/typography
```

2. Initialize shadcn/ui:

```bash
npx -y shadcn@latest init
```

Configure: TypeScript, Inter font, CSS variables, `src/` aliases
3. Add base shadcn components: Button, Sheet, Table, Badge, Input, Select, Card, Tabs
4. Commit: `feat: install shadcn/ui, lucide-react, and design dependencies`

### Task 3.2: Fix Layout — Geist → Inter + Plus Jakarta Sans

**Files:**
- Modify: `web/src/app/layout.tsx`
- Delete: `web/src/app/fonts/GeistVF.woff` (if not needed)
- Delete: `web/src/app/fonts/GeistMonoVF.woff` (if not needed)

**Steps:**
1. Replace localFont(Geist) with next/font/google Inter + Plus_Jakarta_Sans
2. Update metadata: title → "MidesCloud", description → "Construction management system"
3. Set html lang="ru"
4. Commit: `fix(ui): replace Geist with Inter + Plus Jakarta Sans per DESIGN.md`

### Task 3.3: Implement CSS Custom Properties from DESIGN.md

**Files:**
- Modify: `web/src/app/globals.css`

**Steps:**
1. Replace current minimal CSS vars with full DESIGN.md token set:
   - Colors: `--background`, `--foreground`, `--primary`, `--muted`, `--border`, `--accent`, semantic status colors
   - Spacing scale: `--space-1` through `--space-12`
   - Radius: `--radius-sm`, `--radius-md`, `--radius-lg`
   - Elevation/shadows
2. Add dark mode support matching DESIGN.md
3. Commit: `feat(ui): implement full DESIGN.md CSS custom properties`

### Task 3.4: Configure Tailwind for DESIGN.md Tokens

**Files:**
- Modify: `web/tailwind.config.ts`

**Steps:**
1. Extend theme with DESIGN.md color tokens mapped to CSS vars
2. Add font families: `sans: Inter`, `heading: Plus Jakarta Sans`
3. Add custom spacing/radius if needed beyond defaults
4. Remove unused `pages/` from content paths
5. Commit: `feat(ui): configure tailwind with DESIGN.md tokens`

### Task 3.5: Replace Starter Page

**Files:**
- Modify: `web/src/app/page.tsx`

**Steps:**
1. Replace Next.js boilerplate with redirect to `/login` or `/dashboard`
2. Simple redirect logic: if authenticated → dashboard, else → login
3. Commit: `fix(ui): replace starter template with auth redirect`

### Task 3.6: Create Utility Functions

**Files:**
- Create: `web/src/lib/utils.ts`
- Create: `web/src/lib/formatters.ts`

**Steps:**
1. `utils.ts`: cn() function (clsx + tailwind-merge)
2. `formatters.ts`: formatCurrency('ru-KZ', 'KZT'), formatDate('ru-KZ'), formatRelativeDate()
3. Commit: `feat: add cn() utility and locale-aware formatters`

---

## Phase 4: Testing & CI Infrastructure (Score 8.5→9.5)

> Цель: агент может верифицировать свою работу автоматически. Closed-loop delivery.

### Task 4.1: Install Test Dependencies

**Files:**
- Modify: `web/package.json`

**Steps:**
1. Run in `web/`:

```bash
npm install -D vitest @testing-library/react @testing-library/jest-dom @playwright/test
npx -y playwright install chromium
```

2. Add scripts to package.json:

```json
"test": "vitest run",
"test:watch": "vitest",
"test:e2e": "playwright test",
"test:e2e:ui": "playwright test --ui"
```

3. Commit: `feat(test): install vitest and playwright`

### Task 4.2: Configure Vitest

**Files:**
- Create: `web/vitest.config.ts`

**Steps:**
1. Create config with path aliases matching tsconfig
2. Setup file for testing-library
3. Commit: `feat(test): configure vitest with path aliases`

### Task 4.3: Configure Playwright

**Files:**
- Create: `web/playwright.config.ts`
- Create: `web/tests/e2e/.gitkeep`

**Steps:**
1. Configure baseURL localhost:3000
2. Set projects: chromium only (for speed)
3. Commit: `feat(test): configure playwright for E2E`

### Task 4.4: Create Smoke Test

**Files:**
- Create: `web/tests/e2e/smoke.spec.ts`

**Steps:**
1. Write test: app loads, correct title, no console errors
2. Run: `npx playwright test tests/e2e/smoke.spec.ts`
3. Verify it passes against running dev server
4. Commit: `test: add smoke E2E test`

### Task 4.5: Create Seed Script

**Files:**
- Create: `web/scripts/seed.ts`

**Steps:**
1. Import db client and schema
2. Insert test data for: legal_entities (2), bank_accounts (3), projects (2), project_objects (4), contractors (5), cost_codes (10), project_assignments (3), user with DIRECTOR role
3. Add script to package.json: `"db:seed": "tsx scripts/seed.ts"`
4. Commit: `feat: add database seed script for agent testing`

### Task 4.6: Create GitHub Actions CI Pipeline

**Files:**
- Create: `.github/workflows/ci.yml`

**Steps:**
1. Create workflow: push/PR to main
2. Jobs: lint → typecheck → test (vitest) → build
3. E2E tests as separate job (needs database)
4. Commit: `feat(ci): add GitHub Actions lint/typecheck/test/build pipeline`

---

## Phase 5: Task Specification & Agent Routing (Score 9.5→10)

> Цель: каждая задача однозначно специфицирована. Multi-agent routing работает. Full agent autonomy.

### Task 5.1: Create Page Spec Template

**Files:**
- Create: `docs/04_architecture/02_page-spec-template.md`

**Steps:**
1. Define standard template for page specifications:

```markdown
# Page Spec: [Page Name]

## Route
`/dashboard/[module]`

## Agent
Frontend Agent (see AGENTS.md §2)

## Layout
[AccordionGrid | DataTable | CardGrid | Form]

## Data Source
- Server Action: `getItems(projectId)`
- Schema tables: `table_name`

## Components
| Component | Type | Props |
|---|---|---|
| ItemRow | AccordionGrid row | item: Item |

## Interactions
| Action | Trigger | Result |
|---|---|---|
| Create | FAB button | Sheet opens from right |

## Filters & Sorting
| Field | Type | Default |
|---|---|---|

## Status Badges
| Status | Color Token | Label |
|---|---|---|

## Invariants
- [list from Blueprint §8 that apply]
```

2. Commit: `feat(docs): add page spec template for agent-driven development`

### Task 5.2: Create M0 Foundation Page Specs

**Files:**
- Create: `docs/04_architecture/03_page-spec-dashboard.md`
- Create: `docs/04_architecture/04_page-spec-legal-entities.md`
- Create: `docs/04_architecture/05_page-spec-projects.md`
- Create: `docs/04_architecture/06_page-spec-contractors.md`

**Steps:**
1. Write spec for each M0 screen using template from 5.1
2. Reference existing schema tables
3. Cross-reference ADRs (07_accordion-table, 34_ui-interaction-patterns)
4. Commit: `feat(docs): add M0 page specs for agent task routing`

### Task 5.3: Create Delivery Roadmap

**Files:**
- Create: `docs/06_delivery/02_master-roadmap.md`

**Steps:**
1. Define milestones: M0 (Foundation), M1 (P2P), M2 (Auth+WhatsApp), M3 (AI/OCR), M4 (Budget)
2. Map each milestone to page specs and schema tables
3. Reference Blueprint §7 (Modular Growth Path)
4. Commit: `feat(docs): add master delivery roadmap`

### Task 5.4: Create Agent Routing Index

**Files:**
- Create: `docs/00_index/02_agent-routing.md`

**Steps:**
1. Create matrix: task type → agent → pre-read files → output contract
2. Cover all common task patterns:

| Task Pattern | Agent | Key Files |
|---|---|---|
| New page implementation | Frontend | DESIGN.md, page spec, schema |
| New table/migration | Data | Blueprint §4, ADR-38 |
| API route | Backend | Blueprint §8, auth schema |
| Bug fix | QA → relevant agent | test file, error logs |
| New ADR | Product | Blueprint, existing ADRs |
| CI/deploy issue | DevOps | .github/workflows, package.json |

3. Commit: `feat(docs): add agent routing index for task dispatch`

### Task 5.5: Update Docs Index & Final Verification

**Files:**
- Modify: `docs/00_index/01_docs-index.md`

**Steps:**
1. Add all new files created in Phases 1-5 to docs index
2. Verify every path in index exists
3. Run full verification checklist:
   - [ ] `$path` count in docs/ = 0
   - [ ] ADR collision count = 0
   - [ ] `.agents/references/docs/` does not exist
   - [ ] `npm run lint` passes
   - [ ] `npm run build` passes
   - [ ] `npm run test` passes
   - [ ] AGENTS.md has 6 agents with pre-read + output + guard rails
   - [ ] globals.css has DESIGN.md tokens
   - [ ] layout.tsx uses Inter (not Geist)
   - [ ] .env.example exists
   - [ ] seed script exists
   - [ ] CI pipeline exists
   - [ ] Page specs exist for M0
   - [ ] Agent routing index exists
4. Tag: `git tag agent-first-v10`
5. Commit: `feat: agent-first 10/10 milestone complete`

---

## Score Progression

```
Phase 1: Documentation Integrity     4/10 → 6/10  (+2.0)
Phase 2: AGENTS.md & Context         6/10 → 7.5/10 (+1.5)
Phase 3: Code ↔ DESIGN.md Alignment  7.5/10 → 8.5/10 (+1.0)
Phase 4: Testing & CI                8.5/10 → 9.5/10 (+1.0)
Phase 5: Task Specs & Routing        9.5/10 → 10/10  (+0.5)
```

## Estimated Effort

| Phase | Tasks | Time Estimate |
|---|---|---|
| Phase 1 | 5 tasks | ~1.5 hours |
| Phase 2 | 4 tasks | ~1.5 hours |
| Phase 3 | 6 tasks | ~2 hours |
| Phase 4 | 6 tasks | ~2 hours |
| Phase 5 | 5 tasks | ~2 hours |
| **Total** | **26 tasks** | **~9 hours** |

## Dependencies

```
Phase 1 ─── must complete before ──→ Phase 2
Phase 2 ─── must complete before ──→ Phase 3
Phase 3 ─── must complete before ──→ Phase 4
Phase 4 ─── independent of ────────→ Phase 5
Phase 5 ─── can start after ───────→ Phase 2
```

> **Note:** Phases 4 and 5 can run in parallel after Phase 3 is complete.
