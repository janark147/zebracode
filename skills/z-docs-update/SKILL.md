---
argument-hint: "[issue]"
description: "Update DOCS.md and optionally CLAUDE.md with changes from branch"
required-predecessor: "z-work"
---

# /z-docs-update — Documentation Updater

Update project documentation with changes from the current branch. Also referenced by the "Documentation" terminal phase in plans — can be invoked from `/z-work --docs`.

## Pre-flight Validation

1. **Predecessor check**: Check that `git diff` against target branch is non-empty. If empty → redirect to `/z-work`.

---

## Argument Parsing

- **Issue ID**: First positional argument. If not provided, derive from current branch name.
- Read plan file: `.claude/plans/$ARGUMENTS*` — if no argument, use `.claude/plans/X*` where X = current branch name.

---

## Execution

### Step 1: Gather Context

1. Read `.claude/z-project-config.yml` for `docs.main_doc` (default: `DOCS.md`) and `docs.claude_md` (default: `CLAUDE.md`).
2. Review ALL commits in the current branch: `git log {target_branch}..HEAD --oneline`
3. Review the plan file for this issue
4. Read the current documentation file (`DOCS.md` or configured path)

### Step 2: Update Main Documentation

Review the ENTIRE documentation file and:

1. **Add** new information about the work done in this issue:
   - New features, endpoints, components, configuration options
   - Architecture changes
   - New conventions or patterns established
2. **Remove** anything that is outdated or no longer accurate due to the changes
3. **Keep it concise** — avoid unnecessary or useless details, avoid being verbose. Apply documentation best practices:
   - Eliminate vagueness
   - Use structure over prose
   - Be concise without losing meaning

### Step 3: Update CLAUDE.md (Optional)

If any new conventions, rules, or discoveries were made during the work:

**Prompt the user via AskUserQuestion** before editing CLAUDE.md:
- "The following discoveries were made during this issue. Would you like to add any to the project CLAUDE.md?"
- List each candidate rule/convention
- **Do NOT edit CLAUDE.md unless the user explicitly agrees**

### Step 4: Completion Screen

**━━━ ✓ Docs Updated ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━**
**{doc file}**

| | |
|---|---|
| **Sections added** | {N} |
| **Sections updated** | {N} |
| **Sections removed** | {N} |
| **CLAUDE.md updated** | {yes/no} |

───────────────────────────────────────────────────────────────
**▶ Next** · `/z-done` — quality gates, push, and create PR

*`/clear` first — fresh context*

**Also available:**
- `/z-docs-optimise {file}` — optimize the doc further

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
