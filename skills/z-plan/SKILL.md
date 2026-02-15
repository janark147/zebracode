---
argument-hint: "[issue] [--verify] [--design]"
description: "Create implementation plan, or verify existing plan with --verify flag"
required-predecessor: "z-start"
required-mcps: ["context7"]
required-config:
  - "git.target_branch"
---

# /z-plan — Implementation Planner

## Pre-flight Validation

**Run these checks FIRST — before reading plan files, before spawning agents, before any work.**

1. Read `.claude/z-project-config.yml`. If missing → display validation-failed screen and redirect to `/z-project-init`.
2. Check required config key: `git.target_branch`. If missing → display validation-failed screen and redirect to `/z-project-init`.
3. Verify Context7 MCP is available: call `mcp__context7__resolve-library-id` with a known library from the project. If unavailable → display validation-failed screen with install hint.
4. **Predecessor check**: Verify current branch is NOT the target branch (from config). If on target branch → display blocked screen and redirect to `/z-start {issue}`.

### Validation-Failed Screen

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✗ Plan — Pre-flight Failed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  {List each check with ✓ or ✗}

─────────────────────────────────────────────────────────────────
  ▶ Fix     /z-project-init
            Re-run project setup to fill missing keys
─────────────────────────────────────────────────────────────────
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Blocked Screen (predecessor missing)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✗ Plan Blocked — not on feature branch
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Required     /z-start must run first
  Missing      Feature branch checkout

─────────────────────────────────────────────────────────────────
  ▶ Run first  /z-start {issue}
               Checkout branch and read issue context
─────────────────────────────────────────────────────────────────
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Argument Parsing

Parse `$ARGUMENTS` for:
- **Issue ID**: First positional argument (e.g., `AC-1234`, `123`, etc.)
- **`--verify` flag**: If present, switch to **Verify Mode** (see below)
- **`--design` flag**: If present, force inclusion of Phase 0: Design in the plan

If no issue ID is provided, derive it from the current branch name.

**Invalid arguments**:
- Unknown flags → suggest closest match. E.g.: `Unknown flag --verif. Did you mean --verify?`
- Missing issue ID when not on a feature branch → show: `Usage: /z-plan [issue] [--verify] [--design]`

---

## Mode Routing

- If `--verify` is present → Read `references/verify-checklist.md` and follow its instructions. STOP — do not proceed with Create Mode.
- Otherwise → proceed with **Create Mode**.

---

## Create Mode

### Step 1: Load Project Context

1. Read `.claude/z-project-config.yml` for stack, commands, conventions.
2. Read `.claude/project-patterns.md` if it exists — use recorded patterns to inform approach, avoid known pitfalls, and suggest proven solutions.
3. Read grooming output from `.claude/.local/{branch}-grooming.md` if it exists (output from `/z-groom`), if not, try to obtain grooming output from the JIRA/GitHub issue description. Import decisions directly.
4. Load stack-specific planning notes:
   - Check `stack.framework` from config → if `references/stack-{framework}.md` exists (e.g., `references/stack-laravel.md`), Read it.
   - Check `stack.frontend` from config → if set and `references/stack-{frontend}.md` exists (e.g., `references/stack-vue.md`), Read it too.
   - These contain framework-specific planning considerations. If no matching files exist, skip.

### Step 2: Examine Codebase

THOROUGHLY examine the documentation and existing codebase:
- Understand project structure, conventions, patterns
- Identify relevant existing code that will be modified or extended
- Check for existing tests, type definitions, API contracts
- Use Context7 MCP to research framework/library patterns relevant to the task
- Coordinate with MCP servers (Magic for UI, Context7 for patterns) as needed

### Step 3: Gather Requirements

Use the **AskUserQuestion tool liberally** when you encounter:
- Gaps or ambiguities in the issue description
- Multiple valid implementation approaches
- Edge cases that need product decisions
- Unclear acceptance criteria
- Whether a design phase is warranted (when unclear)

**Do NOT assume.** Ask the user. Continue to planning only after all questions are answered.

### Step 4: Design Phase Detection

Assess whether the feature involves significant UI work:
- New pages or views
- Complex interactions or animations
- Layout changes affecting multiple components
- New major visual components

**If significant UI work is detected — OR `--design` flag was passed** → include Phase 0: Design in the plan.

**Minor UI changes** (adding a button, tweaking styles) do NOT warrant a design phase — embed design considerations inline in the relevant implementation phase instead.

**When in doubt** → ask the user via AskUserQuestion: "This feature involves some UI changes. Should I include a dedicated Design phase (Phase 0) for mockup exploration, or handle design inline?"

### Step 5: Write the Plan

Write the plan to `.claude/plans/{issue-id}-{feature-name}.md` where `{feature-name}` is a short kebab-case description.

**Plan file structure — ALL sections are mandatory**:

