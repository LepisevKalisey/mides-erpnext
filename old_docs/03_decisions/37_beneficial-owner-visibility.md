# ADR-37: Beneficial Owner — Payment Visibility

**Status:** PENDING  
**Date:** 2026-05-17  
**Authors:** System Architect  
**Relates to:** ADR-36 (Unified Payment Registry), ADR-04 (Contractor Hierarchy)

## Context

System Blueprint §8, invariant #11 states:

> «При утверждении платежа директор видит суммарную ответственность бенефициара (сумма всех его контрагентов) — ADR-37»

Currently, when a Director approves a payment, they see only the immediate contractor's balance. They cannot see the **aggregate exposure** across all contractors linked to the same Beneficial Owner (`beneficial_owners` table).

This creates a risk: a beneficial owner with multiple contractor entities could accumulate dangerous total debt without the Director's awareness.

## Decision

**PENDING** — This ADR is a placeholder. The decision has not been finalized.

### Proposed approach (to be validated):

1. Create a database VIEW `beneficial_owner_exposure` that aggregates:
   - Total open contract value across all contractors linked to a given `beneficial_owner_id`
   - Total paid amount
   - Total pending payments
   - Net exposure (open - paid)

2. Surface this in the Payment Approval Sheet as a warning panel:
   - If total exposure exceeds threshold (configurable per company), show amber alert
   - Director sees: beneficial owner name, total contractors count, aggregate numbers

3. No new tables required — this is a VIEW + UI enhancement on the existing `contractors.beneficial_owner_id` FK.

## Alternatives Considered

1. **Denormalized `total_exposure` column on `beneficial_owners`** — Rejected. Violates "no stored computed values" invariant (§8.5).
2. **Real-time calculation in application code** — Rejected. Performance risk with many contractors; better as a materialized VIEW.
3. **Defer to M5 (Payments module)** — Possible, but the invariant is declared in M0 Blueprint, suggesting it should be designed now even if implemented later.

## Consequences

- Director gains aggregate risk visibility at payment approval time
- No schema migration required for the VIEW approach
- UI enhancement required in the Payment Approval Sheet (M5)
- Threshold configuration requires a `company_settings` table (M8 scope)

## Implementation Phase

**Target:** M5 (Payment Approval module)  
**Prerequisite:** ADR-36 (Unified Payment Registry) must be implemented first.

## Open Questions

- [ ] What is the default exposure threshold before showing a warning?
- [ ] Should the VIEW be materialized for performance, or is a regular VIEW sufficient?
- [ ] Should the exposure include rejected/cancelled payments or only active ones?
