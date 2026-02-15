---
argument-hint: "[issue] [phase] [phase] [--fix] [--docs]"
description: "Implement the next phase(s) of the plan"
disable-model-invocation: true
required-predecessor: "z-plan"
required-mcps: ["context7"]
required-config:
  - "git.target_branch"
---

# /z-work — Phase Executor

## Pre-flight Validation

**Run these checks FIRST — before reading plan files, before any work.**

1. Read `.claude/z-project-config.yml`. If missing → display validation-failed screen and redirect to `/z-project-init`.
2. Check required config key: `git.target_branch`. If missing → display validation-failed screen and redirect to `/z-project-init`.
3. Verify Context7 MCP is available: call `mcp__context7__get-library-docs` with a `context7_ids` value from config (or fall back to `mcp__context7__resolve-library-id` if no IDs cached). If unavailable → display validation-failed screen with install hint.
4. **Predecessor check**: Check that a plan file exists in `.claude/plans/` matching the issue or branch. If no plan file found → display blocked screen and redirect to `/z-plan {issue}`.

### Blocked Screen

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✗ Work Blocked — no plan file found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Required     Plan file must exist
  Missing      .claude/plans/{issue}*.md

─────────────────────────────────────────────────────────────────
  ▶ Run first  /z-plan {issue}
               Create an implementation plan
─────────────────────────────────────────────────────────────────
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Argument Parsing

Parse `$ARGUMENTS` for:
- **Issue ID**: First positional argument (e.g., `AC-1234`, `123`)
- **Phase numbers**: Subsequent numeric arguments (e.g., `1`, `2 3`, `0`)
- **`--fix` flag**: Execute the "Fix Issues" terminal phase
- **`--docs` flag**: Execute the "Documentation" terminal phase (delegates to `/z-docs-update`)

If no issue ID is provided, derive it from the current branch name.
If no phase numbers are provided, find the next undone phase from the plan file.

**Invalid arguments**:
- Phase number not in plan → show available phases: `Phase 99 not found. Available phases: 0 (Design), 1, 2, 3, 4 (Fix Issues), 5 (Documentation).`
- Unknown flags → suggest closest match.

**NEVER proceed to phases not specified by the user.** Only work on the explicitly requested phase(s).

---

## Execution

### Step 1: Load Context

1. Read the plan file: `.claude/plans/$ARGUMENTS*` — if no argument, use `.claude/plans/X*` where X = current branch name.
2. Read `.claude/z-project-config.yml` for test/lint/typecheck commands, stack info.
3. Read `.claude/project-patterns.md` if it exists — apply known patterns, avoid recorded pitfalls.
4. Read `.claude/.local/{branch}-verify-amendments.md` if it exists — check for outstanding amendments from `/z-plan --verify`.
5. Review the **Decisions** section in the plan:
   - **Locked** decisions → implement exactly as specified
   - **Deferred** decisions → skip entirely. If a Deferred item becomes necessary during implementation, STOP and ask user via AskUserQuestion to re-categorize it.
   - **Discretion** decisions → use professional judgment

### Step 2: Load Phase-Specific References

Based on the phase content, load relevant reference files. Load ONCE per execution, not per step.

- If phase has `**Type**: design` → Read `references/design-patterns.md`. This phase delegates to `/z-design` logic (codebase scan → mockup generation → user selection). The Magic MCP is used instead of Context7 for this phase.
- If phase involves API work (new endpoints, controllers, services) → Read `references/api-patterns.md`
- If phase involves frontend/UI work (components, views, templates) → Read `references/ui-patterns.md`
- If phase involves database changes (migrations, schema, models) → Read `references/migration-patterns.md`
- Test writing guidance is always loaded → Read `references/test-writing.md`

### Step 3: Execute Phase — Step by Step

For each undone action point in the phase:

1. **Pick** the next unchecked action point
2. **Analyze** implementation requirements, detect technology context
3. **Coordinate** with MCP servers:
   - Context7 for framework/library patterns (or Magic MCP if design phase)
   - Use AskUserQuestion tool liberally when uncertain
4. **Implement** the step — write production-quality code:
   - Follow existing project conventions and patterns
   - Consider security: input validation, sanitization, auth checks
   - Consider edge cases: null/empty inputs, boundary values, error states
   - No `Type: any` in TypeScript — fix immediately
5. **Mark done** — check the action point `[x]` in the plan file
6. **Update context** — add implementation notes to the plan file. Keep concise: replace or remove info that became obsolete.
7. **Log** — append to the phase's `### Work Log`: `- /z-work — {what was done} ({commit short hash if committed})`
8. **Inform** the user of any deviations from the plan — even minor ones

