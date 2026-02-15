---
description: "Review and improve project CLAUDE.md against best practices"
---

# /z-claudemd-review — Audit Project CLAUDE.md

## Execution

### 1. Read Current State

- Read the project's current CLAUDE.md
- Read the global `~/.claude/CLAUDE.md` and `~/.claude/RULES.md`
- Read `.claude/z-project-config.yml` for stack context

### 2. Scan Codebase for Conventions

Scan the project for patterns that should be documented:
- Naming conventions (files, classes, variables, routes)
- File organization and directory structure
- Import style (absolute vs relative, barrel files)
- Framework patterns (middleware, services, repositories, controllers)
- Test patterns and conventions (naming, structure, fixtures)
- Known antipatterns or deviations from framework defaults

### 3. Audit Against Quality Principles

Evaluate the existing CLAUDE.md against these 8 principles. Flag violations:

**Structural principles:**

| Principle | What to flag | Fix |
|-----------|-------------|-----|
| **Pitch, don't point** | `@`-references to files/paths (e.g., `@src/utils/auth.ts`) | Describe intent and pattern so Claude discovers the right file |
| **Alternatives over prohibitions** | "Never X" / "Don't X" rules without an alternative | Add what to do instead |
| **Token budget** | Sections exceeding ~500 tokens | Split into linked reference or condense |
| **Automate over document** | Multi-step manual procedures | Suggest a hook, skill, or CLI wrapper |

**Content quality principles:**

| Principle | What to flag | Fix |
|-----------|-------------|-----|
| **Verify with behavior** | Rules Claude already follows by default | Suggest deletion (noise) |
| **Evidence over adjectives** | Vague descriptors ("be thorough", "write clean code") | Replace with actionable, verifiable instructions |
| **Scope separation** | Project-specific info in global CLAUDE.md, or vice versa | Move to correct scope |
| **Freshness check** | Deprecated libraries, outdated API patterns | Update or remove |

### 4. Research Best Practices

Use web search for current CLAUDE.md best practices and tips.

### 5. Present Findings

Use AskUserQuestion to present findings grouped by principle:
- Audit flags from step 3 (each flag = one row: offending text, principle violated, suggested fix)
- Conventions to add from codebase scan
- What to add to global CLAUDE.md vs project CLAUDE.md
- What to skip

### 6. Apply Approved Changes

Only modify CLAUDE.md with explicit user approval. Never edit without consent.

## Context-Dependent Behavior

- **After `/z-project-init`**: Focus on populating a new/empty CLAUDE.md with discovered conventions
- **Standalone invocation**: Focus on auditing and improving an existing CLAUDE.md

## Completion Screen

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✓ CLAUDE.md Reviewed — {N} improvements applied
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Added       {N} conventions to project CLAUDE.md
  Added       {N} rules to global CLAUDE.md
  Skipped     {N} suggestions (user declined)

─────────────────────────────────────────────────────────────────
  ▶ Next    /z-start {issue}
            Begin working on a feature

            /clear first — fresh context
─────────────────────────────────────────────────────────────────

  Also available:
    · /z-groom {issue} — groom before planning
    · /z-plan {issue}  — plan directly

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
