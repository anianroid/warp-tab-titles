# warp-tab-titles

Know which tab is which. A Claude Code plugin that keeps your terminal tab titles in sync with what each session is actually doing, prefixed with the project name. Built Warp-first, works in any terminal that honors OSC titles.

```
✳ planck: fix the calendar sync bug        ← Claude is working
✓ killbill: add stripe webhook tests       ← done, waiting for you
✳ vesta: refactor the board renderer       ← working
```

## Why

If you run multiple Claude Code sessions across tabs, the tabs all look the same. You exit one, come back later, and can't remember which session was which. This plugin gives every tab a human-readable title: the git repo name plus a summary of the current task, with a busy/done indicator.

Warp is the primary target because Warp auto-manages tab titles and silently overrides what programs set, which is exactly why titles seem broken there. This plugin ships with a setup command that fixes it.

## Install

Inside Claude Code:

```
/plugin marketplace add anianroid/warp-tab-titles
/plugin install warp-tab-titles@warp-tab-titles
```

## Warp setup (one time)

Warp overrides program-set titles unless you tell it not to. Either run:

```
/warp-tab-titles:setup
```

and let Claude configure it for you, or add this line to your `~/.zshrc` yourself:

```bash
export WARP_DISABLE_AUTO_TITLE=true
```

New tabs pick this up; existing tabs keep the old behavior until restarted.

Other terminals (iTerm2, Ghostty, kitty, Alacritty, Windows Terminal) need no setup.

## How it works

The plugin registers hooks on four Claude Code events. Each one emits a standard OSC 0 title sequence (`ESC ] 0 ; title BEL`) to `/dev/tty`:

| Event | Title |
|---|---|
| Session starts | `✳ project` |
| You submit a prompt | `✳ project: first words of your prompt` |
| Claude finishes responding | `✓ project: same summary` |
| Session ends | `✓ project: same summary` (persists so a dead tab still tells you what it was) |

The project prefix is the git repo name of the session's working directory, falling back to the directory name. Prompt text is stripped of control characters and truncated before it goes anywhere near an escape sequence.

## Configuration

Environment variables, all optional:

| Variable | Default | Meaning |
|---|---|---|
| `TAB_TITLE_MAX_LEN` | `44` | Max summary length before truncation |
| `TAB_TITLE_BUSY_ICON` | `✳` | Icon while Claude is working |
| `TAB_TITLE_DONE_ICON` | `✓` | Icon when Claude is done |
| `TAB_TITLE_DEBUG` | unset | If set, print the title to stdout instead of the tty |

## Requirements

- Claude Code with plugin support
- `jq` or `python3` on your PATH (for parsing hook input)
- macOS or Linux

## License

MIT
