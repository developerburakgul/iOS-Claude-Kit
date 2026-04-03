#!/bin/bash
# Klonladıktan sonra: bash ~/.ios-claude-kit/install.sh

KIT="$HOME/.ios-claude-kit"

# Hook'ları executable yap
chmod +x "$KIT"/hooks/**/*.sh
chmod +x "$KIT/bin/setup-project.sh"

# Shell alias ekle (.zshrc'ye)
ALIAS_LINE='alias ios-kit="bash $HOME/.ios-claude-kit/bin/ios-kit.sh"'
if ! grep -q "ios-kit" "$HOME/.zshrc" 2>/dev/null; then
  echo "\n# iOS Claude Kit\n$ALIAS_LINE" >> "$HOME/.zshrc"
  echo "✅ alias eklendi → ios-kit"
fi

echo "🎉 Kurulum tamam! Terminal'i yeniden başlat."