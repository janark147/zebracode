---
argument-hint: "[issue-id | resume] [branch]"
description: "Debug an issue with multi-agent investigation and hypothesis testing"
disable-model-invocation: true
---

# /z-debug — Multi-Agent Debugging

Systematic debugging with 3 parallel investigator agents, a judge for hypothesis ranking, fix attempts with rollback, and pattern recording.

## Pre-flight Validation

1. Read `.claude/z-project-config.yml`. If missing → redirect to `/z-project-init`.
2. Ensure clean working tree: run `git status`. If dirty → warn and **stop** (do not proceed with uncommitted changes).

---

## Argument Parsing

- `$ARGUMENTS` is parsed as: `[issue-id | resume] [branch]`
- If first argument is `resume` → jump to **Resume Flow** (below)
- If first argument is an issue ID → proceed with **New Investigation Flow**
- If first argument is a description (not an issue ID, not `resume`) → use it as a bug description
- If no arguments → ask user for bug description via **AskUserQuestion**

---

## New Investigation Flow

### Step 1: Setup

1. If `$2` (branch) is provided, checkout that branch; otherwise use current branch
2. Verify clean working tree (`git status` — if dirty, warn and **stop**)
3. Pull latest from target branch (read `git.target_branch` from config)
4. Run migrations if configured: execute `commands.migrate` from `z-project-config.yml` (skip if null)
5. Clear caches if configured: execute `commands.clear_cache` from `z-project-config.yml` (skip if null)
6. If `$1` is an issue ID: read the issue from the tracker (same pattern as `/z-start`)
7. If `$1` is not an issue ID: use it as the bug description

### Step 2: Reproduce

Attempt to write a failing test that reproduces the bug:

1. Read `z-project-config.yml` for test commands and test file locations
2. Identify the most relevant test file/directory for this bug
3. Write a minimal failing test that demonstrates the expected vs actual behavior
4. Run the test to confirm it fails

**If test fails (good — reproduction successful)**:
- Log: "Reproduction test written: `{test-file}:{line}` — fails as expected"
- This test becomes the success criterion for the fix

**If test passes (cannot reproduce via test)**:
- Log: "Could not reproduce via automated test. Tried: {description of attempt}"
- Continue investigation — the bug may be environment-specific or require manual reproduction
- Document what was tried

### Step 3: Multi-Agent Investigation

Spawn 3 investigator agents in parallel using the Task tool. Each agent receives:
- The bug description / issue details
- The reproduction test results (if any)
- Stack info from `z-project-config.yml`
- Project conventions from CLAUDE.md
- Known patterns from `.claude/project-patterns.md`

**Agents**:

| Agent | Personality | Focus |
|---|---|---|
| `z-debug-investigator-state` | "Follow the data" — methodical, data-flow oriented | Wrong data, race conditions, stale cache, env vars, feature flags, permissions, configuration drift |
| `z-debug-investigator-logic` | "What breaks at the edges?" — adversarial, boundary-obsessed | Wrong conditionals, off-by-one errors, missing cases, null handling, boundary values, encoding, type coercion |
| `z-debug-investigator-integration` | "Where's the contract broken?" — systems thinker, connection-focused | API contract mismatches, event ordering, dependency version conflicts, middleware/pipeline issues |

Each agent MUST return a structured hypothesis report:

```markdown
## Hypothesis: {title}

**Confidence**: {0-100}%
**Category**: State | Logic | Integration

### Evidence FOR
- {description} — `{file:line}`
- {description} — `{file:line}`

### Evidence AGAINST
- {description} — `{file:line}`

### Suggested Fix
{concrete fix description with file:line references}
```

**Rules for investigators:**
- Every hypothesis MUST cite `file:line` for ALL evidence — hypotheses without concrete code references are considered unsupported and will be discarded by the judge
- Must document evidence BOTH for and against the hypothesis
- Can form multiple hypotheses (ranked by confidence)

### Step 4: Debate & Convergence

After investigators complete, spawn a **z-debug-judge** agent that receives all investigator reports.

The judge MUST:
1. Read all hypotheses from all investigators
2. Verify cited `file:line` evidence by reading the actual code
3. Evaluate evidence quality — hypotheses backed by `file:line` citations rank higher than vague references
4. Check for logical fallacies in investigator reasoning
5. Rank hypotheses from most to least likely with justified confidence levels
6. Produce a clear verdict

**Convergence rules:**
- If one hypothesis has >80% confidence and >20% lead over second → clear winner
- If tie (two hypotheses within 10% confidence): judge requests one more round of evidence from tied investigators, then force-ranks
- Output: ordered list of hypotheses with final confidence levels

