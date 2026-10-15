# NestJS Planning Notes

Stack-specific considerations when creating a plan for a NestJS project.

> Checked against NestJS 12.1 (incl. @nestjs/swagger 12.0, @nestjs/passport 12.0, @nestjs/authentication 0.1), class-validator 0.15 on 2026-10-15. If the project uses a newer version, check Context7 before relying on a version-specific statement here.

## Phase Structuring

- **Module-first**: NestJS is modular. Every new feature needs a module. Plan module creation as the first step, then register it in the parent module.
- **DTOs before controllers**: Plan Data Transfer Objects and validation pipes before controllers. NestJS validates at runtime with class-validator decorators (`ValidationPipe`) or, since v12, Standard Schema schemas such as Zod (`StandardSchemaValidationPipe`) — these must exist at request handling time.
- **Providers before consumers**: Services, repositories, and guards must be created and registered in the module before controllers or other services inject them.
- **TypeORM/Prisma entity alignment**: If using an ORM, plan entity/schema changes before service logic that queries them.

## Common Phase Patterns

- **Module phase**: Module + Entity/Schema (TypeORM/Prisma/Mongoose) + Migration + DTO (create, update, response)
- **Service phase**: Service + Repository (if repository pattern) + Unit tests
- **Controller phase**: Controller + Route decorators + Guards/Interceptors + Swagger decorators + e2e tests
- **Auth phase**: Guard + Strategy (Passport) + Decorator (@CurrentUser) + Module registration; with `@nestjs/authentication` (NestJS 12+): `AuthenticationModule.forRoot()` + credential provider, with the global guard, `@CurrentUser()` and `@Public()` built in
- **Event phase**: Event class + EventEmitter/CQRS handler + Listener/Saga

## Planning Pitfalls

- **Dependency injection**: Every injectable must be in a module's `providers` array (or `exports` for cross-module use). Forgetting registration is the #1 NestJS error. Plan module registration for every new provider.
- **Circular dependencies**: NestJS does not handle circular module imports gracefully. Plan the module dependency graph to avoid cycles. Use `forwardRef()` only as a last resort.
- **Global vs module-scoped**: Check if guards, pipes, and interceptors are global (`APP_GUARD`) or module-scoped. Plan accordingly — an `APP_*` provider is global from whichever module registers it (docs recommend the module that defines the guard or pipe); `app.useGlobal*()` calls go in `main.ts`.
- **ORM choice**: Check for TypeORM vs Prisma vs Mongoose vs MikroORM vs Drizzle. Each has different migration strategies and entity patterns. Don't assume.
- **Swagger decorators**: If the project uses `@nestjs/swagger`, plan API documentation decorators (`@ApiTags`, `@ApiResponse`, `@ApiProperty`) in the controller phase, not as a separate step.
- **Testing**: NestJS uses its own `Test.createTestingModule()`. Plan test setup with mock providers. Note which providers need mocking in test action points.

## Must-Have Considerations

- **Artifacts**: Include module file, controller, service, DTOs, entity/schema, migration (if ORM), guard (if auth), test files
- **Links**: Module → imports/providers/controllers registration, Controller → Service injection, Service → Repository/Entity, Guard → Strategy, DTO → class-validator decorators (or `schema` option on `@Body()`, NestJS 12+)
- **Truths**: "Endpoint returns {status code} for {scenario}" + "DTO validation rejects {invalid input} with 400" + "Guard blocks unauthenticated requests with 401"
