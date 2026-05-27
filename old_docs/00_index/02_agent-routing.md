# Agent Routing Index

> Матрица маршрутизации задач по агентам. Используется Agent Manager для автоматического назначения агента на задачу.

## Task → Agent Routing

| Task Pattern | Agent | Key Pre-read Files |
|---|---|---|
| Новая страница / UI компонент | Frontend Agent (§2) | DESIGN.md, page spec, globals.css |
| Редактирование существующей страницы | Frontend Agent (§2) | DESIGN.md, target component files |
| Новая таблица / миграция | Data Agent (§6) | Blueprint §4, ADR-38, existing schema/ |
| Изменение существующей схемы | Data Agent (§6) | Target schema file, related ADRs |
| API route / Server Action | Backend Agent (§3) | Blueprint §8, auth.ts, schema/ |
| Security hardening / RLS | Backend Agent (§3) | auth.ts, ADR-38, Blueprint §8 |
| Написание тестов | QA Agent (§4) | Page spec, existing tests/, playwright.config |
| Регрессионное тестирование | QA Agent (§4) | Blueprint §8 (invariants) |
| CI/CD pipeline | DevOps Agent (§5) | .github/workflows/, package.json |
| Deployment / Docker | DevOps Agent (§5) | ADR-08, system-overview |
| Новый ADR / решение | Product Agent (§1) | Blueprint, existing ADRs, docs-index |
| Обновление Blueprint | Product Agent (§1) | Blueprint (full), related ADRs |
| Bug fix (UI) | Frontend Agent (§2) | Error logs, target component |
| Bug fix (data) | Backend Agent (§3) | Error logs, schema, Server Action |
| Seed data | Data Agent (§6) | Schema, scripts/seed.ts |

## Output Contract Summary

| Agent | Creates | Must Update |
|---|---|---|
| Product (§1) | docs/0X_folder/NN_name.md | docs-index.md |
| Frontend (§2) | src/app/ or src/components/ | — |
| Backend (§3) | src/db/schema/ or src/app/api/ | schema/index.ts |
| QA (§4) | tests/unit/ or tests/e2e/ | — |
| DevOps (§5) | .github/workflows/ | package.json scripts |
| Data (§6) | src/db/schema/, scripts/ | schema/index.ts, docs-index.md |

## Multi-Agent Task Patterns

Some tasks require collaboration between agents:

| Complex Task | Primary Agent | Secondary Agent |
|---|---|---|
| New module (full CRUD) | Frontend | Backend (schema) → Frontend (UI) |
| New workflow stage | Backend | Product (ADR) → Backend (schema) → Frontend (UI) |
| Performance issue | QA (diagnose) | Frontend or Backend (fix) |
| Security audit | Backend (§3) | QA (§4 for verification tests) |

## Related

- See: `AGENTS.md` for full agent contracts
- See: `docs/06_delivery/03_anti-big-bang-roadmap.md` for phase task assignment
