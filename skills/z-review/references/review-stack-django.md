# Django Review Checklist

Stack-specific review items for Django projects (including Django REST Framework). Loaded when `stack.framework` is `django`. Fed to review agents as additional context alongside the generic review instructions.

## Quality Review Items

### Architecture & Patterns
- Views keep business logic minimal — complex logic lives in services, managers, or model methods
- Fat models, thin views pattern followed where established
- DRF serializers handle validation (not raw `request.data` access in views)
- Proper use of class-based views/viewsets with correct mixins (not overriding everything in a generic `APIView`)
- Permission classes applied at view or viewset level

### Django/Python Specifics
- QuerySets optimized: `select_related()` for FK, `prefetch_related()` for M2M and reverse FK (no N+1)
- Migrations are reversible and safe for production (no data loss, no long-running locks on large tables)
- Database transactions used for multi-step write operations (`transaction.atomic()`)
- Celery tasks used for time-consuming operations (email, external APIs, heavy processing)
- Custom managers or querysets used for reusable query logic (not ad-hoc filters in views)
- `F()` and `Q()` expressions used for complex queries (no Python-side filtering of large querysets)
- Proper use of `get_object_or_404()` instead of bare `.get()` with manual 404 handling
- Signals used sparingly and documented — no hidden side effects

### Internationalization
- New translation strings wrapped in `gettext_lazy()` / `_()` for model fields, `gettext()` / `_()` for views
- No hardcoded user-facing strings in views, templates, or serializers
- Translation keys follow existing conventions

### Code Cleanliness
- No `print()`, `pdb.set_trace()`, `breakpoint()`, or `ipdb` debug statements left in code
- No TODO, FIXME, or commented-out code blocks
- Unused imports/variables/functions removed

### Testing
- Test files exist for new functionality (DO NOT RUN TESTS — verify file quality only)
- Tests follow project patterns (pytest-django, Django TestCase, or DRF APITestCase)
- Factories used for test data (factory_boy) — no hardcoded fixture files unless project convention
- Edge cases covered: 404, 403, 400 validation errors, empty querysets

## Security Review Items

### Authentication & Authorization
- Permission classes on all views/viewsets (not just `IsAuthenticated` — check object-level permissions)
- No IDOR vulnerabilities — users can only access resources they own or are authorized for
- `get_queryset()` filtered by current user where applicable (not just the individual object check)
- Token/session handling follows project convention (JWT, session, OAuth2)

### Input Validation & Injection
- All user input validated via serializers or forms (not raw `request.data` or `request.GET` access)
- Raw SQL uses parameterized queries (`.raw(sql, params)` or `cursor.execute(sql, params)`) — no string formatting
- `extra()` and `RawSQL()` avoided unless necessary and properly parameterized
- File uploads validated: type whitelist, size limit, filename sanitization via `upload_to` callable
- Command injection prevented in any `subprocess`, `os.system`, or `Popen` calls

### XSS Prevention
- Templates use `{{ }}` auto-escaping (not `{{ |safe }}` or `{% autoescape off %}` unless rendering trusted HTML)
- DRF responses return JSON (auto-safe) — HTML rendering in DRF browsable API doesn't include user content unsanitized
- User-generated content escaped before inclusion in template context

### CSRF & Request Forgery
- CSRF middleware enabled (not in `CSRF_EXEMPT` list unless API-only with token auth)
- `@csrf_exempt` used only on views with alternative authentication (token, API key)
- State-changing operations use POST/PUT/PATCH/DELETE (never GET)

### Data Exposure
- No sensitive data in logs (passwords, tokens, PII, API keys)
- `DEBUG = False` in production settings
- DRF serializers explicitly list fields (`fields = [...]`) — no `fields = "__all__"` on models with sensitive data
- Error responses don't expose database schema, file paths, or stack traces in production
- `.env` values never committed or hardcoded
