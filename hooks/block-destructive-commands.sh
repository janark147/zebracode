#!/usr/bin/env bash
# ZebraCode Hook: Destructive command protection
# Trigger: PreToolUse (Bash)
# Purpose: Block dangerous commands (seed:fresh, migrate:fresh, etc.)
# Exit 2 = block, Exit 0 = allow

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# No command = allow
[[ -z "$COMMAND" ]] && exit 0

# Built-in dangerous patterns (always blocked)
# Covers: Laravel, Django, Rails, and generic SQL
BUILTIN_PATTERNS=(
  # Laravel
  "seed:fresh"
  "migrate:fresh"
  "db:wipe"
  "migrate:reset"
  # Django
  "manage.py flush"
  "manage.py sqlflush"
  "manage.py reset_db"
  # Rails
  "db:drop"
  "db:reset"
  "db:schema:load"
  "db:purge"
  # Generic SQL
  "DROP TABLE"
  "DROP DATABASE"
  "TRUNCATE "
  "DELETE FROM"
)

# Read additional patterns from config if available
EXTRA_PATTERNS=()
if [[ -n "$CWD" && -f "$CWD/.claude/z-project-config.yml" ]]; then
  while IFS= read -r pattern; do
    [[ -n "$pattern" && "$pattern" != "null" ]] && EXTRA_PATTERNS+=("$pattern")
  done < <(grep -A 50 '^dangerous_commands:' "$CWD/.claude/z-project-config.yml" \
    | tail -n +2 \
    | grep -v '^\s*#' \
    | grep -v '^[a-z]' \
    | sed 's/^\s*//; s/:.*//' \
    | while read -r line; do [[ -n "$line" && "$line" != "null" ]] && echo "$line"; done)
fi

# Combine all patterns
ALL_PATTERNS=("${BUILTIN_PATTERNS[@]}" "${EXTRA_PATTERNS[@]}")

# Check command against patterns (substring match)
for pattern in "${ALL_PATTERNS[@]}"; do
  if [[ "$COMMAND" == *"$pattern"* ]]; then
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Destructive command blocked: \`$pattern\` detected in command. Use AskUserQuestion to get explicit user confirmation before running."
  }
}
EOF
    exit 2
  fi
done

exit 0
