# Django Planning Notes

Stack-specific considerations when creating a plan for a Django project.

## Phase Structuring

- **Migrations first**: If the feature needs new models or field changes, plan the migration phase before views/serializers. Run `makemigrations` + `migrate` as part of the phase.
- **Models before views**: Django's ORM drives everything. Model definitions must exist before views, serializers, or forms reference them.
- **DRF vs Django Views**: Check if the project uses Django REST Framework. If so, plan serializers + viewsets rather than forms + template views.
- **Signals**: If the feature triggers side effects, plan signals in the same phase as the model that emits them.

## Common Phase Patterns

- **Data layer phase**: Model + Migration + Admin registration + Factory (if using factory_boy)
- **API phase (DRF)**: Serializer + ViewSet + Router URL registration + Permissions
- **View phase (Django)**: View/CBV + Form + Template + URL conf
- **Task phase**: Celery task + signal wiring + management command (if needed)

## Planning Pitfalls

- **App structure**: New features may need a new Django app (`python manage.py startapp`). Plan app creation and `INSTALLED_APPS` registration.
- **Settings split**: Check if settings are split (`settings/base.py`, `settings/local.py`, etc.). Environment-specific settings need correct file targeting.
- **Permissions**: DRF permission classes vs Django's `@login_required`/`PermissionRequiredMixin`. Plan authorization in the same phase as the view.
- **Queryset optimization**: Note `select_related`/`prefetch_related` requirements in action points when planning views that fetch related data.
- **Custom managers**: If complex queries are needed, plan custom model managers rather than ad-hoc querysets in views.

## Must-Have Considerations

- **Artifacts**: Include model file, migration, view/viewset, serializer/form, URL conf update, template (if applicable), test files
- **Links**: URL → View → Serializer/Form → Model → Migration chain. Also: Signal → Receiver, Task → Celery config
- **Truths**: "API returns {status code} for {scenario}" + "Unauthenticated requests return 401/403" + "Invalid data returns 400 with field errors"
