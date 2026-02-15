---
argument-hint: "[issue] [phase]"
description: "Verify a phase implementation against acceptance criteria"
required-predecessor: "z-work"
---

# /z-verify — Phase Verification

Manual step-by-step verification of implemented work (user acceptance testing). Can be invoked standalone or from within `/z-work`.

## Pre-flight Validation

1. **Predecessor check**: Check that a plan file exists in `.claude/plans/` matching the issue or branch, and that the specified phase has checked action points (indicating work was done). If no plan → redirect to `/z-plan`. If phase has no checked items → redirect to `/z-work`.

### Blocked Screen

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✗ Verify Blocked — {reason}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Required     {predecessor} must run first
  Missing      {what's missing}

─────────────────────────────────────────────────────────────────
  ▶ Run first  /z-{predecessor} {issue}
─────────────────────────────────────────────────────────────────
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Argument Parsing

- **Issue ID**: First positional argument. If not provided, derive from current branch name.
- **Phase number**: Second positional argument. If not provided, verify the most recently completed phase.
- Invalid phase number → show available phases with their completion status.

---

## Execution

### Step 1: Load Context

1. Read the plan file: `.claude/plans/$ARGUMENTS*` — if no argument, use `.claude/plans/X*` where X = current branch name.
2. Focus on the specified phase. Read its Must-Haves and Acceptance Criteria sections.

### Step 2: Verify Must-Haves (Automated)

Run automated checks — no user input needed for this step:

**Artifacts** — check each listed file exists:
- Use `Glob` to verify each file path listed in the Artifacts section
- Report pass/fail per file with the full path

**Links** — check each connection is wired:
- Use `Grep` to find imports/calls for each listed link
- Report `file:line` evidence per link

**Truths** — verify behavioral assertions:
- Run relevant tests that exercise the behavior
- Show test output or demonstrate the behavior holds
- Cite evidence per truth

**If any must-have fails**: Flag immediately and present all failures before proceeding to acceptance criteria.

### Step 3: Walk Through Acceptance Criteria

For each acceptance criterion in the phase, interactively verify with the user:

1. Show what was implemented (relevant code, component, endpoint)
2. Show evidence (test results, code references at `file:line`, visual output if applicable)
3. Use **AskUserQuestion**: "Does this meet the criterion: '{criterion text}'?"

**Do NOT auto-pass anything.** Every criterion gets explicit user confirmation.

### Step 4: Handle Failures

For each failed must-have or criterion:
1. Document the specific issue
2. Use **AskUserQuestion**: "Fix now or defer to Fix Issues phase?"
   - **Fix now** → attempt the fix, then re-verify that specific item
   - **Defer** → add the issue to the "Fix Issues" phase in the plan file with clear description

### Step 5: Write Work Log

Append a verification summary to the phase's `### Work Log`:

```
- /z-verify — Truths: {n}/{n} | Artifacts: {n}/{n} | Links: {n}/{n} | Criteria: {pass}/{total}
```

If issues were deferred:
```
- /z-verify — Truths: {n}/{n} | Artifacts: {n}/{n} | Links: {n}/{n} | Criteria: {pass}/{total} — {N} deferred to Fix Issues
```

### Step 6: Completion Screen

**━━━ ✓ Phase {N} Verified ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━**
**{pass}/{total} criteria passed**

| | |
|---|---|
| **Must-haves** | {N}/{N} ✓ |
| **Criteria** | {pass}/{total} passed |
| **Deferred** | {N} issues → Fix Issues phase |

───────────────────────────────────────────────────────────────
**▶ Next** · `/z-work {issue} {next-phase}` — continue to Phase {next}: {phase name}

*`/clear` first — fresh context*

**Also available:**
- `/z-pause` — save and stop

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
