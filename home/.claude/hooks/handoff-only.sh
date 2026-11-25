#!/bin/bash
# PreToolUse(Write) de los agentes de solo lectura: solo pueden escribir su handoff.
# Argumentos opcionales: carpetas extra permitidas (el designer: design).
path=$(jq -r '.tool_input.file_path // ""')
[[ "$path" == *..* ]] && { echo "BLOQUEADO por handoff-only.sh: ruta con .." >&2; exit 2; }
for dir in handoff "$@"; do
  case "$path" in "$dir"/*|*/"$dir"/*) exit 0 ;; esac
done
echo "BLOQUEADO por handoff-only.sh: este agente solo escribe en handoff/" >&2
exit 2
