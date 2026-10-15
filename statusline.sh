#!/bin/bash
# ZebraCode status line
# Line 1: directory · git branch · model + effort · Claude Code version
# Line 2: context left · plan usage limits (5-hour, 7-day) · current plan phase
# Line 3: session cost · weekly cost (ccusage) · prompt cache expiry

input=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Shared plan helpers (zc_find_plan, zc_plan_phases), installed with the ZebraCode hooks
[ -f "$SCRIPT_DIR/hooks/lib/plan.sh" ] && source "$SCRIPT_DIR/hooks/lib/plan.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "ZebraCode status line needs jq (brew install jq)"
  exit 0
fi

# ---- colors ----
use_color=1
[ -n "$NO_COLOR" ] && use_color=0
c() { [ "$use_color" -eq 1 ] && printf '\033[38;5;%sm' "$1"; }   # 256-color foreground
rst() { [ "$use_color" -eq 1 ] && printf '\033[0m'; }
SKY=117; PURPLE=147; GRAY=249; GREEN=150; MINT=158; PEACH=215; CORAL=203; GOLD=222; LILAC=183; YELLOW=180

# Color for a percentage where high is bad (usage) — green, peach from 50, coral from 80
used_color() { if [ "$1" -ge 80 ]; then c $CORAL; elif [ "$1" -ge 50 ]; then c $PEACH; else c $MINT; fi; }

# ---- read every field with one jq call ----
# Fields are joined with the unit separator (\x1f), which never appears in the values and,
# unlike a tab, does not collapse when a field is empty.
IFS=$'\x1f' read -r current_dir project_dir model effort cc_version ctx_left cost \
  five_used five_reset seven_used seven_reset cache_txt < <(echo "$input" | jq -r '
  def pct: if . == null then "" else floor | tostring end;
  def window($w; $fmt):
    if $w == null or $w.used_percentage == null then ["", ""]
    elif ($w.resets_at // 0) > 0 and $w.resets_at <= now then ["0", "reset"]
    else [($w.used_percentage | pct), (if ($w.resets_at // 0) > 0 then ($w.resets_at | strflocaltime($fmt)) else "" end)]
    end;
  [ (.workspace.current_dir // .cwd // ""),
    (.workspace.project_dir // .workspace.current_dir // .cwd // ""),
    (.model.display_name // "Claude"),
    (.effort.level // ""),
    (.version // ""),
    (.context_window.remaining_percentage | pct),
    (.cost.total_cost_usd // "" | tostring) ]
  + window(.rate_limits.five_hour; "%H:%M")
  + window(.rate_limits.seven_day; "%a %d %b")
  + [ (if .prompt_cache == null then ""
       elif .prompt_cache.warm == true and (.prompt_cache.expires_at // 0) > now
         then "until " + (.prompt_cache.expires_at | strflocaltime("%H:%M"))
       else "cold" end) ]
  | join("\u001f")' 2>/dev/null)

display_dir=$(echo "$current_dir" | sed "s|^$HOME|~|")

# ---- git branch (of the directory Claude Code was started in) ----
git_branch=$(git -C "$project_dir" branch --show-current 2>/dev/null)
[ -z "$git_branch" ] && git_branch=$(git -C "$project_dir" rev-parse --short HEAD 2>/dev/null)

# ---- current plan phase ----
phase_txt=""
if [ -d "$project_dir/.claude/plans" ] && [ -n "$git_branch" ] && type zc_find_plan >/dev/null 2>&1; then
  plan_file=$(zc_find_plan "$project_dir" "$git_branch")
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

# ---- weekly cost from ccusage ----
# ccusage takes ~20s, and Claude Code cancels a status line run when the next update arrives,
# so read a cached result and refresh it in the background at most every 10 minutes.
weekly_cost=""
WEEKLY_CACHE="$SCRIPT_DIR/.statusline-weekly-cost.json"
if command -v ccusage >/dev/null 2>&1; then
  # A lock older than 5 minutes belongs to a refresh that was killed
  [ -n "$(find "$WEEKLY_CACHE.lock" -maxdepth 0 -mmin +5 2>/dev/null)" ] && rmdir "$WEEKLY_CACHE.lock" 2>/dev/null
  if [ -z "$(find "$WEEKLY_CACHE" -mmin -10 2>/dev/null)" ] && mkdir "$WEEKLY_CACHE.lock" 2>/dev/null; then
    nohup bash -c 'ccusage weekly --json > "$1.tmp" 2>/dev/null && mv "$1.tmp" "$1"; rmdir "$1.lock"' _ "$WEEKLY_CACHE" \
      >/dev/null 2>&1 </dev/null &
  fi
  [ -f "$WEEKLY_CACHE" ] && weekly_cost=$(jq -r '.weekly[-1].totalCost // empty' "$WEEKLY_CACHE" 2>/dev/null)
fi

# ---- line 1: directory, branch, model + effort, version ----
line1="📁 $(c $SKY)${display_dir}$(rst)"
[ -n "$git_branch" ] && line1="$line1  🌿 $(c $GREEN)${git_branch}$(rst)"
line1="$line1  🤖 $(c $PURPLE)${model}${effort:+ · $effort}$(rst)"
[ -n "$cc_version" ] && line1="$line1  📟 $(c $GRAY)v${cc_version}$(rst)"

# ---- line 2: context left, usage limits, phase ----
# Claude Code computes remaining_percentage for the session's real window size (200k or 1M); null early in a session
if [[ "$ctx_left" =~ ^[0-9]+$ ]]; then
  if [ "$ctx_left" -le 20 ]; then ctx_c=$CORAL; elif [ "$ctx_left" -le 40 ]; then ctx_c=$PEACH; else ctx_c=$MINT; fi
  line2="🧠 $(c $ctx_c)Context left: ${ctx_left}%$(rst)"
else
  line2="🧠 Context left: —"
fi

limit_txt() {   # <label> <used %> <reset time or "reset">
  [ -z "$2" ] && return
  if [ "$3" = "reset" ]; then
    printf '%s%s reset%s' "$(c $MINT)" "$1" "$(rst)"
  else
    printf '%s%s %s%%%s%s' "$(used_color "$2")" "$1" "$2" "${3:+ (resets $3)}" "$(rst)"
  fi
}
limits=$(limit_txt 5h "$five_used" "$five_reset")
seven=$(limit_txt 7d "$seven_used" "$seven_reset")
[ -n "$seven" ] && limits="${limits:+$limits · }$seven"
[ -n "$limits" ] && line2="$line2  ⏳ $limits"
[ -n "$phase_txt" ] && line2="$line2  📋 $(c $YELLOW)${phase_txt}$(rst)"

# ---- line 3: session cost, weekly cost, prompt cache ----
line3=""
[[ "$cost" =~ ^[0-9.]+$ ]] && line3="💰 $(c $GOLD)\$$(printf '%.2f' "$cost")$(rst)"
[[ "$weekly_cost" =~ ^[0-9.]+$ ]] && line3="${line3:+$line3  }📅 $(c $LILAC)\$$(printf '%.2f' "$weekly_cost") this week$(rst)"
[ -n "$cache_txt" ] && line3="${line3:+$line3  }💾 $(c $GRAY)cache ${cache_txt}$(rst)"

printf '%s\n%s\n' "$line1" "$line2"
[ -n "$line3" ] && printf '%s\n' "$line3"
exit 0
