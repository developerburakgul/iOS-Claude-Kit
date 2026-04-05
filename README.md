# iOS-Claude-Kit

A reusable Claude Code toolkit for iOS projects. One kit, every project.

Drop it into any iOS project to get pre-configured hooks, skills, and a `CLAUDE.md` — no global install, no submodules. The kit lives in `.claude-kit/` (gitignored), so each project stays clean.

## Quick Start

In your iOS project root:

```bash
git clone --depth 1 https://github.com/developerburakgul/iOS-Claude-Kit.git .claude-kit
bash .claude-kit/setup.sh
```

That's it. Now run `claude` in your project.

### What happens

```
MyApp/
  .claude-kit/                  ← the kit (gitignored, not committed)
  .claude/
    settings.json               ← core hook config (committed, shared with team)
    settings.local.json         ← personal hook config (gitignored, just for you)
  CLAUDE.md                     ← project context for Claude (committed)
  .gitignore                    ← updated automatically
```

### For teammates

When a teammate clones your project, they run the same two commands:

```bash
git clone --depth 1 https://github.com/developerburakgul/iOS-Claude-Kit.git .claude-kit
bash .claude-kit/setup.sh
```

`settings.json` and `CLAUDE.md` are already in git — setup detects them and only downloads the kit.

### Updating the kit

```bash
rm -rf .claude-kit
git clone --depth 1 https://github.com/developerburakgul/iOS-Claude-Kit.git .claude-kit
bash .claude-kit/setup.sh
```

---

## Hooks

Hooks are shell scripts that Claude Code runs at specific moments. Each hook is a single `.sh` file that does one thing.

### How hooks work

| Event | When it runs | Use case |
|-------|-------------|----------|
| `PreToolUse` | Before Claude calls a tool | Block unwanted patterns, enforce rules |
| `PostToolUse` | After a tool runs | Lint checks, build verification |
| `Stop` | Claude finishes its turn | Notifications, summaries |

Every hook receives JSON on stdin and can return JSON on stdout:

```
stdin  → {"tool_name": "Edit", "tool_input": {"file_path": "...", ...}}
stdout → {"decision": "block", "reason": "Why it was blocked"}
exit 0 → allow
exit 2 → block (reason is shown to Claude)
```

### Core hooks vs personal hooks

| | Core | Personal |
|---|---|---|
| Scripts in | `.claude-kit/core/hooks/` | `.claude-kit/personal/hooks/` |
| Config in | `.claude/settings.json` | `.claude/settings.local.json` |
| In git? | `settings.json` yes, kit no | No |
| Who sees it | Everyone on the team | Only you |
| How to add | Add to kit repo + `setup.sh` | Edit `settings.local.json` locally |

Claude Code merges both files — core and personal hooks run together.

### Matchers

Matchers filter which tools trigger a hook:

```
Write|Edit          → file write/edit operations
Bash(git commit:*)  → git commit commands
Bash(git push:*)    → git push commands
.*                  → everything
```

---

## Included Core Hooks

These hooks are active in every project that runs `setup.sh`.

### `protect-files.sh` — Block edits to protected files

Prevents Claude from editing files that should not be modified manually. Triggers on `Write|Edit`.

| Category | Protected files |
|----------|----------------|
| Xcode project | `.pbxproj`, `.xcworkspace`, `xcuserdata/`, `DerivedData/` |
| App metadata | `Info.plist`, `.entitlements` |
| Asset catalog | `Assets.xcassets/Contents.json` |
| Lock files | `Package.resolved`, `Podfile.lock` |
| Sensitive config | `GoogleService-Info.plist`, `Secrets.swift`, `.env*` |
| Certificates | `.p12`, `.mobileprovision`, `.cer` |
| Git / Kit | `.git/`, `.claude-kit/core/` |

### `safe-git.sh` — Block dangerous git commands

Prevents irreversible git operations. Triggers on `Bash`.

| Blocked | Why |
|---------|-----|
| `push --force` / `push -f` | Overwrites remote history |
| `reset --hard` | Deletes uncommitted changes |
| `branch -D` | Force-deletes branch |
| `checkout -- .` | Discards all changes |
| `clean -f` / `clean -fd` | Deletes untracked files |
| `stash clear` | Drops all stashes |
| `remote remove` / `remote rm` | Removes remote |
| `push --delete` / `push :refs/` | Deletes remote tag/branch |

### `safe-bash.sh` — Block dangerous shell commands

Prevents system-damaging commands. Triggers on `Bash`.

