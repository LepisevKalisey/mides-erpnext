# ADR-34: UI Interaction Patterns — Dashboard & Detail Views

**Status:** Accepted  
**Date:** 2026-05-13  
**Applies to:** All MidesCloud web UI components

---

## Context

Recurring inconsistencies in UI interaction patterns across dashboard widgets, list pages, and action controls. These rules standardise how the application behaves in common scenarios.

---

## Decision

### Rule 1 — Icon-only action buttons

In compact contexts (table rows, widget cards, list items), action buttons **must not contain text labels**. Use icon-only buttons with a clear visual affordance (tooltip on hover if needed).

**Applies to:** approve/reject, edit/delete, claim/release, upload, any inline action.

**Rationale:** Text labels in dense layouts create visual noise and reduce scanning speed. Icons communicate intent at a glance.

**Implementation:**
```tsx
// ✅ Correct — icon only, tooltip via title attribute
<button title="Утвердить" className="..."><Check className="h-4 w-4" /></button>

// ❌ Wrong — text wastes space in compact card
<button><Check /> Утвердить</button>
```

---

### Rule 2 — Detail sidebar instead of inline expansion

When a compact view (widget card, table row) does not show all necessary data (contractor details, amount breakdown, history, attachments), clicking the item **must open a slide-in sidebar panel** (right-side drawer) showing the full record.

**Do not** expand inline in the card or navigate away to a separate page for details.

**Applies to:** approval queue items, purchase items in supply view, AVR cards, payment items.

**Sidebar must contain:**
- Full item data (all fields)
- Contractor / initiator info
- Status history / audit log
- Contextual actions (approve, reject, upload, etc.)

**Rationale:** Preserves dashboard context. Director can review and act without losing their place.

---

### Rule 3 — Widget titles as navigation links

If a dashboard widget summarises data from a dedicated module page, the **widget title must be a clickable link** navigating to that page.

**Applies to:** any summary widget on the Director Dashboard and other dashboards.

| Widget | Target route |
|---|---|
| Требует утверждения | `/procurement` |
| SLA — нарушения сроков | `/supply` |
| Освоение бюджета | `/projects` |
| Расходы за период | `/requests` |

**Rationale:** Dashboard is a launchpad. One click to the full data set.

---

### Rule 4 — No page-level headers or subtitle descriptions

Pages **must not** have a large `<h1>` title or subtitle/description paragraph at the top of the main content area. The page context is already established by:
- The sidebar navigation item (active state)
- The first tab label

**Applies to:** all main content pages.

**Exception:** Onboarding screens, empty-state explanatory text, and modal/dialog headers are exempt.

**Rationale:** Redundant headers waste vertical space and add visual clutter. Content should start immediately.

---

## Consequences

- Reduced visual clutter in all dashboard and list views
- Faster director decision-making via sidebar detail panels
- Consistent navigation pattern: widget title = link to full list
- More vertical real estate for actual content on all pages
