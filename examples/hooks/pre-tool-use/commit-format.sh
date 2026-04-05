#!/bin/bash
# examples/hooks/pre-tool-use/commit-format.sh
# Commit mesajlarının conventional commit formatına uymasını zorlar.
# Projeye göre PREFIXES listesini düzenleyebilirsin.
#
# Matcher: Bash
# if: Bash(git commit*)

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

# git commit değilse geç
if ! echo "$COMMAND" | grep -q "git commit"; then
  exit 0
fi

# Commit mesajını çıkar (-m "..." veya -m '...')
COMMIT_MSG=$(echo "$COMMAND" | grep -oP '(?<=-m\s)["\x27]([^"\x27]*)["\x27]' | head -1 | tr -d "\"'")

# -m yoksa geç (--amend vs olabilir)
if [ -z "$COMMIT_MSG" ]; then
  exit 0
fi

# İzin verilen prefix'ler — projeye göre düzenle
PREFIXES="^(feat|fix|chore|docs|style|refactor|test|perf|ci|build|revert)(\(.+\))?: .+"

if ! echo "$COMMIT_MSG" | grep -qE "$PREFIXES"; then
  echo "Blocked: commit message doesn't follow conventional commit format." >&2
  echo "Expected: <type>: <description>" >&2
  echo "Types: feat, fix, chore, docs, style, refactor, test, perf, ci, build, revert" >&2
  echo "Example: feat: add user login screen" >&2
  echo "Got: $COMMIT_MSG" >&2
  exit 2
fi

exit 0
