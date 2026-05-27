# Master Documentation Index

## Core Documents

| Path | Title | Purpose | Status | Linked Docs |
|---|---|---|---|---|
| `docs/00_index/01_docs-index.md` | Master Index | Index of all project documentation | Active | — |
| `docs/00_index/02_agent-routing.md` | Agent Routing Index | Task → Agent routing matrix | Active | AGENTS.md |
| `docs/01_product/01_system-blueprint.md` | System Blueprint | Core domain model, dual-path P2P, invariants | Active | All ADRs |
| `docs/01_product/02_project-goals.md` | Project Goals | Machine-readable goals: environment (G1-G5) + artifact (A1-A5) | Active | All core docs |
| `docs/04_architecture/01_system-overview.md` | System Overview | Technical stack and deployment context | Active | ADR-08, ADR-09 |
| `docs/04_architecture/02_page-spec-template.md` | Page Spec Template | Standard template for page specifications | Active | ADR-07, ADR-34 |
| `DESIGN.md` | Semantic Design System | Master UI tokens for Stitch and Agents | Active | ADR-06c, ADR-07, ADR-34 |
| `AGENTS.md` | Agent Pipelines | Autonomous agent contracts and routing (6 agents) | Active | `.antigravityrules` |
| `.antigravityrules` | Project Rules | Agent-first rules, context loading, forbidden patterns | Active | `AGENTS.md` |
| `README.md` | Root README | Agent/developer entry point | Active | All core docs |
| `CHANGELOG.md` | Changelog | Phase completion history and release notes | Active | — |

## Research

| Path | Title | Purpose | Status |
|---|---|---|---|
| `docs/02_research/01_construction-industry-workflow.md` | Construction Industry Workflow | Industry research and workflow analysis | Active |
| `docs/02_research/01_erp-benchmark-review.md` | ERP Benchmark Review | Competitor analysis | Active |
| `docs/02_research/02_ai-strategy-practical.md` | AI Strategy Practical | AI/ML strategy for construction domain | Active |
| `docs/02_research/03_value-stream-map.md` | Value Stream Map | L1-L3 conveyor hierarchy: Bid-to-Cash pipeline, all process flows | Active |
| `docs/02_research/04_agent-instructions-review.md` | Agent-First Instruction Review | Review of agent instructions and drift detection | Active |
| `docs/02_research/06_ap-best-practices.md` | AP Best Practices | Мировые стандарты AP (SAP, Oracle, Procore, Sage): four-way match, advance payments, lump sum ledger, gap analysis MidesCloud | Active |
| `docs/02_research/05_requests-performance-analysis.md` | Requests Performance Analysis | Анализ масштабируемости реестра и расчета балансов | Active |
| `docs/02_research/07_procore-user-stories.md` | Procore User Stories Benchmark | Спецификация пользовательских сценариев (User Stories) Procore | Active |


## Architecture & Page Specs

| Path | Title | Purpose | Status | Linked Docs |
|---|---|---|---|---|
| `docs/04_architecture/01_system-overview.md` | System Overview v2.0 | Tech stack, schema, auth flow | Active | ADR-08, ADR-09 |
| `docs/04_architecture/02_page-spec-template.md` | Page Spec Template | Reusable template for all page specs | Active | ADR-07, ADR-34 |
| `docs/04_architecture/03_page-spec-dashboard.md` | Page Spec: Dashboard | Обзор директора — KPI, статусы договоров (M0) | Active | ADR-29, ADR-34 |
| `docs/04_architecture/04_page-spec-legal-entities.md` | Page Spec: Legal Entities | Юридические лица CRUD (M0) | Active | ADR-07, ADR-34 |
| `docs/04_architecture/05_page-spec-projects.md` | Page Spec: Projects | Проекты CRUD with objects/team (M0) | Active | ADR-07, ADR-29, ADR-30, ADR-34 |
| `docs/04_architecture/06_page-spec-contractors.md` | Page Spec: Contractors | Контрагенты CRUD (M0) — исправлен JOIN, типы COMPANY/INDIVIDUAL | Active | ADR-04, ADR-07, ADR-20, ADR-34, ADR-37 |
| `docs/04_architecture/07_page-spec-contracts.md` | Page Spec: Contracts | Договоры CRUD + lifecycle INTENT→SIGNED→ACTIVE (M0) | Active | ADR-07, ADR-17, ADR-24, ADR-34, ADR-38 |
| `docs/04_architecture/08_page-spec-employees.md` | Page Spec: Employees | Сотрудники по отделам/должностям (M0) | Active | ADR-03, ADR-07, ADR-31, ADR-34 |
| `docs/04_architecture/09_page-spec-requests.md` | Page Spec: Мои заявки | Слайс 1.1 — /requests для всех ролей: AccordionGrid, CreateCommitmentSheet (ADR-41, ADR-42) | Active | ADR-07, ADR-34, ADR-38, ADR-41, ADR-42 |
| `docs/04_architecture/10_page-spec-requests-approvals.md` | Page Spec: Очередь Директора | Слайс 1.2 — /requests/approvals для DIRECTOR/DEPUTY_DIRECTOR: ApprovalsGrid, RejectSheet, SLA-таймер, badge (ADR-42, ADR-27) | Active | ADR-07, ADR-27, ADR-34, ADR-38, ADR-40, ADR-42 |
| `docs/04_architecture/11_page-spec-payments.md` | Page Spec: Казначейский стол | Слайс 1.3 — /dashboard/payments для TREASURER: PaymentsGrid, RecordPaymentSheet (ADR-43) | Active | ADR-07, ADR-34, ADR-38, ADR-40, ADR-43 |
| `docs/04_architecture/12_page-spec-avr-document.md` | Page Spec: АВР + OCR Gate | Слайс [C.2] — AvrDocumentSheet: строки работ, cost_code_id (ADR-41), OCR confidence gate, data_status lifecycle | **IMPLEMENTED** | ADR-41, ADR-38, Blueprint §5.2 |


