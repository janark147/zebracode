#!/bin/bash
# Custom Claude Code statusline
# Theme: detailed | Colors: true | Features: directory, git, model, context, phase, cost

input=$(cat)

# Get the directory where this statusline script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Shared plan helpers (zc_find_plan, zc_plan_phases), installed with the ZebraCode hooks
[ -f "$SCRIPT_DIR/hooks/lib/plan.sh" ] && source "$SCRIPT_DIR/hooks/lib/plan.sh"

# ---- check jq availability ----
HAS_JQ=0
if command -v jq >/dev/null 2>&1; then
  HAS_JQ=1
fi

# ---- color helpers (force colors for Claude Code) ----
use_color=1
[ -n "$NO_COLOR" ] && use_color=0

C() { if [ "$use_color" -eq 1 ]; then printf '\033[%sm' "$1"; fi; }
RST() { if [ "$use_color" -eq 1 ]; then printf '\033[0m'; fi; }

# ---- modern sleek colors ----
dir_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;117m'; fi; }    # sky blue
model_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;147m'; fi; }  # light purple
cc_version_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;249m'; fi; } # light gray
rst() { if [ "$use_color" -eq 1 ]; then printf '\033[0m'; fi; }

# git utilities
num_or_zero() { v="$1"; [[ "$v" =~ ^[0-9]+$ ]] && echo "$v" || echo 0; }

