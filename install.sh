#!/bin/bash
# Instala la empresa de agentes a nivel usuario: enlaces simbólicos en ~/.claude
# (editar el kit = editar lo instalado) y el despachador en launchd.
# No toca ~/.claude/settings.json: los permisos y hooks de los agentes van en
# bg-settings.json y solo se cargan en las sesiones que lanza el despachador.
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
for f in agents/tech-lead.md agents/backend-dev.md agents/frontend-dev.md agents/qa.md agents/reviewer.md agents/quality.md agents/designer.md agents/asistente.md \
         skills/feature skills/run-issue skills/onboard-repo skills/frontend-design skills/frontend-craft skills/backend-craft skills/emil-design-eng skills/animate skills/animation-performance skills/break-ui skills/ux-heuristics skills/vercel-react-best-practices hooks/guard.sh hooks/require-green.sh agent-company; do
  dst="$HOME/.claude/$f"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then echo "ya existe y no es un enlace, lo salto: $dst"; continue; fi
  ln -sfn "$KIT/home/.claude/$f" "$dst"
done
chmod +x "$KIT"/home/.claude/hooks/*.sh "$KIT"/home/.claude/agent-company/dispatch.sh "$KIT"/home/.claude/agent-company/merge-stacked.sh "$KIT"/home/.claude/agent-company/board/start.sh "$KIT"/home/.claude/agent-company/asistente.sh

load() {
  plist="$HOME/Library/LaunchAgents/$1.plist"
  cp "$KIT/launchd/$1.plist" "$plist"
  launchctl bootout "gui/$(id -u)" "$plist" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$plist"
}
for arg in "$@"; do
  case "$arg" in
    --with-launchd)
      load com.agent-company.dispatch
      echo "despachador activo cada 10 min (log: /tmp/agent-company-dispatch.log)" ;;
    --with-asistente)
      command -v tmux >/dev/null || { echo "falta tmux: brew install tmux"; exit 1; }
      [ -d "$HOME/segundo-cerebro" ] || { echo "falta ~/segundo-cerebro: ver README, sección Asistente"; exit 1; }
      load com.agent-company.asistente
      load com.agent-company.asistente-lint
      echo "asistente activo (tmux attach -t asistente; log: /tmp/agent-company-asistente.log)" ;;
  esac
done
echo "listo. Prueba: abre claude en un repo y ejecuta /onboard-repo"
