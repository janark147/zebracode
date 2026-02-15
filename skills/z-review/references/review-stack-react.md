# React Review Checklist

Stack-specific review items for React projects (Vite, CRA, or custom bundler — NOT Next.js). Loaded when `stack.framework` is `react`. Fed to review agents as additional context alongside the generic review instructions.

## Quality Review Items

### Architecture & Patterns
- Components follow project's established patterns (functional components, hooks-based)
- Business logic extracted into custom hooks (`use*`), not embedded in components
- State management uses the project's chosen library (Context, Redux, Zustand, Jotai) — no mixing
- Proper separation between container/smart components and presentational/dumb components
- No prop drilling deeper than 2-3 levels — use context or state management instead

### React Specifics
- Hooks follow Rules of Hooks (no conditional hooks, no hooks in loops)
- `useEffect` dependencies are correct and complete — no missing deps, no unnecessary deps
- `useEffect` cleanup functions present for subscriptions, timers, and event listeners
- `key` props on list items use stable, unique identifiers (not array index, unless list is static and never reordered)
- No direct DOM manipulation — use refs when DOM access is necessary
- `useMemo`/`useCallback` used only when there's a demonstrated performance need (not premature optimization)
- Error boundaries placed around feature sections that fetch data or render dynamic content
- React Query/SWR cache keys are consistent and follow project conventions

### CSS & Styling
- CSS approach matches project convention (CSS Modules, Tailwind, styled-components, etc.)
- No inline styles for non-dynamic values
- Responsive design maintained — no hardcoded widths that break at breakpoints

### Code Cleanliness
- No `console.log()`, `debugger`, or `console.debug()` statements left in code
- No TODO, FIXME, or commented-out code blocks
- Unused imports/variables/components removed

### Testing
- Test files exist for new functionality (DO NOT RUN TESTS — verify file quality only)
- Components tested with user-facing behavior (not implementation details)
- Edge cases covered: loading states, error states, empty states
- Tests follow project patterns (React Testing Library, Vitest/Jest)
- Mock boundaries match project conventions (MSW for API, jest.mock for modules)

## Security Review Items

### XSS Prevention
- No `dangerouslySetInnerHTML` with unsanitized user content — if used, content is sanitized with DOMPurify or equivalent
- User-generated content rendered via text nodes (JSX `{}` escapes by default), not injected as HTML
- No `eval()`, `Function()`, or `new Function()` with user-controlled input
- URL values validated before use in `href`, `src`, or `action` attributes (prevent `javascript:` protocol injection)

### Input Handling
- Form inputs validated before submission (React Hook Form, Formik, or manual validation)
- File upload inputs restrict accepted types and validate file size client-side
- Rich text editor output sanitized before display

### Data Exposure
- No sensitive data (tokens, API keys, secrets) in client-side code or bundled assets
- Environment variables use `REACT_APP_` / `VITE_` prefix only for intentionally public values
- API responses handled defensively (null checks before accessing nested properties)
- Error messages displayed to users don't expose stack traces, internal IDs, or system structure

### Authentication & State
- Auth tokens stored securely (httpOnly cookies preferred over localStorage)
- Protected routes redirect unauthenticated users
- Sensitive data cleared from state/storage on logout
