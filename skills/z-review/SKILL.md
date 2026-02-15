---
argument-hint: "[branch/issue-id]"
description: "Comprehensive multi-agent code review of branch"
required-predecessor: "z-work"
required-mcps: ["context7"]
required-config:
  - "git.target_branch"
  - "stack.language"
  - "stack.framework"
---

# /z-review — Multi-Agent Code Review

Comprehensive code review with 3 parallel review agents, optional 3-agent debate ring, must-haves audit, and structured issue tracking.

**This skill is READ-ONLY.** Do not modify code, run tests, or run build commands.

## Pre-flight Validation

1. Read `.claude/z-project-config.yml`. If missing → redirect to `/z-project-init`.
2. Check required config keys: `git.target_branch`, `stack.language`, `stack.framework`. If missing → redirect to `/z-project-init`.
3. Verify Context7 MCP is available: call `mcp__context7__get-library-docs` with a `context7_ids` value from config (or fall back to `mcp__context7__resolve-library-id` if no IDs cached). If unavailable → display validation-failed screen.
4. **Predecessor check**: Check that `git diff` against target branch is non-empty. If empty → redirect to `/z-work`.

---

## Argument Parsing

- **Branch or issue ID**: First positional argument. If not provided, use current branch.
- Read plan file: `.claude/plans/$ARGUMENTS*` — if no argument, use `.claude/plans/X*` where X = current branch name.

---

## Execution

### Step 1: Gather Context

1. Fetch from origin, checkout branch: `git fetch origin && git checkout {branch} && git pull origin {branch}`
2. Get branch diff: `git diff {target_branch}...HEAD`
3. Read `.claude/z-project-config.yml` for stack info
4. Read project CLAUDE.md for conventions
5. Read project DOCS.md (or configured `docs.main_doc`) for architecture/style rules
6. Read `.claude/project-patterns.md` for known patterns/pitfalls
7. Read the plan file for requirements, decisions, and must-haves
8. Fetch issue description from tracker (same pattern as `/z-start`)

### Step 2: Must-Haves Audit

Before spawning review agents, verify all must-haves across ALL implemented phases:

- **Artifacts**: Confirm every listed file exists (`Glob`)
- **Links**: Confirm every connection is wired (`Grep` with `file:line` evidence)
- **Truths**: Cross-reference against test results

Any unchecked must-have is automatically flagged as a review issue with **Severity: Critical**. These are prepended to the consolidated findings table and **cannot be dismissed by the user**.

### Step 3: Spawn Review Agents (3 in parallel)

**Load stack-specific review checklists first:**
- Check `stack.framework` from config → if `references/review-stack-{framework}.md` exists (e.g., `review-stack-laravel.md`), Read it.
- Check `stack.frontend` from config → if set and `references/review-stack-{frontend}.md` exists (e.g., `review-stack-jquery.md`), Read it too.

Spawn all 3 review agents in parallel using the Task tool. Each agent receives:
- The full branch diff
- Stack info from `z-project-config.yml`
- Stack-specific review checklist (from references/ above — if loaded)
- Project conventions from CLAUDE.md
- Architecture/style rules from DOCS.md
- Known patterns from `project-patterns.md`
- Plan file content (for requirements context)
- Instructions to use Context7 to verify framework-native protections (suppress false positives)

**Agents**:

| Agent | Focus | ID prefix | Output type |
|---|---|---|---|
| `z-reviewer-quality` | Correctness, architecture, conventions, CLAUDE.md compliance, test coverage validation | Q-xxx | Quality, Convention |
| `z-reviewer-security` | Vulnerabilities, auth, input handling, data exposure | S-xxx | Security |
| `z-reviewer-performance` | N+1 queries, unnecessary loops, memory issues, scalability | P-xxx | Performance |

**All agents MUST return findings in this table format:**

```markdown
| ID | Issue | Type | Severity | File:Line | Confidence | Suggestion |
|------|-------|------|----------|-----------|------------|------------|
| Q-001 | Missing error handling | Quality | Medium | api.ts:42 | 85% | Wrap in try-catch |
```

**Consolidation rules for all agents:**
- Merge similar issues: same pattern in 3+ places → report once with "and N other locations"
- Skip unchanged code (unless Critical severity)
- No noise: no style preferences, subjective opinions, or "nice to have" improvements
- Every finding MUST have `file:line` — findings without citations are invalid and discarded

### Step 4: Consolidate Findings

After all agents complete:

1. Merge all agent output tables into one consolidated table
2. Prepend must-have failures from Step 2 (Severity: Critical, auto-included)
3. Check "Fix Issues" and "Disregarded Issues" sections in the plan — do not re-flag already listed items
4. Sort by Severity: Critical → High → Medium → Low

### Step 5: Debate Ring (Optional)

Present the consolidated table and ask via **AskUserQuestion**:
"Run debate ring for deeper analysis? This spawns 3 additional agents to challenge and re-rank the findings."
- **Yes — run debate (recommended for large changes)**: Spawn 3 debate agents
- **No — skip debate, use review findings as-is**: Proceed to Step 6

If debate ring is selected, spawn 3 debate agents in parallel:

| Agent | Perspective | Adjusts |
|---|---|---|
| `z-debate-pragmatist` | "Is this fix worth the complexity? What's the simplest solution?" | Severity, Confidence |
| `z-debate-adversary` | "How can this break? What edge cases are missed?" | Severity (up), Confidence |
| `z-debate-architect` | "Does this fit the system design? Will it scale?" | Severity, Suggestion |

Debate agents receive the consolidated findings table and add rationale annotations. Output: re-ranked table with debate notes.

### Step 6: Present Issues to User

Present the final consolidated table sorted by Severity.

Use **AskUserQuestion**: "Which issues do you want to fix?" (present the table as context)

- **Selected issues** → added to "Fix Issues" phase in the plan (create the phase if it doesn't exist)
- **Unselected issues** → added to "Disregarded Issues" section with one-line rationale
- **Must-have failures** → cannot be dismissed, always added to Fix Issues

### Step 7: Pattern Recording

If the same type of issue appeared 3+ times (e.g., missing null checks, inconsistent error handling):

Use **AskUserQuestion**: "Recurring pattern detected: {pattern}. Save to project patterns as a pitfall?"

If approved: append to `.claude/project-patterns.md` under "Common Pitfalls":
- Format: `- {pattern description} (found in review of {issue-id}, {date})`

### Step 8: Work Log

For each phase that has review findings, append summary lines to that phase's `### Work Log`:
- Format: `- /z-review — {ID}: {issue summary} [{severity}] → {disposition}`
- Example: `- /z-review — Q-001: Missing rate limiting on login [HIGH] → Fix Issues`

### Step 9: Completion Screen

**━━━ ✓ Review Complete ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━**
**{N} issues, {M} to fix**

| | |
|---|---|
| **Must-haves** | {verified}/{total} |
| **Issues found** | {N} (Q:{n} S:{n} P:{n}) |
| **To fix** | {M} *(added to Fix Issues phase)* |
| **Dismissed** | {D} |

> **Severity:** Critical {n} · High {n} · Medium {n} · Low {n}

───────────────────────────────────────────────────────────────

**If issues marked to fix (M > 0):**

**▶ Next** · `/z-work {issue} --fix` — address {M} review findings

*`/clear` first — fresh context*

**Also available:**
- `/z-pause` — save and stop

**If clean review (M = 0):**

**▶ Next** · `/z-done {issue}` — finalize and wrap up

*`/clear` first — fresh context*

**Also available:**
- `/z-pause` — save and stop

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
