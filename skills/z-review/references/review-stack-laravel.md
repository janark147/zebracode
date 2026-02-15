# Laravel Review Checklist

Stack-specific review items for Laravel projects. Loaded when `stack.framework` is `laravel`. Fed to review agents as additional context alongside the generic review instructions.

## Quality Review Items

### Architecture & Patterns
- Service layer used for complex business logic (not in controllers)
- Repository pattern followed where established in the project
- Form Request validation for all user input (with `authorize()` method)
- Proper dependency injection (no `new Service()` in controllers)
- Permission/authorization checks on routes and controller actions
- No code duplication > 5 lines — extract to Traits, Services, or Helpers per project conventions

### Laravel/PHP Specifics
- Eloquent relationships used correctly (no N+1 queries — check for `with()`, `load()`)
- Migrations are reversible (`down()` method exists and works) and safe for production
- Database transactions used for multi-step write operations
- Queue jobs used for time-consuming operations (email, external API calls, heavy processing)
- Proper use of Laravel collections (no unnecessary `->all()` or `->toArray()` on collections that should stay lazy)
- Carbon used for all date/time handling (no raw `date()` or `strtotime()`)
- Soft deletes handled correctly where applicable (queries filter soft-deleted records)

### Internationalization
- New translation keys added to appropriate lang files
- No hardcoded user-facing strings in views, controllers, or JavaScript
- Translation keys follow existing naming conventions

### Code Cleanliness
- No `dd()`, `dump()`, `ray()`, `console.log()` debug statements left in code
- No TODO, FIXME, or commented-out code blocks
- Unused imports/variables/methods removed

### Testing
- Test files exist for new functionality (DO NOT RUN TESTS — verify file quality only)
- Edge cases covered in tests
- Tests follow existing patterns (Feature tests for HTTP integration, Unit tests for isolated logic)
- Test factories updated for new models/columns

## Security Review Items

### Authentication & Authorization
- Form Request `authorize()` methods properly implemented
- Permission checks on sensitive routes (middleware or policy)
- No IDOR vulnerabilities (user can only access resources they own / are authorized for)
- Session handling secure (no session fixation risks)
- Password handling uses Laravel's `Hash` facade (never plain text, never md5/sha1)

### Input Validation & Injection
- All user input validated via Form Requests (not inline validation)
- Raw DB queries use parameter binding (`?` placeholders or named bindings — no string concatenation)
- File uploads validated: type whitelist, size limit, filename sanitization
- Path traversal prevented in file operations (`basename()`, no user-controlled paths)
- Command injection prevented in any `exec()`, `shell_exec()`, `Process` calls

### XSS Prevention
- Blade templates use `{{ }}` (escaped) not `{!! !!}` (raw) unless intentionally rendering trusted HTML
- User-generated content escaped before rendering in JavaScript context
- Rich text editor output (TinyMCE, CKEditor, etc.) sanitized server-side before storage and display

### CSRF & Request Forgery
- `@csrf` token in all forms
- AJAX requests include CSRF token (via meta tag or axios default header)
- State-changing operations use POST/PUT/PATCH/DELETE (never GET)

### Data Exposure
- No sensitive data in logs (passwords, tokens, PII, API keys)
- API responses don't leak internal IDs, stack traces, or system structure
- Error messages don't expose database schema or file paths
- `.env` values never committed or exposed

### Mass Assignment
- Models use `$fillable` (whitelist) or `$guarded` (blacklist) appropriately
- No `Model::create($request->all())` without proper Form Request validation
- Sensitive fields (role, permissions, is_admin) are guarded

### Database
- Migrations don't set sensitive defaults (e.g., `is_admin = true`)
- No plaintext password or secret storage
- Appropriate indexes for columns used in WHERE, ORDER BY, JOIN clauses
- Foreign key constraints with correct ON DELETE behavior
