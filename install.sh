#!/bin/bash
# install.sh

KIT="$HOME/.ios-claude-kit"

echo "🚀 iOS Claude Kit kuruluyor..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Hook'lara execute permission ver
chmod +x "$KIT"/core/hooks/**/*.sh 2>/dev/null
echo "✅ Hook izinleri verildi"

# 2. ios-kit alias'ını ekle
if ! grep -q "ios-claude-kit" "$HOME/.zshrc" 2>/dev/null; then
  echo '\nalias ios-kit="bash $HOME/.ios-claude-kit/bin/ios-kit.sh"' >> ~/.zshrc
  echo "✅ ios-kit komutu eklendi"
else
  echo "⚠️  ios-kit zaten tanımlı, atlandı"
fi

# 3. personal/ alt klasörlerini oluştur
mkdir -p "$KIT/personal/skills"
mkdir -p "$KIT/personal/hooks/post-tool-use"
mkdir -p "$KIT/personal/hooks/stop"
echo "✅ personal/ klasörü hazırlandı"

# 4. Örnekleri kopyala
echo ""
echo "💡 examples/ klasöründe hazır hook ve skill'ler var."
echo "   Bunları personal/ klasörüne kopyalamak ister misin?"
echo -n "   (y/n): "
read -r ANSWER

if [ "$ANSWER" = "y" ]; then
  cp -r "$KIT/examples/hooks/"* "$KIT/personal/hooks/"
  cp -r "$KIT/examples/skills/"* "$KIT/personal/skills/"
  chmod +x "$KIT"/personal/hooks/**/*.sh 2>/dev/null
  echo "✅ Örnekler personal'a kopyalandı"
  echo "   Düzenlemek için: $KIT/personal/"
else
  echo "⏭️  Atlandı, istediğinde manuel kopyalayabilirsin"
  echo "   examples/: $KIT/examples/"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Kurulum tamam!"
echo ""
echo "Terminali yeniden başlat, sonra:"
echo "  cd <proje klasörü>"
echo "  ios-kit setup"