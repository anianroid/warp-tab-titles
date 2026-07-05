#!/usr/bin/env bash
# Smoke test for set-title.sh: exercises every hook event and asserts the
# exact title output. Run from anywhere; exits non-zero on any failure.
set -u
cd "$(dirname "$0")/.." || exit 1
export TAB_TITLE_DEBUG=1
FAIL=0

check() { # desc expected actual
  if [ "$2" = "$3" ]; then
    echo "ok: $1"
  else
    echo "FAIL: $1"
    echo "  expected: $2"
    echo "  actual:   $3"
    FAIL=1
  fi
}

for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json hooks/hooks.json; do
  if python3 -m json.tool "$f" > /dev/null 2>&1; then
    echo "ok: valid json $f"
  else
    echo "FAIL: invalid json $f"
    FAIL=1
  fi
done

# Same project-name resolution the script uses.
PROJECT="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")")"

run() {
  printf '%s' "$1" | scripts/set-title.sh
}

check "SessionStart shows project" \
  "TITLE: ✳ $PROJECT" \
  "$(run '{"hook_event_name":"SessionStart","cwd":"'"$PWD"'","session_id":"t1"}')"

check "UserPromptSubmit truncates long prompt" \
  "TITLE: ✳ $PROJECT: fix the calendar sync bug in the scheduler a…" \
  "$(run '{"hook_event_name":"UserPromptSubmit","cwd":"'"$PWD"'","session_id":"t1","prompt":"fix the calendar sync bug in the scheduler and also refactor the timezone handling because it is broken"}')"

check "UserPromptSubmit accepts user_prompt field" \
  "TITLE: ✳ $PROJECT: short task" \
  "$(run '{"hook_event_name":"UserPromptSubmit","cwd":"'"$PWD"'","session_id":"t1","user_prompt":"short task"}')"

check "Stop recalls last summary" \
  "TITLE: ✓ $PROJECT: short task" \
  "$(run '{"hook_event_name":"Stop","cwd":"'"$PWD"'","session_id":"t1"}')"

check "SessionEnd keeps summary" \
  "TITLE: ✓ $PROJECT: short task" \
  "$(run '{"hook_event_name":"SessionEnd","cwd":"'"$PWD"'","session_id":"t1"}')"

# Prompt smuggling a raw ESC + BEL must have them stripped from the title.
INJECTED="$(python3 -c 'import json,sys; sys.stdout.write(json.dumps({"hook_event_name":"UserPromptSubmit","cwd":"/","session_id":"t2","prompt":"evil ]0;pwned title \t\n injection"}))' | scripts/set-title.sh)"
check "control characters stripped from title" \
  "TITLE: ✳ /: evil ]0;pwned title injection" \
  "$INJECTED"

run '{"hook_event_name":"PreToolUse","session_id":"t1"}' > /dev/null
check "unknown event exits 0 silently" "0" "$?"

echo 'not json' | scripts/set-title.sh > /dev/null 2>&1
check "garbage stdin exits 0" "0" "$?"

if [ "$FAIL" -eq 0 ]; then
  echo "all checks passed"
else
  exit 1
fi
