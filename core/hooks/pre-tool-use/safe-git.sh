#!/bin/bash
# core/hooks/pre-tool-use/safe-git.sh
# Tehlikeli git komutlarını engeller.
# Geri dönüşü zor veya takımı etkileyen komutları bloklar.

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Sadece Bash tool'unda git komutlarını kontrol et
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

# git komutu değilse geç
if ! echo "$COMMAND" | grep -q "^\s*git "; then
  exit 0
fi

BLOCKED_PATTERNS=(
  # Force push — remote history'yi yok eder
  "push.*--force"
  "push.*-f"

  # Reset hard — commit edilmemiş değişiklikleri siler
  "reset.*--hard"

  # Branch silme — geri dönüşü zor
  "branch.*-D"
  "branch.*--delete.*--force"

  # Checkout ile tüm değişiklikleri silme
  "checkout.*-- \."
  "checkout.*--\."

  # Clean — untracked dosyaları siler
  "clean.*-f"
  "clean.*-fd"

  # Rebase — interaktif olmayanı bile tehlikeli olabilir
  "rebase.*--force"

  # Stash drop all
  "stash.*clear"
  "stash.*drop.*--all"

  # Remote silme
  "remote.*remove"
  "remote.*rm"

  # Tag silme (remote)
  "push.*--delete"
  "push.*:refs/"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "Blocked: dangerous git command detected ('$COMMAND' matched '$pattern'). This command can cause irreversible damage." >&2
    exit 2
  fi
done

exit 0
