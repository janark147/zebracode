#!/usr/bin/env bash
# ZebraCode Hook: TypeScript `any` check
# Trigger: PostToolUse (Edit|Write)
# Purpose: Warn when `: any` is introduced in TypeScript files
# Note: PostToolUse cannot block — feedback only (stdout message)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path
[[ -z "$FILE_PATH" ]] && exit 0

# Only check .ts and .tsx files
case "$FILE_PATH" in
  *.ts|*.tsx) ;;
  *) exit 0 ;;
esac

# Skip if file doesn't exist
[[ ! -f "$FILE_PATH" ]] && exit 0

# Search for `any` type usage, excluding comments
# Matches: `: any`, `: any[]`, `: any)`, `as any`, `<any>`, `<any,`
# Skips: lines that are pure comments (// or /*)
MATCHES=$(grep -n -E '(:\s*any\b|\bas\s+any\b|<any[>,])' "$FILE_PATH" \
  | grep -v -E '^\s*[0-9]+:\s*//' \
  | grep -v -E '^\s*[0-9]+:\s*\*' \
  | grep -v -E '^\s*[0-9]+:\s*/\*' \
  || true)

if [[ -n "$MATCHES" ]]; then
  echo "⚠ TypeScript \`any\` type detected in ${FILE_PATH}:"
  echo "$MATCHES" | while IFS=: read -r LINE_NUM CONTENT; do
    echo "  Line ${LINE_NUM}: ${CONTENT}"
  done
  echo "Consider using a specific type instead."
fi

exit 0
