#!/bin/bash
# PreToolUse(Write|Edit) de los agentes de solo lectura: solo pueden escribir su handoff.
path=$(jq -r '.tool_input.file_path // ""')
[[ "$path" == *..* ]] && { echo "BLOQUEADO por handoff-only.sh: ruta con .." >&2; exit 2; }
case "$path" in
  handoff/*|*/handoff/*) exit 0 ;;
esac
echo "BLOQUEADO por handoff-only.sh: este agente solo escribe en handoff/" >&2
exit 2
