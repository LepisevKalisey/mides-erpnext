# Agent-First Readiness Audit v3 + Pre-Mortem самодостаточности

**Date:** 2026-05-17  
**Status:** COMPLETED  
**Type:** Explanation (conceptual reasoning, trade-offs, context)

## Score

| Метрика | Значение |
|---------|------:|
| Agent-First Score | **7.4/10** |
| Предыдущий Score (v2) | 7.2/10 |
| Предыдущий Score (v1) | 4/10 |
| Целевой Score | 9.0/10 |

## Портативность (Self-Sufficiency)

| Сценарий | Балл |
|----------|-----:|
| Перенос на другой ПК завтра | 6/10 |
| Новый AI-агент (без memory) | 7/10 |
| Возврат через 6 месяцев | 5/10 |
| Через 10 лет (без действий) | 2/10 |
| Через 10 лет (с планом) | 7/10 |

## Полный отчёт

Полный анализ в артефакте Antigravity: `artifacts/agent-first-audit-v3.md`

## Ключевые находки

### Блокеры (P0)
1. **Memory graph эфемерен** — 14 сущностей контекста НЕ в git-репо
2. **KI не гарантированно в git** — .antigravity/knowledge/ статус неясен
3. ~~**Нет .nvmrc / engines**~~ ✅ Решено: .nvmrc + engines в package.json
4. **Нет setup-from-scratch** — невозможно восстановить среду без человека

### Противоречия в документации (P1)
1. skills-guide ссылается на Fira Sans (отменён) и Vanilla CSS (заменён на Tailwind)
2. system-overview указывает Tailwind v4, в package.json — v3.4
3. Memory graph противоречит коду (Drizzle «удалён», но в зависимостях)

### Стратегические дефициты (P2)
1. Нет dependency update strategy
2. ~~Нет architectural fitness functions~~ ✅ Решено: `context-health.ts` (10 проверок)
3. Нет disaster recovery plan
4. 1 мега-коммит вместо гранулярной истории

## План действий (обновлён 2026-05-17)

### ✅ Выполнено
- `context-health.ts` — автоматический детектор дрифта (10 проверок)
- Context Maintenance Protocol в AGENTS.md (таблица «если изменил X, обнови Y»)
- `.nvmrc` + `engines` — Node.js зафиксирован
- Branching strategy в `.antigravityrules` §7 (main=prod, dev=work)
- CI обновлён: `context:check` первым шагом + триггеры на dev+main

### Осталось: 3 фазы, ~7 часов
- **Фаза 1: Самодостаточность (3ч)** — memory export в docs, KI в git, setup-from-scratch guide, fix stale docs, CHANGELOG.md
- **Фаза 2: Верификация (3ч)** — создать ветку dev, тесты auth/workflow, push и верифицировать CI
- **Фаза 3: Стратегия (1ч)** — Dependabot, dependency update strategy, DR plan

## Related

- See: `docs/05_experiments/01_agent-first-audit-v2-premortem.md`
- See: `AGENTS.md` §0 Context Maintenance Protocol
- See: `web/scripts/context-health.ts`
- See: `docs/06_delivery/01_agent-first-10-plan.md`

