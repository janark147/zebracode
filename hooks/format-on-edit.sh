#!/usr/bin/env bash
# ZebraCode Hook: Auto-format on edit
# Trigger: PostToolUse (Edit|Write|NotebookEdit)
# Purpose: Run project formatter on edited files
# Note: PostToolUse cannot block — silent on success, stderr on failure

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# No file path = skip
[[ -z "$FILE_PATH" ]] && exit 0

# Skip if file doesn't exist (may have been deleted)
[[ ! -f "$FILE_PATH" ]] && exit 0

# Read formatter config from z-project-config.yml
FORMATTER=""
FORMAT_CMD=""
if [[ -n "$CWD" && -f "$CWD/.claude/z-project-config.yml" ]]; then
  FORMATTER=$(grep '^\s*formatter:' "$CWD/.claude/z-project-config.yml" | head -1 | sed 's/.*:\s*//; s/"//g; s/'"'"'//g; s/\s*#.*//' | tr -d '[:space:]')
  FORMAT_CMD=$(grep '^\s*format:' "$CWD/.claude/z-project-config.yml" | head -1 | sed 's/.*:\s*//; s/"//g; s/'"'"'//g; s/\s*#.*//')
fi

# If formatter is null, empty, or "null" — formatting disabled, exit silently
[[ -z "$FORMATTER" || "$FORMATTER" == "null" ]] && exit 0

# If a custom format command is configured, use it
if [[ -n "$FORMAT_CMD" && "$FORMAT_CMD" != "null" ]]; then
  # Run in project directory
  cd "$CWD" 2>/dev/null || exit 0
  eval "$FORMAT_CMD \"$FILE_PATH\"" 2>/dev/null
  exit 0
fi

# Otherwise, determine formatter from file extension and configured formatter
EXT="${FILE_PATH##*.}"

case "$FORMATTER" in
  prettier)
    case "$EXT" in
      ts|tsx|js|jsx|css|scss|json|md|html|yaml|yml|vue|svelte)
        if command -v npx &>/dev/null; then
          cd "$CWD" 2>/dev/null || exit 0
          npx prettier --write "$FILE_PATH" 2>/dev/null
        fi
        ;;
    esac
    ;;
  eslint)
    case "$EXT" in
      ts|tsx|js|jsx)
        if command -v npx &>/dev/null; then
          cd "$CWD" 2>/dev/null || exit 0
          npx eslint --fix "$FILE_PATH" 2>/dev/null
        fi
        ;;
    esac
    ;;
  pint)
    case "$EXT" in
      php)
        if [[ -f "$CWD/vendor/bin/pint" ]]; then
          cd "$CWD" 2>/dev/null || exit 0
          ./vendor/bin/pint "$FILE_PATH" 2>/dev/null
        fi
        ;;
    esac
    ;;
  black)
    case "$EXT" in
      py)
        if command -v black &>/dev/null; then
          cd "$CWD" 2>/dev/null || exit 0
          black "$FILE_PATH" 2>/dev/null
        fi
        ;;
    esac
    ;;
esac

exit 0
