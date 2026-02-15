#!/usr/bin/env bash
# ZebraCode Hook: SessionStart workflow state injection
# Trigger: SessionStart
# Purpose: Show active workflow state on session start
# Must be fast — runs every session

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

[[ -z "$CWD" ]] && exit 0

# Check if z-project-config.yml exists
if [[ ! -f "$CWD/.claude/z-project-config.yml" ]]; then
  # Not a ZebraCode project — check if .claude/ dir exists at all
  if [[ -d "$CWD/.claude" ]]; then
    cat <<OUTPUT
  ZebraCode  not configured for this project
  ▶ Setup      /z-project-init
OUTPUT
  fi
  exit 0
fi

# Get current branch
BRANCH=$(cd "$CWD" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)
[[ -z "$BRANCH" ]] && exit 0

# Read target branch from config
TARGET_BRANCH=$(grep '^\s*target_branch:' "$CWD/.claude/z-project-config.yml" 2>/dev/null | head -1 | sed 's/.*:\s*//; s/"//g; s/'"'"'//g; s/\s*#.*//' | tr -d '[:space:]')
TARGET_BRANCH="${TARGET_BRANCH:-main}"

# If on target branch with no active session — stay silent
[[ "$BRANCH" == "$TARGET_BRANCH" ]] && exit 0

# Check for session file (paused state)
LOCAL_DIR="$CWD/.claude/.local"
SESSION_FILE="$LOCAL_DIR/${BRANCH}-session.md"
DEBUG_FILE="$LOCAL_DIR/${BRANCH}-debug.md"

# Find plan file matching the branch
PLAN_FILE=""
PLAN_DIR="$CWD/.claude/plans"
if [[ -d "$PLAN_DIR" ]]; then
  for f in "$PLAN_DIR"/*.md; do
    [[ ! -f "$f" ]] && continue
    PLAN_BASENAME=$(basename "$f" .md)
    if [[ "$BRANCH" == *"$PLAN_BASENAME"* || "$PLAN_BASENAME" == *"$BRANCH"* ]]; then
      PLAN_FILE="$f"
      break
    fi
  done
fi

# No plan and no session/debug files — nothing to show
[[ -z "$PLAN_FILE" && ! -f "$SESSION_FILE" && ! -f "$DEBUG_FILE" ]] && exit 0

# --- Build output ---

echo "─────────────────────────────────────────────────────────────────"
echo "  ZebraCode ◆ Active Session"
echo "─────────────────────────────────────────────────────────────────"
echo "  Branch       ${BRANCH}"

# Parse plan file if it exists
if [[ -n "$PLAN_FILE" ]]; then
  PLAN_REL="${PLAN_FILE#$CWD/}"

  # Extract issue from plan file name or first heading
  ISSUE=$(head -5 "$PLAN_FILE" | grep -oE '[A-Z]+-[0-9]+' | head -1)
  [[ -n "$ISSUE" ]] && echo "  Issue        ${ISSUE}"

  echo "  Plan         ${PLAN_REL}"

  # Count progress
  CHECKED=$(grep -c '\- \[x\]' "$PLAN_FILE" 2>/dev/null || echo 0)
  UNCHECKED=$(grep -c '\- \[ \]' "$PLAN_FILE" 2>/dev/null || echo 0)
  TOTAL=$((CHECKED + UNCHECKED))

  if [[ "$TOTAL" -gt 0 ]]; then
    # Count phases
    TOTAL_PHASES=$(grep -cE '^###.*[Pp]hase' "$PLAN_FILE" 2>/dev/null || echo 0)

    # Find last completed phase and next phase
    LAST_COMPLETE=""
    NEXT_PHASE=""
    COMPLETED_PHASES=0
    IN_PHASE=""
    PHASE_HAS_UNCHECKED=false

    while IFS= read -r line; do
      if [[ "$line" =~ ^###.*[Pp]hase ]]; then
        if [[ -n "$IN_PHASE" && "$PHASE_HAS_UNCHECKED" == false ]]; then
          LAST_COMPLETE="$IN_PHASE"
          ((COMPLETED_PHASES++))
        fi
        IN_PHASE=$(echo "$line" | sed 's/^### //')
        PHASE_HAS_UNCHECKED=false
      elif [[ "$line" =~ "- [ ]" ]]; then
        PHASE_HAS_UNCHECKED=true
        [[ -z "$NEXT_PHASE" ]] && NEXT_PHASE="$IN_PHASE"
      fi
    done < "$PLAN_FILE"

    # Handle last phase
    if [[ -n "$IN_PHASE" && "$PHASE_HAS_UNCHECKED" == false ]]; then
      LAST_COMPLETE="$IN_PHASE"
      ((COMPLETED_PHASES++))
    fi

    # Build progress bar
    if [[ "$TOTAL_PHASES" -gt 0 ]]; then
      FILLED=$(( COMPLETED_PHASES * 10 / TOTAL_PHASES ))
    else
      FILLED=$(( CHECKED * 10 / TOTAL ))
    fi
    EMPTY=$(( 10 - FILLED ))
    BAR=""
    for ((i=0; i<FILLED; i++)); do BAR="${BAR}█"; done
    for ((i=0; i<EMPTY; i++)); do BAR="${BAR}░"; done

    if [[ "$TOTAL_PHASES" -gt 0 ]]; then
      echo "  Progress     ${BAR}  ${COMPLETED_PHASES}/${TOTAL_PHASES} phases complete"
    else
      echo "  Progress     ${BAR}  ${CHECKED}/${TOTAL} steps"
    fi

    [[ -n "$LAST_COMPLETE" ]] && echo "" && echo "  Last phase   ${LAST_COMPLETE} ✓"
    [[ -n "$NEXT_PHASE" ]] && echo "  Next phase   ${NEXT_PHASE}"
  fi
fi

# Check for paused state
if [[ -f "$SESSION_FILE" ]]; then
  PAUSE_DATE=$(grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' "$SESSION_FILE" | head -1)
  echo ""
  echo "  Status       ◆ Paused${PAUSE_DATE:+ ($PAUSE_DATE)}"
  echo "  ▶ Resume     /z-resume"
elif [[ -f "$DEBUG_FILE" ]]; then
  HYPO_COUNT=$(grep -c '\- \[' "$DEBUG_FILE" 2>/dev/null || echo 0)
  echo ""
  echo "  Status       ◆ Debugging — ${HYPO_COUNT} hypotheses"
  echo "  ▶ Resume     /z-debug resume"
elif [[ -n "$NEXT_PHASE" ]]; then
  ISSUE="${ISSUE:-$(echo "$BRANCH" | grep -oE '[A-Z]+-[0-9]+')}"
  # Extract phase number from next phase name
  PHASE_NUM=$(echo "$NEXT_PHASE" | grep -oE '[0-9]+' | head -1)
  echo ""
  echo "  ▶ Resume     /z-work${ISSUE:+ $ISSUE}${PHASE_NUM:+ $PHASE_NUM}"
fi

echo "─────────────────────────────────────────────────────────────────"

exit 0
