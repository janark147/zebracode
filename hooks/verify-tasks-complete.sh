#!/usr/bin/env bash
# ZebraCode Hook: Stop verification
# Trigger: Stop
# Purpose: Warn if there are unchecked items in the active plan phase
# Exit 2 = block stop, Exit 0 = allow stop

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

# Guard against infinite loops — if guard file exists, allow stop immediately
GUARD_FILE="/tmp/zebracode-stop-guard-${SESSION_ID}"
if [[ -f "$GUARD_FILE" ]]; then
  rm -f "$GUARD_FILE"
  exit 0
fi

# No CWD = allow
[[ -z "$CWD" ]] && exit 0

# Get current branch
BRANCH=$(cd "$CWD" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)
[[ -z "$BRANCH" ]] && exit 0

# Find plan file matching the branch name
PLAN_DIR="$CWD/.claude/plans"
[[ ! -d "$PLAN_DIR" ]] && exit 0

# Search for plan file containing the branch name or issue ID
PLAN_FILE=""
for f in "$PLAN_DIR"/*.md; do
  [[ ! -f "$f" ]] && continue
  PLAN_BASENAME=$(basename "$f" .md)
  if [[ "$BRANCH" == *"$PLAN_BASENAME"* || "$PLAN_BASENAME" == *"$BRANCH"* ]]; then
    PLAN_FILE="$f"
    break
  fi
done

# No plan file = allow stop
[[ -z "$PLAN_FILE" ]] && exit 0

# Find the currently active phase (last phase with at least one checked item
# but also at least one unchecked item)
CHECKED=$(grep -c '\- \[x\]' "$PLAN_FILE" 2>/dev/null || echo 0)
UNCHECKED=$(grep -c '\- \[ \]' "$PLAN_FILE" 2>/dev/null || echo 0)

# If nothing is checked or nothing is unchecked, allow stop
[[ "$CHECKED" -eq 0 ]] && exit 0
[[ "$UNCHECKED" -eq 0 ]] && exit 0

# There are unchecked items — set the guard file and block
touch "$GUARD_FILE"

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "decision": "block",
    "reason": "Incomplete items found: ${UNCHECKED} unchecked task(s) in the plan (${CHECKED} completed). Are you sure you want to stop? If yes, stop again to confirm."
  }
}
EOF
exit 2