## Delivery & Operations

| Path | Title | Purpose | Status | Linked Docs |
|---|---|---|---|---|
| `docs/06_delivery/01_agent-first-10-plan.md` | Agent-First 10/10 Plan | Implementation plan for full agent readiness | Completed | This index |
| `docs/06_delivery/02_master-roadmap.md` | Master Delivery Roadmap | M0→M4 milestone timeline | **SUPERSEDED** by Anti-Big Bang | — |
| `docs/06_delivery/03_anti-big-bang-roadmap.md` | Anti-Big Bang Roadmap | 7-phase vertical slice implementation order (Ф0-Ф6) | Active | Blueprint §4, Value Stream Map, ADR-38 |
| `docs/06_delivery/04_phase0-frontend-plan.md` | Phase 0 Frontend Plan | 7 vertical UI slices: App Shell → Legal Entities → Contractors → Projects → Contracts → Employees → Dashboard | Active | AGENTS.md §2, all page specs |
| `docs/06_delivery/05_phase1-execution-plan.md` | Phase 1 Execution Plan v2 | Детальный план Фазы 1 с интегрированными Pre-Mortem рисками: 4 группы слайсов [A]-[D], warranty calc, approval matrix, OCR gate | Active | Anti-Big-Bang Roadmap §Ф1, ADR-38, ADR-41, ADR-42 |
| `docs/06_delivery/06_phase0-code-review.md` | Phase 0 Code Review | Code Review documenting audited components, identified blockers, and resolved defects | Active | ADR-38, ADR-39, ADR-40, AGENTS.md |
| `docs/06_delivery/07_hat-slice-b-current-stage.md` | HAT: Слайс [B] | Инструкция для ручного тестирования current_stage VIEW | Active | `docs/06_delivery/05_phase1-execution-plan.md` |
| `docs/06_delivery/08_hat-slice-c2-avr-ocr-gate.md` | HAT: Слайс [C.2] | 5 тест-сценариев: OCR gate, ADR-41 (cost_code_id), lifecycle DRAFT→SUBMITTED→COMMITTED, роли ПМ/ПТО | **Ожидает** | `docs/04_architecture/12_page-spec-avr-document.md` |


## Operations

| Path | Title | Purpose | Status | Linked Docs |
|---|---|---|---|---|
| `docs/07_operations/01_cross-agent-handoffs.md` | Cross-Agent Handoff Signals | Commit message signal tags and PR labels for inter-agent communication | Active | AGENTS.md §0 |
| `docs/07_operations/02_setup-from-scratch.md` | Setup From Scratch | Step-by-step guide to set up project on a new machine | Active | — |
| `docs/07_operations/03_dependency-update-strategy.md` | Dependency Update Strategy | Automated + manual dependency update process | Active | — |
| `docs/07_operations/04_disaster-recovery.md` | Disaster Recovery Plan | Recovery procedures for Supabase, GitHub, machine loss | Active | — |

