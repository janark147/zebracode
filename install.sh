#!/usr/bin/env bash
set -euo pipefail

# ZebraCode v2.0 Installer
# Copies skills, agents, hooks, templates to ~/.claude/
# Merges hooks into settings.json (preserves existing settings)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
BACKUP_SUFFIX=".backup-$(date +%Y%m%d%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo ""
echo "  ╔══════════════════════════════════╗"
echo "  ║     ZebraCode v2.0 Installer     ║"
echo "  ╚══════════════════════════════════╝"
echo ""

# ── Prerequisites ─────────────────────────────

if ! command -v jq &>/dev/null; then
    error "'jq' is required but not installed."
    echo "  Install: brew install jq (macOS) or apt install jq (Linux)"
    exit 1
fi

if ! command -v claude &>/dev/null; then
    warn "'claude' CLI not found in PATH. ZebraCode requires Claude Code to function."
    echo "  Install: https://docs.anthropic.com/en/docs/claude-code"
    read -rp "  Continue anyway? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || exit 0
fi

if command -v claude &>/dev/null && ! claude plugin list 2>/dev/null | grep -q 'frontend-design@claude-plugins-official'; then
    warn "'frontend-design' plugin not installed. /z-design needs it."
    read -rp "  Install now? [Y/n] " answer
    if [[ ! "$answer" =~ ^[Nn]$ ]]; then
        claude plugin install frontend-design@claude-plugins-official && ok "frontend-design plugin installed"
    fi
fi

if [[ "$(uname)" == "Darwin" ]] && ! command -v terminal-notifier &>/dev/null; then
    warn "'terminal-notifier' not found. Desktop notifications will not work."
    echo "  Install: brew install terminal-notifier"
    read -rp "  Install now? [Y/n] " answer
    if [[ ! "$answer" =~ ^[Nn]$ ]]; then
        if command -v brew &>/dev/null; then
            brew install terminal-notifier
            ok "terminal-notifier installed"
        else
            error "Homebrew not found. Install manually: brew install terminal-notifier"
        fi
    fi
fi

# ── Create ~/.claude if needed ────────────────

if [ ! -d "$CLAUDE_DIR" ]; then
    info "Creating $CLAUDE_DIR/"
    mkdir -p "$CLAUDE_DIR"
fi

# ── Remove previously installed ZebraCode files ──
# Copying never deletes, so files removed from the repo would stay installed.
# Hooks that earlier versions installed and later removed:
RETIRED_HOOKS=(
    block-protected-files.sh
    block-destructive-commands.sh
    check-typescript-any.sh
    format-on-edit.sh
    pre-compact-save.sh
)

info "Removing previously installed ZebraCode skills, agents and hooks"
rm -rf "$CLAUDE_DIR"/skills/z-* "$CLAUDE_DIR/skills/commit" "$CLAUDE_DIR/hooks/lib"
rm -f "$CLAUDE_DIR"/agents/z-*.md
for hook in "${RETIRED_HOOKS[@]}" $(cd "$SCRIPT_DIR/hooks" && ls *.sh); do
    rm -f "$CLAUDE_DIR/hooks/$hook"
done

# ── Copy directories (skills, agents, hooks, templates) ──

