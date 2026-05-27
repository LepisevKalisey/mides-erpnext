# ADR-40: Initial Data Loading for Client Components

**Status:** Accepted  
**Date:** 2026-05-19  
**Applies to:** All Dashboard list views and client components

---

## Context

Client-side components that manage lists with filters (e.g., Projects, Contracts, Contractors, Legal Entities, Employees) previously suffered from a double-fetching issue. On initial page load, the server would pre-fetch the data, but the `useEffect` within the client component would trigger another fetch immediately upon mounting because the dependency array included filter states. This caused a waterfall of loading states, UI flashes, and redundant database queries.

## Decision

All client components managing list states with filters must accept their initial data as a prop from the Server Component (`page.tsx`). 
Additionally, a `useRef` hook must be used to track the initial mount and prevent the `useEffect` from triggering a data fetch on the very first render.

### Implementation Pattern

**1. Server Component (`page.tsx`)**
```tsx
export default async function ListPage() {
  // SSR Pre-fetch
  const initialData = await getData({});
  
  return <ListClient initialData={initialData} />;
}
```

**2. Client Component (`list-client.tsx`)**
```tsx
"use client";

import { useState, useEffect, useCallback, useRef } from "react";

export function ListClient({ initialData }: { initialData: DataType[] }) {
  const [data, setData] = useState(initialData);
  const isFirstMount = useRef(true);

  const loadData = useCallback(() => {
    // ... data fetching logic ...
  }, [filters]);

  useEffect(() => {
    if (isFirstMount.current) {
      isFirstMount.current = false;
      return; // Skip the fetch on initial mount
    }
    loadData();
  }, [filters, loadData]);

  // Sync state if initial props change (e.g. Server Action revalidation)
  useEffect(() => {
    setData(initialData);
  }, [initialData]);
  
  // ...
}
```

## Consequences

- **Eliminates redundant network waterfalls**: Pages render immediately with data fetched during Server-Side Rendering (SSR).
- **Reduced Database Load**: Eliminates double queries on page load.
- **Improved UX**: Users no longer see a flash of a loading skeleton right after the page loads.
- **Consistency**: Standardizes how initial state is managed across all dashboard modules.
