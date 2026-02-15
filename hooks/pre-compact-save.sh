#!/usr/bin/env bash
# ZebraCode Hook: PreCompact state save + stdout context restoration
# Trigger: PreCompact
# Purpose: Save workflow state to disk AND output context for post-compaction injection
# Note: PostCompact doesn't exist — stdout from PreCompact is the ONLY way to carry context

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

[[ -z "$CWD" ]] && exit 0

# Get current branch
BRANCH=$(cd "$CWD" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)
[[ -z "$BRANCH" ]] && exit 0

# Ensure .local directory exists
LOCAL_DIR="$CWD/.claude/.local"
mkdir -p "$LOCAL_DIR" 2>/dev/null

# Find plan file for current branch
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

# Count progress if plan exists
CHECKED=0
UNCHECKED=0
TOTAL=0
PLAN_REL=""
if [[ -n "$PLAN_FILE" ]]; then
  CHECKED=$(grep -c '\- \[x\]' "$PLAN_FILE" 2>/dev/null || echo 0)
  UNCHECKED=$(grep -c '\- \[ \]' "$PLAN_FILE" 2>/dev/null || echo 0)
  TOTAL=$((CHECKED + UNCHECKED))
  PLAN_REL="${PLAN_FILE#$CWD/}"
fi

# Detect current phase (look for last phase header before first unchecked item)
CURRENT_PHASE=""
if [[ -n "$PLAN_FILE" ]]; then
  CURRENT_PHASE=$(awk '/^###.*[Pp]hase/{phase=$0} /\- \[ \]/{print phase; exit}' "$PLAN_FILE" 2>/dev/null | sed 's/^### //')
fi

# Write state snapshot to disk
STATE_FILE="$LOCAL_DIR/${BRANCH}-compact-state.md"
cat > "$STATE_FILE" <<SNAPSHOT
# Compact State Snapshot
- **Branch**: ${BRANCH}
- **Plan**: ${PLAN_REL:-none}
- **Phase**: ${CURRENT_PHASE:-unknown}
- **Progress**: ${CHECKED}/${TOTAL} steps
- **Saved**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
SNAPSHOT

# Output context block to stdout (injected into post-compaction context)
if [[ -n "$PLAN_FILE" ]]; then
  # Build progress bar (10 chars wide)
  if [[ "$TOTAL" -gt 0 ]]; then
    FILLED=$(( CHECKED * 10 / TOTAL ))
  else
    FILLED=0
  fi
  EMPTY=$(( 10 - FILLED ))
  BAR=$(printf '%0.s█' $(seq 1 $FILLED 2>/dev/null) 2>/dev/null)$(printf '%0.s░' $(seq 1 $EMPTY 2>/dev/null) 2>/dev/null)
  # Handle edge cases where seq fails
  [[ ${#BAR} -eq 0 ]] && BAR="░░░░░░░░░░"

  cat <<OUTPUT
─────────────────────────────────────────────────────────────────
  ZebraCode ◆ Context Preserved (pre-compaction)
─────────────────────────────────────────────────────────────────
  Branch       ${BRANCH}
  Plan         ${PLAN_REL}
  Phase        ${CURRENT_PHASE:-unknown}
  Progress     ${BAR}  ${CHECKED}/${TOTAL} steps

  State saved to .claude/.local/${BRANCH}-compact-state.md
─────────────────────────────────────────────────────────────────
OUTPUT
fi

exit 0
