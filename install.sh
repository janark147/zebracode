#!/usr/bin/env bash
set -euo pipefail

# ZebraCode v1.4 Installer
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
echo "  ║     ZebraCode v1.4 Installer     ║"
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

# ── Create ~/.claude if needed ────────────────

if [ ! -d "$CLAUDE_DIR" ]; then
    info "Creating $CLAUDE_DIR/"
    mkdir -p "$CLAUDE_DIR"
fi

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
    info "Merging hooks into existing settings.json"
    cp "$SETTINGS_FILE" "${SETTINGS_FILE}${BACKUP_SUFFIX}"
    ok "Backup saved to settings.json${BACKUP_SUFFIX}"

    # Extract hooks from example and merge into existing settings
    # jq's * operator does deep merge — existing non-hook settings are preserved
    EXAMPLE_HOOKS=$(jq '.hooks // {}' "$EXAMPLE_FILE")
    EXAMPLE_ENV=$(jq '.env // {}' "$EXAMPLE_FILE")

    jq --argjson hooks "$EXAMPLE_HOOKS" \
       --argjson env "$EXAMPLE_ENV" \
       '.hooks = $hooks | .env = (.env // {} | . * $env) | .includeCoAuthoredBy = false' \
       "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" \
       && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"

    ok "Hooks and env merged into settings.json"
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

SKILL_COUNT=$(ls -d "$CLAUDE_DIR/skills"/*/SKILL.md 2>/dev/null | wc -l | tr -d ' ')
AGENT_COUNT=$(ls "$CLAUDE_DIR/agents/"*.md 2>/dev/null | wc -l | tr -d ' ')
HOOK_COUNT=$(ls "$CLAUDE_DIR/hooks/"*.sh 2>/dev/null | wc -l | tr -d ' ')

info "Skills: $SKILL_COUNT | Agents: $AGENT_COUNT | Hooks: $HOOK_COUNT"

if [ "$SKILL_COUNT" -lt 19 ]; then
    warn "Expected 19 skills, found $SKILL_COUNT"
    ERRORS=$((ERRORS + 1))
fi

if [ "$AGENT_COUNT" -lt 10 ]; then
    warn "Expected 10 agents, found $AGENT_COUNT"
    ERRORS=$((ERRORS + 1))
fi

if [ "$HOOK_COUNT" -lt 8 ]; then
    warn "Expected 8 hooks, found $HOOK_COUNT"
    ERRORS=$((ERRORS + 1))
fi

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
    echo -e "  ${YELLOW}Installation completed with $ERRORS warning(s).${NC}"
    echo "  Review the warnings above."
    echo ""
fi
