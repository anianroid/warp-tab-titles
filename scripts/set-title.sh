#!/usr/bin/env bash
# warp-tab-titles: set the terminal tab title from Claude Code hook events.
#
# Title format:  <icon> <project>: <task summary>
#   ✳ planck: fix the calendar sync bug     (Claude is working)
#   ✓ planck: fix the calendar sync bug     (Claude is done, waiting for you)
#
# This script must never fail: a missing title is not worth breaking a session.

INPUT="$(cat 2>/dev/null || true)"

get() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$INPUT" | jq -r --arg k "$1" '.[$k] // empty' 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$INPUT" | python3 -c 'import json,sys
d = json.load(sys.stdin)
v = d.get(sys.argv[1], "")
print(v if isinstance(v, str) else "")' "$1" 2>/dev/null
  fi
}

EVENT="$(get hook_event_name)"
CWD="$(get cwd)"
SESSION="$(get session_id)"
[ -n "$CWD" ] || CWD="$PWD"
[ -n "$SESSION" ] || SESSION="default"

# Project prefix: git repo name if inside one, else the directory name.
ROOT="$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || true)"
PROJECT="$(basename "${ROOT:-$CWD}")"

MAX_LEN="${TAB_TITLE_MAX_LEN:-44}"
BUSY_ICON="${TAB_TITLE_BUSY_ICON:-✳}"
DONE_ICON="${TAB_TITLE_DONE_ICON:-✓}"

STATE_DIR="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/warp-tab-titles}"
mkdir -p "$STATE_DIR" 2>/dev/null || true
STATE_FILE="$STATE_DIR/summary-$SESSION"

# Strip control characters (including escape sequences a prompt could smuggle
# into the title), collapse whitespace, trim.
sanitize() {
  printf '%s' "$1" | LC_ALL=C tr -d '\000-\037\177' | tr -s ' ' | sed 's/^ //; s/ $//'
}

clip() {
  local t="$1"
  if [ "${#t}" -gt "$MAX_LEN" ]; then
    printf '%s…' "${t:0:$MAX_LEN}"
  else
    printf '%s' "$t"
  fi
}

SUMMARY=""
case "$EVENT" in
  SessionStart)
    TITLE="$BUSY_ICON $PROJECT"
    ;;
  UserPromptSubmit)
    PROMPT="$(get user_prompt)"
    [ -n "$PROMPT" ] || PROMPT="$(get prompt)"
    SUMMARY="$(clip "$(sanitize "$PROMPT")")"
    [ -n "$SUMMARY" ] && printf '%s' "$SUMMARY" > "$STATE_FILE" 2>/dev/null
    TITLE="$BUSY_ICON $PROJECT${SUMMARY:+: $SUMMARY}"
    ;;
  Stop)
    [ -f "$STATE_FILE" ] && SUMMARY="$(cat "$STATE_FILE" 2>/dev/null)"
    TITLE="$DONE_ICON $PROJECT${SUMMARY:+: $SUMMARY}"
    ;;
  SessionEnd)
    [ -f "$STATE_FILE" ] && SUMMARY="$(cat "$STATE_FILE" 2>/dev/null)"
    rm -f "$STATE_FILE" 2>/dev/null
    TITLE="$DONE_ICON $PROJECT${SUMMARY:+: $SUMMARY}"
    ;;
  *)
    exit 0
    ;;
esac

if [ -n "${TAB_TITLE_DEBUG:-}" ]; then
  printf 'TITLE: %s\n' "$TITLE"
elif [ -w /dev/tty ]; then
  printf '\033]0;%s\007' "$TITLE" > /dev/tty 2>/dev/null
fi
exit 0
