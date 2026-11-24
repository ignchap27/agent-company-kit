#!/bin/zsh -l
# Reinicio diario del asistente de Telegram (lo llama launchd a las 4 am): contexto limpio, la memoria vive en el repo.
tmux kill-session -t asistente 2>/dev/null
sleep 2
exec ~/.claude/agent-company/asistente.sh
