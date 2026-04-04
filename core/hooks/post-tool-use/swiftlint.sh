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

RESULT="$(swiftlint lint --path "$FILE_PATH" --quiet 2>/dev/null)"

if [ -n "$RESULT" ]; then
  # Hata sayısını bul
  ERROR_COUNT="$(echo "$RESULT" | grep -c "error")"
  WARNING_COUNT="$(echo "$RESULT" | grep -c "warning")"

  REASON="SwiftLint found ${ERROR_COUNT} error(s), ${WARNING_COUNT} warning(s) in ${FILE_PATH}:\n\n${RESULT}\n\nFix all issues before continuing."

  echo "{\"decision\": \"block\", \"reason\": \"$REASON\"}"
  exit 2
fi

exit 0
