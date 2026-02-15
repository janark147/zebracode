# Laravel Planning Notes

Stack-specific considerations when creating a plan for a Laravel project.

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
- **Middleware**: New middleware must be registered in `bootstrap/app.php` (Laravel 11+) or `app/Http/Kernel.php` (older)
- **Service providers**: New bindings/singletons need provider registration — plan this in the phase that creates the service
- **Database transactions**: If a phase writes to multiple tables, note transaction requirements in the action points

## Must-Have Considerations

- **Artifacts**: Include migration file, model, controller, routes file update, FormRequest, Policy, and test files
- **Links**: Route → Controller → FormRequest → Model → Migration chain. Also: Policy → Gate registration, Event → Listener registration
- **Truths**: "User can {action}" + "Unauthorized user gets 403" + "Invalid input shows validation errors"
