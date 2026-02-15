# /z-plan --verify — Multi-Agent Plan Verification

Runs a multi-agent plan verification. Replaces the former `/z-checklist` command.

## Step 1: Load Plan

1. Read the existing plan file: `.claude/plans/$ARGUMENTS*` — if no argument, use `.claude/plans/X*` where X = current branch name.
2. If no plan file found → display blocked screen and redirect to `/z-plan {issue}`.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✗ Plan Verify Blocked — no plan file found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Required     Plan file must exist
  Missing      .claude/plans/{issue}*.md

─────────────────────────────────────────────────────────────────
  ▶ Run first  /z-plan {issue}
               Create an implementation plan
─────────────────────────────────────────────────────────────────
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 2: Spawn Verification Agents

Count the implementation phases in the plan (excluding "Fix Issues" and "Documentation" terminal phases).

- **Plans with ≤2 phases** → spawn **2 agents**:
  - Agent 1: Architecture + completeness (combined design fit and integration check)
  - Agent 2: Security + research (combined safety audit and best practices)

- **Plans with ≥3 phases** → spawn **4 agents**:
  - Agent 1: Architecture & design fit
  - Agent 2: Security & safety audit
  - Agent 3: Integration & completeness check
  - Agent 4: Research best practices for the specific task

Spawn agents using the Task tool with `subagent_type: "general-purpose"`. Each agent receives:
- The full plan file content
- The project config (`z-project-config.yml`)
- The verification checklist categories assigned to that agent (see Step 3)
- Instructions to follow this process for EACH checklist item: **READ → RESEARCH → ANALYZE ROOT CAUSE → CHALLENGE → THINK → RESPOND**
- Instructions to cite specific plan sections AND `file:line` code references for every flagged issue (see §9.10)
- Access to Context7 for framework/library verification

**ANALYZE ALL ITEMS ONE BY ONE. ACHIEVE 100% COVERAGE. DO NOT MISS A SINGLE ITEM.**

## Step 3: Verification Checklist

Each agent evaluates the plan against their assigned categories from this full checklist:

**Research**:
- [ ] Researched industry best practices
- [ ] Analyzed existing codebase patterns
- [ ] Conducted additional research where needed

**Architecture & Design**:
- [ ] Evaluated current architecture fit
- [ ] Recommended changes if beneficial
- [ ] Identified technical debt impact
- [ ] Challenged suboptimal patterns
- [ ] Honest assessment — NOT a yes-man

**Solution Quality**:
- [ ] CLAUDE.md compliant
- [ ] Simple, streamlined, no redundancy
- [ ] 100% complete (not 99%)
- [ ] Best solution with trade-offs explained
- [ ] Prioritized long-term maintainability

**Security & Safety**:
- [ ] No security vulnerabilities introduced
- [ ] Input validation and sanitization added
- [ ] Authentication/authorization properly handled
- [ ] Sensitive data protected (encryption, no logging)
- [ ] OWASP guidelines followed

**Integration & Testing**:
- [ ] All upstream/downstream impacts handled
- [ ] All affected files updated
- [ ] Consistent with valuable patterns
- [ ] Fully integrated, no silos
- [ ] Tests with edge cases added

**Technical Completeness**:
- [ ] Environment variables configured
- [ ] DB / Storage rules updated
- [ ] Utils and helpers checked
- [ ] Performance analyzed

## Step 4: Consolidate & Present Issues

Collect all issues found by agents. Present to user with numbered IDs.

Use **AskUserQuestion** for each issue — the user can:
- **Accept** → added to plan as amendment items
- **Dismiss** → added to "Disregarded Issues" section at end of plan with one-line rationale

## Step 5: Write Amendments

1. Write accepted issues to `.claude/.local/{branch}-verify-amendments.md` so they survive `/clear`. Structure the file so `/z-work` can reference it.
2. Update the plan file:
   - Add accepted amendments to relevant phases
   - Add dismissed issues to the "Disregarded Issues" section
3. Track which checklist items passed/failed.

## Step 6: Completion Screen

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✓ Plan Verified — {pass}/{total} checks passed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Checks passed    {N}
  Issues found     {N}
  Accepted         {N} (added to plan as amendments)
  Dismissed        {N} (moved to Disregarded Issues)

─────────────────────────────────────────────────────────────────
  ▶ Next    /z-work {issue} 1
            Begin Phase 1 implementation

            /clear first — fresh context
─────────────────────────────────────────────────────────────────

  Also available:
    · /z-work {issue} 0 — start with design phase (if Phase 0 exists)
    · /z-plan {issue}   — revise the plan

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
