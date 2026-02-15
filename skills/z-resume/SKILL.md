---
description: "Resume work from a previous session"
required-predecessor: "z-pause"
---

# /z-resume — Restore Session Context

## Pre-flight

- Look for `.claude/.local/{current-branch}-session.md`
- If not found: check all files in `.claude/.local/` for any `*-session.md` files and present options via AskUserQuestion
- If none exist: inform user "No session to resume" and stop

## Execution

### 1. Read Context

- Read the session file completely
- Read the plan file referenced in the session file
- Read recent git log for the branch (`git log --oneline -10`)

### 2. Present Overview

Display all context from the session file:

```
## Resuming: {branch-name}
- Last paused: {date}
- Current phase: {N} — {phase name}
- Status: {current status from session file}
- Next steps: {recommended next steps}
```

If the session file mentions **hypotheses** or **failed attempts**, highlight these prominently with a `⚠` marker.

### 3. Wait for Confirmation

DO NOT begin work. Use AskUserQuestion: "Ready to continue, or would you like to adjust the approach?"

### 4. After Confirmation

Suggest the next command: `/z-work {issue} {phase}`

## Completion Screen

**━━━ ✓ Context Restored ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━**
**{branch-name}**

| | |
|---|---|
| **Paused at** | {date} |
| **Current phase** | Phase {N}: {name} |
| **Status** | {current status from session file} |

> **Notes from last session:**
> {key findings, hypotheses, or gotchas — 1-3 lines}

───────────────────────────────────────────────────────────────
**▶ Next** · `/z-work {issue} {phase}` — continue Phase {N}

*`/clear` first — fresh context*

**Also available:**
- `/z-verify {issue} {N-1}` — verify previous phase first
- `/z-review` — skip to review

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
