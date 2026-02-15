---
description: "Save session state for later resumption"
disable-model-invocation: true
required-predecessor: "z-start"
---

# /z-pause — Save Session State

## Pre-flight

- Must NOT be on the target branch (must be on a feature branch).
- If no active work detected (no plan file, no changes), inform user and stop.

## Execution

### 1. Update Plan File

Find the plan file for the current branch in `.claude/plans/`. Ensure it reflects current progress:
- Mark completed steps as `[x]`
- Add notes to the current phase about what was in progress

### 2. Analyze Working Tree

- Run `git status` and `git diff --stat`
- Present overview of uncommitted changes to user
- Use AskUserQuestion: "Do you want to commit these changes before pausing?"
  - If yes: create a WIP commit with message `WIP: {phase} in progress`
  - If no: leave changes as-is

### 3. Write Session File

Write to `.claude/.local/{branch-name}-session.md`:

```markdown
# Session: {branch-name}
**Paused**: {date/time}
**Plan file**: .claude/plans/{issue}-{feature}.md
**Current phase**: Phase {N}

## What Was Done
{summary of completed work this session}

## What Was Discovered
{any findings, gotchas, or context learned}

## Current Status
{where exactly we are — which step of which phase}

## Hypotheses
{any working theories about problems encountered}

## Attempted Fixes
{what was tried and didn't work, if applicable}

## Recommended Next Steps
{what should be done next when resuming}
```

**Rules for session file content**:
- Do NOT include code examples or copy-paste — the code is in git
- Be concise but complete enough for a cold-start agent to pick up
- Focus on context that would be lost after `/clear`

### 4. Ensure `.local/` directory exists

Create `.claude/.local/` if it doesn't exist. Ensure `.claude/.gitignore` contains `.local/`.

## Completion Screen

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ◆ Session Paused — {branch-name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Current phase    Phase {N}: {name}
  WIP committed    {yes/no}
  Session file     .claude/.local/{branch}-session.md ✓
  Plan updated     ✓

─────────────────────────────────────────────────────────────────
  ▶ Resume  /z-resume
            Restores full context from session file

            /clear first — fresh context
─────────────────────────────────────────────────────────────────
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
