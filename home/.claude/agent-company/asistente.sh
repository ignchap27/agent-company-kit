#!/bin/bash
# Asistente de Telegram. launchd lo llama cada 5 min: si la sesión tmux "asistente"
# no existe (reinicio, crash), la levanta. `asistente.sh lint` = revisión nocturna del cerebro.
set -euo pipefail
SETTINGS="$HOME/.claude/agent-company/bg-settings.json"
cd "${ASISTENTE_DIR:-$HOME/Developer/segundo-cerebro}"

if [ "${1:-}" = lint ]; then
  exec claude -p --agent asistente --settings "$SETTINGS" \
    "Lint nocturno del segundo cerebro según CLAUDE.md, con commit y push. Nadie está en Telegram: no escribas por el canal."
fi

tmux has-session -t asistente 2>/dev/null && exit 0
# ponytail: una sola sesión de larga vida; si su contexto se llena, `tmux kill-session -t asistente` y launchd la relanza limpia.
tmux new-session -d -s asistente \
  "claude --agent asistente --channels plugin:telegram@claude-plugins-official --settings '$SETTINGS'"
