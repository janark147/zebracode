#!/usr/bin/env bash
# ZebraCode Hook: Desktop notification
# Trigger: Notification event
# Purpose: Alert user when Claude needs input or completes a task

# Read stdin JSON (fire and forget — non-blocking)
INPUT=$(cat)

MESSAGE=$(echo "$INPUT" | jq -r '.message // "Claude needs your attention"')
TITLE="ZebraCode"

# Detect OS and notify
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS — use terminal-notifier if available, fall back to osascript
  if command -v terminal-notifier &>/dev/null; then
    terminal-notifier -title "$TITLE" -message "$MESSAGE" -sound default &>/dev/null &
  else
    osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"default\"" &>/dev/null &
  fi
elif [[ "$OSTYPE" == "linux"* ]]; then
  if command -v notify-send &>/dev/null; then
    notify-send "$TITLE" "$MESSAGE" &>/dev/null &
  fi
fi

exit 0