copy_dir() {
    local src="$1"
    local dest="$2"
    local name="$3"

    if [ ! -d "$src" ]; then
        warn "Source directory $src not found, skipping $name"
        return
    fi

    if [ -d "$dest" ]; then
        info "Updating $name (merging into existing $dest/)"
        cp -r "$src"/* "$dest"/ 2>/dev/null || true
    else
        info "Installing $name to $dest/"
        cp -r "$src" "$dest"
    fi
    ok "$name installed ($(ls "$dest" | wc -l | tr -d ' ') items)"
}

copy_dir "$SCRIPT_DIR/skills"    "$CLAUDE_DIR/skills"    "Skills"
copy_dir "$SCRIPT_DIR/agents"    "$CLAUDE_DIR/agents"    "Agents"
copy_dir "$SCRIPT_DIR/hooks"     "$CLAUDE_DIR/hooks"     "Hooks"
copy_dir "$SCRIPT_DIR/templates" "$CLAUDE_DIR/templates" "Templates"

# ── Make hooks executable ─────────────────────

chmod +x "$CLAUDE_DIR/hooks/"*.sh 2>/dev/null || true
ok "Hook scripts made executable"

# ── Copy statusline ──────────────────────────

if [ -f "$SCRIPT_DIR/statusline.sh" ]; then
    cp "$SCRIPT_DIR/statusline.sh" "$CLAUDE_DIR/statusline.sh"
    chmod +x "$CLAUDE_DIR/statusline.sh"
    ok "Status line script installed"
fi

# ── Merge settings.json ──────────────────────

SETTINGS_FILE="$CLAUDE_DIR/settings.json"
EXAMPLE_FILE="$SCRIPT_DIR/settings.json.example"

if [ ! -f "$EXAMPLE_FILE" ]; then
    warn "settings.json.example not found, skipping settings merge"
elif [ ! -f "$SETTINGS_FILE" ]; then
    info "No existing settings.json — copying example as-is"
    cp "$EXAMPLE_FILE" "$SETTINGS_FILE"
    ok "settings.json created"
else
    info "Merging hooks, permissions and attribution into existing settings.json"
    cp "$SETTINGS_FILE" "${SETTINGS_FILE}${BACKUP_SUFFIX}"
    ok "Backup saved to settings.json${BACKUP_SUFFIX}"

    # Extract hooks/env/permission rules from example and merge into existing settings
    # Each example hook entry is added to its event's list unless its command is already there,
    # so the user's own hooks on the same events are kept (jq's * would replace the whole list)
    # Env vars are deep-merged; permission rules are added to the user's lists, never replacing them
    EXAMPLE_HOOKS=$(jq '.hooks // {}' "$EXAMPLE_FILE")
    EXAMPLE_ENV=$(jq '.env // {}' "$EXAMPLE_FILE")
    EXAMPLE_DENY=$(jq '.permissions.deny // []' "$EXAMPLE_FILE")
    EXAMPLE_ASK=$(jq '.permissions.ask // []' "$EXAMPLE_FILE")
    RETIRED=$(printf '%s\n' "${RETIRED_HOOKS[@]}" | jq -R . | jq -s .)

    jq --argjson hooks "$EXAMPLE_HOOKS" \
       --argjson env "$EXAMPLE_ENV" \
       --argjson deny "$EXAMPLE_DENY" \
       --argjson ask "$EXAMPLE_ASK" \
       --argjson retired "$RETIRED" \
       '.hooks = (reduce ($hooks | to_entries[]) as $event (.hooks // {};
            .[$event.key] = ((.[$event.key] // []) as $mine
              | [$mine[].hooks[]?.command] as $have
              | $mine + [$event.value[] | select([.hooks[]?.command] | any(. as $c | $have | index($c)) | not)])))
        | .hooks |= with_entries(.value |= map(select(
            [.hooks[]?.command // "" | split("/") | last] | any(. as $c | $retired | index($c)) | not)))
        | .hooks |= with_entries(select(.value | length > 0))
        | .env = (.env // {} | . * $env)
        | .permissions.deny = ((.permissions.deny // []) + $deny | unique)
        | .permissions.ask = ((.permissions.ask // []) + $ask | unique)
        | .attribution = false
        | del(.includeCoAuthoredBy)' \
       "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" \
       && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"

    ok "Hooks, env, permissions and attribution merged into settings.json"
fi

# ── Handle global instruction files ──────────

handle_instruction_file() {
    local src="$1"
    local dest="$2"
    local name="$3"

    if [ ! -f "$src" ]; then
        return
    fi

    if [ ! -f "$dest" ]; then
        cp "$src" "$dest"
        ok "$name installed"
    else
        # Check if content is materially different
        if diff -q "$src" "$dest" &>/dev/null; then
            ok "$name already up to date"
        else
            warn "$name already exists and differs from ZebraCode version"
            echo "  Your file:      $dest"
            echo "  ZebraCode file: $src"
            echo ""
            read -rp "  Overwrite with ZebraCode version? (backup will be saved) [y/N] " answer
            if [[ "$answer" =~ ^[Yy]$ ]]; then
                cp "$dest" "${dest}${BACKUP_SUFFIX}"
                cp "$src" "$dest"
                ok "$name updated (backup: ${name}${BACKUP_SUFFIX})"
            else
                info "Keeping existing $name"
            fi
        fi
    fi
}

handle_instruction_file "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md" "CLAUDE.md"
handle_instruction_file "$SCRIPT_DIR/RULES.md"  "$CLAUDE_DIR/RULES.md"  "RULES.md"

# ── Verify installation ──────────────────────

echo ""
echo "  ── Verification ──────────────────"

ERRORS=0

check() {
    local path="$1"
    local label="$2"
    if [ -e "$path" ]; then
        ok "$label"
    else
        error "$label — MISSING"
        ERRORS=$((ERRORS + 1))
    fi
}

check "$CLAUDE_DIR/skills"    "skills/ directory"
check "$CLAUDE_DIR/agents"    "agents/ directory"
check "$CLAUDE_DIR/hooks"     "hooks/ directory"
check "$CLAUDE_DIR/templates" "templates/ directory"
check "$CLAUDE_DIR/settings.json" "settings.json"

# Count installed copies of the repo's own skills, agents and hooks
count_installed() {   # <repo glob> <installed dir> <suffix to check>
    local n=0 item
    for item in $1; do
        [ -e "$2/$(basename "$item")$3" ] && n=$((n + 1))
    done
    echo "$n"
}
EXPECTED_SKILLS=$(ls -d "$SCRIPT_DIR"/skills/*/ | wc -l | tr -d ' ')
EXPECTED_AGENTS=$(ls "$SCRIPT_DIR"/agents/*.md | wc -l | tr -d ' ')
EXPECTED_HOOKS=$(ls "$SCRIPT_DIR"/hooks/*.sh | wc -l | tr -d ' ')
SKILL_COUNT=$(count_installed "$SCRIPT_DIR/skills/*" "$CLAUDE_DIR/skills" "/SKILL.md")
AGENT_COUNT=$(count_installed "$SCRIPT_DIR/agents/*.md" "$CLAUDE_DIR/agents" "")
HOOK_COUNT=$(count_installed "$SCRIPT_DIR/hooks/*.sh" "$CLAUDE_DIR/hooks" "")

info "Skills: $SKILL_COUNT | Agents: $AGENT_COUNT | Hooks: $HOOK_COUNT"

if [ "$SKILL_COUNT" -lt "$EXPECTED_SKILLS" ]; then
    warn "Expected $EXPECTED_SKILLS skills, found $SKILL_COUNT"
    ERRORS=$((ERRORS + 1))
fi

if [ "$AGENT_COUNT" -lt "$EXPECTED_AGENTS" ]; then
    warn "Expected $EXPECTED_AGENTS agents, found $AGENT_COUNT"
    ERRORS=$((ERRORS + 1))
fi

if [ "$HOOK_COUNT" -lt "$EXPECTED_HOOKS" ]; then
    warn "Expected $EXPECTED_HOOKS hooks, found $HOOK_COUNT"
    ERRORS=$((ERRORS + 1))
fi

check "$CLAUDE_DIR/hooks/lib/plan.sh" "hooks/lib/plan.sh (shared plan helpers)"

echo ""
if [ "$ERRORS" -eq 0 ]; then
    echo -e "  ${GREEN}Installation complete!${NC}"
    echo ""
    echo "  Next steps:"
    echo "    1. Start Claude Code in your project directory"
    echo "    2. Run /z-project-init to configure ZebraCode for the project"
    echo "    3. Run /z-start [issue] to begin a feature"
    echo ""
else
    echo -e "  ${RED}Installation failed with $ERRORS error(s).${NC}"
    echo "  Review the errors above and re-run the installer."
    echo ""
    exit 1
fi
