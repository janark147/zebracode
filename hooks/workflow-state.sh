#!/usr/bin/env bash
# ZebraCode Hook: SessionStart workflow state injection
# Trigger: SessionStart (startup, resume, clear and compact)
# Purpose: Show active workflow state on session start
# Must be fast — runs every session

source "$(dirname "${BASH_SOURCE[0]}")/lib/plan.sh"

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
TARGET_BRANCH=$(grep -E '^[[:space:]]*target_branch:' "$CWD/.claude/z-project-config.yml" 2>/dev/null | head -1 | sed -E 's/.*:[[:space:]]*//; s/"//g; s/'"'"'//g; s/[[:space:]]*#.*//' | tr -d '[:space:]')
TARGET_BRANCH="${TARGET_BRANCH:-main}"

# If on target branch — stay silent
[[ "$BRANCH" == "$TARGET_BRANCH" ]] && exit 0

DEBUG_FILE="$CWD/.claude/.local/${BRANCH}-debug.md"
PLAN_FILE=$(zc_find_plan "$CWD" "$BRANCH")

# No plan and no debug file — nothing to show
[[ -z "$PLAN_FILE" && ! -f "$DEBUG_FILE" ]] && exit 0

# --- Build output ---

echo "─────────────────────────────────────────────────────────────────"
echo "  ZebraCode ◆ Active Session"
echo "─────────────────────────────────────────────────────────────────"
echo "  Branch       ${BRANCH}"

NEXT_NUM=""
if [[ -n "$PLAN_FILE" ]]; then
  ISSUE=$(zc_issue_key "$BRANCH")
  echo "  Issue        ${ISSUE}"
  echo "  Plan         ${PLAN_FILE#$CWD/}"

  # One line per phase: number, checked, unchecked, name
  PHASES=$(zc_plan_phases "$PLAN_FILE")
  if [[ -n "$PHASES" ]]; then
    TOTAL_PHASES=$(echo "$PHASES" | wc -l | tr -d ' ')
    COMPLETED_PHASES=$(echo "$PHASES" | awk -F'\t' '$3 == 0' | wc -l | tr -d ' ')
    # Next phase = first phase with unchecked items; last phase = the phase before it
    NEXT=$(echo "$PHASES" | awk -F'\t' '$3 > 0 { print; exit }')
    if [[ -n "$NEXT" ]]; then
      LAST=$(echo "$PHASES" | awk -F'\t' -v n="$(echo "$NEXT" | cut -f1)" '$1 == n { exit } $3 == 0 { last = $0 } END { print last }')
    else
      LAST=$(echo "$PHASES" | tail -1)
    fi

    FILLED=$(( COMPLETED_PHASES * 10 / TOTAL_PHASES ))
    BAR=""
    for ((i=0; i<FILLED; i++)); do BAR="${BAR}█"; done
    for ((i=FILLED; i<10; i++)); do BAR="${BAR}░"; done
    echo "  Progress     ${BAR}  ${COMPLETED_PHASES}/${TOTAL_PHASES} phases complete"

    if [[ -n "$LAST" ]]; then
      echo ""
      echo "  Last phase   Phase $(echo "$LAST" | cut -f1): $(echo "$LAST" | cut -f4) ✓"
    fi
    if [[ -n "$NEXT" ]]; then
      NEXT_NUM=$(echo "$NEXT" | cut -f1)
      echo "  Next phase   Phase ${NEXT_NUM}: $(echo "$NEXT" | cut -f4)"
    fi
  fi
fi

if [[ -f "$DEBUG_FILE" ]]; then
  HYPO_COUNT=$(grep -c '\- \[' "$DEBUG_FILE" 2>/dev/null)
  echo ""
  echo "  Status       ◆ Debugging — ${HYPO_COUNT:-0} hypotheses"
  echo "  ▶ Resume     /z-debug resume"
elif [[ -n "$NEXT_NUM" ]]; then
  echo ""
  echo "  ▶ Resume     /z-work ${ISSUE} ${NEXT_NUM}"
fi

echo "─────────────────────────────────────────────────────────────────"

exit 0
