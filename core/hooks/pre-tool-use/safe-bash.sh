#!/bin/bash
# core/hooks/pre-tool-use/safe-bash.sh
# Tehlikeli bash komutlarını engeller.
# Sistem dosyalarına, prod ortamına veya geri dönüşü zor işlemlere karşı korur.

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Sadece Bash tool'u
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

BLOCKED_PATTERNS=(
  # Tehlikeli silme
  "^\s*rm\s"
  "^\s*rmdir\s"

  # Sudo — Claude'un root yetkisi olmamalı
  "^\s*sudo "

  # Sistem dosyalarına yazma
  "> /etc/"
  ">> /etc/"
  "chmod 777"

  # Disk/partition işlemleri
  "mkfs\."
  "dd if="
  "fdisk"

  # Ağ/download ve çalıştırma — güvenlik riski
  "curl.*\| *sh"
  "curl.*\| *bash"
  "wget.*\| *sh"
  "wget.*\| *bash"

  # Process kill all
  "killall"
  "pkill -9"

  # Xcode temizlik — DerivedData dışında tehlikeli
  "rm -rf.*\.xcodeproj"
  "rm -rf.*\.xcworkspace"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "Blocked: dangerous command detected ('$COMMAND' matched '$pattern'). This command can cause irreversible damage to your system or project." >&2
    exit 2
  fi
done

exit 0
