#!/bin/bash
THEME="catppuccin"
case "$THEME" in

  catppuccin)
    # Catppuccin Mocha — pastel ấm, dễ nhìn
    C_MODEL='\033[38;2;203;166;247m'   # mauve
    C_OK='\033[38;2;166;227;161m'      # green
    C_WARN='\033[38;2;249;226;175m'    # yellow
    C_DANGER='\033[38;2;243;139;168m'  # red/pink
    C_LABEL='\033[38;2;148;226;213m'   # teal
    C_DIM='\033[38;2;88;91;112m'       # muted
    C_SLASH='\033[38;2;69;71;90m'      # faint separator
    C_IN='\033[38;2;137;180;250m'      # blue
    C_OUT='\033[38;2;245;194;231m'     # pink
    C_CACHE='\033[38;2;250;179;135m'   # peach
    C_CTX='\033[38;2;148;226;213m'     # teal
    SEP='  '
    ;;

  tokyo)
    # Tokyo Night — xanh navy lạnh + accent tím/cyan
    C_MODEL='\033[38;2;187;154;247m'   # purple
    C_OK='\033[38;2;158;206;106m'      # green
    C_WARN='\033[38;2;224;175;104m'    # orange
    C_DANGER='\033[38;2;247;118;142m'  # red
    C_LABEL='\033[38;2;122;162;247m'   # blue
    C_DIM='\033[38;2;86;95;137m'       # muted
    C_SLASH='\033[38;2;65;72;104m'     # faint
    C_IN='\033[38;2;122;162;247m'      # blue
    C_OUT='\033[38;2;255;158;175m'     # pink
    C_CACHE='\033[38;2;224;175;104m'   # orange
    C_CTX='\033[38;2;125;207;255m'     # cyan
    SEP='  '
    ;;

  dracula)
    # Dracula — tím đậm + neon contrast
    C_MODEL='\033[38;2;189;147;249m'   # purple
    C_OK='\033[38;2;80;250;123m'       # green neon
    C_WARN='\033[38;2;241;250;140m'    # yellow
    C_DANGER='\033[38;2;255;85;85m'    # red
    C_LABEL='\033[38;2;139;233;253m'   # cyan
    C_DIM='\033[38;2;98;114;164m'      # muted
    C_SLASH='\033[38;2;68;71;90m'      # faint
    C_IN='\033[38;2;139;233;253m'      # cyan
    C_OUT='\033[38;2;255;121;198m'     # pink
    C_CACHE='\033[38;2;255;184;108m'   # orange
    C_CTX='\033[38;2;80;250;123m'      # green
    SEP='  '
    ;;

  nord)
    # Nord — xanh băng lạnh, tối giản
    C_MODEL='\033[38;2;180;142;173m'   # aurora purple
    C_OK='\033[38;2;163;190;140m'      # aurora green
    C_WARN='\033[38;2;235;203;139m'    # aurora yellow
    C_DANGER='\033[38;2;191;97;106m'   # aurora red
    C_LABEL='\033[38;2;136;192;208m'   # frost
    C_DIM='\033[38;2;76;86;106m'       # muted
    C_SLASH='\033[38;2;59;66;82m'      # faint
    C_IN='\033[38;2;129;161;193m'      # frost blue
    C_OUT='\033[38;2;191;97;106m'      # aurora red
    C_CACHE='\033[38;2;208;135;112m'   # aurora orange
    C_CTX='\033[38;2;136;192;208m'     # frost teal
    SEP='  '
    ;;
esac

RESET='\033[0m'

# ── READ INPUT ────────────────────────────────────────
input=$(cat)

# ── EXTRACT DATA ──────────────────────────────────────
MODEL=$(echo "$input" | jq -r '.model.display_name')
CTX_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 0')

