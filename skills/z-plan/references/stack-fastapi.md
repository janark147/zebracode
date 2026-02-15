# FastAPI Planning Notes

Stack-specific considerations when creating a plan for a FastAPI project.

## Phase Structuring

- **Models before routes**: SQLAlchemy/Tortoise models or Pydantic schemas must exist before route handlers reference them. Plan data layer first.
- **Schemas alongside models**: Plan Pydantic request/response schemas in the same phase as the database models they mirror. They evolve together.
- **Router then app**: Plan route handlers in a dedicated router module, then register the router in the main app. Don't dump everything in `main.py`.
- **Dependencies before consumers**: If the feature uses FastAPI dependency injection (`Depends()`), plan the dependency functions before the route handlers that use them.

## Common Phase Patterns

- **Data layer phase**: SQLAlchemy model + Alembic migration + Pydantic schemas (create, update, response) + CRUD utility functions
- **Router phase**: Router + Route handlers + Dependencies (auth, pagination, etc.) + Response models
- **Auth phase**: OAuth2 scheme + JWT utility + `get_current_user` dependency + Permission dependency
- **Background task phase**: Background task function or Celery task + triggering route handler
- **WebSocket phase**: WebSocket route + Connection manager + Event handlers

## Planning Pitfalls

- **Sync vs async**: Check if the project uses `async def` routes with an async database driver (asyncpg, aiosqlite) or sync `def` routes. Don't mix patterns — async routes with sync DB calls block the event loop.
- **Alembic migrations**: If using SQLAlchemy, check for Alembic. Plan `alembic revision --autogenerate` + `alembic upgrade head` as phase steps. Auto-generate may miss some changes (enum types, constraints).
- **Dependency injection scope**: FastAPI dependencies can be function-scoped (default), or use `yield` for cleanup. Plan DB session dependencies with proper session lifecycle (commit/rollback/close).
- **Pydantic v1 vs v2**: Check the Pydantic version. v2 uses `model_validator` instead of `validator`, `model_config` instead of `Config` inner class. Significant API differences.
- **Testing**: FastAPI uses `TestClient` (sync, wraps httpx) or `AsyncClient` (async). Check which the project uses. Plan test fixtures for DB setup/teardown.
- **Auto-docs**: FastAPI auto-generates OpenAPI docs. Plan response models and docstrings for route handlers — they appear in `/docs`.

## Must-Have Considerations

- **Artifacts**: Include model file, migration, Pydantic schemas, router, dependency functions (if new), test files
- **Links**: App → Router registration (`app.include_router`), Route → Dependency injection, Route → Schema validation, Model → Migration, Schema → Model field alignment
- **Truths**: "Endpoint returns {status code} for {scenario}" + "Schema validation rejects {invalid input} with 422" + "Dependency injects {resource} correctly"
