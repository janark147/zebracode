# Design Phase Handler

Loaded when the current phase has `**Type**: design`. This phase delegates to `/z-design` logic.

**Skill requirement**: This phase uses the `frontend-design:frontend-design` skill (plugin `frontend-design@claude-plugins-official`). If it is not in your list of available skills, tell the user to install it with `claude plugin install frontend-design@claude-plugins-official` and stop.

## Execution Flow

1. **Read** `~/.claude/skills/z-design/SKILL.md` and follow its **Execution** Steps 1–7 (codebase scan → design skill → mockups → generic-design check → user selection → Design Decisions → clean up). Skip its pre-flight and its completion screen; `/z-work`'s own phase steps and completion screen apply instead.
   - Use the CSS framework from `z-project-config.yml` → `stack.css` and the component library from `stack.frontend` in the codebase scan.

2. **Complete the phase**: Standard must-haves verification, work log, completion screen apply. The key must-haves for a design phase are:
   - **Truth**: User has reviewed and selected a design direction
   - **Artifact**: Design Decisions section populated in the plan file
   - **Link**: Existing components identified for reuse are verified to exist
