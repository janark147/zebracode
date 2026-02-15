# Vue.js Review Checklist

Stack-specific review items for Vue.js projects. Loaded when `stack.framework` is `vue`. Fed to review agents as additional context alongside the generic review instructions.

## Quality Review Items

### Architecture & Patterns
- Component API style is consistent with project (Composition API vs Options API — don't mix)
- Business logic extracted into composables (`use*`), not embedded in components
- State management uses the project's chosen library (Pinia, Vuex, or none) — no mixing
- Proper use of props/emits for parent-child communication — no excessive event bus or provide/inject abuse
- Page components separated from reusable UI components

### Vue Specifics
- `v-for` always has a `:key` with a stable, unique identifier (not array index, unless list is static)
- `v-if` and `v-for` never used on the same element (Vue 3 precedence issue)
- Reactive refs accessed with `.value` in `<script setup>` and without `.value` in templates
- Computed properties used for derived state (not methods that recalculate on every render)
- Watchers have proper cleanup and avoid infinite loops (no watcher that modifies its own dependency)
- `defineProps` and `defineEmits` use TypeScript generics (if project uses TS)
- Component registration follows project pattern (auto-import, global, or local)
- Lifecycle hooks in correct order and used appropriately (`onMounted` for DOM access, not `setup`)

### Inertia.js (if applicable)
- Shared data accessed via `usePage()` composable, not redundant API calls
- Form submissions use Inertia's `useForm()` for proper progress/error handling
- Navigation uses `router.visit()` / `<Link>` instead of raw `window.location`
- Preserved scroll position handled where needed

### Code Cleanliness
- No `console.log()`, `debugger` statements left in code
- No TODO, FIXME, or commented-out code blocks
- Unused imports/variables/components removed
- No unused component registrations

### Testing
- Test files exist for new functionality (DO NOT RUN TESTS — verify file quality only)
- Components tested for user-facing behavior, not internal implementation
- Edge cases covered: loading states, error states, empty states
- Tests follow project patterns (Vitest, Vue Test Utils, Cypress Component Testing)

## Security Review Items

### XSS Prevention
- No `v-html` with unsanitized user content — if used, content is sanitized with DOMPurify or equivalent
- User-generated content rendered via text interpolation `{{ }}` (auto-escaped), not injected as HTML
- No `eval()`, `Function()`, or `innerHTML` with user-controlled data
- Dynamic attribute bindings (`:href`, `:src`) validated against `javascript:` protocol injection

### Input Handling
- Form inputs validated before submission (VeeValidate, FormKit, or manual validation)
- File upload inputs restrict accepted types and validate file size
- Rich text editor output sanitized before display

### CSRF
- AJAX requests include CSRF token (via Axios defaults, Inertia auto-handling, or meta tag)
- State-changing operations use POST/PUT/PATCH/DELETE (never GET)

### Data Exposure
- No sensitive data (tokens, API keys) in client-side code or bundled assets
- Environment variables use `VITE_` prefix only for intentionally public values
- API responses handled defensively (null/undefined checks on nested properties)
- Error messages don't expose stack traces or internal system structure
