#!/bin/bash
# setup.sh — iOS projesinin root'unda çalıştırılır.
# Kit'i .claude-kit/'e indirir, settings.json ve CLAUDE.md oluşturur.
#
# Kullanım:
#   bash <(curl -s https://raw.githubusercontent.com/developerburakgul/iOS-Claude-Kit/main/setup.sh)
# veya:
#   bash setup.sh              (kit repo'su içinden)
#   bash .claude-kit/setup.sh  (zaten indirilmişse)

REPO="https://github.com/developerburakgul/iOS-Claude-Kit.git"
PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
KIT_DIR="$PROJECT_DIR/.claude-kit"
CLAUDE_DIR="$PROJECT_DIR/.claude"

echo ""
echo "iOS Claude Kit"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Kit'i indir (yoksa)
if [ -d "$KIT_DIR/core" ]; then
  echo "✅ .claude-kit/ zaten var"
else
  echo "⬇️  Kit indiriliyor..."
  git clone --depth 1 "$REPO" "$KIT_DIR" 2>/dev/null
  rm -rf "$KIT_DIR/.git"
  echo "✅ .claude-kit/ oluşturuldu"
fi

# 2. Hook'lara execute permission ver
chmod +x "$KIT_DIR"/core/hooks/**/*.sh 2>/dev/null
chmod +x "$KIT_DIR"/examples/hooks/**/*.sh 2>/dev/null

# 3. personal/ klasörünü oluştur
mkdir -p "$KIT_DIR/personal/hooks/pre-tool-use"
mkdir -p "$KIT_DIR/personal/hooks/post-tool-use"
mkdir -p "$KIT_DIR/personal/hooks/stop"
mkdir -p "$KIT_DIR/personal/skills"

# 4. .claude/settings.json oluştur
mkdir -p "$CLAUDE_DIR"
cat > "$CLAUDE_DIR/settings.json" <<'SETTINGS'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude-kit/core/hooks/pre-tool-use/protect-files.sh"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude-kit/core/hooks/pre-tool-use/safe-git.sh"
          },
          {
            "type": "command",
            "command": "bash .claude-kit/core/hooks/pre-tool-use/safe-bash.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude-kit/core/hooks/post-tool-use/swiftlint.sh"
          }
        ]
      }
    ],
    "Stop": []
  }
}
SETTINGS
echo "✅ .claude/settings.json oluşturuldu"

# 5. .claude/settings.local.json oluştur (personal hook'lar için, yoksa)
if [ ! -f "$CLAUDE_DIR/settings.local.json" ]; then
cat > "$CLAUDE_DIR/settings.local.json" <<'LOCAL'
{
  "hooks": {
    "PreToolUse": [],
    "PostToolUse": [],
    "Stop": []
  }
}
LOCAL
echo "✅ .claude/settings.local.json oluşturuldu (kişisel hook'ların için)"
else
  echo "⚠️  .claude/settings.local.json zaten var, atlanıyor"
fi

# 6. CLAUDE.md oluştur
if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
  echo "⚠️  CLAUDE.md zaten var, atlanıyor"
else
  sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g; s|{{KIT_DIR}}|.claude-kit|g; s|{{DATE}}|$(date +%Y-%m-%d)|g" \
    "$KIT_DIR/core/templates/CLAUDE.md.template" > "$PROJECT_DIR/CLAUDE.md"
  echo "✅ CLAUDE.md oluşturuldu"
fi

# 7. .swiftlint.yml oluştur (yoksa)
if [ -f "$PROJECT_DIR/.swiftlint.yml" ]; then
  echo "⚠️  .swiftlint.yml zaten var, atlanıyor"
else
  cp "$KIT_DIR/core/templates/.swiftlint.yml" "$PROJECT_DIR/.swiftlint.yml"
  echo "✅ .swiftlint.yml oluşturuldu"
fi

# 8. .gitignore'a .claude-kit/ ve settings.local.json ekle
GITIGNORE_LINES=".claude-kit/
.claude/settings.local.json"

if [ -f "$PROJECT_DIR/.gitignore" ]; then
  NEEDS_UPDATE=false
  if ! grep -q "^\.claude-kit/" "$PROJECT_DIR/.gitignore" 2>/dev/null; then
    NEEDS_UPDATE=true
  fi
  if ! grep -q "settings.local.json" "$PROJECT_DIR/.gitignore" 2>/dev/null; then
    NEEDS_UPDATE=true
  fi
  if [ "$NEEDS_UPDATE" = true ]; then
    echo -e "\n# Claude Kit (setup.sh ile indirilir)\n$GITIGNORE_LINES" >> "$PROJECT_DIR/.gitignore"
    echo "✅ .gitignore güncellendi"
  fi
else
  echo -e "# Claude Kit (setup.sh ile indirilir)\n$GITIGNORE_LINES" > "$PROJECT_DIR/.gitignore"
  echo "✅ .gitignore oluşturuldu"
fi

# 8. Bağımlılık kontrolü
echo ""
if command -v swiftlint &>/dev/null; then
  echo "✅ SwiftLint bulundu"
else
  echo "⚠️  SwiftLint bulunamadı — swiftlint hook'u sessizce atlanacak"
  echo -n "   Şimdi kurmak ister misin? (y/n): "
  read -r INSTALL_LINT
  INSTALL_LINT="$(echo "$INSTALL_LINT" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
  if [ "$INSTALL_LINT" = "y" ] || [ "$INSTALL_LINT" = "yes" ]; then
    if command -v brew &>/dev/null; then
      brew install swiftlint
      echo "✅ SwiftLint kuruldu"
    else
      echo "❌ Homebrew bulunamadı. Manuel kur: brew install swiftlint"
    fi
  fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 $PROJECT_NAME hazır!"
echo ""
echo "Sonraki adım:"
echo "  claude"
