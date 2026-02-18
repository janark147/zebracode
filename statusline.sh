#!/bin/bash
# Custom Claude Code statusline
# Theme: detailed | Colors: true | Features: directory, git, model, context, phase, cost
STATUSLINE_VERSION="1.4.0"

input=$(cat)

# Get the directory where this statusline script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/statusline.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# ---- check jq availability ----
HAS_JQ=0
if command -v jq >/dev/null 2>&1; then
  HAS_JQ=1
fi

# ---- logging ----
{
  echo "[$TIMESTAMP] Status line triggered (cc-statusline v${STATUSLINE_VERSION})"
  echo "[$TIMESTAMP] Input:"
  if [ "$HAS_JQ" -eq 1 ]; then
    echo "$input" | jq . 2>/dev/null || echo "$input"
    echo "[$TIMESTAMP] Using jq for JSON parsing"
  else
    echo "$input"
    echo "[$TIMESTAMP] WARNING: jq not found, using bash fallback for JSON parsing"
  fi
  echo "---"
} >> "$LOG_FILE" 2>/dev/null

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

get_max_context() {
  local model_name="$1"
  case "$model_name" in
    *"Opus 4"*|*"opus 4"*|*"Opus"*|*"opus"*)
      echo "200000"
      ;;
    *"Sonnet 4"*|*"sonnet 4"*|*"Sonnet 3.5"*|*"sonnet 3.5"*|*"Sonnet"*|*"sonnet"*)
      echo "200000"
      ;;
    *"Haiku 3.5"*|*"haiku 3.5"*|*"Haiku 4"*|*"haiku 4"*|*"Haiku"*|*"haiku"*)
      echo "200000"
      ;;
    *"Claude 3 Haiku"*|*"claude 3 haiku"*)
      echo "100000"
      ;;
    *)
      echo "200000"
      ;;
  esac
}

if [ -n "$session_id" ] && [ "$HAS_JQ" -eq 1 ]; then
  MAX_CONTEXT=$(get_max_context "$model_name")

  project_dir=$(echo "$current_dir" | sed "s|~|$HOME|g" | sed 's|/|-|g' | sed 's|^-||')
  session_file="$HOME/.claude/projects/-${project_dir}/${session_id}.jsonl"

  if [ -f "$session_file" ]; then
    latest_tokens=$(tail -20 "$session_file" | jq -r 'select(.message.usage) | .message.usage | ((.input_tokens // 0) + (.cache_read_input_tokens // 0))' 2>/dev/null | tail -1)

    if [ -n "$latest_tokens" ] && [ "$latest_tokens" -gt 0 ]; then
      context_used_pct=$(( latest_tokens * 100 / MAX_CONTEXT ))
      context_remaining_pct=$(( 100 - context_used_pct ))

      if [ "$context_remaining_pct" -le 20 ]; then
        context_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;203m'; fi; }  # coral red
      elif [ "$context_remaining_pct" -le 40 ]; then
        context_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;215m'; fi; }  # peach
      else
        context_color() { if [ "$use_color" -eq 1 ]; then printf '\033[38;5;158m'; fi; }  # mint green
      fi

      context_pct="${context_remaining_pct}%"
    fi
  fi
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
weekly_cost=""
if command -v ccusage >/dev/null 2>&1 && [ "$HAS_JQ" -eq 1 ]; then
  weekly_output=""
  if command -v timeout >/dev/null 2>&1; then
    weekly_output=$(timeout 5s ccusage weekly --json 2>/dev/null)
  elif command -v gtimeout >/dev/null 2>&1; then
    weekly_output=$(gtimeout 5s ccusage weekly --json 2>/dev/null)
  else
    weekly_output=$(ccusage weekly --json 2>/dev/null)
  fi
  if [ -n "$weekly_output" ]; then
    weekly_cost=$(echo "$weekly_output" | jq -r '.weekly[-1].totalCost // empty' 2>/dev/null)
  fi
fi

# ---- phase detection from plan files ----
phase_txt=""
resolve_dir=$(echo "$current_dir" | sed "s|^~|$HOME|")
if [ -d "$resolve_dir/.claude/plans" ]; then
  plan_branch=""
  if [ -n "$git_branch" ]; then
    plan_branch="$git_branch"
  else
    plan_branch=$(cd "$resolve_dir" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)
  fi

  if [ -n "$plan_branch" ]; then
    plan_file=""
    for f in "$resolve_dir/.claude/plans/"*.md; do
      [ ! -f "$f" ] && continue
      plan_basename=$(basename "$f" .md)
      if [[ "$plan_branch" == *"$plan_basename"* || "$plan_basename" == *"$plan_branch"* ]]; then
        plan_file="$f"
        break
      fi
    done

    if [ -n "$plan_file" ]; then
      total_phases=$(grep -cE '^#{2,3} .*[Pp]hase' "$plan_file" 2>/dev/null || echo 0)
      if [ "$total_phases" -gt 0 ]; then
        completed_phases=0
        in_phase=""
        next_phase=""
        phase_has_unchecked=false

        while IFS= read -r line; do
          if [[ "$line" =~ ^#{2,3}\ .*[Pp]hase ]]; then
            if [ -n "$in_phase" ] && [ "$phase_has_unchecked" = false ]; then
              ((completed_phases++))
            fi
            in_phase=$(echo "$line" | sed 's/^#\{2,3\} //')
            phase_has_unchecked=false
          elif [[ "$line" == *"- [ ]"* ]]; then
            phase_has_unchecked=true
            [ -z "$next_phase" ] && next_phase="$in_phase"
          fi
        done < "$plan_file"

        # Handle last phase
        if [ -n "$in_phase" ] && [ "$phase_has_unchecked" = false ]; then
          ((completed_phases++))
        fi

        if [ -n "$next_phase" ]; then
          phase_txt="Phase ${completed_phases}/${total_phases}: ${next_phase}"
        else
          phase_txt="Phase ${completed_phases}/${total_phases}: All complete"
        fi
      fi
    fi
  fi
fi

# ---- log extracted data ----
{
  echo "[$TIMESTAMP] Extracted: dir=${current_dir:-}, model=${model_name:-}, git=${git_branch:-}, context=${context_pct:-}, cost=${cost_usd:-}, cost_ph=${cost_per_hour:-}, weekly=${weekly_cost:-}, phase=${phase_txt:-}"
  if [ "$HAS_JQ" -eq 0 ]; then
    echo "[$TIMESTAMP] Note: Context and weekly cost require jq for full functionality"
  fi
} >> "$LOG_FILE" 2>/dev/null

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
