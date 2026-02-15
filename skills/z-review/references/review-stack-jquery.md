# jQuery / Bootstrap / CoreUI Review Checklist

Stack-specific review items for projects using jQuery with Bootstrap or CoreUI frontend. Loaded when `stack.frontend` is `jquery`. Fed to review agents as additional context.

## Quality Review Items

### JavaScript Patterns
- No inline `<script>` blocks with business logic — extract to separate `.js` files
- Event handlers attached via delegation where appropriate (for dynamic content)
- AJAX calls use consistent patterns (same error handling, loading states)
- No global variable pollution — use namespaces, modules, or IIFE patterns

### DataTables
- Configuration consistent with existing tables in the project
- Server-side processing used for large datasets
- Column definitions match backend API response structure
- Export buttons and search configured per project conventions

### Responsive Design
- Layouts verified at mobile, tablet, and desktop breakpoints
- Bootstrap grid classes used correctly (no hardcoded widths that break responsive)
- Modals, dropdowns, and tooltips work on touch devices
- Tables are scrollable or responsive on small screens

### Translations & i18n
- Translations passed from backend to JavaScript via the project's mechanism (check CLAUDE.md for the specific pattern — common patterns include `@json`, JavaScript::put(), or blade data attributes)
- No hardcoded user-facing strings in `.js` files
- Date/number formatting respects locale

## Security Review Items

### XSS Prevention
- User input escaped before DOM insertion (use `.text()` not `.html()` for user content)
- Template literals and string concatenation in jQuery selectors sanitized
- No `eval()`, `Function()`, or `innerHTML` with user-controlled data

### CSRF
- AJAX requests include CSRF token (via `$.ajaxSetup` or per-request header)
- Form submissions include `@csrf` / CSRF meta tag

### Data Handling
- Sensitive data not stored in `localStorage`, `sessionStorage`, or cookies without encryption
- API responses handled defensively (check for null/undefined before accessing nested properties)
- File upload previews sanitized (SVG uploads can contain XSS payloads)
