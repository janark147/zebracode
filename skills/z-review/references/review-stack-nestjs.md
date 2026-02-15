# NestJS Review Checklist

Stack-specific review items for NestJS projects. Loaded when `stack.framework` is `nestjs`. Fed to review agents as additional context alongside the generic review instructions.

## Quality Review Items

### Architecture & Patterns
- Every feature in its own module — controllers, services, and DTOs grouped by domain
- Controllers are thin — business logic lives in services
- Repository pattern used for database access (not raw queries in services)
- Dependency injection used correctly — all injectables registered in module `providers` (or `exports` for cross-module)
- No circular module dependencies (no `forwardRef()` unless absolutely necessary and documented)

### NestJS/TypeScript Specifics
- DTOs use `class-validator` decorators for runtime validation (`@IsString()`, `@IsNotEmpty()`, `@IsOptional()`)
- DTOs use `class-transformer` decorators where needed (`@Exclude()`, `@Transform()`)
- Global validation pipe configured (`ValidationPipe` with `whitelist: true`, `forbidNonWhitelisted: true`)
- Guards, interceptors, and pipes scoped correctly (global vs controller vs method level)
- Proper use of NestJS decorators (`@Body()`, `@Param()`, `@Query()`) with DTO types
- Custom decorators follow NestJS conventions (`createParamDecorator` for param decorators)
- Exception filters handle errors consistently (not raw `try/catch` with manual response building)
- TypeORM/Prisma/Mongoose entities align with DTOs and migrations are present

### Module Registration
- New providers registered in module's `providers` array
- Cross-module services listed in `exports` array of the providing module and `imports` of the consuming module
- Dynamic modules configured correctly (`forRoot()`, `forRootAsync()`, `forFeature()`)
- No provider registered in multiple modules without `@Global()` or explicit re-export

### Swagger / OpenAPI
- `@ApiTags()` on controllers for logical grouping
- `@ApiResponse()` decorators on endpoints documenting success and error responses
- `@ApiProperty()` on DTO properties for accurate schema generation

### Code Cleanliness
- No `console.log()`, `debugger` statements left in code
- No TODO, FIXME, or commented-out code blocks
- Unused imports/variables/services removed
- No unused module registrations

### Testing
- Test files exist for new functionality (DO NOT RUN TESTS — verify file quality only)
- Unit tests use `Test.createTestingModule()` with proper mock providers
- e2e tests use `INestApplication` with proper setup/teardown
- Tests follow project patterns (Jest — NestJS default)
- Edge cases covered: validation errors, unauthorized access, missing resources

## Security Review Items

### Authentication & Authorization
- Guards applied to all protected endpoints (`@UseGuards()` or global `APP_GUARD`)
- Role-based or permission-based authorization via custom guards or `@Roles()` decorator
- No IDOR vulnerabilities — queries scoped to authenticated user where applicable
- JWT strategy validates expiry, signature, and issuer (Passport JWT strategy configured correctly)
- Password handling uses bcrypt (never plain text, never md5/sha1)

### Input Validation & Injection
- `ValidationPipe` active globally with `whitelist: true` (strips unexpected properties)
- `forbidNonWhitelisted: true` configured to reject payloads with extra properties
- DTOs validate all fields — no accepting raw `@Body() body: any`
- TypeORM queries use parameterized queries (`.where("field = :val", { val })`) — no string concatenation
- Prisma queries use parameterized inputs (built-in protection) — verify no `$queryRaw` with string interpolation
- File uploads validated: type whitelist, size limit via `FileInterceptor` with `fileFilter` and `limits`
- Command injection prevented in any `child_process` or `exec` calls

### CORS Configuration
- CORS configured with explicit origins in `main.ts` (`app.enableCors()`) — not wildcard `*` in production
- Credentials, methods, and headers explicitly configured

### Data Exposure
- No sensitive data in logs (passwords, tokens, PII, API keys)
- Response DTOs use `@Exclude()` to omit internal fields (hashed passwords, internal IDs)
- `ClassSerializerInterceptor` enabled to enforce `@Exclude()` / `@Expose()` decorators
- Error responses don't expose stack traces or database schema (exception filters handle this)
- Environment variables loaded via `ConfigModule` — not hardcoded in code

### Rate Limiting
- Rate limiting applied to authentication endpoints (`@nestjs/throttler` or custom guard)
- Pagination enforced on list endpoints (no unbounded queries)
- Request body size limited via platform adapter configuration
