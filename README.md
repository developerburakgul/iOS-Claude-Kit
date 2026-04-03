# iOS-Claude-Kit

A reusable Claude Code toolkit for iOS projects. One kit, every project.

Instead of setting up Claude Code from scratch for each iOS project, install this kit once and run a single command to get your project ready — with hooks, skills, and a pre-configured `CLAUDE.md`.

## Install

```bash
git clone https://github.com/developerburakgul/iOS-Claude-Kit.git ~/.ios-claude-kit
cd ~/.ios-claude-kit
bash install.sh
```

Restart your terminal after installation.

## Usage

### Set up a project

```bash
cd ~/Projects/MyApp
ios-kit setup
```

This creates two files in your project:

- `.claude/settings.json` — hook configurations
- `CLAUDE.md` — project context for Claude (Swift conventions, architecture rules, etc.)

### Other commands

```bash
ios-kit update   # pull latest changes from the kit
ios-kit skills   # list available skills
ios-kit help     # show all commands
```

## How It Works

### Project Structure

```
~/.ios-claude-kit/
├── bin/
│   ├── ios-kit.sh             # CLI entry point
│   └── setup-project.sh       # Project setup script
├── core/
│   ├── hooks/                 # Shared team hooks (empty by default)
│   │   ├── pre-tool-use/      # Runs before Claude writes/edits files
│   │   ├── post-tool-use/     # Runs after Claude writes/edits files
│   │   └── stop/              # Runs when Claude finishes its turn
│   └── templates/
│       └── CLAUDE.md.template # Template for project CLAUDE.md
├── examples/
│   └── hooks/                 # Ready-to-use example hooks
│       └── stop/
│           └── notify-waiting.sh
├── personal/                  # Your custom hooks/skills (gitignored)
└── install.sh
```

### Hooks

Hooks are shell scripts that Claude Code runs at specific moments. Each hook is a single `.sh` file that does one thing.

#### Hook Events

| Event | When | Use Case |
|-------|------|----------|
| `PreToolUse` | Before Claude calls a tool | Block unwanted patterns, enforce rules |
| `PostToolUse` | After a tool runs | Lint checks, build verification |
| `Stop` | Claude finishes its turn | Notifications, summaries |

#### Hook I/O

```
stdin  → JSON (tool_name, tool_input)
stdout → JSON (decision, reason)
exit 0 → allow
exit 2 → block (reason is shown to Claude)
```

#### Adding a Hook

**Step 1 — Write the script**

Create a `.sh` file in `core/hooks/<event>/`. Example: `core/hooks/pre-tool-use/no-force-unwrap.sh`

```bash
#!/bin/bash
INPUT="$(cat)"
NEW_STRING="$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')"

if echo "$NEW_STRING" | grep -q '![[:space:]]'; then
  echo '{"decision": "block", "reason": "Force unwrap (!) is not allowed. Use guard let or if let."}'
  exit 2
fi

exit 0
```

**Step 2 — Register it in `bin/setup-project.sh`**

Open `bin/setup-project.sh` and add your hook to the settings.json block under the right event and matcher:

```json
"PreToolUse": [
  {
    "matcher": "Write|Edit",
    "hooks": [
      {
        "type": "command",
        "command": "bash $KIT/core/hooks/pre-tool-use/no-force-unwrap.sh"
      }
    ]
  }
]
```

Each hook entry needs:
- `matcher` — which tools trigger this hook (see Matchers below)
- `type` — always `"command"`
- `command` — path to your script (`$KIT` expands to `~/.ios-claude-kit`)

**Step 3 — Apply to your project**

```bash
ios-kit setup
```

This regenerates `.claude/settings.json` in your project with the new hook.

#### Matchers

Matchers filter which tools trigger a hook:

```
Write|Edit          → file write/edit operations
Bash(git commit:*)  → git commit commands
Bash(git push:*)    → git push commands
.*                  → everything
```

### Example Hooks

The `examples/` directory contains ready-to-use hooks. You can copy them to `personal/` during installation, or manually anytime.

#### `examples/hooks/stop/notify-waiting.sh`

Sends a macOS notification with sound when Claude finishes and is waiting for your input. Useful when you're working in another window.

```bash
#!/bin/bash
osascript -e 'display notification "Cevap hazır, seni bekliyor." with title "Claude Code" sound name "Glass"'
```

**To activate manually:**

```bash
cp ~/.ios-claude-kit/examples/hooks/stop/notify-waiting.sh ~/.ios-claude-kit/personal/hooks/stop/
```

Then add the hook to your project's `.claude/settings.json`:

```json
"Stop": [
  {
    "matcher": ".*",
    "hooks": [
      {
        "type": "command",
        "command": "bash ~/.ios-claude-kit/personal/hooks/stop/notify-waiting.sh"
      }
    ]
  }
]
```

### Personal Hooks

The `personal/` directory is gitignored. Put your own hooks and skills here — they won't affect the shared repo. You can also copy examples here during installation.

## Customization

### CLAUDE.md Template

The template at `core/templates/CLAUDE.md.template` defines what goes into each project's `CLAUDE.md`. It includes:

- Project metadata (iOS, Swift, SwiftUI)
- Architecture rules (MVVM)
- Coding conventions (no force unwrap, no singletons, etc.)
- Git commit/branch naming

Edit the template to match your team's conventions.

## Uninstall

```bash
# Remove the kit
rm -rf ~/.ios-claude-kit

# Remove the alias from .zshrc
# Delete the line: alias ios-kit="bash $HOME/.ios-claude-kit/bin/ios-kit.sh"
```

In each project, delete `.claude/settings.json` and `CLAUDE.md` if you no longer need them.

## License

MIT
