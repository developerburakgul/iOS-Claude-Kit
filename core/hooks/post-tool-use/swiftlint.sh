#!/bin/bash
# core/hooks/post-tool-use/swiftlint.sh
# Claude bir .swift dosyası editledikten sonra SwiftLint çalıştırır.
# Hata varsa Claude'a bildirir ve düzeltmesini zorunlu kılar.

# swiftlint yoksa sessizce geç
if ! command -v swiftlint &>/dev/null; then
  exit 0
fi

INPUT="$(cat)"
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')"

# .swift değilse geç
if [[ "$FILE_PATH" != *.swift ]]; then
  exit 0
fi

# Dosya yoksa geç (silinmiş olabilir)
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

RESULT="$(swiftlint lint --quiet "$FILE_PATH" 2>/dev/null)"

if [ -n "$RESULT" ]; then
  ERROR_COUNT="$(echo "$RESULT" | grep -c ": error:")"
  WARNING_COUNT="$(echo "$RESULT" | grep -c ": warning:")"

  # Her satırı "  - file:line: type: message" formatına çevir
  FORMATTED="$(echo "$RESULT" | while IFS= read -r line; do
    FILE="$(echo "$line" | cut -d: -f1 | xargs basename 2>/dev/null)"
    LINE_NUM="$(echo "$line" | cut -d: -f2)"
    TYPE="$(echo "$line" | cut -d: -f3 | tr -d ' ')"
    RULE="$(echo "$line" | sed 's/.*(\(.*\))/\1/' 2>/dev/null)"
    MSG="$(echo "$line" | cut -d: -f4- | sed 's/ *(.*//' | sed 's/^ *//')"
    if [ "$TYPE" = "error" ]; then
      echo "  [ERROR] $FILE:$LINE_NUM — $MSG ($RULE)"
    else
      echo "  [WARN]  $FILE:$LINE_NUM — $MSG ($RULE)"
    fi
  done)"

  REASON="SwiftLint: ${ERROR_COUNT} error(s), ${WARNING_COUNT} warning(s)

${FORMATTED}

Fix all issues in ${FILE_PATH} before continuing."

  # JSON-safe: newline'ları \n'e çevir, tırnak escape et
  REASON_ESCAPED="$(echo "$REASON" | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')"

  echo "{\"decision\": \"block\", \"reason\": \"${REASON_ESCAPED}\"}"
  exit 2
fi

exit 0
