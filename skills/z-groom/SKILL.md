---
argument-hint: "[issue]"
description: "Interactive grooming session for an issue"
disable-model-invocation: true
required-predecessor: "z-start"
required-config:
  - "issue_tracker.type"
---

# /z-groom — Issue Grooming

Interactive refinement of an issue before planning. Produces categorized decisions (Locked/Deferred/Discretion) that feed directly into `/z-plan`.

## Pre-flight Validation

1. Read `.claude/z-project-config.yml`. If missing → redirect to `/z-project-init`.
2. Check required config key: `issue_tracker.type`. If missing → redirect to `/z-project-init`.
3. **Predecessor check**: Verify current branch is NOT the target branch. If on target branch → redirect to `/z-start {issue}`.

---

## Argument Parsing

- **Issue ID**: First positional argument. If not provided, derive from current branch name.

---

## Execution

### Step 1: Read & Analyse the Issue

1. Fetch issue from tracker:
   - **jira**: Use `issue_tracker.mcp_tool` with issue ID
   - **github**: Use `gh issue view {issue-number}`
   - **linear**: Use configured MCP tool
   - **none**: Ask user to describe the task
2. Scan the codebase for related context:
   - `Grep` for relevant models, routes, components, services
   - Check `.claude/project-patterns.md` for related pitfalls or patterns
   - Check git history for similar past issues or related changes
3. Use this context to inform which areas are most relevant — ask *informed* questions, not generic ones.

### Step 2: Recommend Discussion Areas

Present a checklist of discussion areas via **AskUserQuestion** (`multiSelect: true`). Pre-check the areas most relevant to this specific issue:

- Requirements clarity
- Technical approach
- UX/UI considerations
- Edge cases & error handling
- Dependencies & integration
- Testing strategy
- Performance considerations
- Security implications

Example: a backend API issue would pre-check "Technical approach", "Edge cases", "Security" but not "UX/UI considerations".

### Step 3: Area-by-Area Deep Dive

For each selected area (in the order selected):

1. Ask **3 targeted questions** informed by the codebase analysis from Step 1. Questions should be probing, not superficial.
2. After 3 questions, use **AskUserQuestion**: "More questions in this area, or move to next area?"
   - "More" → ask 3 more questions, then ask again
   - "Next" → proceed to next selected area
3. Adapt questions based on previous answers — each question should build on what was discussed.

### Step 4: Decision Categorization

As decisions emerge during grooming, categorize each one via **AskUserQuestion** with 3 options:

- **Locked** — Non-negotiable. Must appear as a task in the plan. Cannot be changed without user approval.
  - Example: "Use OAuth2 for authentication" / "Email must validate on blur"
- **Deferred** — Explicitly out of scope for this issue. Must NOT appear as a task in the plan.
  - Example: "Password reset flow — separate issue" / "Dark mode — future work"
- **Discretion** — AI decides the best approach during implementation.
  - Example: "Use whichever validation library fits best" / "Component structure is up to you"

**Every significant decision must be categorized.** Do not skip this step. IDs ([L1], [D1], [X1]) are used for traceability in `/z-plan`.

### Step 5: Produce Summary

After all areas are covered, produce a structured summary:

```markdown
## Grooming Summary: {issue}

### Decisions
**Locked** (must appear in plan):
- [L1] {decision}
- [L2] {decision}

**Deferred** (out of scope — must NOT be in plan):
- [D1] {decision} — {reason}
- [D2] {decision} — {reason}

**Discretion** (AI decides during implementation):
- [X1] {decision}
- [X2] {decision}

### Requirements
- {clarified requirements}

### Open Questions
- {unresolved items}

### Edge Cases Identified
- {edge cases}

### Acceptance Criteria (refined)
- {updated criteria}
```

### Step 6: Save Grooming Output

Save the full summary to `.claude/.local/{branch}-grooming.md` so it survives `/clear` and is available to `/z-plan`.

### Step 7: Update Issue in Tracker

Use **AskUserQuestion**: "Update the issue description in {tracker} with grooming results?"

If confirmed:
- **Jira**: Update issue description via MCP (append grooming summary + refined acceptance criteria)
- **GitHub**: Update issue body via `gh issue edit` (append grooming summary + refined acceptance criteria)

### Step 8: Completion Screen

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✓ Grooming Complete — {issue-id}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Areas covered     {N}/{total}
  Decisions made    {N}
  Open questions    {N}
  Edge cases found  {N}
  Posted to         {tracker} ✓

─────────────────────────────────────────────────────────────────
  ▶ Next    /z-plan {issue}
            Create implementation plan from grooming

            /clear first — fresh context
─────────────────────────────────────────────────────────────────

  Also available:
    · /z-plan {issue} --design — force a design phase into the plan

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
