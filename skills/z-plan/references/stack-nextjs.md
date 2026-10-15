# Next.js Planning Notes

Stack-specific considerations when creating a plan for a Next.js project.

> Checked against React 19.3.1, Next.js 16.4.1 on 2026-10-15. If the project uses a newer version, check Context7 before relying on a version-specific statement here.

## Phase Structuring

- **App Router vs Pages Router**: Check the project structure (`app/` vs `pages/`). This fundamentally changes how routes, layouts, and data fetching are planned.
- **Server Components first**: Plan server components and data fetching before client components. Server components provide the data boundary.
- **API routes alongside pages**: If a feature needs API endpoints, plan them in the same phase as the consuming page/component — they're tightly coupled in Next.js.
- **Shared layouts**: If a new page needs a new layout or modifies an existing one, plan layout changes before page components.

## Common Phase Patterns

- **Data layer phase**: Database schema (Prisma/Drizzle migration) + server actions or API routes + types
- **Page phase**: Server component + client components + loading/error states
- **Auth phase**: Proxy (`proxy.ts`, formerly middleware) + auth checks + protected routes
- **Integration phase**: Third-party API clients + environment variables + Node.js runtime compatibility (the `edge` runtime is deprecated)

## Planning Pitfalls

- **Server vs Client boundary**: Every component is server by default (App Router). Mark `"use client"` only when needed. Plan which components need interactivity.
- **Environment variables**: `NEXT_PUBLIC_*` for client, plain for server. Note this in phases that introduce new env vars.
- **Proxy**: Single `proxy.ts` (renamed from `middleware.ts` in Next.js 16) at project root or `src/` — plan carefully if multiple features modify it.
- **Caching and revalidation**: Plan `updateTag`/`revalidateTag(tag, profile)`/`revalidatePath` calls when data mutations happen. With `cacheComponents` enabled (on in new `create-next-app` apps since 16.4), plan `'use cache'` + `cacheLife`/`cacheTag` and `<Suspense>` for request-time data; otherwise note ISR/SSG/SSR strategy per route.
- **TypeScript strict mode**: Check `tsconfig.json` strict settings — plan type definitions accordingly.

## Must-Have Considerations

- **Artifacts**: Include page file, layout (if needed), API route, types file, and test files
- **Links**: Page → Server Action/API Route → Database/Service chain. Also: Layout → Page nesting, Proxy → Route matching
- **Truths**: "Page renders at {route}" + "Data loads without client-side loading spinner (if SSR)" + "Error state handles {failure case}"
