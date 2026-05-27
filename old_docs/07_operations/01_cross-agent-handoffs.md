# Cross-Agent Handoff Signals

> Протокол для передачи контекста между автономными агентами MidesCloud.

## Commit Message Convention

Каждый агент при завершении работы, затрагивающей домен другого агента,
ОБЯЗАН добавить сигнальный тег в commit message.

### Format

```
<type>(<scope>): <description>

[SIGNAL-TAG] affected-items

Body: what was done, why, what the next agent should know.
```

### Signal Tags

| Tag | From | To | Meaning |
|-----|------|-----|---------|
| `[QA-READY]` | Frontend | QA Agent | Page/component ready for E2E testing |
| `[SCHEMA-UPDATED]` | Backend/Data | Frontend, QA | Schema changed — update queries and types |
| `[MIGRATION-READY]` | Data | Backend | New migration generated — review and push |
| `[ADR-CREATED]` | Product | All | New decision record — may affect implementation |
| `[DESIGN-UPDATED]` | Product | Frontend | DESIGN.md tokens changed — update globals.css |
| `[CI-UPDATED]` | DevOps | All | CI pipeline changed — may affect workflow |
| `[SEED-UPDATED]` | Data | QA | Test data changed — update test expectations |
| `[LOCALE-UPDATED]` | Frontend | QA | Locale strings changed — update E2E assertions |

### Examples

```
feat(projects): implement projects list page

[QA-READY] projects
[SCHEMA-UPDATED] projects, project_objects

AccordionGrid with expandable project → objects hierarchy.
Server Action: getProjects() with director-scoped RLS.
Sheet panel for create/edit form.
QA: seed.ts has 2 projects with 4 objects for E2E.
```

```
feat(schema): add sourcing_tasks table

[SCHEMA-UPDATED] sourcing_tasks, sourcing_results
[MIGRATION-READY] 0003_add_sourcing_tasks

New task table per ADR-38. FK to purchase_items.
Frontend: update imports from @/db/schema.
QA: seed.ts updated with 3 test sourcing tasks.
```

## Pull Request Labels

| Label | Purpose |
|-------|---------|
| `agent:frontend` | Changes by Frontend Agent |
| `agent:backend` | Changes by Backend/Security Agent |
| `agent:data` | Changes by Data/Migration Agent |
| `agent:qa` | Changes by QA Agent |
| `agent:devops` | Changes by DevOps Agent |
| `agent:product` | Changes by Product Agent |
| `needs:review` | Requires human review before merge |
| `auto:merge` | Safe to auto-merge after CI passes |

## Agent-to-Agent Routing

When an agent encounters work outside its domain:

1. Complete current task within own domain
2. Add appropriate signal tag to commit
3. Create a brief note in `docs/07_operations/` if complex handoff context is needed
4. Do NOT attempt cross-domain work (e.g., Frontend Agent must not modify schema)
