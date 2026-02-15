#!/usr/bin/env bash
# ZebraCode Hook: Stop verification
# Trigger: Stop
# Purpose: Warn if there are unchecked items in the active plan phase
# Exit 2 = block stop, Exit 0 = allow stop

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

# Validate SESSION_ID format (alphanumeric, hyphens, underscores only)
if [[ -n "$SESSION_ID" && ! "$SESSION_ID" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  exit 0
fi

# Guard against infinite loops — if guard file exists, allow stop immediately
# Use user-specific directory with restrictive permissions to prevent symlink attacks
GUARD_DIR="${TMPDIR:-/tmp}/zebracode-$(id -u)"
mkdir -p "$GUARD_DIR" 2>/dev/null
chmod 700 "$GUARD_DIR" 2>/dev/null
GUARD_FILE="$GUARD_DIR/stop-guard-${SESSION_ID}"
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

# Count unchecked items only in phases that have been started (have at least one [x])
# Phases are delimited by "## Phase" headings
TOTAL_CHECKED=0
TOTAL_UNCHECKED=0
IN_PHASE=false
PHASE_CHECKED=0
PHASE_UNCHECKED=0

while IFS= read -r line; do
  # Detect phase boundary
  if [[ "$line" =~ ^##\ Phase ]]; then
    # Tally previous phase if it was started (has checked items) but incomplete
    if [[ "$PHASE_CHECKED" -gt 0 && "$PHASE_UNCHECKED" -gt 0 ]]; then
      TOTAL_CHECKED=$((TOTAL_CHECKED + PHASE_CHECKED))
      TOTAL_UNCHECKED=$((TOTAL_UNCHECKED + PHASE_UNCHECKED))
    fi
    PHASE_CHECKED=0
    PHASE_UNCHECKED=0
    IN_PHASE=true
    continue
  fi
  # Count checkboxes within a phase
  if [[ "$IN_PHASE" == true ]]; then
    if [[ "$line" =~ ^[[:space:]]*-\ \[x\] ]]; then
      PHASE_CHECKED=$((PHASE_CHECKED + 1))
    elif [[ "$line" =~ ^[[:space:]]*-\ \[\ \] ]]; then
      PHASE_UNCHECKED=$((PHASE_UNCHECKED + 1))
    fi
  fi
done < "$PLAN_FILE"

# Tally the last phase
if [[ "$PHASE_CHECKED" -gt 0 && "$PHASE_UNCHECKED" -gt 0 ]]; then
  TOTAL_CHECKED=$((TOTAL_CHECKED + PHASE_CHECKED))
  TOTAL_UNCHECKED=$((TOTAL_UNCHECKED + PHASE_UNCHECKED))
fi

# If no started phase has unchecked items, allow stop
[[ "$TOTAL_UNCHECKED" -eq 0 ]] && exit 0

# There are unchecked items in started phases — set the guard file and block
touch "$GUARD_FILE"

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "decision": "block",
    "reason": "Incomplete items found: ${TOTAL_UNCHECKED} unchecked task(s) in started phases (${TOTAL_CHECKED} completed). Are you sure you want to stop? If yes, stop again to confirm."
  }
}
EOF
exit 2
