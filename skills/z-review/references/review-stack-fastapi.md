# FastAPI Review Checklist

Stack-specific review items for FastAPI projects. Loaded when `stack.framework` is `fastapi`. Fed to review agents as additional context alongside the generic review instructions.

## Quality Review Items

### Architecture & Patterns
- Route handlers are thin — business logic lives in service functions or dedicated modules
- Repository pattern or CRUD utility layer used for database operations (not raw queries in route handlers)
- Dependency injection via `Depends()` used for shared concerns (auth, DB sessions, pagination)
- Router modules organized by domain, registered in main app with `app.include_router()`
- Response models defined for all endpoints (not returning raw dicts or ORM objects)

### FastAPI/Python Specifics
- Async/sync consistency: `async def` routes use async DB drivers (asyncpg, aiosqlite); `def` routes use sync drivers — no mixing async route with sync DB calls (blocks event loop)
- Pydantic schemas defined for request and response bodies (correct version: v1 `validator` vs v2 `model_validator`)
- Database sessions properly scoped: `yield`-based dependencies with commit/rollback/close lifecycle
- Alembic migrations present for schema changes, reversible, and production-safe
- `select_related` / `joinedload` / `selectinload` used in SQLAlchemy queries (no N+1)
- Background tasks used for non-blocking operations (`BackgroundTasks` or Celery)
- Proper HTTP status codes returned (201 for creation, 204 for deletion, 422 for validation errors)
- Path and query parameters have proper type annotations and validation constraints (`gt=0`, `max_length`, etc.)

### OpenAPI / Documentation
- Route handlers have docstrings (appear in auto-generated `/docs`)
- Response models annotated with `response_model` parameter or return type hints
- `tags` parameter used on routers for logical grouping in Swagger UI

### Code Cleanliness
- No `print()`, `pdb.set_trace()`, `breakpoint()`, or `ipdb` debug statements left in code
- No TODO, FIXME, or commented-out code blocks
- Unused imports/variables/functions removed

### Testing
- Test files exist for new functionality (DO NOT RUN TESTS — verify file quality only)
- Tests use `TestClient` (sync) or `AsyncClient` (async) matching project convention
- Database fixtures with proper setup/teardown (not leaving test data behind)
- Edge cases covered: 404, 403, 422 validation errors, empty results

## Security Review Items

### Authentication & Authorization
- Auth dependencies applied to route handlers or router-level (`dependencies=[Depends(get_current_user)]`)
- No IDOR vulnerabilities — queries scoped to current user where applicable
- Permission/role checks implemented as dependencies, not inline in route handlers
- JWT tokens validated properly: expiry, signature, issuer (not just decoded)
- OAuth2 scopes enforced where applicable

### Input Validation & Injection
- All user input validated via Pydantic schemas (not raw `request.body()` or `request.json()`)
- SQLAlchemy queries use parameterized statements (`.filter(Model.field == value)`) — no string formatting in `.text()` or raw SQL
- File uploads validated: content type whitelist, size limit via `UploadFile` constraints
- Path parameters validated with type annotations and constraints (no path traversal via `../`)
- Command injection prevented in any `subprocess`, `os.system`, or `asyncio.create_subprocess` calls

### CORS Configuration
- CORS middleware configured with explicit origins (not `allow_origins=["*"]` in production)
- Credentials, methods, and headers explicitly allowed (not blanket wildcards)

### Data Exposure
- No sensitive data in logs (passwords, tokens, PII, API keys)
- Response models exclude internal fields (database IDs, hashed passwords, internal metadata)
- Error handlers don't expose stack traces, file paths, or database schema in production
- Environment variables loaded via `pydantic-settings` or `python-dotenv` — not hardcoded

### Rate Limiting & DoS
- Rate limiting applied to authentication endpoints (login, token refresh)
- Large file uploads have size constraints
- Pagination enforced on list endpoints (no unbounded `SELECT *` via API)
