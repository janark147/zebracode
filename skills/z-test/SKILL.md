---
argument-hint: "[backend/frontend]"
description: "Run test suite and fix any failures"
required-predecessor: "z-work"
required-config:
  - "commands.test_backend"
---

# /z-test — Test Runner & Fixer

On-demand utility for running the full test suite and fixing failures. Separate from the per-phase test writing in `/z-work`.

## Pre-flight Validation

1. Read `.claude/z-project-config.yml`. If missing → redirect to `/z-project-init`.
2. Check required config key: `commands.test_backend`. If missing → redirect to `/z-project-init`.
3. **Predecessor check**: Check that `git diff` against target branch is non-empty. If empty → redirect to `/z-work`.

---

## Argument Parsing

- `backend` (default) → run `commands.test_backend` from config
- `frontend` → run `commands.test_frontend` from config. If not set, inform user.
- No argument → default to `backend`

---

## Execution

### Step 1: Run Full Test Suite

Run the test command from config. **ALL tests must pass — not just feature-related ones. DO NOT SKIP ANY TESTS.**

Show evidence:
- Total test count
- Pass count
- Fail count
- Skip count
- Execution time

### Step 2: Handle Failures

**If a single test fails**: Fix it directly.

**If multiple tests fail**:
1. Write findings to `.claude/.local/{branch}-{backend|frontend}-test-review.md`
2. Inform the user of the scope
3. Fix tests ONE BY ONE, updating the temp review file with progress

After each fix, re-run the affected test to confirm it passes before moving to the next failure.

### Step 3: Verify All Pass

Re-run the full suite after all fixes. Show evidence again.

### Step 4: Clean Up

Remove the temp review file when all tests pass.

### Step 5: Completion Screen

**All tests passing:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✓ Tests Passing — {backend|frontend}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Total     {N} tests
  Passed    {N}
  Failed    0
  Skipped   {N}
  Time      {time}s

─────────────────────────────────────────────────────────────────
  ▶ Next    /z-done
            Quality gates, push, and create PR

            /clear first — fresh context
─────────────────────────────────────────────────────────────────

  Also available:
    · /z-review — multi-agent code review

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Some tests still failing:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✗ Tests Failing — {backend|frontend}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Total     {N} tests
  Passed    {N}
  Failed    {N}
  Time      {time}s
  Auto-fix  attempted {N} failures, {M} remain

─────────────────────────────────────────────────────────────────
  ▶ Next    Fix failures manually, then re-run /z-test
─────────────────────────────────────────────────────────────────
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
