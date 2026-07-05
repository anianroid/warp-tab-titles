---
description: Configure your terminal (Warp-first) so tab titles set by this plugin are not overridden
allowed-tools: Bash, Read, Edit
---

You are setting up the warp-tab-titles plugin for this user. The plugin already emits
OSC title sequences via hooks; your job is to make sure the terminal actually displays them.

Follow these steps:

1. Detect the terminal: run `echo "$TERM_PROGRAM"`.

2. If it is `WarpTerminal`:
   - Warp auto-manages tab titles and overrides titles set by programs unless
     `WARP_DISABLE_AUTO_TITLE=true` is set in the shell environment.
   - Determine the user's shell rc file (`~/.zshrc` for zsh, `~/.bashrc` for bash).
   - Check whether it already contains `WARP_DISABLE_AUTO_TITLE`.
   - If not, show the user the exact line you want to append
     (`export WARP_DISABLE_AUTO_TITLE=true`), ask for confirmation, then append it.
   - Tell the user the change applies to NEW tabs only; existing tabs keep the old behavior
     until restarted.

3. If it is any other terminal (iTerm2, Ghostty, Alacritty, Windows Terminal, kitty):
   - Tell the user no configuration is needed; these terminals honor OSC titles by default.
   - Exception: iTerm2 users who enabled "Preferences > Profiles > General > Title" with a
     fixed value should include "Session Name" in the title format.

4. Verify: run the plugin script directly in debug mode and show the user the output:

   ```bash
   echo '{"hook_event_name":"UserPromptSubmit","cwd":"'"$PWD"'","session_id":"test","prompt":"testing tab titles"}' \
     | TAB_TITLE_DEBUG=1 "${CLAUDE_PLUGIN_ROOT}/scripts/set-title.sh"
   ```

   Expected output: `TITLE: ✳ <project>: testing tab titles`

5. Mention that Claude Code itself may also update the terminal title with its own
   conversation summaries. This plugin re-asserts its title on every prompt, response,
   and session event, so the project-prefixed title generally wins.