```markdown
# Plan: {issue-id} — {feature title}

## Context
**Issue**: {issue-id}
**Title**: {issue title from tracker}
**Branch**: {branch name}
**Created**: {date}

## Issue Description / Specification
{full issue description pasted here}

## Technical Discovery
{findings from codebase examination — relevant files, patterns found,
existing implementations to build on, potential conflicts}

## Decisions
{imported from grooming output if /z-groom was run or information present in Description, otherwise gathered during planning}

**Locked** (non-negotiable — each must map to at least one action point):
- [L1] {decision} → Phase {N}, step {M}
- [L2] {decision} → Phase {N}, step {M}

**Deferred** (out of scope — must NOT have action points):
- [D1] {decision} — {reason}

**Discretion** (AI decides during implementation):
- [X1] {decision}

## Design Decisions
{empty until Phase 0 completes — populated by /z-design or /z-work Phase 0}
{After design phase: selected mockup, component inventory, layout rationale}

## Phase 0: UI/UX Design  ← ONLY if design phase detected or --design flag
**Type**: design
### Requirements
- Explore existing codebase components for reuse
- Generate mockup variations for user selection
### Action Points
- [ ] Scan codebase for existing UI components, patterns, spacing, icons
- [ ] Generate 5+ distinct mockup variations, using Magic MCP if relevant
- [ ] Present mockups to user for selection
- [ ] Document selected design approach with rationale
- [ ] Create component inventory (new vs reused)
### Must-Haves
**Truths**:
- [ ] User has reviewed and selected a design direction
**Artifacts**:
- [ ] Design Decisions section populated in this plan file
**Links**:
- [ ] Existing components identified for reuse are verified to exist
### Acceptance Criteria
- [ ] User has explicitly chosen a mockup direction
- [ ] Component inventory distinguishes new components from reused ones
- [ ] Design aligns with existing app look and feel
### Work Log

## Phase 1: {name}
### Requirements
{what this phase achieves — concise}
### Action Points
- [ ] Step 1
- [ ] Step 2
### Must-Haves
**Truths** (behavioral assertions — things that must be true):
- [ ] {user-facing outcome}
**Artifacts** (files that must exist after this phase):
- [ ] `{file path}`
**Links** (connections between components that must be wired):
- [ ] {component A imports/uses component B}
### Acceptance Criteria
- [ ] {specific, testable criterion}
### Test Cases
{test case outlines — validated after implementation based on actual code diffs}
### Work Log

## Phase 2: {name}
...

## Phase N: Fix Issues
{empty — populated by /z-review}

## Phase N+1: Documentation
{references /z-docs-update skill}

## Disregarded Issues
{populated by /z-plan --verify and /z-review}
```

**Critical plan rules**:
- Break into SMALL phases that can be implemented separately, one by one
- Every phase MUST have Must-Haves with all three categories (Truths, Artifacts, Links)
- Tests are written as part of each `/z-work` phase — do NOT create a separate "Testing" phase
- Design is handled via Phase 0 when applicable — do NOT add design instructions to implementation phases
- Always include empty "Fix Issues" and "Documentation" terminal phases at the end
- DO NOT include time estimates
- Concise task definitions — no fluff

### Step 6: Decision Traceability Self-Check

After writing the plan, before displaying completion:

1. Read grooming output from `.claude/.local/{branch}-grooming.md` (if exists) or the issue description.
2. For each **Locked** decision: verify at least one action point implements it. If not → ask user via AskUserQuestion: "Locked decision [L{N}] has no implementing task. Add a task, or change to Deferred?"
3. For each **Deferred** decision: verify NO action point implements it. If found → ask user via AskUserQuestion: "Deferred decision [D{N}] appears to have a task in Phase {X}. Remove the task, or change to Locked?"
4. If no grooming output exists: still create a Decisions section by asking the user to categorize key decisions discovered during planning.
5. Write the decision-to-task mapping in the Decisions section (e.g., `[L1] Use OAuth2 → Phase 1, step 3`).

### Step 7: Completion Screen

Count the plan metrics and display:

**━━━ ✓ Plan Created ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━**
**{issue-id}: {feature title}**

| | |
|---|---|
| **Plan file** | `.claude/plans/{issue}-{feature}.md` |
| **Phases** | {N} implementation + Fix Issues + Documentation |
| **Design** | {Yes (Phase 0) / No} |
| **Steps** | {total action points across all phases} |
| **Must-haves** | {total truths + artifacts + links} |

───────────────────────────────────────────────────────────────
**▶ Next** · `/z-plan {issue} --verify` — validate plan with multi-agent review

*`/clear` first — fresh context*

**Also available:**
- `/z-work {issue} 0` — start with design phase (if Phase 0 exists)
- `/z-work {issue} 1` — skip verification, start building

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

If a Design phase was included, mention it in the completion screen and suggest `/z-work {issue} 0` as the first step.

**Do NOT start any implementation. Only create the plan file.**

