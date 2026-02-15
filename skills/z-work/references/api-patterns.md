# API Implementation Patterns

Loaded when the current phase involves API work (new endpoints, controllers, services, serializers).

## Implementation Checklist

When implementing API endpoints, ensure each endpoint has:

1. **Route registration** — added to the correct route file/group, with proper HTTP method and middleware
2. **Input validation** — request validation class/schema (FormRequest, DTO, Pydantic schema, etc.) with appropriate rules
3. **Authorization** — policy/guard/permission check before business logic executes
4. **Controller/handler** — thin controller that delegates to a service for complex logic
5. **Response format** — consistent with existing API responses (resource/serializer for success, structured error for failure)
6. **Error handling** — appropriate HTTP status codes, meaningful error messages, no stack traces in production
7. **Tests** — request/integration tests covering: valid input, invalid input (422), unauthorized (401/403), not found (404), and any business-rule failures

## Conventions to Check

Before writing API code, verify these against the existing codebase:
- **Naming**: How are routes named? RESTful? Custom?
- **Versioning**: Is the API versioned (`/api/v1/`)? Which version?
- **Pagination**: What pagination style? Cursor-based? Page-based? What helper?
- **Response envelope**: Does the API wrap responses (`{ data: ..., meta: ... }`)? Or return raw?
- **Error format**: How are validation errors structured? How are domain errors returned?
- **Auth middleware**: What middleware stack do existing authenticated routes use?

## Security Reminders

- Parameterized queries only — never concatenate user input into SQL
- Validate and sanitize all user input at the boundary
- Rate limiting for public endpoints
- CORS configuration if serving a separate frontend
- Never expose internal IDs or stack traces in error responses
- Audit logging for sensitive operations (delete, permission change, etc.)
