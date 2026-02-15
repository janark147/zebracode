---
argument-hint: "[message]"
description: "Create a commit (never credits Claude/Anthropic)"
disable-model-invocation: true
---

Create a commit in the current branch. NEVER MENTION CLAUDE, ANTHROPIC, OR AI IN THE COMMIT MESSAGE.

## Arguments

Use $ARGUMENTS as the commit message if provided. If arguments are provided, follow the arguments EXACTLY TO THE LETTER. You are NOT allowed to fantasize or change/add anything in the commit message. Follow the user's input TO THE LETTER.

If no commit message is provided by the user, create a **SHORT AND TO THE POINT** commit message. One line. No body unless the change is genuinely complex.

## Rules

- NEVER credit Claude Code or Anthropic in the commit message. NEVER EVER.
- Do NOT add "Co-authored-by" or any AI attribution.
- After committing, display the completion line and STOP. Do not continue working.

## Completion

After committing, display:

```
─────────────────────────────────────────────────────────────────
  ✓ Committed  {short-hash}  {message}
─────────────────────────────────────────────────────────────────
```
