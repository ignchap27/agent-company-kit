#!/bin/bash
# Instala la empresa de agentes a nivel usuario: enlaces simbólicos en ~/.claude
# (editar el kit = editar lo instalado) y el despachador en launchd.
# No toca ~/.claude/settings.json: los permisos y hooks de los agentes van en
# bg-settings.json y solo se cargan en las sesiones que lanza el despachador.
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
for f in agents/tech-lead.md agents/backend-dev.md agents/frontend-dev.md agents/qa.md agents/reviewer.md agents/quality.md agents/designer.md \
         skills/feature skills/run-issue skills/onboard-repo skills/frontend-design skills/frontend-craft skills/backend-craft skills/emil-design-eng skills/animate skills/animation-performance skills/break-ui skills/ux-heuristics skills/vercel-react-best-practices hooks/guard.sh hooks/require-green.sh agent-company; do
  dst="$HOME/.claude/$f"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then echo "ya existe y no es un enlace, lo salto: $dst"; continue; fi
  ln -sfn "$KIT/home/.claude/$f" "$dst"
done
chmod +x "$KIT"/home/.claude/hooks/*.sh "$KIT"/home/.claude/agent-company/dispatch.sh "$KIT"/home/.claude/agent-company/merge-stacked.sh "$KIT"/home/.claude/agent-company/board/start.sh

if [ "${1:-}" = "--with-launchd" ]; then
  plist="$HOME/Library/LaunchAgents/com.agent-company.dispatch.plist"
  cp "$KIT/launchd/com.agent-company.dispatch.plist" "$plist"
  launchctl bootout "gui/$(id -u)" "$plist" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$plist"
  echo "despachador activo cada 10 min (log: /tmp/agent-company-dispatch.log)"
fi
echo "listo. Prueba: abre claude en un repo y ejecuta /onboard-repo"
