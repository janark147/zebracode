#!/usr/bin/env bash
# ZebraCode Hook: Stop verification
# Trigger: Stop
# Purpose: Ask Claude to confirm before stopping when a started plan phase has unchecked items
# Output: additionalContext continues the turn once; stop_hook_active lets the next stop through

source "$(dirname "${BASH_SOURCE[0]}")/lib/plan.sh"

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# Claude is already continuing because of this hook — allow the stop
[[ "$STOP_HOOK_ACTIVE" == "true" ]] && exit 0

# No CWD = allow
[[ -z "$CWD" ]] && exit 0

BRANCH=$(cd "$CWD" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)
[[ -z "$BRANCH" ]] && exit 0

PLAN_FILE=$(zc_find_plan "$CWD" "$BRANCH")
[[ -z "$PLAN_FILE" ]] && exit 0

# Count unchecked items only in phases that have been started (at least one [x]) but not finished
read -r TOTAL_CHECKED TOTAL_UNCHECKED < <(zc_plan_phases "$PLAN_FILE" \
  | awk -F'\t' '$2 > 0 && $3 > 0 { c += $2; u += $3 } END { print c + 0, u + 0 }')

[[ "$TOTAL_UNCHECKED" -eq 0 ]] && exit 0

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "additionalContext": "Incomplete items found: ${TOTAL_UNCHECKED} unchecked task(s) in started phases (${TOTAL_CHECKED} completed). Are you sure you want to stop? If yes, stop again to confirm."
  }
}
EOF
exit 0
