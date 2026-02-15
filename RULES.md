# RULES.md - ZebraCode Framework Actionable Rules

Simple actionable rules for Claude Code ZebraCode framework operation.

## Core Operational Rules

### Task Management Rules
- TodoRead() → TodoWrite(3+ tasks) → Execute → Track progress
- Use batch tool calls when possible, sequential only when dependencies exist
- Always validate before execution, verify after completion
- Run lint/typecheck before marking tasks complete
- Maintain ≥90% context retention across operations

### File Operation Security
- Always use Read tool before Write or Edit operations
- Use absolute paths only, prevent path traversal attacks
- Prefer batch operations and transaction-like behavior
- Never commit automatically unless explicitly requested

### Framework Compliance
- Check package.json/pyproject.toml before using libraries
- Follow existing project patterns and conventions
- Use project's existing import styles and organization
- Respect framework lifecycles and best practices

### Systematic Codebase Changes
- **MANDATORY**: Complete project-wide discovery before any changes
- Search ALL file types for ALL variations of target terms
- Document all references with context and impact assessment
- Plan update sequence based on dependencies and relationships
- Execute changes in coordinated manner following plan
- Verify completion with comprehensive post-change search
- Validate related functionality remains working
- Use Task tool for comprehensive searches when scope uncertain

### Skill Completion & Evidence
- Every skill that completes must display the standardized completion screen
- Atomic commits — one commit per logical unit of work, never bundle cross-phase changes
- When discovering conventions during work, ask user about adding to CLAUDE.md immediately

### User Interaction
- Use AskUserQuestion liberally when uncertain — better to ask than to guess wrong

### Grooming Decisions
- Locked decisions from grooming are non-negotiable — every locked decision must map to at least one action point in the plan
- Deferred decisions must NOT have action points in the plan
- If either check fails, ask the user before proceeding
- Never implement deferred items — if a deferred item becomes necessary, ask the user to re-categorize it as Locked first

### Agent Tool Access
- Custom agents for analysis/review: constrained scope, read-only tools (Read, Grep, Glob, Context7)
- General agent for implementation: full context, full tools
- Never give analysis agents Write/Edit/Bash access
- Never constrain the implementation agent's tool access

## Quick Reference

### Do
✅ Read before Write/Edit/Update
✅ Use absolute paths
✅ Batch tool calls
✅ Validate before execution
✅ Check framework compatibility
✅ Auto-activate personas
✅ Preserve context across operations
✅ Complete discovery before codebase changes
✅ Verify completion with evidence

### Don't
❌ Skip Read operations
❌ Use relative paths
❌ Auto-commit without permission
❌ Ignore framework patterns
❌ Skip validation steps
❌ Mix user-facing content in config
❌ Override safety protocols
❌ Make reactive codebase changes
❌ Mark complete without verification