# ---- JSON extraction utilities ----
# Pure bash JSON value extractor (fallback when jq not available)
extract_json_string() {
  local json="$1"
  local key="$2"
  local default="${3:-}"

  # For nested keys like workspace.current_dir, get the last part
  local field="${key##*.}"
  field="${field%% *}"  # Remove any jq operators

  # Try to extract string value (quoted)
  local value=$(echo "$json" | grep -o "\"\${field}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/')

  # Convert escaped backslashes to forward slashes for Windows paths
  if [ -n "$value" ]; then
    value=$(echo "$value" | sed 's/\\\\/\//g')
  fi

  # If no string value found, try to extract number value (unquoted)
  if [ -z "$value" ] || [ "$value" = "null" ]; then
    value=$(echo "$json" | grep -o "\"\${field}\"[[:space:]]*:[[:space:]]*[0-9.]\+" | head -1 | sed 's/.*:[[:space:]]*\([0-9.]\+\).*/\1/')
  fi

  # Return value or default
  if [ -n "$value" ] && [ "$value" != "null" ]; then
    echo "$value"
  else
    echo "$default"
  fi
}

# ---- basics ----
if [ "$HAS_JQ" -eq 1 ]; then
  current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "unknown"' 2>/dev/null | sed "s|^$HOME|~|g")
  model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"' 2>/dev/null)
  session_id=$(echo "$input" | jq -r '.session_id // ""' 2>/dev/null)
  cc_version=$(echo "$input" | jq -r '.version // ""' 2>/dev/null)
else
  # Bash fallback for JSON extraction
  current_dir=$(echo "$input" | grep -o '"workspace"[[:space:]]*:[[:space:]]*{[^}]*"current_dir"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"current_dir"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | sed 's/\\\\/\//g')

  if [ -z "$current_dir" ] || [ "$current_dir" = "null" ]; then
    current_dir=$(echo "$input" | grep -o '"cwd"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | sed 's/\\\\/\//g')
  fi

  [ -z "$current_dir" ] && current_dir="unknown"
  current_dir=$(echo "$current_dir" | sed "s|^$HOME|~|g")

  model_name=$(echo "$input" | grep -o '"model"[[:space:]]*:[[:space:]]*{[^}]*"display_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"display_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
  [ -z "$model_name" ] && model_name="Claude"
  session_id=$(extract_json_string "$input" "session_id" "")
  cc_version=$(echo "$input" | grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
fi

# ---- git colors ----
git_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;150m'; fi; }  # soft green
rst() { if [ "$use_color" -eq 1 ]; then printf '\033[0m'; fi; }

# ---- git ----
git_branch=""
if git rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git branch --show-current 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
fi

# ---- context window calculation ----
context_pct=""
context_color() { if [ "$use_color" -eq 1 ]; then printf '\033[1;37m'; fi; }  # default white

# Claude Code passes the remaining percentage for the session's real window size (200k or 1M)
if [ "$HAS_JQ" -eq 1 ]; then
  context_remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty' 2>/dev/null)
else
  context_remaining_pct=$(extract_json_string "$input" "remaining_percentage" "")
fi
context_remaining_pct="${context_remaining_pct%%.*}"   # drop decimals if any; null early in a session

if [[ "$context_remaining_pct" =~ ^[0-9]+$ ]]; then
  if [ "$context_remaining_pct" -le 20 ]; then
    context_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;203m'; fi; }  # coral red
  elif [ "$context_remaining_pct" -le 40 ]; then
    context_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;215m'; fi; }  # peach
  else
    context_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;158m'; fi; }  # mint green
  fi

  context_pct="${context_remaining_pct}%"
fi

# ---- cost colors ----
cost_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;222m'; fi; }   # light gold
burn_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;220m'; fi; }   # bright gold
weekly_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;183m'; fi; } # light purple
phase_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;180m'; fi; }  # soft yellow

# ---- cost extraction ----
cost_usd=""; cost_per_hour=""

if [ "$HAS_JQ" -eq 1 ]; then
  cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty' 2>/dev/null)
  total_duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty' 2>/dev/null)

  if [ -n "$cost_usd" ] && [ -n "$total_duration_ms" ] && [ "$total_duration_ms" -gt 0 ]; then
    cost_per_hour=$(echo "$cost_usd $total_duration_ms" | awk '{printf "%.2f", $1 * 3600000 / $2}')
  fi
else
  cost_usd=$(echo "$input" | grep -o '"total_cost_usd"[[:space:]]*:[[:space:]]*[0-9.]*' | sed 's/.*:[[:space:]]*\([0-9.]*\).*/\1/')
  total_duration_ms=$(echo "$input" | grep -o '"total_duration_ms"[[:space:]]*:[[:space:]]*[0-9]*' | sed 's/.*:[[:space:]]*\([0-9]*\).*/\1/')

  if [ -n "$cost_usd" ] && [ -n "$total_duration_ms" ] && [ "$total_duration_ms" -gt 0 ]; then
    cost_per_hour=$(echo "$cost_usd $total_duration_ms" | awk '{printf "%.2f", $1 * 3600000 / $2}')
  fi
fi

# ---- weekly cost from ccusage ----
# ccusage takes ~20s, and Claude Code cancels a status line run when the next update arrives,
# so read a cached result and refresh it in the background at most every 10 minutes.
weekly_cost=""
WEEKLY_CACHE="$SCRIPT_DIR/.statusline-weekly-cost.json"
if command -v ccusage >/dev/null 2>&1 && [ "$HAS_JQ" -eq 1 ]; then
  # A lock older than 5 minutes belongs to a refresh that was killed
  [ -n "$(find "$WEEKLY_CACHE.lock" -maxdepth 0 -mmin +5 2>/dev/null)" ] && rmdir "$WEEKLY_CACHE.lock" 2>/dev/null
  if [ -z "$(find "$WEEKLY_CACHE" -mmin -10 2>/dev/null)" ] && mkdir "$WEEKLY_CACHE.lock" 2>/dev/null; then
    nohup bash -c 'ccusage weekly --json > "$1.tmp" 2>/dev/null && mv "$1.tmp" "$1"; rmdir "$1.lock"' _ "$WEEKLY_CACHE" \
      >/dev/null 2>&1 </dev/null &
  fi
  [ -f "$WEEKLY_CACHE" ] && weekly_cost=$(jq -r '.weekly[-1].totalCost // empty' "$WEEKLY_CACHE" 2>/dev/null)
fi

# ---- phase detection from plan files ----
# Plans live in the directory Claude Code was started in, which can differ from the current one
phase_txt=""
if [ "$HAS_JQ" -eq 1 ]; then
  resolve_dir=$(echo "$input" | jq -r '.workspace.project_dir // .workspace.current_dir // .cwd // empty' 2>/dev/null)
else
  resolve_dir=$(echo "$current_dir" | sed "s|^~|$HOME|")
fi
if [ -d "$resolve_dir/.claude/plans" ]; then
  plan_branch=$(git -C "$resolve_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)

  if [ -n "$plan_branch" ] && type zc_find_plan >/dev/null 2>&1; then
    plan_file=$(zc_find_plan "$resolve_dir" "$plan_branch")

    if [ -n "$plan_file" ]; then
      # One line per phase: number, checked, unchecked, name
      phases=$(zc_plan_phases "$plan_file")
      if [ -n "$phases" ]; then
        last_phase=$(echo "$phases" | tail -1 | cut -f1)
        current=$(echo "$phases" | awk -F'\t' '$3 > 0 { print; exit }')
        if [ -n "$current" ]; then
          phase_txt="Phase $(echo "$current" | cut -f1)/${last_phase}: $(echo "$current" | cut -f4)"
        else
          phase_txt="Phase ${last_phase}/${last_phase}: All complete"
        fi
      fi
    fi
  fi
fi

# ---- render statusline ----
# Line 1: [dir] [git branch] [model] [model version] [cc version]
printf '📁 %s%s%s' "$(dir_color)" "$current_dir" "$(rst)"
if [ -n "$git_branch" ]; then
  printf '  🌿 %s%s%s' "$(git_color)" "$git_branch" "$(rst)"
fi
printf '  🤖 %s%s%s' "$(model_color)" "$model_name" "$(rst)"
if [ -n "$cc_version" ] && [ "$cc_version" != "null" ]; then
  printf '  📟 %sv%s%s' "$(cc_version_color)" "$cc_version" "$(rst)"
fi

# Line 2: [context remaining %] [phase X/Y: phase name]
line2=""
if [ -n "$context_pct" ]; then
  line2="🧠 $(context_color)Context: ${context_pct}$(rst)"
fi
if [ -n "$phase_txt" ]; then
  if [ -n "$line2" ]; then
    line2="$line2  📋 $(phase_color)${phase_txt}$(rst)"
  else
    line2="📋 $(phase_color)${phase_txt}$(rst)"
  fi
fi
if [ -z "$line2" ]; then
  line2="🧠 $(context_color)Context: TBD$(rst)"
fi

# Line 3: [session $X.XX ($Y.YY/h)] [weekly $Z.ZZ]
line3=""
if [ -n "$cost_usd" ] && [[ "$cost_usd" =~ ^[0-9.]+$ ]]; then
  if [ -n "$cost_per_hour" ] && [[ "$cost_per_hour" =~ ^[0-9.]+$ ]]; then
    cost_per_hour_formatted=$(printf '%.2f' "$cost_per_hour")
    line3="💰 $(cost_color)\$$(printf '%.2f' "$cost_usd")$(rst) ($(burn_color)\$${cost_per_hour_formatted}/h$(rst))"
  else
    line3="💰 $(cost_color)\$$(printf '%.2f' "$cost_usd")$(rst)"
  fi
fi
if [ -n "$weekly_cost" ] && [[ "$weekly_cost" =~ ^[0-9.]+$ ]]; then
  weekly_formatted=$(printf '%.2f' "$weekly_cost")
  if [ -n "$line3" ]; then
    line3="$line3  📅 $(weekly_color)\$${weekly_formatted} this week$(rst)"
  else
    line3="📅 $(weekly_color)\$${weekly_formatted} this week$(rst)"
  fi
fi

# Print lines
if [ -n "$line2" ]; then
  printf '\n%s' "$line2"
fi
if [ -n "$line3" ]; then
  printf '\n%s' "$line3"
fi
printf '\n'
