# Rails Review Checklist

Stack-specific review items for Ruby on Rails projects. Loaded when `stack.framework` is `rails`. Fed to review agents as additional context alongside the generic review instructions.

## Quality Review Items

### Architecture & Patterns
- Controllers are thin — complex business logic lives in service objects, concerns, or model methods
- Service objects follow project conventions (single `call` method, dependency injection)
- Proper use of concerns for shared model/controller behavior (not a dumping ground)
- Strong params used for all user input (`params.require(:model).permit(:fields)`)
- Callbacks (`before_action`, `after_create`, etc.) are minimal and well-documented — no hidden side effects

### Rails/Ruby Specifics
- ActiveRecord associations loaded eagerly where needed (`includes`, `preload`, `eager_load` — no N+1 queries)
- Migrations are reversible (`change` method or explicit `up`/`down`) and safe for production
- Database transactions used for multi-step write operations (`ActiveRecord::Base.transaction`)
- Background jobs used for time-consuming operations (email, external APIs, heavy processing)
- Scopes used for reusable query logic (not ad-hoc `where` chains in controllers)
- `find_each` / `in_batches` used for iterating over large datasets (not `.all.each`)
- Proper use of `find_by` vs `find` vs `where` (correct exception behavior)
- Enums defined with explicit values (not relying on implicit integer mapping)

### Internationalization
- New user-facing strings use `I18n.t()` / `t()` helper
- Translation keys added to appropriate locale files
- No hardcoded user-facing strings in views, controllers, or mailers

### Code Cleanliness
- No `puts`, `pp`, `p`, `binding.pry`, `byebug`, or `debugger` statements left in code
- No TODO, FIXME, or commented-out code blocks
- Unused variables/methods removed

### Testing
- Test files exist for new functionality (DO NOT RUN TESTS — verify file quality only)
- Tests follow project patterns (RSpec or Minitest — don't mix)
- Factories updated for new models/columns (FactoryBot)
- Edge cases covered: validation errors, unauthorized access, missing records
- Request specs for controller actions, unit specs for models and services

## Security Review Items

### Authentication & Authorization
- Authorization checks on all controller actions (Pundit policies, CanCanCan abilities, or manual checks)
- No IDOR vulnerabilities — scoped queries (`current_user.posts.find(params[:id])` not `Post.find(params[:id])`)
- `before_action :authenticate_user!` (Devise) or equivalent on protected controllers
- Password handling uses bcrypt via `has_secure_password` or Devise (never plain text)

### Input Validation & Injection
- Strong params on all create/update actions — no `params.permit!` or mass assignment from unfiltered params
- No string interpolation in `where` clauses (`where("name = '#{name}'"`) — use parameterized queries (`where(name: name)` or `where("name = ?", name)`)
- `find_by_sql` and `connection.execute` use parameterized queries
- File uploads validated: content type whitelist, size limit, filename sanitization (ActiveStorage or CarrierWave/Shrine)
- Command injection prevented in any `system()`, backtick, `exec`, `IO.popen` calls
- No `send` or `public_send` with user-controlled method names

### XSS Prevention
- ERB templates use `<%= %>` (escaped) not `<%= raw %>` or `<%= .html_safe %>` unless rendering trusted HTML
- `sanitize()` helper used when rendering user-generated HTML
- JSON embedded in views uses `json_escape()` or `to_json` (not raw interpolation)

### CSRF & Request Forgery
- `protect_from_forgery` enabled (default in Rails — verify not disabled)
- API controllers using token auth may skip CSRF (`skip_forgery_protection`) but only with proper token validation
- `authenticity_token` included in forms (automatic with `form_with`/`form_for`)

### Mass Assignment
- Models don't use `attr_accessible` (Rails 3 pattern) — strong params in controller handle whitelisting
- Sensitive attributes (role, admin, permissions) never in permitted params without explicit authorization check
- Nested attributes (`accepts_nested_attributes_for`) have proper `reject_if` and attribute whitelisting

### Data Exposure
- No sensitive data in logs — `filter_parameters` configured for passwords, tokens, PII
- Error pages don't expose stack traces in production (`config.consider_all_requests_local = false`)
- API responses use serializers with explicit field lists (not `.to_json` on full model)
- Credentials stored in Rails credentials (`rails credentials:edit`) or environment variables, not in code
