# ZebraCode shared plan helpers
# Sourced by workflow-state.sh, verify-tasks-complete.sh and statusline.sh so all three
# find the same plan file and count phases the same way.

# zc_issue_key <branch>
# Prints the issue key for a branch: the part after the last "/" (feature/TAL-1 → TAL-1).
zc_issue_key() {
  echo "${1##*/}"
}

# zc_find_plan <project dir> <branch>
# Prints the plan file for the branch, or nothing.
# Tries, in order:
#   1. .claude/plans/{key}.md or .claude/plans/{key}-*.md
#   2. the same with the issue ID at the start of the key (366-fix-login → 366, AC-12-foo → AC-12)
#   3. a plan whose file name is contained in the branch name (longest name wins)
# When several plans match in step 1 or 2, the most recently changed one wins.
zc_find_plan() {
  local dir="$1/.claude/plans" key id f best="" name
  key=$(zc_issue_key "$2")
  [[ -d "$dir" && -n "$key" ]] || return 0

  for id in "$key" "$(echo "$key" | grep -oE '^([A-Za-z]+-)?[0-9]+')"; do
    [[ -n "$id" ]] || continue
    for f in "$dir/$id.md" "$dir/$id"-*.md; do
      [[ -f "$f" ]] || continue
      [[ -z "$best" || "$f" -nt "$best" ]] && best="$f"
    done
    [[ -n "$best" ]] && { echo "$best"; return 0; }
  done

  for f in "$dir"/*.md; do
    [[ -f "$f" ]] || continue
    name=$(basename "$f" .md)
    if [[ "$2" == *"$name"* && ${#name} -gt ${#best} ]]; then
      best="$name"
    fi
  done
  [[ -n "$best" ]] && echo "$dir/$best.md"
  return 0
}

# zc_plan_phases <plan file>
# Prints one tab-separated line per "## Phase <number>" section:
#   <number>  <checked boxes>  <unchecked boxes>  <name>
# A section ends at the next "## " heading. Lines inside ``` code blocks are ignored.
# Other headings that mention "phase" (### Phase 4 Work Log, ## Phases 0–2 ...) are not phases.
zc_plan_phases() {
  awk '
    function flush() { if (num != "") printf "%s\t%d\t%d\t%s\n", num, done, open, name }
    /^```/ { code = !code; next }
    code { next }
    /^## / {
      flush(); num = ""
      if (match($0, /^## Phase [0-9]+/)) {
        num = substr($0, 10, RLENGTH - 9)
        name = substr($0, RLENGTH + 1)
        sub(/^[:.)]/, "", name); sub(/^ +/, "", name)
        sub(/^(—|–|-) */, "", name)
        done = 0; open = 0
      }
      next
    }
    num != "" && /^[[:space:]]*[-*] \[[xX]\]/ { done++ }
    num != "" && /^[[:space:]]*[-*] \[ \]/ { open++ }
    END { flush() }
  ' "$1"
}
