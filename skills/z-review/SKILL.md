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

Comprehensive code review with 3 parallel review agents (one instance per file group on large diffs, up to 3 passes), optional 3-agent debate ring, must-haves audit, and structured issue tracking.

**This skill is READ-ONLY.** Do not modify code, run tests, or run build commands.

## Pre-flight Validation

1. Read `.claude/z-project-config.yml`. If missing → redirect to `/z-project-init`.
2. Check required config keys: `git.target_branch`, `stack.language`, `stack.framework`. If missing → redirect to `/z-project-init`.
3. Verify Context7 MCP is available: check that `mcp__context7__*` tools are present in your available tools. Do NOT make a Context7 call just to test availability — that wastes a full doc fetch. If absent → display validation-failed screen.
4. **Clean working tree check**: Run `git status --porcelain`. If output is non-empty → STOP and ask via AskUserQuestion: "Working tree has uncommitted changes. Did you forget to `/commit`?" Do not proceed until the tree is clean.
5. **Predecessor check**: Check that `git diff` against target branch is non-empty. If empty → redirect to `/z-work`.

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

### Step 3: Spawn Review Agents (in parallel, up to 3 passes)

**Load stack-specific review checklists first:**
- Check `stack.framework` from config → if `references/review-stack-{framework}.md` exists (e.g., `review-stack-laravel.md`), Read it.
- Check `stack.frontend` from config → if set and `references/review-stack-{frontend}.md` exists (e.g., `review-stack-jquery.md`), Read it too.

**Split large diffs:** If the diff changes more than 10 files or more than 1,000 lines, split the changed files into groups of at most 8 files and about 800 changed lines each. Keep files from the same directory or feature in the same group. Spawn one instance of each of the 3 review agents per group. A smaller diff is one group.

Spawn all review agent instances in parallel using the Task tool. Each instance receives:
- The diff of its file group, plus the paths of all other changed files (it can Read them for context, but it reviews only its own group)
- Stack info from `z-project-config.yml`
- Stack-specific review checklist (from references/ above — if loaded)
- Project conventions from CLAUDE.md
- Architecture/style rules from DOCS.md
- Known patterns from `project-patterns.md`
- Plan file content (for requirements context)
- Instructions to use Context7 sparingly: at most one targeted call, only to verify a specific framework-native protection a finding hinges on (suppress false positives)

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

**Every agent MUST also return a coverage table** with one row per file in its group:

```markdown
| File | Focus areas with findings | Focus areas checked, none found | Not applicable |
|------|---------------------------|---------------------------------|----------------|
| api.ts | Error handling (Q-001) | Correctness, Architecture, Conventions | UI quality |
```

If a file from the agent's group is missing from its coverage table, spawn that agent again for the missing files only.

**Rules for all agents:**
- Check every file in the group against every focus area. Do not stop after a few findings — there is no limit on the number of findings
- Merge similar issues: same pattern in 3+ places → report once and list every `file:line` where it occurs
- Skip unchanged code (unless Critical severity)
- No noise: no style preferences, subjective opinions, or "nice to have" improvements
- Every finding MUST have `file:line` — findings without citations are invalid and discarded
- Verify before reporting: re-read the cited lines. Discard a finding only if the re-read shows the claim is false. If the claim could be true but you cannot confirm it, keep the finding and lower its Confidence
- Confidence is the agent's certainty after that re-read. It is shown to the user and is never used to drop a finding — the user decides

**Follow-up passes:** One pass misses real issues, and which ones it misses differs per pass. After the first pass completes:

1. Merge the findings of all instances into one list
2. Spawn new instances of the same agents for the same file groups (new instances, not continuations of the previous ones). In addition to the inputs above, each receives the merged findings list for its group and its previous coverage table, with the instruction: "These issues are already found. Do not repeat them. Find the issues that were missed. Go through every file and focus area again, starting with the cells recorded as 'checked, none found'."
3. A finding is new if no finding in the merged list has the same file + Type + underlying problem. Add new findings to the merged list
4. Do not spawn an agent instance again once it has returned a pass with no new findings
5. Repeat until no instance returns a new finding, or 3 passes in total have run
6. Record the number of new findings per pass for the completion screen

### Step 4: Consolidate Findings

After all passes complete:

1. Merge all agent output tables from all passes into one consolidated table and renumber IDs sequentially per prefix (Q-, S-, P-). Keep every finding regardless of Confidence or Severity
2. Prepend must-have failures from Step 2 (Severity: Critical, auto-included)
3. Check "Fix Issues" and "Disregarded Issues" sections in the plan — do not re-flag already listed items. Match on file path + Type + the same underlying problem. Ignore IDs and line numbers — IDs restart every run and line numbers shift
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

Write every entry in both sections in this format, so a later `/z-review` run can match it in Step 4:

`- [review] {file path} | {Type} | {one-line issue} — {fix suggestion or dismissal rationale}`

Example: `- [review] app/Http/Controllers/AuthController.php | Security | No rate limiting on login — dismissed: handled at the load balancer`

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
| **Review passes** | {passes} *(new findings per pass: {n1} / {n2} / {n3})* |
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
