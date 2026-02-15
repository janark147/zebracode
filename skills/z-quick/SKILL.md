---
argument-hint: "[issue] [branch]"
description: "Quick implementation: start + work + test + commit (no plan file)"
disable-model-invocation: true
---

# /z-quick — Fast-Track Workflow

Designed for small bug fixes, trivial features, and config changes. Skips planning overhead but maintains quality (tests, lint).

## Pre-flight

1. Read `.claude/z-project-config.yml` for project configuration (if it exists).
2. If `$2` (branch) is provided, checkout that branch. Otherwise use the current branch.
3. Ensure clean working tree (`git status`). If dirty, warn and ask user.

## Execution

### 1. Read Issue

- If `$1` is an issue ID: read from tracker (same pattern as `/z-start`)
- If `$1` is a description: use it directly

### 2. Implement

- Single phase, no plan file
- Follow conventions from CLAUDE.md
- Use Context7 and MCP servers as needed
- Use AskUserQuestion when uncertain about any decision.
- If the task turns out to be complex mid-implementation: suggest switching to the full workflow (`/z-plan`)

### 3. Verify

- Run affected tests (from `commands.test_backend` / `commands.test_frontend` in config)
- Run typecheck (from `commands.typecheck` in config, if configured)
- Run lint (from `commands.lint` in config, if configured)

### 4. Commit

- Create a descriptive commit message (short, to the point)
- NEVER credit Claude or Anthropic

## Completion Screen

**━━━ ✓ Quick Task Complete ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━**
**{issue-id}: {title}**

| | |
|---|---|
| **Commits** | {N} |
| **Tests** | {N} passing |
| **Linter** | {N} warnings |

───────────────────────────────────────────────────────────────
**▶ Next** · `/z-done` — push and create PR

*`/clear` first — fresh context*

**Also available:**
- `/z-review {issue}` — review before pushing
- `/z-test` — run full test suite

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