| Blocked | Why |
|---------|-----|
| `rm -rf /` / `rm -rf ~` / `rm -rf .` | Catastrophic deletion |
| `sudo` | Claude should not have root access |
| `chmod 777` | Removes all file security |
| `curl\|sh` / `wget\|bash` | Remote code execution risk |
| `killall` / `pkill -9` | Kills processes indiscriminately |
| `rm -rf *.xcodeproj` / `*.xcworkspace` | Xcode project deletion |
| `dd if=` / `mkfs.` / `fdisk` | Disk/partition operations |

### `swiftlint.sh` — Lint Swift files after edits

Runs SwiftLint on `.swift` files after Claude edits them. Blocks and reports issues so Claude fixes them automatically. Triggers on `Write|Edit`.

- Skips silently if SwiftLint is not installed
- Skips non-Swift files
- Setup offers to install SwiftLint via Homebrew if missing

---

## Adding a Core Hook

Core hooks apply to everyone on the team. They live in the kit repo.

**Step 1 — Write the script**

Create a `.sh` file in `core/hooks/<event>/`.

Example — block force unwraps (`core/hooks/pre-tool-use/no-force-unwrap.sh`):

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

**Step 2 — Register it in `setup.sh`**

Open `setup.sh` in the kit repo. Find the settings.json block and add your hook under the right event:

```json
"PreToolUse": [
  {
    "matcher": "Write|Edit",
    "hooks": [
      {
        "type": "command",
        "command": "bash .claude-kit/core/hooks/pre-tool-use/no-force-unwrap.sh"
      }
    ]
  }
]
```

Each entry needs:
- **`matcher`** — which tools trigger this hook
- **`type`** — always `"command"`
- **`command`** — relative path from project root

**Step 3 — Apply**

In your project, update the kit and re-run setup:

```bash
rm -rf .claude-kit
git clone --depth 1 https://github.com/developerburakgul/iOS-Claude-Kit.git .claude-kit
bash .claude-kit/setup.sh
```

---

## Adding a Personal Hook

Personal hooks are just for you. They don't affect teammates.

**Step 1 — Write or copy the script**

```bash
# Copy an example
cp .claude-kit/examples/hooks/stop/notify-waiting.sh .claude-kit/personal/hooks/stop/

# Or write your own
vim .claude-kit/personal/hooks/stop/my-hook.sh
```

**Step 2 — Register it in `.claude/settings.local.json`**

```json
{
  "hooks": {
    "PreToolUse": [],
    "PostToolUse": [],
    "Stop": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude-kit/personal/hooks/stop/notify-waiting.sh"
          }
        ]
      }
    ]
  }
}
```

No re-run needed — Claude Code picks up changes to `settings.local.json` immediately.

---

## Example Hooks

Ready-to-use hooks in `examples/`. These are project-specific — copy to `personal/` and register in `settings.local.json` to activate.

### `examples/hooks/pre-tool-use/commit-format.sh`

Enforces [Conventional Commits](https://www.conventionalcommits.org/) format on commit messages.

```
feat: add user login screen       ← allowed
fix: crash on launch              ← allowed
updated something                 ← blocked
```

Allowed prefixes: `feat`, `fix`, `chore`, `docs`, `style`, `refactor`, `test`, `perf`, `ci`, `build`, `revert`. Edit the `PREFIXES` variable in the script to customize.

### `examples/hooks/pre-tool-use/branch-naming.sh`

Enforces branch naming conventions when creating new branches.

```
feature/user-login                ← allowed
fix/crash-on-launch               ← allowed
my-branch                         ← blocked
```

Allowed prefixes: `feature/`, `fix/`, `hotfix/`, `bugfix/`, `release/`, `chore/`, `refactor/`, `test/`, `docs/`. Edit `ALLOWED_PREFIXES` to customize.

### `examples/hooks/stop/notify-waiting.sh`

Sends a macOS notification with sound when Claude finishes its turn. Useful when you're working in another window.

### Activating an example hook

1. Copy to personal:
```bash
cp .claude-kit/examples/hooks/pre-tool-use/commit-format.sh .claude-kit/personal/hooks/pre-tool-use/
```

2. Add to `.claude/settings.local.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude-kit/personal/hooks/pre-tool-use/commit-format.sh"
          }
        ]
      }
    ]
  }
}
```

---

## CLAUDE.md Template

The template at `core/templates/CLAUDE.md.template` generates each project's `CLAUDE.md`. Default config:

- **Platform:** iOS 17+, Swift, SwiftUI
- **Architecture:** MVVM
- **Backend:** Firebase
- **Rules:** No force unwrap, no singletons, no god classes, @Observable over ObservableObject

Edit the template in the kit repo to match your team's conventions. Changes apply next time `setup.sh` runs (only if `CLAUDE.md` doesn't already exist in the project).

---

## Uninstall

```bash
rm -rf .claude-kit .claude/settings.json .claude/settings.local.json CLAUDE.md
```

## License

MIT
