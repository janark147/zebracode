# Next.js Review Checklist

Stack-specific review items for Next.js projects. Loaded when `stack.framework` is `nextjs`. Fed to review agents as additional context alongside the generic review instructions.

> Checked against React 19.3.1, Next.js 16.4.1 on 2026-10-15. If the project uses a newer version, check Context7 before relying on a version-specific statement here.

## Quality Review Items

### Architecture & Patterns
- Server Components used by default — `"use client"` only added when interactivity is required
- Data fetching happens in server components (not client-side `useEffect` + `fetch` for initial data); server actions are for mutations, not data fetching
- Proper separation between server and client component boundaries
- Shared layouts used for common UI (not duplicated across pages)
- Proxy (`proxy.ts`, formerly `middleware.ts`) used appropriately (optimistic auth checks, redirects) — not overloaded with business logic

### Next.js Specifics (App Router)
- Route segments follow file-system conventions (`page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`)
- `loading.tsx` and `error.tsx` present for routes with data fetching
- Proper use of `generateMetadata` or `metadata` export for SEO
- Server Actions validate input (Zod or manual) — they're public HTTP endpoints
- `updateTag()` / `revalidateTag(tag, profile)` / `revalidatePath()` called after data mutations (stale cache prevention; single-argument `revalidateTag()` is deprecated)
- Dynamic routes use proper typing for `params` and `searchParams`
- `next/image` used for images (not raw `<img>`) with proper `width`/`height` or `fill`
- `next/link` used for internal navigation (not `<a>` tags) with proper prefetching behavior

### Next.js Specifics (Pages Router — if applicable)
- `getServerSideProps` / `getStaticProps` return correct shape (`{ props: {} }`)
- `getStaticPaths` returns all expected paths with correct `fallback` behavior
- API routes in `pages/api/` properly validate request method and input

### TypeScript
- Page props, server action params, and API route handlers are properly typed
- No `any` types on data boundaries (API responses, form data, server action inputs)
- `searchParams` and route `params` typed correctly

### Code Cleanliness
- No `console.log()`, `debugger` statements left in code
- No TODO, FIXME, or commented-out code blocks
- Unused imports/variables/components removed

### Testing
- Test files exist for new functionality (DO NOT RUN TESTS — verify file quality only)
- Server components and server actions tested appropriately
- Edge cases covered: loading states, error states, not-found states
- Tests follow project patterns (Jest, Vitest, Playwright, Cypress)

## Security Review Items

### Server Actions & API Routes
- Server Actions validate ALL input with Zod or equivalent (they are publicly accessible endpoints)
- Server Actions check authentication and authorization before performing operations
- API routes validate request method (`req.method` in `pages/api/`; App Router `route.ts` exports one function per method, others get 405), input, and authentication
- No sensitive logic exposed to client components — business logic stays server-side

### Authentication & Authorization
- Proxy (`proxy.ts`) checks auth on protected routes (not just client-side redirects) — as an optimistic check only, never the only line of defense
- `cookies()` and `headers()` used server-side for session validation
- Protected API routes and server actions verify session/token before proceeding
- No auth bypass via direct API route access (all routes independently validate auth)

### Environment Variables
- `NEXT_PUBLIC_*` variables contain ONLY intentionally public values
- Server-only secrets (database URLs, API keys) do NOT use `NEXT_PUBLIC_` prefix
- No secrets hardcoded in source — all via environment variables

### XSS Prevention
- No `dangerouslySetInnerHTML` with unsanitized user content
- User-generated content rendered via JSX text interpolation (auto-escaped)
- URL values in `href`/`src` validated against `javascript:` protocol injection
- Server-rendered HTML doesn't include unsanitized user input

### Data Exposure
- Server component data not leaked to client via props (only pass what client needs)
- Error pages don't expose stack traces, database schemas, or file paths
- API responses don't include internal IDs, system info, or excess data
- `console.log` with sensitive data not present in server components (shows in server logs)

### CSRF & Request Integrity
- Server Actions have built-in CSRF protection (POST-only, `Origin` vs `Host` check) — verify `serverActions.allowedOrigins` is not overly broad
- Custom API routes implement CSRF protection if accepting form submissions
- State-changing operations use POST/PUT/PATCH/DELETE (never GET)
