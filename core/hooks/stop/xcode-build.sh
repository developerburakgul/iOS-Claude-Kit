#!/bin/bash
# core/hooks/stop/xcode-build.sh
# Claude degisikliklerini bitirdiginde Xcode build kontrolu yapar.
# Build basarisizsa Claude'a hatalari bildirir ve duzeltmesini ister.
#
# Stop hook: exit 0 = Claude durur, exit 2 = Claude devam eder (stdout feedback olur)
#
# Opsiyonel ortam degiskenleri:
#   XCODE_SCHEME       — Scheme adi (otomatik tespit yerine)
#   XCODE_BUILD_TIMEOUT — Timeout saniye (varsayilan: 120)

TIMEOUT="${XCODE_BUILD_TIMEOUT:-120}"

# xcodebuild yoksa sessizce gec
if ! command -v xcodebuild &>/dev/null; then
  exit 0
fi

# Degisen .swift dosyasi var mi kontrol et
CHANGED_SWIFT="$(git diff --name-only 2>/dev/null | grep '\.swift$' || true)"
STAGED_SWIFT="$(git diff --cached --name-only 2>/dev/null | grep '\.swift$' || true)"
UNTRACKED_SWIFT="$(git ls-files --others --exclude-standard 2>/dev/null | grep '\.swift$' || true)"

if [ -z "$CHANGED_SWIFT" ] && [ -z "$STAGED_SWIFT" ] && [ -z "$UNTRACKED_SWIFT" ]; then
  exit 0
fi

# Workspace veya project bul
WORKSPACE="$(find . -maxdepth 1 -name "*.xcworkspace" ! -path "*.xcodeproj/*" -print -quit 2>/dev/null)"
PROJECT="$(find . -maxdepth 1 -name "*.xcodeproj" -print -quit 2>/dev/null)"

if [ -n "$WORKSPACE" ]; then
  BUILD_TARGET="-workspace $WORKSPACE"
elif [ -n "$PROJECT" ]; then
  BUILD_TARGET="-project $PROJECT"
else
  # Xcode projesi bulunamadi, gec
  exit 0
fi

# Scheme belirle
if [ -n "$XCODE_SCHEME" ]; then
  SCHEME="$XCODE_SCHEME"
else
  SCHEME="$(xcodebuild -list $BUILD_TARGET 2>/dev/null \
    | awk '/Schemes:/{found=1; next} found && /^[[:space:]]*$/{exit} found{gsub(/^[[:space:]]+|[[:space:]]+$/, ""); print; exit}')"
fi

if [ -z "$SCHEME" ]; then
  exit 0
fi

# Build (sadece compile, test yok)
BUILD_OUTPUT="$(timeout "$TIMEOUT" xcodebuild build \
  $BUILD_TARGET \
  -scheme "$SCHEME" \
  -destination "generic/platform=iOS Simulator" \
  -quiet \
  2>&1)"

BUILD_EXIT=$?

# Timeout (exit 124)
if [ $BUILD_EXIT -eq 124 ]; then
  echo "Xcode build timed out after ${TIMEOUT}s. You may want to increase XCODE_BUILD_TIMEOUT or check for issues."
  exit 0  # timeout durumunda bloklamiyoruz, sadece uyariyoruz
fi

if [ $BUILD_EXIT -ne 0 ]; then
  # Hatalari filtrele ve formatla
  ERRORS="$(echo "$BUILD_OUTPUT" | grep -E ":\d+:\d+: error:" | head -20)"

  # Eger grep ile bulamadiysa genel error satirlarini al
  if [ -z "$ERRORS" ]; then
    ERRORS="$(echo "$BUILD_OUTPUT" | grep -i "error:" | head -20)"
  fi

  ALL_SWIFT="$(printf '%s\n%s\n%s' "$CHANGED_SWIFT" "$STAGED_SWIFT" "$UNTRACKED_SWIFT" \
    | sort -u | grep -v '^$' | sed 's/^/  - /')"

  REASON="Xcode build FAILED (scheme: ${SCHEME})

Build errors:
${ERRORS}

Changed Swift files:
${ALL_SWIFT}

Fix all build errors before finishing."

  REASON_ESCAPED="$(echo "$REASON" | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')"

  echo "{\"decision\": \"block\", \"reason\": \"${REASON_ESCAPED}\"}"
  exit 2
fi

exit 0