**Convention Discovery**: If during work you discover a convention, antipattern, or useful shortcut → immediately ask user via AskUserQuestion: "I discovered: {pattern}. Save to project patterns?" If approved: append to `.claude/project-patterns.md`. Format: `- {description} (discovered in {issue-id}, {date})`. Do NOT postpone.

### Step 4: Write Tests

When a phase introduces new or changed behavior, write tests within the same phase. Follow the guidance in `references/test-writing.md`:

- Use plan file's test case outlines as starting points, validate against actual diffs
- Cover happy path + failure path for new features
- Bug fix → add regression test + amend existing tests if needed
- Follow existing test suite patterns — consistency is paramount
- Do NOT write tests that only test framework behavior
- Flag brittle mocks explicitly
- Run affected tests (not full suite) before announcing phase completion
- If ANY test fails (even "unrelated"): **STOP** and ask user via AskUserQuestion

### Step 5: Quality Checks

Before announcing phase completion, run all applicable quality checks from config:

1. **Tests**: Run `commands.test_backend` (and `test_frontend` if applicable). Report: `{pass} passing, {fail} failing`
2. **Linter**: If `commands.lint` is set, run it. Report: `{N} warnings`
3. **Type checker**: If `commands.typecheck` is set, run it. Report: `{N} errors`. NO `Type: any` allowed — fix immediately.
4. **Build**: If `commands.build` is set, verify it succeeds.

### Step 6: Must-Haves Verification

Before announcing phase completion, verify ALL must-haves from the plan for this phase:

- **Truths**: Run relevant tests or demonstrate the behavior holds. Cite evidence.
- **Artifacts**: Confirm each listed file exists (`Glob`). Cite the path.
- **Links**: Confirm each connection is wired by finding the import/call (`Grep`). Cite `file:line`.

Check the must-have checkboxes `[x]` in the plan file as each is verified.

If ANY must-have cannot be verified: **STOP** and ask user via AskUserQuestion.

### Step 7: Atomic Commits

Each phase gets its own commit (or multiple small commits within a phase). Never bundle multiple phases into one commit. Commit messages should be short and to the point — just the main result.

### Step 8: Self-Reflection Checkpoint

Before announcing phase completion, silently evaluate:
- Where did I use a default/template pattern instead of making a deliberate choice for this codebase?
- Did I actually verify behavior, or just confirm the code exists?
- Is there anything I'd flag if I were reviewing someone else's implementation?
- Did I deviate from the plan without noting it?

If nothing surfaces → proceed silently.
- Minor concern → append to Work Log: `- /z-work ⚠ — {concern}`
- Genuine issue → flag to user via AskUserQuestion before completing

### Step 9: Phase Summary & Completion Screen

Display evidence-based progress, then the completion screen:

**━━━ ✓ Phase {N} Complete ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━**
**{phase name}**

| | |
|---|---|
| **Commits** | {N} ({message1}, {message2}) |
| **Tests** | {pass} passing, {fail} failing |
| **Linter** | {N} warnings |
| **Type errors** | {N} |
| **Must-haves** | {verified}/{total} verified |

> **Must-haves:** Truths {N}/{N} ✓ · Artifacts {N}/{N} ✓ · Links {N}/{N} ✓

**Progress** ██████████░░░░░░░░ {done}/{total} phases
{completed list} ✓ │ {remaining list}

───────────────────────────────────────────────────────────────
**▶ Next** · `/commit` — commit phase changes
         · Then → `/z-work {issue} {next-phase}` — continue to Phase {next}: {phase name}

*`/clear` before the next phase — fresh context*

**Also available:**
- `/z-verify {issue} {N}` — verify this phase with user
- `/z-pause` — save progress and stop
- `/z-review` — skip ahead to review

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**When the last implementation phase is complete** (before Fix Issues), change the Next suggestion:

**▶ Next** · `/commit` — commit phase changes
         · Then → `/z-review {issue}` — multi-agent code review before fixing issues

**Also available:**
- `/z-pause` — save progress and stop

---

## Terminal Phase: --fix (Fix Issues)

When `--fix` is passed, execute the "Fix Issues" phase from the plan:

1. Read the Fix Issues phase — it should contain items added by `/z-review`
2. Work through each item step by step (same loop as Step 3)
3. Each fix gets its own commit
4. Run full test suite after all fixes
5. Display completion screen with Next → `/commit`, then `/z-done` or `/z-work {issue} --docs`

## Terminal Phase: --docs (Documentation)

When `--docs` is passed, delegate to `/z-docs-update` skill logic:

1. Analyze all changes made across all phases
2. Update project documentation accordingly
3. Display completion screen with Next → `/commit`, then `/z-done`
