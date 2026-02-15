# Rails Planning Notes

Stack-specific considerations when creating a plan for a Ruby on Rails project.

## Phase Structuring

- **Migrations first**: Database changes drive everything in Rails. Plan migrations before models, models before controllers. Run `rails db:migrate` as part of the phase.
- **Model before controller**: ActiveRecord models must exist before controllers reference them. Plan validations, associations, and scopes in the model phase.
- **Concerns and services**: If complex business logic is needed, plan service objects or concerns in the same phase as the controller that calls them — not as a separate phase.
- **API vs views**: Check if the project is API-only (`--api` mode) or full-stack with views. This determines whether you plan serializers/jbuilder or ERB/Haml templates.

## Common Phase Patterns

- **Data layer phase**: Migration + Model (validations, associations, scopes) + Factory (FactoryBot) + Seeds (if applicable)
- **Controller phase**: Controller + Routes + Strong params + Policy/Pundit (if authorization) + Service object (if complex logic)
- **API phase**: Controller + Serializer (ActiveModelSerializer/Blueprinter/jbuilder) + Routes + Request specs
- **View phase**: Controller actions + ERB/Haml templates + Partials + Turbo frames/streams (if Hotwire)
- **Background job phase**: Job class + Sidekiq/GoodJob config + triggering logic in model/controller

## Planning Pitfalls

- **Convention over configuration**: Rails has strong opinions. Plan to use Rails conventions (REST routes, resource controllers, standard directory structure). Fighting conventions creates maintenance burden.
- **N+1 queries**: Plan `includes`, `eager_load`, or `preload` when controller actions load associations. Note this in action points.
- **STI vs polymorphism**: If the feature involves model hierarchies, decide early between STI and polymorphic associations. Plan migration columns accordingly.
- **Hotwire/Turbo**: Check if the project uses Hotwire. If so, plan Turbo frames and streams instead of full page reloads. This fundamentally changes the UI approach.
- **Engine/gem dependencies**: Check `Gemfile` before planning features that might need gems (Devise for auth, Pundit for authorization, Sidekiq for jobs). Plan gem addition as a step.
- **Test framework**: Check for RSpec vs Minitest. Plan test files in the correct location and style (`spec/` vs `test/`).

## Must-Have Considerations

- **Artifacts**: Include migration file, model, controller, route update, serializer/view, policy (if auth), service object (if needed), test files
- **Links**: Route → Controller → Model → Migration chain. Also: Policy → Controller authorization, Job → Sidekiq config, Serializer → Model associations
- **Truths**: "User can {action} via {HTTP method} {route}" + "Unauthorized user receives 403" + "Invalid params return 422 with error messages"
