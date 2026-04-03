#!/bin/bash
# bin/setup-project.sh

KIT="$HOME/.ios-claude-kit"
PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
CLAUDE_DIR="$PROJECT_DIR/.claude"

echo "🚀 $PROJECT_NAME — Claude'a hazırlanıyor..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. .claude/ klasörünü oluştur
mkdir -p "$CLAUDE_DIR"
echo "✅ .claude/ oluşturuldu"

# 2. settings.json oluştur
cat > "$CLAUDE_DIR/settings.json" <<EOF
{
  "hooks": {
    "PreToolUse": [],
    "PostToolUse": [],
    "Stop": []
  }
}
EOF
echo "✅ .claude/settings.json oluşturuldu"

# 3. CLAUDE.md oluştur
if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
  echo "⚠️  CLAUDE.md zaten var, atlanıyor"
  echo "   Güncellemek için sil, tekrar ios-kit setup çalıştır"
else
  sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g; s|{{KIT_DIR}}|$KIT|g; s|{{DATE}}|$(date +%Y-%m-%d)|g" \
    "$KIT/core/templates/CLAUDE.md.template" > "$PROJECT_DIR/CLAUDE.md"
  echo "✅ CLAUDE.md oluşturuldu"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 $PROJECT_NAME hazır!"
echo ""
echo "Sonraki adım:"
echo "  claude   ← projeyi aç"