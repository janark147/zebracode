---
description: "Analyze recent workflow artifacts for recurring issues and improvement suggestions"
---

# /z-retrospective — Workflow Pattern Mining

Mine plan files, git history, project patterns, and debug artifacts for recurring themes, pain points, and improvement opportunities.

**This is a periodic maintenance skill** — not part of the standard feature workflow. Suggested cadence: end of sprint, end of week, or after a complex feature ships.

---

## Execution

### Step 1: Scan Plan Files

Scan all `.claude/plans/*.md` files:

1. **Work Log entries** — look for `⚠` markers → recurring self-reflection concerns
2. **Fix Issues phases** — what did review keep finding wrong? Extract patterns
3. **Disregarded Issues** — patterns in what gets dismissed (may indicate unclear requirements or recurring false positives)

Collect findings with plan file references.

### Step 2: Scan Git History

Scan git history for the project. Use argument for scope (e.g., `last 50 commits`, `last 30 days`). Default: last 50 commits.

1. **Revert commits** — `git log --oneline --grep="revert"` → what had to be undone
2. **Fixup/amend patterns** — files that appear in multiple sequential commits with "fix" in the message → files that keep getting corrected after commit
3. **High-churn files** — files changed across multiple branches in the scan window → stability concerns

Collect findings with commit hashes.

### Step 3: Scan Project Patterns

Read `.claude/project-patterns.md` (if it exists):

1. **Categories growing fastest** — count entries per category, compare against file age → what the team keeps discovering
2. **Pitfalls sharing a root theme** — cluster related pitfalls (e.g., multiple "missing null check" entries, multiple "N+1 query" entries) → may indicate a systemic issue

### Step 4: Scan Debug Artifacts

Check `.claude/.local/*-debug.md` files (if any survive):

1. **Root cause clustering** — common bug categories across debug sessions
2. **Failed hypothesis patterns** — investigation angles that never pay off (may indicate a blind spot in debugging approach)

### Step 5: Cross-Reference & Cluster

Group related findings from Steps 1-4 into themes:

- Example: "N+1 query found in review" + "N+1 bug debugged" + "N+1 added to pitfalls" = **systemic theme: N+1 queries**
- Rank themes by **frequency** (how often it appeared) and **impact** (severity of associated issues)
- **Maximum 5 themes** — do not overwhelm the user. Pick the most impactful.

### Step 6: Present Themes

For each theme (one at a time), present via **AskUserQuestion**:

- Theme description with evidence (plan file refs, commit hashes, `file:line`)
- Suggested action — one of:

| Action | When to suggest |
|--------|-----------------|
| **Add to CLAUDE.md** | Claude got stuck on X multiple times — add guidance to prevent recurrence |
| **Add to project-patterns.md** | A pitfall keeps recurring — record it so review catches it |
| **Create a hook** | A manual check happens every time — automate it |
| **Refactor** | A specific file/module keeps breaking — consider dedicated cleanup |
| **No action** | Noted but not actionable yet — pattern too weak or too rare |

Options for each theme: "Apply suggested action", "Apply different action", "No action — skip"

### Step 7: Apply Approved Actions

For each approved action:

- **CLAUDE.md update**: Append convention/guidance to project CLAUDE.md
- **project-patterns.md update**: Append pattern entry under appropriate category
- **Hook creation**: Describe the hook needed but do NOT write hook code — suggest as a follow-up task
- **Refactor**: Create a note for the user (do not refactor in this skill — it's analysis-only)
- **No action**: Skip

### Step 8: Completion Screen

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✓ Retrospective Complete — {N} themes found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Artifacts scanned  {N} plan files, {N} commits, {N} debug files
  Themes found       {N}
  Actions taken      {N} CLAUDE.md updates, {N} patterns recorded
  Deferred           {N}

─────────────────────────────────────────────────────────────────
  ▶ Next    Continue with your current workflow
─────────────────────────────────────────────────────────────────
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Prompt Notes

- All findings must cite concrete evidence (plan file name, commit hash, file:line) — no vague "I noticed things could improve"
- If no meaningful patterns found: say so honestly, do not invent findings
- Maximum 5 themes — prioritize by impact, not by quantity
- This skill is read-only with respect to code — it only writes to CLAUDE.md and project-patterns.md
- Be honest about weak signals — if a theme has only 1-2 data points, present it as a weak signal, not a conclusion
