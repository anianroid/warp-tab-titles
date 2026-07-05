#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
export TAB_TITLE_DEBUG=1

for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json hooks/hooks.json; do
  python3 -m json.tool "$f" > /dev/null && echo "OK json: $f" || echo "BAD json: $f"
done

echo '{"hook_event_name":"SessionStart","cwd":"'"$PWD"'","session_id":"t1"}' | scripts/set-title.sh
echo '{"hook_event_name":"UserPromptSubmit","cwd":"'"$PWD"'","session_id":"t1","prompt":"fix the calendar sync bug in the scheduler and also refactor the timezone handling because it is broken"}' | scripts/set-title.sh
echo '{"hook_event_name":"UserPromptSubmit","cwd":"'"$PWD"'","session_id":"t1","user_prompt":"short task"}' | scripts/set-title.sh
echo '{"hook_event_name":"Stop","cwd":"'"$PWD"'","session_id":"t1"}' | scripts/set-title.sh
echo '{"hook_event_name":"SessionEnd","cwd":"'"$PWD"'","session_id":"t1"}' | scripts/set-title.sh

# control-char injection attempt: prompt contains a raw ESC and BEL
python3 -c 'import json,sys; sys.stdout.write(json.dumps({"hook_event_name":"UserPromptSubmit","cwd":"/","session_id":"t2","prompt":"evil ]0;pwned  title   injection"}))' | scripts/set-title.sh

# unknown event should exit 0 silently
echo '{"hook_event_name":"PreToolUse","session_id":"t1"}' | scripts/set-title.sh
echo "unknown-event exit: $?"

# empty/garbage stdin should not crash
echo 'not json' | scripts/set-title.sh
echo "garbage exit: $?"
