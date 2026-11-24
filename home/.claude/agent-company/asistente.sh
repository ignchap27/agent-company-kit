#!/bin/zsh -l
# Mantiene vivo el asistente de Telegram en la sesión tmux "asistente" (lo llama launchd).
# Ver en vivo: tmux attach -t asistente   (salir sin pararlo: Ctrl-b d)
tmux has-session -t asistente 2>/dev/null && exit 0
tmux new-session -d -s asistente -c ~/Developer/segundo-cerebro \
  'while true; do CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=30 claude --agent asistente --permission-mode auto --channels plugin:telegram@claude-plugins-official; sleep 5; done'
