#!/bin/bash
# bin/ios-kit.sh

KIT="$HOME/.ios-claude-kit"
COMMAND="${1:-help}"

case "$COMMAND" in

  setup)
    bash "$KIT/bin/setup-project.sh"
    ;;

  update)
    echo "⬇️  Güncelleniyor..."
    git -C "$KIT" pull origin main
    chmod +x "$KIT"/core/hooks/**/*.sh 2>/dev/null
    chmod +x "$KIT"/personal/hooks/**/*.sh 2>/dev/null
    echo "✅ ios-claude-kit güncellendi"
    ;;

  skills)
    echo "📚 Core skill'ler:"
    ls "$KIT/core/skills/"
    echo ""
    echo "📚 Personal skill'ler:"
    ls "$KIT/personal/skills/" 2>/dev/null || echo "  henüz yok"
    ;;

  help)
    echo ""
    echo "iOS Claude Kit"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ios-kit setup    → projeyi Claude'a hazırlar"
    echo "  ios-kit update   → kit'i günceller"
    echo "  ios-kit skills   → mevcut skill'leri listeler"
    echo "  ios-kit help     → bu ekranı gösterir"
    echo ""
    ;;

  *)
    echo "❌ Bilinmeyen komut: $COMMAND"
    echo "   ios-kit help ile komutları görebilirsin"
    ;;

esac