### Step 5: Write Findings

Write debug findings to `.claude/.local/{branch}-debug.md`:

```markdown
# Debug: {issue}
**Date**: {date}
**Bug**: {description}

## Hypotheses (ranked)
1. [MOST LIKELY - {confidence}%] {hypothesis} — {evidence summary with file:line}
2. [LIKELY - {confidence}%] {hypothesis} — {evidence summary with file:line}
3. [POSSIBLE - {confidence}%] {hypothesis} — {evidence summary with file:line}
...

## Attempted Fixes
(none yet)

## Current Status
Ready to attempt fix #1
```

### Step 6: Attempt Fix

Apply the most likely fix:

1. Implement the fix as suggested by the highest-ranked hypothesis
2. Run relevant tests (including the reproduction test from Step 2, if it exists)

**IF TESTS PASS:**
1. Delete the debug temp file (`.claude/.local/{branch}-debug.md`)
2. Commit with descriptive message (e.g., "fix: {root cause description}")
3. **Pattern recording** — ask via **AskUserQuestion**: "Root cause was: {root cause}. Save to project patterns?"
   - If approved: append to `.claude/project-patterns.md` under "Common Pitfalls"
   - Format: `- {root cause description} — fix: {brief solution} (debugged in {issue-id}, {date})`
4. Provide user with manual verification instructions (specific, actionable steps)
5. Ask user to verify on their end via **AskUserQuestion**: "Does the fix work correctly in your testing?"
6. If user confirms: display success completion screen

**IF TESTS FAIL:**
1. Update debug file: mark attempt as failed, record what happened
2. Stash the failed fix: `git stash push -m "z-debug: failed hypothesis #{N} - {name}"`
3. Check remaining hypotheses:
   - If more hypotheses remain → display failure completion screen with "Next: /z-debug resume"
   - If all exhausted → display exhausted completion screen

### Step 7: Completion Screens

**Success:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✓ Bug Fixed — {issue-id}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Root cause     {one-line description}
  Evidence       {file:line}
  Fix            {one-line description of fix}
  Hypotheses     {N} investigated, #{winner} confirmed
  Tests          {N} passing ✓

─────────────────────────────────────────────────────────────────
  ▶ Next    /z-done
            Push fix and create PR

            /clear first — fresh context
─────────────────────────────────────────────────────────────────

  Also available:
    · /z-test             — run full test suite
    · /z-review {issue}   — review the fix

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Fix failed (more hypotheses remain):**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✗ Fix Attempt Failed — hypothesis #{N}: {name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Attempted      {hypothesis description}
  Result         {what went wrong}
  Changes        rolled back ✓
  Remaining      {N} untried hypotheses

─────────────────────────────────────────────────────────────────
  ▶ Next    /z-debug resume
            Try next hypothesis: {next hypothesis name}

            /clear first — fresh context
─────────────────────────────────────────────────────────────────
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**All hypotheses exhausted:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✗ Investigation Exhausted — {issue-id}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Hypotheses tested  {N}/{N}
  All failed         Changes rolled back ✓

  Top hypothesis     #{N}: {name} ({confidence}%)
  Evidence           {file:line summary}

─────────────────────────────────────────────────────────────────
  ▶ Next    Provide additional context or try a different angle
            Consider: /z-pause to save findings for manual review
─────────────────────────────────────────────────────────────────
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Resume Flow

When `$1` = `resume`:

1. Read `.claude/.local/{current-branch}-debug.md`
   - If not found → inform user: "No debug session to resume on this branch"
2. Show user the current state:
   - Ranked hypotheses
   - Which have been attempted and failed
   - Which is next to try
3. Attempt the next untried hypothesis
4. Follow same pass/fail flow as Step 6 above
5. On success: clean up stashes from previous failed attempts with `git stash drop`
6. On failure: stash remains available for user recovery via `git stash list` / `git stash pop`

---

## Prompt Notes

- Must handle the case where bug cannot be reproduced (proceed with investigation anyway)
- Investigator agents must cite `file:line` for ALL evidence — hypotheses without concrete code references are considered unsupported
- Judge agent needs explicit convergence criteria (not just "discuss")
- Judge must evaluate evidence quality: hypotheses backed by `file:line` citations rank higher than those with vague references
- Must discard changes on failed fix attempt (reversible state via `git stash`)
- Manual verification instructions should be specific and actionable (e.g., "Open /login, enter invalid email, verify error appears within 500ms")
- Never force-push or make destructive git operations
