# Laravel Planning Notes

Stack-specific considerations when creating a plan for a Laravel project.

> Checked against Laravel 13.36.0 on 2026-10-15. If the project uses a newer version, check Context7 before relying on a version-specific statement here.

## Phase Structuring

- **Migrations first**: If the feature needs new tables or columns, put migration work in Phase 1. Laravel migrations must exist before models/controllers reference them.
- **Backend before frontend**: Plan API/controller phases before Vue/Blade UI phases. The frontend needs endpoints to call.
- **Form Requests and Policies**: Plan validation (FormRequest) and authorization (Policy/Gate) as part of the controller phase, not as a separate phase. They're tightly coupled.
- **Events and Listeners**: If the feature triggers side effects (emails, notifications, cache invalidation), plan event/listener creation in the same phase as the triggering action.

## Common Phase Patterns

- **Database phase**: Migration + Model + Factory + Seeder
- **Backend phase**: Controller + FormRequest + Policy + Routes + Service (if complex logic)
- **API phase**: Resource/Collection + API routes + API tests
- **Frontend phase**: Vue components + composables + API client integration
- **Notification phase**: Notification class + Mail template + Event/Listener wiring

## Planning Pitfalls

- **Sail vs local**: Check config `commands.*` for `sail` prefix — determines how test/migrate commands run
- **Queue jobs**: If feature uses queued jobs, note that testing may need `Queue::fake()` or synchronous driver
- **Middleware**: Global middleware, group changes and aliases are registered in `bootstrap/app.php` (Laravel 11+ structure) or `app/Http/Kernel.php` (Laravel 10, and apps upgraded without migrating the structure). Route middleware can be attached by class name without registration
- **Service providers**: New interface bindings/singletons need registering in a service provider, or via `#[Bind]`/`#[Singleton]` attributes (Laravel 12.21+); concrete classes resolve without binding — plan this in the phase that creates the service
- **Database transactions**: If a phase writes to multiple tables, note transaction requirements in the action points

## Must-Have Considerations

- **Artifacts**: Include migration file, model, controller, routes file update, FormRequest, Policy, and test files
- **Links**: Route → Controller → FormRequest → Model → Migration chain. Also: Policy → Model (auto-discovered by naming convention; otherwise `Gate::policy()` or `#[UsePolicy]` in Laravel 12.18+), Event → Listener (auto-discovered from `app/Listeners` in the Laravel 11+ structure; otherwise `Event::listen()` or the app's `EventServiceProvider`)
- **Truths**: "User can {action}" + "Unauthorized user gets 403" + "Invalid input shows validation errors"