## Reference

| Path | Title | Purpose | Status |
|---|---|---|---|
| `docs/08_reference/01_roles-and-permissions.md` | Roles & Permissions | System and project role reference | Active |
| `docs/08_reference/02_development-skills-guide.md` | Development Skills Guide | Developer onboarding / AI skills | Active |
| `docs/08_reference/03_project-context.md` | Project Context Snapshot | Full project context for new agents/machines | Active |
| `docs/08_reference/04_developer-resources.md` | Developer Resources | Development environment, scripts and UI components | Active |
| `docs/08_reference/05_cost-codes.csv` | Cost Codes Reference | Cost code master data | Active |

## Architecture Decision Records

| Path | Title | Status | Linked Docs |
|---|---|---|---|
| `docs/03_decisions/01_screen-access-model.md` | Screen Access Model | Active | Blueprint §2 |
| `docs/03_decisions/02_department-navigation.md` | Department Navigation | Active | ADR-01, ADR-13 |
| `docs/03_decisions/03_role-as-position.md` | Role As Position | Active | ADR-31 |
| `docs/03_decisions/04_contractor-hierarchy.md` | Contractor Hierarchy | Active | ADR-06, ADR-07b |
| `docs/03_decisions/05_dashboard-workday-contractor-manager.md` | Dashboard Workday Contractor Manager | Active | ADR-01 |
| `docs/03_decisions/05b_matrix-org-and-pm-role.md` | Matrix Org And PM Role | Active | Blueprint §2, ADR-31 |
| `docs/03_decisions/06_contractor-employee-link.md` | Contractor Employee Link | Active | ADR-04, ADR-07b |
| `docs/03_decisions/06b_cost-codes-dual-structure.md` | Cost Codes Dual Structure | Active | Blueprint §4, ADR-28b |
| `docs/03_decisions/06c_typography-fira-sans-fira-code.md` | Typography Fira Sans / Fira Code | Superseded | DESIGN.md (Inter) |
| `docs/03_decisions/07_accordion-table-standard.md` | Accordion Table Standard | Active | DESIGN.md, ADR-34 |
| `docs/03_decisions/07b_contractor-lifecycle-payment-threshold.md` | Contractor Lifecycle Payment Threshold | Active | ADR-04, ADR-20 |
| `docs/03_decisions/08_deployment-environments.md` | Deployment Environments | Active | System Overview |
| `docs/03_decisions/09_tech-stack.md` | Tech Stack | Active | System Overview |
| `docs/03_decisions/10_project-entity.md` | Project Entity | Active | Blueprint §4 |
| `docs/03_decisions/11_dual-path-p2p-workflow.md` | Dual Path P2P Workflow | Active | Blueprint §3, ADR-38 |
| `docs/03_decisions/12_purchase-item-lifecycle.md` | Purchase Item Lifecycle | Superseded | ADR-11, ADR-38 |
| `docs/03_decisions/13_routing-model.md` | Routing Model | Active | ADR-01, ADR-02 |
| `docs/03_decisions/14_overhead-project-type.md` | Overhead Project Type | Active | ADR-10 |
| `docs/03_decisions/15_avr-lifecycle-esf.md` | AVR Lifecycle ESF | Active | ADR-35 |
| `docs/03_decisions/16_1c-integration-pattern.md` | 1C Integration Pattern | Active | Blueprint §6 |
| `docs/03_decisions/17_warranty-retention.md` | Warranty Retention | Active | ADR-36 |
| `docs/03_decisions/18_approval-matrix.md` | Approval Matrix | Active — [A.2] Реализовано: авто-утверждение, batch approve, бейдж «авто» (мигр. 0010) | ADR-38 |
| `docs/03_decisions/19_direct-payment-order.md` | Direct Payment Order | Active | ADR-11, ADR-36 |
| `docs/03_decisions/20_contractor-volume-limit.md` | Contractor Volume Limit | Active | ADR-07b |
| `docs/03_decisions/21_subcontractor-ledger.md` | Subcontractor Ledger | Active | ADR-32 |
| `docs/03_decisions/22_sourcing-workspace.md` | Sourcing Workspace | Active | ADR-38 |
| `docs/03_decisions/23_avr-photo-recognition.md` | AVR Photo Recognition | Active | ADR-35 |
| `docs/03_decisions/24_contract-closeout.md` | Contract Closeout | Active | ADR-29 |
| `docs/03_decisions/25_change-orders-excess.md` | Change Orders Excess | Active | ADR-11 |
| `docs/03_decisions/26_grn-warehouse.md` | GRN Warehouse | Active | ADR-38 |
| `docs/03_decisions/27_sla-framework.md` | SLA Framework | Active | Blueprint §8 |
| `docs/03_decisions/28_material-intelligence-graphrag-strategy.md` | Material Intelligence GraphRAG Strategy | Active | ADR-22 |
| `docs/03_decisions/28b_triple-hierarchy-p2p.md` | Triple Hierarchy P2P | Active | ADR-11, ADR-06b |
| `docs/03_decisions/29_project-lifecycle.md` | Project Lifecycle | Active | ADR-10 |
| `docs/03_decisions/30_object-as-project-child.md` | Object As Project Child | Active | ADR-10, ADR-29 |
| `docs/03_decisions/31_org-structure-and-roles.md` | Org Structure And Roles | Partially Superseded | Blueprint §2, ADR-05b |
| `docs/03_decisions/32_contractor-summary-trigger-ledger.md` | Contractor Summary Trigger Ledger | Active | ADR-21 |
| `docs/03_decisions/33_cascade-visibility.md` | Cascade Visibility | Active | ADR-01, ADR-13 |
| `docs/03_decisions/34_ui-interaction-patterns.md` | UI Interaction Patterns | Active | DESIGN.md, ADR-07 |
| `docs/03_decisions/35_avr-module-architecture.md` | AVR Module Architecture | Active | ADR-15, ADR-23 |
| `docs/03_decisions/36_unified-payment-registry.md` | Unified Payment Registry | Partially Superseded | ADR-38, Value Stream Map, Blueprint §4 |
| `docs/03_decisions/37_beneficial-owner-visibility.md` | Beneficial Owner Payment Visibility | Pending | ADR-36, ADR-04, Blueprint §8.11 |
| `docs/03_decisions/38_task-per-role-architecture.md` | Task Per Role Architecture | Active | Blueprint §4, ADR-11, ADR-36 |
| `docs/03_decisions/39_project-object-work-stream.md` | Project Object Work Stream (CIVIL/MEP) | Active | ADR-30, ADR-38 |
| `docs/03_decisions/40_client-component-initial-data-loading.md` | Client Component Initial Data Loading | Active | ADR-34 |
| `docs/03_decisions/41_cost-code-at-avr-line-level.md` | Cost Code At AVR Line Level | Active | ADR-38, ADR-21, ADR-36, Blueprint §4.2 |
| `docs/03_decisions/42_requests-registry-view-model.md` | Requests Registry View Model | Active | ADR-36, ADR-19, ADR-14, ADR-38, ADR-01 |
| `docs/03_decisions/43_payment-tasks-schema.md` | Payment Tasks Schema | Active | ADR-11, ADR-36, ADR-38 |
| `docs/03_decisions/44_security-and-rls-hardening.md` | Security And RLS Hardening | Active | ADR-01, ADR-09, ADR-43 |
| `docs/03_decisions/45_ap-advance-payment-form.md` | AP Advance Payment Form | Active | ADR-38, ADR-42, ADR-43, ADR-21 |
| `docs/03_decisions/46_contractor-level-requests-nesting.md` | Contractor Level Requests Nesting | Active | ADR-07, ADR-21, ADR-38, ADR-42, ADR-43 |
| `docs/03_decisions/47_contract-items-sov.md` | Contract Items (Schedule of Values) | Active | ADR-41, Blueprint §4 |
| `docs/03_decisions/48_pm-avr-approval-step.md` | PM утверждает АВР после ПТО | Active | ADR-05, ADR-35, Blueprint §8.5 |
| `docs/03_decisions/49_project-centric-ui-navigation.md` | Project-Centric UI Navigation | Active | ADR-07, Blueprint §9 |



## Experiments

| Path | Title | Purpose | Status |
|---|---|---|---|
| `docs/05_experiments/01_agent-first-audit-v2-premortem.md` | Agent-First Audit v2 + Pre-Mortem | Readiness assessment and failure scenario analysis | Completed |
| `docs/05_experiments/02_agent-first-audit-v3-portability.md` | Agent-First Audit v3 + Portability Pre-Mortem | Self-sufficiency analysis, 10-year maintainability plan | Completed |
| `docs/05_experiments/03_agent-first-audit-v4-readiness.md` | Agent-First Audit v4 + Dev Readiness | Full 10-dimension review with graph topology, final 9.5/10 | Completed |
