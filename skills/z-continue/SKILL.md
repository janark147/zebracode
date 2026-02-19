---
description: "Continue post-work tasks on current branch"
---

# /z-continue — Branch Context Loader

Lightweight context loader for ad-hoc post-work tasks on a branch (fixes, cleanup, docs, etc.). No formal workflow — just loads context and waits for instructions.

## Pre-flight

- Must NOT be on the target branch (must be on a feature branch). If on main/master, inform user and stop.

## Execution

### 1. Load Plan Context

- Find the plan file: `.claude/plans/$ARGUMENTS*` — if no argument, use `.claude/plans/X*` where X = current branch name.
- If found: read it silently (do not dump the full plan).
- If not found: note that no plan file exists — this is fine, not a blocker.

### 2. Check Git History

- Run `git log --oneline -15` to see recent work on the branch.
- Run `git diff main --stat` to see the overall scope of changes on this branch.

### 3. Present Summary & Wait

Display a brief summary and wait for instructions:

```
## Ready: {branch-name}

| | |
|---|---|
| **Plan** | {plan file name or "none"} |
| **Current phase** | Phase {N}: {name} (or "N/A") |
| **Commits on branch** | {N} |
| **Files changed** | {N} |
```

Then say: **"What would you like to do?"**

DO NOT begin any work. Wait for the user's instructions.
