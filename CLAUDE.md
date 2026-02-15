@RULES.md

# ZebraCode v1.4
- Stack config lives in `.claude/z-project-config.yml` — always read it for commands, tools, stack info
- Never use native `/plan` — use `/z-plan` for tracked plan files with must-haves and phase structure
- Skills validate prerequisites automatically — if blocked, follow the redirect to the predecessor skill

# Tool policy: Context7
When you see ANY of the following, call Context7 before answering:
- Library/framework names found in package manifests or imports
- Version conflicts, deprecations, or API uncertainty
- Errors mentioning unknown methods/props/hooks
Process:
1) Resolve the library id.
2) Fetch docs for the detected version and the specific topic.
3) Cite what you used and apply the exact API.

# Verification first
- IMPORTANT: Always verify your work — run tests, check output, validate behavior. This is the single highest-leverage practice.
- Show evidence: test counts, linter output, type errors. "It works" is not evidence.
- Run affected tests after changes, not the full suite (unless asked or finishing a phase)
- If you can't verify a change, say so explicitly — don't pretend it works

# Debugging discipline
- Diagnose step-by-step before proposing fixes. Explain possible root causes, then fix the most likely one.
- No silent failures — never swallow exceptions without logging or re-throwing
- Address root causes, not symptoms — don't suppress errors to make them go away
- After 2 failed fix attempts on the same issue, stop and reassess the approach entirely

# Edge cases & security
- For non-trivial logic, always consider: empty/null inputs, boundary values, invalid states, concurrent access
- Prefer failing fast on bad input over proceeding with wrong assumptions
- Validate user input at system boundaries. Parameterized queries only — never concatenate user input into SQL.
- Sanitize HTML content before rendering. Never store secrets in code or log sensitive data.

# Context management
- When compacting, always preserve: modified file list, test commands, current plan/phase context, key decisions made
- Use subagents for deep investigation to keep main context clean
- After 2 failed corrections on the same issue, suggest `/clear` and a fresh approach with a better prompt
- Scope investigations narrowly — "investigate the auth token refresh in src/auth/" not "investigate authentication"

# Communication
- VERY IMPORTANT! Don't blindly agree with me. Before agreeing, verify I'm ACTUALLY right. If not, tell me so. You know more about code than I do.
- NEVER say "You're right!" or "You're absolutely right". It's meaningless praise, which is often actually wrong.
- YOU ARE FORBIDDEN to say "You're absolutely right"
- ALWAYS MAKE COMMIT MESSAGES SHORT AND TO THE POINT. JUST THE MAIN RESULT. **NEVER** CREDIT CLAUDE OR ANTHROPIC!!!
