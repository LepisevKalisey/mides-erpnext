# System Overview — MidesCloud Architecture

**Date:** 2026-05-17  
**Version:** 2.0 (v3 scaffold)

> For the complete domain model, see `docs/01_product/01_system-blueprint.md`

## Purpose

MidesCloud — система управленческого учёта для строительной компании. Заменяет Google Sheets + Apps Script на масштабируемый веб-сервис с RBAC, WhatsApp OTP и структурированной реляционной моделью.

---

## Tech Stack

| Layer | Technology | Version |
|---|---|---|
| Frontend | Next.js (App Router) | 14.2 |
| ORM | Drizzle ORM | 0.45+ |
| Database | PostgreSQL (Supabase) | 15+ |
| Auth | Supabase Auth | SSR |
| Styling | Tailwind CSS | 3.4.1 |
| Components | shadcn/ui | latest |
| Icons | Lucide React | latest |
| Font | Inter (body), Plus Jakarta Sans (headings) | Google Fonts |

---

## Dev Environment

```
┌─────────────────────────────────────────────────────────┐
│                     Developer                           │
│                  localhost:3000                          │
└────────────────────┬────────────────────────────────────┘
                     │ next dev
┌────────────────────▼────────────────────────────────────┐
│              Next.js 14 (App Router)                    │
│         Server Components + Server Actions              │
│              Supabase SSR (email+password)               │
└────────────────────┬────────────────────────────────────┘
                     │ DATABASE_URL (port 5432)
┌────────────────────▼────────────────────────────────────┐
│           Supabase PostgreSQL (Free Tier)               │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Auth: Managed by Supabase (auth.users),         │   │
│  │        synced to public.profiles, user_roles     │   │
│  │  Core: legal_entities, bank_accounts, projects,  │   │
│  │        project_objects, beneficial_owners,        │   │
│  │        contractors, cost_codes,                   │   │
│  │        project_assignments, project_bank_accounts │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## Auth Flow

```
User → Enter email + password
     → Supabase SSR auth route
     → Session created (cookie via SSR)
     → RBAC via user_roles junction table
```

**Roles (RBAC):** See Blueprint §2 for full 14 system_roles + 7 project_roles.

Current schema supports: `text("role")` in `user_roles` table.

---

## Current Database Schema (Drizzle)

```
profiles ───────── user_roles (RBAC)
 │
 ▼
legal_entities ──── bank_accounts
                    beneficial_owners
 │
 ▼
projects ──── project_objects
         ──── project_assignments (user junction)
         ──── project_bank_accounts (bank junction)
 │
 ▼
contractors ──── cost_codes
```

**Schema files:**
- `web/src/db/schema/auth.ts` — Auth + RBAC tables
- `web/src/db/schema/core.ts` — Business entity tables
- `web/src/db/index.ts` — Drizzle client

---

## Key Files

```
web/
├── src/
│   ├── app/
│   │   ├── api/auth/callback/route.ts   # Supabase OAuth callback
│   │   ├── globals.css                  # CSS custom properties
│   │   ├── layout.tsx                   # Root layout
│   │   └── page.tsx                     # Landing / redirect
│   ├── db/
│   │   ├── index.ts                     # Drizzle client
│   │   └── schema/
│   │       ├── auth.ts                  # Auth tables
│   │       ├── core.ts                  # Business tables
│   │       └── index.ts
│   └── lib/
│       ├── supabase/
│       │   ├── client.ts                # Browser client
│       │   └── server.ts                # Server client
├── drizzle.config.ts
├── tailwind.config.ts
└── package.json
```

---

## Related

- See: `docs/03_decisions/08_deployment-environments.md`
- See: `docs/03_decisions/09_tech-stack.md`
- See: `docs/01_product/01_system-blueprint.md` (full domain model)
- See: `DESIGN.md` (UI tokens and component specs)
