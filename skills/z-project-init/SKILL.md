---
description: "Initialize ZebraCode for a new project"
disable-model-invocation: true
---

# /z-project-init — Bootstrap Project Configuration

## Pre-flight

- Check if `.claude/z-project-config.yml` already exists
- If it does: ask user "Config already exists. Update existing config, or overwrite?" via AskUserQuestion

## Execution

### 1. Auto-detect Stack

Scan the project root for manifests and config files:

| File | Detects |
|------|---------|
| `package.json` | language=typescript/javascript, scripts (test, lint, build, dev), dependencies (react, vue, next, etc.) |
| `composer.json` | language=php, framework (laravel, symfony), test runner (phpunit) |
| `pyproject.toml` / `requirements.txt` | language=python, framework (django, flask, fastapi) |
| `Cargo.toml` | language=rust |
| `go.mod` | language=go |
| `tsconfig.json` | type_checker=tsc |
| `.prettierrc` / `prettier.config.*` | formatter=prettier |
| `eslint.config.*` / `.eslintrc.*` | linter=eslint |
| `phpunit.xml` | test_runner_backend=phpunit |
| `vite.config.*` | frontend build tool |
| `pint.json` | formatter=pint |
| `.github/` | issue_tracker=github |
| `.jira/` or Jira MCP configured | issue_tracker=jira |

Also check:
- `git remote -v` for repository info
- `git branch -r` for target branch (main vs master)
- Existing CLAUDE.md for conventions

### 2. Interactive Questionnaire

Use AskUserQuestion to present auto-detected values as defaults. Let user confirm or override:

1. **Project name and description**
2. **Git target branch** (detected: main/master)
3. **Issue tracker type** (Jira/GitHub/Linear/None) + project key
4. **Stack details** — pre-filled from step 1:
   - Language, framework, frontend, CSS
   - Test runner (backend/frontend)
   - Formatter, linter, type checker
5. **Commands** — pre-filled if scripts found in manifest:
   - Test commands
   - Lint/format/typecheck commands
   - Build/dev server commands
   - Migration / cache clear commands
6. **Protected files** — defaults shown, user can add project-specific patterns
7. **Dangerous commands** — defaults shown, user can add

### 3. Create Configuration Files

1. Write `{project-root}/.claude/z-project-config.yml` from answers
2. Create `{project-root}/.claude/plans/` directory
3. Create `{project-root}/.claude/.local/` directory
4. Create `{project-root}/.claude/.gitignore` containing `.local/`
5. Create `{project-root}/.claude/project-patterns.md`:

```markdown
# Project Patterns
> Auto-accumulated by ZebraCode skills. Edit freely.

## Architectural Patterns

## Common Pitfalls

## Testing Shortcuts

## Performance Fixes
```

### 4. Update CLAUDE.md (if applicable)

If `{project-root}/CLAUDE.md` exists:
- Add reference to project conventions discovered by scanning the codebase
- Add stack-specific patterns found in existing code
- Do NOT overwrite existing content — append only

If it doesn't exist: create a minimal one with stack info and convention pointers.

## Completion Screen

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✓ Project Initialized — {project name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Stack      {language} / {framework} / {frontend}
  Tracker    {type} ({project key})
  Config     .claude/z-project-config.yml   ✓
  Plans dir  .claude/plans/                ✓
  Gitignore  .claude/.gitignore            ✓

─────────────────────────────────────────────────────────────────
  ▶ Next    /z-claudemd-review
            Audit and improve project CLAUDE.md

            /clear first — fresh context
─────────────────────────────────────────────────────────────────

  Also available:
    · /z-start {issue} — jump straight into a feature
    · /z-groom {issue} — groom an issue first

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