IN_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
OUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
CACHE_TOKENS=$(echo "$input" | jq -r '
  (.context_window.current_usage.cache_creation_input_tokens // 0)
  + (.context_window.current_usage.cache_read_input_tokens // 0)')
TOKENS_USED=$(( IN_TOKENS + OUT_TOKENS + CACHE_TOKENS ))

PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
FIVE_HR_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage  // 0' | cut -d. -f1)
SEVEN_DAY_PCT=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // 0' | cut -d. -f1)


# Reset countdowns
NOW=$(date +%s)
FH_RESET_AT=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // 0')
SD_RESET_AT=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // 0')

fmt_reset() {
  local reset_at=$1 now=$2
  if [ "$reset_at" -eq 0 ] || [ "$reset_at" -le "$now" ]; then
    echo "--"
  else
    local secs=$(( reset_at - now ))
    local h=$(( secs / 3600 ))
    local m=$(( (secs % 3600) / 60 ))
    if   [ "$h" -ge 24 ]; then
      local d=$(( h / 24 )); local rh=$(( h % 24 ))
      printf "(%dd%02dh)" "$d" "$rh"
    elif [ "$h" -gt 0 ]; then printf "(%dh%02dm)" "$h" "$m"
    else printf "(%dm)" "$m"; fi
  fi
}

FH_RESET=$(fmt_reset "$FH_RESET_AT" "$NOW")
SD_RESET=$(fmt_reset "$SD_RESET_AT" "$NOW")

# ── COLOR PICKER BY PERCENTAGE ────────────────────────
pct_color() {
  local p=$1
  if   [ "$p" -ge 80 ]; then echo "$C_DANGER"
  elif [ "$p" -ge 60 ]; then echo "$C_WARN"
  else echo "$C_OK"; fi
}

# ── PROGRESS BAR (12 chars) ───────────────────────────
make_bar() {
  local pct=$1 color=$2
  local filled=$(( pct * 12 / 100 ))
  local empty=$(( 12 - filled ))
  printf -v F "%${filled}s"; printf -v E "%${empty}s"
  echo "${color}${F// /█}${C_DIM}${E// /░}${RESET}"
}

# ── FORMAT HELPERS ────────────────────────────────────
fmt_tokens() {
  echo "$1" | awk '{
    if      ($1>=1000000) printf "%.1fM", $1/1000000
    else if ($1>=1000)    printf "%dk",   int($1/1000)
    else                  printf "%d",    $1
  }'
}

USED_FMT=$(fmt_tokens "$TOKENS_USED")
MAX_FMT=$(fmt_tokens "$CTX_SIZE")
IN_FMT=$(fmt_tokens "$IN_TOKENS")
OUT_FMT=$(fmt_tokens "$OUT_TOKENS")
CACHE_FMT=$(fmt_tokens "$CACHE_TOKENS")

CTX_C=$(pct_color "$PCT")
FH_C=$(pct_color  "$FIVE_HR_PCT")
SD_C=$(pct_color  "$SEVEN_DAY_PCT")

CTX_BAR=$(make_bar "$PCT"          "$CTX_C")
FH_BAR=$(make_bar  "$FIVE_HR_PCT"  "$FH_C")
SD_BAR=$(make_bar  "$SEVEN_DAY_PCT" "$SD_C")

# ── LINE 1: Model | In/Out/Cache | Context ───────
echo -e \
  "${C_MODEL}${MODEL}${RESET}" \
  "${C_SLASH}│${RESET}" \
  "${C_IN}In:${RESET} ${C_IN}${IN_FMT}${RESET}" \
  "${C_SLASH}│${RESET}" \
  "${C_OUT}Out:${RESET} ${C_OUT}${OUT_FMT}${RESET}" \
  "${C_SLASH}│${RESET}" \
  "${C_CACHE}Cache:${RESET} ${C_CACHE}${CACHE_FMT}${RESET}" \
  "${C_SLASH}│${RESET}" \
  "${C_CTX}Ctx:${RESET} ${CTX_BAR}" \
  "${CTX_C}${PCT}%${RESET}" \
  "${C_DIM}${USED_FMT}${C_SLASH}/${C_DIM}${MAX_FMT}${RESET}"

# ── LINE 2: Rate limits ────────────────────────────────
echo -e \
  "${C_LABEL}5h${RESET} ${FH_BAR} ${FH_C}${FIVE_HR_PCT}%${RESET} ${C_DIM}${FH_RESET}${RESET}" \
  "${SEP}" \
  "${C_LABEL}7d${RESET} ${SD_BAR} ${SD_C}${SEVEN_DAY_PCT}%${RESET} ${C_DIM}${SD_RESET}${RESET}"