---
description: "Complete feature: quality gates, push, PR, and wrap up"
disable-model-invocation: true
required-predecessor: "z-work"
required-config:
  - "git.target_branch"
  - "commands.test_backend"
---

# /z-done — Feature Completion

Quality gates with evidence, push, PR creation, memory write, cleanup.

## Pre-flight Validation

1. Read `.claude/z-project-config.yml`. If missing → redirect to `/z-project-init`.
2. Check required config keys: `git.target_branch`, `commands.test_backend`. If missing → redirect to `/z-project-init`.
3. **Predecessor check**: Check that `git diff` against target branch is non-empty (work was done). If empty → redirect to `/z-work`.

### Blocked Screen

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✗ Done Blocked — no changes to push
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Required     Non-empty diff vs target branch
  Missing      No code changes found

─────────────────────────────────────────────────────────────────
  ▶ Run first  /z-work {issue}
               Implement plan phases
─────────────────────────────────────────────────────────────────
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Execution

### Step 1: Pre-flight Quality Gates

**ALL checks must pass. Show evidence — not just checkmarks.**

Run each check and display results as a summary table:

| Check | Command | Evidence required |
|---|---|---|
| Clean tree | `git status` | Show output — must have no uncommitted changes |
| Up to date | `git merge-base --is-ancestor` | Show merge-base result against target branch |
| Tests pass | `commands.test_backend` (and `test_frontend` if set) | Show: total count, pass count, fail count, skip count, execution time |
| Type checker | `commands.typecheck` (if set) | Show error count (e.g., "tsc: 0 errors") |
| Linter | `commands.lint` (if set) | Show warning/error count |
| Build | `commands.build` (if set, skip if null) | Show build output summary |
| No `: any` | Grep TypeScript files for `: any` | Show grep result count |

**If ANY check fails**:
- Report which failed with actual output
- STOP — do not proceed
- If tests fail: suggest `/z-test` to auto-fix failures before retrying `/z-done`

### Step 2: Push and PR Creation

**Confirm with user first** — this is a side-effect action.

Use **AskUserQuestion**: "Pre-flight passed. Ready to push and create PR?"

If confirmed:
1. Push branch to origin: `git push -u origin {branch}`
2. Create PR using `gh pr create`:
   - Title: from issue title or branch name (short, under 70 chars)
   - Body: summary of changes from plan file + link to issue
3. Display PR URL to user
4. **Never force-push.**

If the user also wants to merge (old `/merge` behavior):
- Ask first via AskUserQuestion: "Also merge the PR now?"
- If confirmed: `gh pr merge` with appropriate strategy

### Step 3: Memory Write

1. Read the plan file for a summary of what was done
2. Write a one-liner to `~/.claude/projects/{project}/memory/MEMORY.md`:
   - Format: `- {date}: {issue-id} — {one-liner about what was done or learned}`
3. Check `.claude/project-patterns.md` for entries from this issue-id
   - If patterns were recorded during the workflow: include a note in the completion screen

### Step 4: Cleanup

1. Remove temp files: `.claude/.local/{branch}-*`
2. Mark all plan phases as complete in the plan file

### Step 5: Completion Screen

**━━━ ✓ Feature Complete ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━**
**{issue-id}: {title}**

**Pre-flight**

| | | |
|---|---|---|
| **Tests** | {N} passed | ✓ |
| **Linter** | {N} warnings | ✓ |
| **Types** | {N} errors | ✓ |
| **Clean tree** | no uncommitted changes | ✓ |
| **Up to date** | merged with {target} | ✓ |

| | |
|---|---|
| **PR** | {url} |
| **Memory** | updated ✓ |
| **Temp files** | cleaned ✓ |

**━━━ Branch ready for review ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━**

This is the terminal skill — no "Next" section. The PR URL is the final deliverable.
