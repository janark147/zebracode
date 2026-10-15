# ZebraCode v2.0

A structured workflow framework for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Brings opinionated, repeatable workflows to AI-assisted software development — with plans and phases that persist across sessions, multi-agent reviews, and automated quality gates.

### What makes it different

| Principle | What it means |
|-----------|---------------|
| **Evidence-based verification** | Every skill that claims progress must show concrete proof — test counts, linter output, `file:line` citations. No bare checkmarks, no "it works." |
| **Least-privileged tool access** | Review and debug agents get read-only tools (Read, Grep, Glob, Context7 docs lookup). Only the main session modifies code. Agents can't accidentally break things. |
| **Workflow state validation** | A Stop hook asks Claude to confirm before stopping with unchecked items in a started phase. Permission rules block edits to protected files and ask before destructive commands. |
| **Decision enforcement** | Grooming decisions are categorized as Locked, Deferred, or Discretion. Locked decisions map to plan actions. Deferred items are never implemented unless re-categorized. |
| **Persistent project patterns** | Conventions, pitfalls, and shortcuts discovered during work are recorded in `.claude/project-patterns.md` (with user approval) and retained across sessions and branches. |
| **Full audit trail** | Plan files contain per-phase Work Logs — append-only entries with commit hashes, skill references, and `file:line` citations that survive `/clear` and context compaction. |
| **Automated self-reflection** | Before claiming a phase complete, the agent silently evaluates: Did I verify behavior or just confirm code exists? Did I deviate from the plan? Would I flag this in review? |
| **Optimized CLAUDE.md** | Global instructions enforce verification-first development, debugging discipline, security boundaries, and context management — reviewed and tuned via `/z-claudemd-review`. |

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Project Setup](#project-setup)
- [Workflow Guide](#workflow-guide)
- [Skill Reference](#skill-reference)
- [Hook Reference](#hook-reference)
- [Agent Reference](#agent-reference)
- [Status Line](#status-line)
- [Configuration](#configuration)
- [File Structure](#file-structure)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required

| Tool | Purpose |
|------|---------|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | CLI agent (ZebraCode is a framework on top of it) |
| `jq` 1.6+ | JSON parsing in hook scripts and the status line (`brew install jq`) |
| `terminal-notifier` | Desktop notifications on macOS (`brew install terminal-notifier`) |
| [Context7](https://github.com/upstash/context7) MCP | Framework/library documentation lookup (required by `/z-plan`, `/z-work`, `/z-review`) |

### Optional MCPs and tools

| MCP / tool | Purpose | When needed |
|-----|---------|-------------|
| Jira MCP | Issue tracker integration | Jira projects |
| Laravel Boost | Enhanced Laravel support | Laravel projects |
| [`ccusage`](https://github.com/ccusage/ccusage) | Weekly cost in the [status line](#status-line) | Leave it out to hide the weekly cost |

### Plugins

| Plugin | Purpose | When needed |
|--------|---------|-------------|
| `frontend-design@claude-plugins-official` | Claude's design skill — design plan, generic-default checks, self-critique | `/z-design` mockups (`install.sh` offers to install it) |

> **Tip**: Use project-scope MCP configuration where possible to avoid loading unused MCPs globally.

---

## Installation

### Quick Install

```bash
git clone https://github.com/janark147/zebracode ~/zebracode
cd ~/zebracode
./install.sh
```

### Manual Install

Copy framework files to your Claude Code config directory:

```bash
# Skills
cp -r skills/ ~/.claude/skills/

# Agents
cp -r agents/ ~/.claude/agents/

# Hooks
cp -r hooks/ ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh

# Templates
cp -r templates/ ~/.claude/templates/

# Status line
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh

# Global instructions (review before overwriting — may contain your own customizations)
# cp CLAUDE.md ~/.claude/CLAUDE.md
# cp RULES.md ~/.claude/RULES.md
```

Then merge the hooks, permission rules and `attribution` setting from `settings.json.example` into your `~/.claude/settings.json`. See [Configuration](#configuration).

---

## Project Setup

After installing ZebraCode globally, initialize it for each project:

```
cd /path/to/your/project
/z-project-init
```

This runs an interactive questionnaire that:
1. Auto-detects your stack (language, framework, test runner, formatter)
2. Asks about issue tracker, git conventions, and tooling preferences
3. Creates `.claude/z-project-config.yml` with your answers
4. Writes protected files and dangerous commands as permission rules in `.claude/settings.json`
5. Creates `.claude/.gitignore` (ignores `.local/` ephemeral state)

Both files are committed to git so all team members share the same ZebraCode configuration and protections.

---

## Workflow Guide

<p align="center">
  <img src="zebracode-workflow.svg" alt="ZebraCode Standard Feature Workflow" width="700" />
</p>

**Key principle**: Run `/clear` between each skill invocation. Context is preserved via plan files and git history — not the conversation window.

---

## Skill Reference

### Core Workflow

| Skill | Description | Arguments |
|-------|-------------|-----------|
| `/z-start` | Checkout branch, read issue, prepare workspace | `[issue]` |
| `/z-groom` | Interactive issue grooming with decision categorization | `[issue]` |
| `/z-plan` | Create implementation plan with phases and must-haves | `[issue] [--verify] [--design]` |
| `/z-design` | Generate UI/UX design mockups (standalone or via Phase 0) | `[issue]` |
| `/z-work` | Implement the next phase(s) of the plan | `[issue] [phase...] [--fix] [--docs]` |
| `/z-verify` | Verify phase implementation against acceptance criteria | `[issue] [phase]` |
| `/z-review` | Multi-agent code review with optional debate ring | `[branch/issue-id]` |
| `/z-done` | Quality gates, push, PR creation, cleanup | — |

To continue an earlier conversation, use Claude Code's built-in `/resume` (or `claude --resume`). After `/clear` or in a new session, the SessionStart hook shows the plan's next phase and the `/z-work` command for it.

### Alternative Flows

| Skill | Description | Arguments |
|-------|-------------|-----------|
| `/z-quick` | Fast-track: start + implement + test + commit | `[issue] [branch]` |
| `/z-debug` | Multi-agent bug investigation with hypothesis testing | `[issue-id \| resume] [branch]` |

### Documentation & Quality

| Skill | Description | Arguments |
|-------|-------------|-----------|
| `/z-test` | Run test suite and fix failures | `[backend/frontend]` |
| `/z-docs-update` | Update DOCS.md with changes from branch | `[issue]` |
| `/z-docs-optimise` | Optimize documentation for conciseness and clarity | `[file-path]` |
| `/z-claudemd-review` | Audit and improve project CLAUDE.md | — |
| `/z-retrospective` | Analyze workflow artifacts for recurring patterns | — |

### Utilities

| Skill | Description | Arguments |
|-------|-------------|-----------|
| `/commit` | Create a commit (short message, never credits AI) | `[message]` |
| `/z-project-init` | Initialize ZebraCode for a new project | — |

---

## Hook Reference

All hooks are shell scripts in `~/.claude/hooks/`. They're wired via `~/.claude/settings.json`.

| Hook | Event | Tool Match | Behavior |
|------|-------|------------|----------|
| `workflow-state.sh` | SessionStart | — | Injects workflow progress bar and next-step suggestion (also after `/clear` and compaction) |
| `verify-tasks-complete.sh` | Stop | — | Asks Claude to confirm once before stopping when a started phase has unchecked items |
| `notify-user.sh` | Notification | — | Desktop notification (macOS `terminal-notifier`) |

`workflow-state.sh`, `verify-tasks-complete.sh` and `statusline.sh` share `hooks/lib/plan.sh`, which finds the plan for a branch (`feature/TAL-1` → `.claude/plans/TAL-1-*.md`) and counts only `## Phase <number>` sections.

Protected files and dangerous commands are not hooks — they are `permissions.deny` and `permissions.ask` rules (see [Settings](#settings-claudesettingsjson)). Formatting runs once per phase in `/z-work`'s quality checks and in `/commit`, not after every edit.

### Hook API Notes

- Hooks receive context via **JSON on stdin** (not command-line arguments)
- Parse with `jq`: e.g., `jq -r '.tool_input.file_path'` or `jq -r '.tool_input.command'`
- SessionStart plain stdout is added to Claude's context. For most other events plain stdout only goes to the debug log — return `hookSpecificOutput.additionalContext` in JSON to reach Claude
- Stop hooks get `stop_hook_active: true` when Claude is already continuing because of a stop hook — allow the stop then, or the turn never ends

---

## Agent Reference

ZebraCode includes 10 custom agent definitions for multi-agent workflows.

### Review Agents (spawned by `/z-review`)

| Agent | Focus | Model |
|-------|-------|-------|
| `z-reviewer-quality` | Code quality, patterns, maintainability | Opus |
| `z-reviewer-security` | Security vulnerabilities, OWASP, data exposure | Opus |
| `z-reviewer-performance` | Performance bottlenecks, N+1 queries, caching | Opus |

### Debate Agents (spawned by `/z-review` debate ring)

| Agent | Personality | Model |
|-------|-------------|-------|
| `z-debate-pragmatist` | Practical, trade-off focused, ships features | Opus |
| `z-debate-adversary` | Adversarial, edge-case hunter, worst-case thinker | Opus |
| `z-debate-architect` | Big-picture, system design, long-term implications | Opus |

### Debug Agents (spawned by `/z-debug`)

| Agent | Focus | Model |
|-------|-------|-------|
| `z-debug-investigator-state` | Data flow, state management, caching issues | Opus |
| `z-debug-investigator-logic` | Edge cases, boundary values, off-by-one errors | Opus |
| `z-debug-investigator-integration` | API contracts, middleware, cross-service issues | Opus |
| `z-debug-judge` | Synthesizes investigator reports, ranks hypotheses | Opus |

All agents use **read-only tools** — Read, Grep, Glob and the whole Context7 server (`mcp__context7`, so a renamed Context7 tool doesn't break them); the security reviewer also gets WebSearch. They cannot modify files. Only the main Claude Code session makes changes.

The three reviewers run at `effort: xhigh`. The debate and debug agents use your session's effort level.

---

## Status Line

`statusline.sh` (installed to `~/.claude/statusline.sh`) shows three lines:

```
📁 ~/code/my-app  🌿 TAL-1  🤖 Opus 5.5 · xhigh  📟 v2.1.300
🧠 Context left: 79%  ⏳ 5h 36% (resets 20:30) · 7d 24% (resets Thu 22 Oct)  📋 Phase 3/8: API endpoints
💰 $8.60  📅 $294.19 this week  💾 cache until 20:24
```

| Item | Source |
|------|--------|
| Directory, git branch | Branch of the folder Claude Code was started in |
| Model · effort | Claude Code's current model and effort level |
| Context left | Claude Code's own remaining percentage for the real window size (200k or 1M). `—` early in a session |
| 5h / 7d | Claude subscription usage limits and their reset times. Hidden when Claude Code doesn't send them (API-key users) |
| Phase X/Y | The plan for the current branch: the first `## Phase` with unchecked items, out of the last phase number |
| Session cost | Claude Code's session cost estimate |
| Weekly cost | `ccusage weekly`, refreshed in the background at most every 10 minutes (cached in `~/.claude/.statusline-weekly-cost.json`), because one `ccusage` run takes about 20 seconds |
| Cache | When the prompt cache expires. After that, the next message re-sends the whole context at full price |

The script reads all input with one `jq` call and takes about 0.1 seconds. Claude Code cancels a status line run when a new update arrives, so a slow script leaves old values on screen.

---

## Configuration

### Project Config: `z-project-config.yml`

Created by `/z-project-init` in your project's `.claude/` directory. Key sections:

```yaml
project:
  name: "my-project"

git:
  target_branch: "main"
  branch_prefix: "feature/"

issue_tracker:
  type: "github"          # github | jira | linear | none

stack:
  language: "typescript"
  framework: "nextjs"
  frontend: "react"
  test_runner_backend: "jest"
  formatter: "prettier"

commands:
  test_backend: "npm test"
  lint: "npm run lint"
  format: "npx prettier --write"
  typecheck: "npx tsc --noEmit"
```

### Project Permissions: `.claude/settings.json`

Also written by `/z-project-init`. Protected files are `deny` rules, dangerous commands are `ask` rules (Claude Code asks you every time, even in auto mode):

```json
{
  "permissions": {
    "deny": ["Edit(.env)", "Edit(.env.*)", "Edit(/storage/**)", "Edit(*.pem)"],
    "ask": ["Bash(*artisan migrate:fresh*)", "Bash(*wrangler delete*)"]
  }
}
```

`Edit(...)` rules also cover the Write tool and shell redirects such as `> .env`. A bare file name matches at any depth; a leading `/` anchors a path to the project root.

### Global Instructions

- **`~/.claude/CLAUDE.md`**: Framework behavior rules (plan usage, verification, debugging)
- **`~/.claude/RULES.md`**: Actionable operational rules (task management, when to ask the user instead of deciding, grooming decisions, agent access)

### Settings: `~/.claude/settings.json`

The `settings.json.example` file contains the complete configuration. Key settings:

- `attribution: false`: No AI co-author trailer, PR text or session link in commits and PRs (Claude Code v2.1.281+)
- `permissions.deny`: `.env` files and lock files can't be edited in any project
- `permissions.ask`: database wipe commands, force pushes and `git reset --hard` always ask first
- `statusLine`: runs `~/.claude/statusline.sh` (see [Status Line](#status-line))

Auto-mode settings (`autoMode`) are only read from `~/.claude/settings.json`, never from a project's settings files. Keep them general there, and put project-specific security facts (trusted domains, where secrets and personal data live) in the project's `CLAUDE.md`, which auto mode's safety check also reads.

---

## File Structure

### User-Global (`~/.claude/`)

```
~/.claude/
├── CLAUDE.md              # Global instructions
├── RULES.md               # Operational rules
├── settings.json          # Hooks, permission rules, settings
├── skills/                # 17 skill directories (SKILL.md + references/)
├── agents/                # 10 agent definitions
├── hooks/                 # 3 hook scripts + lib/plan.sh
├── templates/             # Config templates
├── statusline.sh          # Status line script
└── .statusline-weekly-cost.json   # ccusage result cache (only if ccusage is installed)
```

### Per-Project (`{project}/.claude/`)

```
{project}/.claude/
├── z-project-config.yml   # Stack + tool config (committed)
├── settings.json          # Permission rules: protected files, dangerous commands (committed)
├── project-patterns.md    # Accumulated patterns (committed)
├── plans/                 # Plan files — like ADRs (committed)
├── .gitignore             # Contains: .local/
└── .local/                # Ephemeral state (gitignored)
    ├── {branch}-debug.md
    └── mockups/{issue}/   # /z-design mockup files
```

---

## Troubleshooting

### Skills not appearing

- Verify skill files exist: `ls ~/.claude/skills/*/SKILL.md`
- Each skill must be in its own directory: `skills/{name}/SKILL.md`
- Front-matter must be valid YAML between `---` delimiters

### Hooks not firing

- Check `~/.claude/settings.json` has the hooks section (compare with `settings.json.example`)
- Verify scripts are executable: `chmod +x ~/.claude/hooks/*.sh`
- Test hooks manually: `echo "{\"cwd\":\"$PWD\"}" | ~/.claude/hooks/workflow-state.sh`
- Check `jq` is installed: `which jq`

### Formatter not running

- `/z-work` runs the formatter once per phase (Step 5, Quality Checks), and `/commit` runs it before committing
- Ensure `stack.formatter` or `commands.format` is set in `z-project-config.yml` (e.g., `npx prettier --write`)
- The formatter must be installed in the project (`npm install`)

### "Not on target branch" errors

- Skills like `/z-plan` require you to be on a feature branch, not `main`/`master`
- Run `/z-start` first to create/checkout the feature branch

### Protected file blocked unexpectedly

- Run `/permissions` to see which `deny` rule matched and which settings file it comes from
- Global rules are in `~/.claude/settings.json`, project rules in `.claude/settings.json`
- A deny rule can't be overridden by an allow rule — to edit a protected file intentionally, remove its rule temporarily, or edit the file yourself

### Status line shows old or missing values

- Time one run: `echo '{}' | ~/.claude/statusline.sh` should finish in well under a second. Claude Code cancels slow runs, which leaves old values on screen
- `Context left: —` early in a session is expected — Claude Code sends no percentage until the first response
- No weekly cost: install `ccusage`; the first value appears about 20 seconds after the first refresh
- No phase: the plan must be `.claude/plans/{issue}.md` or `.claude/plans/{issue}-*.md`, where `{issue}` is the branch name after its last `/`, and it must use `## Phase <number>` headings

### Context lost after `/clear`

- This is expected — context is preserved via files, not conversation history
- Plan files in `.claude/plans/` track all progress
- Use `/resume` to continue an earlier conversation
- The SessionStart hook shows current workflow state automatically

### Multi-agent review timeout

- `/z-review` runs its 3 review agents for 2 passes (a third only when pass 2 still finds more than 5 new issues), each reviewer seeing the whole diff, then a verification round for findings below 70% confidence, plus 3 optional debate agents — this takes time
- All agents use the `opus` model alias, which resolves to the current Opus model. To use a different model, change `model:` in `~/.claude/agents/z-*.md`
- If `/z-review` or `/z-debug` reports that its agent types are not available, run `claude --debug` and look for skipped files in `~/.claude/agents/` — every agent file needs both `name` and `description` in its frontmatter
- The agents are ordinary subagents; they don't need the experimental agent-teams setting

---

## License

Apache 2.0
