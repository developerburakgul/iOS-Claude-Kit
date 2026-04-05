#!/bin/bash
# examples/hooks/pre-tool-use/branch-naming.sh
# Branch isimlerinin belirlenen formata uymasını zorlar.
# Projeye göre ALLOWED_PREFIXES'i düzenleyebilirsin.
#
# Matcher: Bash
# if: Bash(git checkout* -b*) veya Bash(git branch*)

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

# Branch oluşturma komutlarını yakala
BRANCH_NAME=""

# git checkout -b <branch>
if echo "$COMMAND" | grep -qE "git checkout.*-b\s+"; then
  BRANCH_NAME=$(echo "$COMMAND" | grep -oP '(?<=-b\s)\S+')
fi

# git branch <branch>
if echo "$COMMAND" | grep -qE "git branch\s+[^-]"; then
  BRANCH_NAME=$(echo "$COMMAND" | sed 's/git branch\s\+//' | awk '{print $1}')
fi

# git switch -c <branch>
if echo "$COMMAND" | grep -qE "git switch.*-c\s+"; then
  BRANCH_NAME=$(echo "$COMMAND" | grep -oP '(?<=-c\s)\S+')
fi

# Branch ismi yoksa geç
if [ -z "$BRANCH_NAME" ]; then
  exit 0
fi

# main/develop'a geçişi engelleme
if [ "$BRANCH_NAME" = "main" ] || [ "$BRANCH_NAME" = "develop" ] || [ "$BRANCH_NAME" = "master" ]; then
  exit 0
fi

# İzin verilen prefix'ler — projeye göre düzenle
ALLOWED_PREFIXES="^(feature|fix|hotfix|bugfix|release|chore|refactor|test|docs)/"

if ! echo "$BRANCH_NAME" | grep -qE "$ALLOWED_PREFIXES"; then
  echo "Blocked: branch name '$BRANCH_NAME' doesn't follow naming convention." >&2
  echo "Expected: <prefix>/<description>" >&2
  echo "Prefixes: feature/, fix/, hotfix/, bugfix/, release/, chore/, refactor/, test/, docs/" >&2
  echo "Example: feature/user-login, fix/crash-on-launch" >&2
  exit 2
fi

exit 0
