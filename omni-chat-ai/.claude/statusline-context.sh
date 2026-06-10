#!/usr/bin/env bash
# Live context-window monitor for Claude Code.
# Reads the statusLine JSON payload on stdin and prints a colored `ctx NN%` bar.
# Source of truth is the harness (context_window.* fields) — the model cannot self-measure.
# Degrades gracefully on older CLIs (<v2.1.132) that don't emit context_window.*.
set -euo pipefail

payload="$(cat)"

# Tiny field extractor (no jq dependency): pull a numeric/string value by key.
jget() { printf '%s' "$payload" | python3 -c "import sys,json;
d=json.load(sys.stdin)
cw=d.get('context_window') or {}
cu=cw.get('current_usage') or {}
ws=d.get('workspace') or {}
keys={
 'pct':cw.get('used_percentage'),
 'size':cw.get('context_window_size'),
 'in':cw.get('total_input_tokens') or cu.get('input_tokens'),
 'out':cw.get('total_output_tokens') or cu.get('output_tokens'),
 'over':cw.get('exceeds_200k_tokens'),
 'dir':ws.get('current_dir') or d.get('cwd') or '',
}
v=keys.get('$1')
print('' if v is None else v)" 2>/dev/null || printf ''; }

GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; DIM=$'\033[2m'; RESET=$'\033[0m'

dir="$(jget dir)"; label="${dir##*/}"; [ -n "$label" ] && label="${DIM}${label}${RESET} "

pct="$(jget pct)"
# Fallback: derive % from token counts if used_percentage absent.
if [ -z "$pct" ]; then
  tin="$(jget in)"; tout="$(jget out)"; size="$(jget size)"
  if [ -n "$size" ] && [ "$size" != "0" ] && { [ -n "$tin" ] || [ -n "$tout" ]; }; then
    pct="$(python3 -c "print(round((${tin:-0}+${tout:-0})/${size}*100))" 2>/dev/null || printf '')"
  fi
fi

# Old CLI: nothing to measure — print a neutral label and exit cleanly.
if [ -z "$pct" ]; then
  printf '%sctx %s—%s\n' "$label" "$DIM" "$RESET"
  exit 0
fi

over="$(jget over)"
if [ "$over" = "True" ] || [ "$pct" -ge 85 ] 2>/dev/null; then
  printf '%s%sctx %s%%  ⚠ hallucination risk%s\n' "$label" "$RED" "$pct" "$RESET"
elif [ "$pct" -ge 70 ] 2>/dev/null; then
  printf '%s%sctx %s%%%s\n' "$label" "$YELLOW" "$pct" "$RESET"
else
  printf '%s%sctx %s%%%s\n' "$label" "$GREEN" "$pct" "$RESET"
fi
