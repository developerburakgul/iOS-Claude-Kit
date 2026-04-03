#!/bin/bash
# core/hooks/stop/notify-waiting.sh
# Claude cevabını bitirip kullanıcıdan input beklediğinde macOS bildirimi gönderir.

osascript -e 'display notification "Cevap hazır, seni bekliyor." with title "Claude Code" sound name "Glass"'
