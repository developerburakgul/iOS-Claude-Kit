---
name: commit
description: Creates commits following Conventional Commits v1.0.0 specification. Analyzes changes, determines appropriate type and scope, and proposes a commit message.
user-invocable: true
argument-hint: "message"
---

# Conventional Commits v1.0.0

## Commit Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Rules

1. **type** is required
2. **scope** is optional, written in parentheses: `feat(auth): ...`
3. **description** is required, separated from type by `: ` (colon + space)
4. **description** starts with lowercase, no period at the end
5. **body** is optional, starts after a blank line following the description
6. **footer** is optional, starts after a blank line following the body, in `token: value` or `token #value` format
7. To indicate a **BREAKING CHANGE**: add `BREAKING CHANGE: description` in the footer OR append `!` after the type: `feat!: ...`

---

## Allowed Types

| Type | Description |
|---|---|
| `feat` | New feature (SemVer MINOR) |
| `fix` | Bug fix (SemVer PATCH) |
| `docs` | Documentation-only changes |
| `style` | Formatting changes that don't affect code behavior (whitespace, punctuation, etc.) |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Performance improvement |
| `test` | Adding or fixing tests |
| `build` | Build system or external dependency changes (SPM, CocoaPods, etc.) |
| `ci` | CI configuration files and scripts |
| `chore` | Maintenance tasks that don't modify source code |
| `revert` | Reverting a previous commit |

---

## Steps

Follow these steps when this skill is invoked:

### 1. Analyze changes

```bash
git status
git diff --staged
git diff
```

- If there are staged changes, commit only those.
- If there are no staged changes, show the unstaged changes and ask the user which files they want to stage.
- If there are no changes at all, inform the user and stop.

### 2. Create the commit message

Analyze the changes and select the appropriate type:

- **New file/feature added** → `feat`
- **Bug fixed** → `fix`
- **Only README/CLAUDE.md changed** → `docs`
- **Only tests added/modified** → `test`
- **Existing code restructured without behavior change** → `refactor`
- **Performance improvement** → `perf`
- **Build/dependency change** → `build`
- **Formatting/whitespace change** → `style`
- **CI files changed** → `ci`
- **Other maintenance tasks** → `chore`

**Determining scope (optional):**
- If the change belongs to a single module/feature, add a scope: `feat(onboarding): ...`
- If it spans multiple areas, omit the scope: `feat: ...`

**Writing the description:**
- Write in English
- Start with lowercase
- Use imperative mood ("add", "fix", "update" — not "added", "fixed")
- No period at the end
- Keep it short and clear (under 50 characters)

### 3. Check consistency with recent commits

```bash
git log --oneline -10
```

Stay consistent with the language and style of the existing commit history.

### 4. Confirm with the user and commit

Show the proposed commit message to the user and get their approval. Once approved:

```bash
git add <files>
git commit -m "<type>(<scope>): <description>"
```

If body or footer is needed, use a HEREDOC:

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <description>

<body>

<footer>
EOF
)"
```

---

## Examples

```
feat: add user authentication flow
fix(cart): resolve crash when removing last item
docs: update API integration guide
refactor(network): extract base request handler
feat!: drop iOS 16 support
test(payment): add RevenueCat purchase tests
build: update Firebase to 11.0
chore: remove unused asset catalogs

feat(auth): add biometric login support

Implements Face ID and Touch ID authentication
as an alternative to password-based login.

Closes #42

fix(sync)!: change data merge strategy

The previous merge strategy was causing data loss
when offline changes conflicted with server state.

BREAKING CHANGE: sync conflict resolution now
favors local changes over server changes
```

---

## Don'ts

- Don't commit unstaged files without asking first
- Don't use `git add .` or `git add -A` — add files individually
- Don't commit `.env`, credentials, or files containing secrets
- Don't use `--no-verify`
- Don't use `--amend` (unless the user explicitly requests it)
- Don't create empty commits
