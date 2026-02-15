---
argument-hint: "[issue]"
description: "Start working on a feature. Reads the GH/JIRA issue & switches to the correct branch."
disable-model-invocation: true
required-config:
  - "git.target_branch"
  - "issue_tracker.type"
---

# /z-start — Prepare Working Tree

## Pre-flight

1. Read `.claude/z-project-config.yml` for project configuration.
2. Validate required config keys exist (`git.target_branch`, `issue_tracker.type`). If missing, display validation-failed screen and redirect to `/z-project-init`.

## Execution

1. **Check working tree**: Run `git status`. If there are uncommitted changes, HALT and ask the user for instructions. Do NOT proceed with dirty working tree.

2. **Checkout target branch**:
   - Read `git.target_branch` from config (e.g., `main` or `master`)
   - `git checkout {target_branch} && git pull origin {target_branch}`

3. **Run setup commands** (from config, skip if null):
   - `commands.migrate` — run migrations
   - `commands.clear_caches` — clear caches

4. **Create or checkout feature branch**:
   - Branch name = `$ARGUMENTS` (the issue ID, e.g., `AC-1234`)
   - Apply `git.branch_prefix` from config if set (e.g., `feature/AC-1234`)
   - If branch already exists: `git checkout {branch} && git pull origin {branch}` — ask user: "Branch already exists. Continue on existing branch, or reset from {target_branch}?"
   - If branch doesn't exist: `git checkout -b {branch}`

5. **Read issue description**:
   - Check `issue_tracker.type` from config:
     - **jira**: Use `issue_tracker.mcp_tool` (e.g., `mcp__jira__get_issue`) with issue ID
     - **github**: Use `gh issue view {issue-number}`
     - **linear**: Use the configured MCP tool
     - **none**: Ask user to describe the task
   - If MCP tool is not available: prompt user to paste issue details, suggest installing the MCP

6. **Present the issue** to the user. DO NOT BEGIN IMPLEMENTING OR PLANNING.

## Completion Screen

**━━━ ✓ Ready to Work ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━**
**{issue-id}: {issue title}**

| | |
|---|---|
| **Branch** | {branch-name} |
| **Issue** | {issue-id} — {title} |
| **Tracker** | {tracker type} |
| **Migrated** | ✓ |
| **Cache** | cleared ✓ |

───────────────────────────────────────────────────────────────
**▶ Next** · `/z-plan {issue}` — create an implementation plan

*`/clear` first — fresh context*

**Also available:**
- `/z-groom {issue}` — groom before planning
- `/z-quick {issue}` — small task, skip planning
- `/z-debug {issue}` — bug investigation workflow

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
