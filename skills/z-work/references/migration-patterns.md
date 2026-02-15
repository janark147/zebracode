# Database Migration Patterns

Loaded when the current phase involves database changes (migrations, schema changes, model definitions).

## Implementation Checklist

When implementing database changes, ensure:

1. **Migration file** — created using the framework's migration generator (not by hand). Follows naming conventions.
2. **Reversibility** — migration has a proper `down`/`rollback` method. Can it be reversed without data loss?
3. **Indexes** — foreign keys are indexed. Columns used in WHERE/ORDER BY clauses are indexed. Don't over-index.
4. **Nullable** — explicitly decide nullable vs NOT NULL for every column. Default to NOT NULL unless there's a reason.
5. **Defaults** — set sensible defaults for columns that need them. Avoid defaults that mask missing data.
6. **Constraints** — foreign key constraints with appropriate ON DELETE behavior (CASCADE, SET NULL, RESTRICT). Unique constraints where business rules require uniqueness.
7. **Model update** — model/entity reflects the migration. Fillable/guarded, casts, relationships, scopes all updated.
8. **Factory/seed** — test factory updated to generate valid data for new columns. Seeds updated if needed.
9. **Run migration** — actually run the migration and verify it applies cleanly. Report success.

## Safety Rules

- **Never drop columns in production** without a multi-step migration plan (add new column → migrate data → remove old column across separate deploys)
- **Never rename columns** directly — add new, copy data, remove old
- **Large tables**: Adding columns to large tables can lock the table. Note this risk in the work log if the table has significant data.
- **Enum columns**: Avoid database-level enums — they're painful to modify. Use string columns with application-level validation instead.
- **Default values on existing columns**: Adding a default to an existing NOT NULL column in a migration is generally safe. Changing a default is not.

## Conventions to Check

Before writing migrations, verify:
- **Naming**: How does the project name migrations? Timestamps? Sequential?
- **Column types**: What types does the project use for IDs (bigint? uuid?)? Timestamps (datetime? timestamp with tz?)?
- **Soft deletes**: Does the project use soft deletes? If so, add `deleted_at` column.
- **Audit columns**: Does the project track `created_by`/`updated_by`? Add if pattern exists.
- **Multi-tenancy**: Is the data scoped to a tenant? Add tenant foreign key if pattern exists.
