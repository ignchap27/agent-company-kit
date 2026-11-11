#!/bin/bash
# PreToolUse(Bash) de las sesiones de agentes (cargado vía bg-settings.json).
# exit 2 + stderr = la llamada se bloquea y Claude recibe el motivo.
input=$(cat)
cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
agent=$(jq -r '.agent_type // ""' <<<"$input")

block() { echo "BLOQUEADO por guard.sh: $1" >&2; exit 2; }

grep -Eq 'gh +pr +(merge|review)' <<<"$cmd" && block "merge/aprobación es solo del dueño"
grep -Eq 'gh +api[^|;&]*pulls/[0-9]+/(merge|reviews)' <<<"$cmd" && block "merge/aprobación por API es solo del dueño"
grep -Eq 'git +push[^|;&]*(--force|-f( |$)|--delete|:refs/heads/(main|master))' <<<"$cmd" && block "push forzado/borrado"
grep -Eq 'git +push[^|;&]* (origin +)?(HEAD:)?(main|master|develop)( |$)' <<<"$cmd" && block "push directo a la rama principal"
grep -Eq -- '--no-verify' <<<"$cmd" && block "--no-verify"

# Subagentes de solo lectura: no pueden modificar el árbol ni el historial vía Bash.
case "$agent" in
  qa|quality|reviewer|tech-lead)
    sed -E 's#[0-9]?>+ */dev/null##g' <<<"$cmd" | grep -Eq '(^|[^>2&])>[^&>]|>>|sed +-i|tee |git +(add|commit|checkout|switch|reset|stash|rebase|merge|push|restore|apply)|rm +' \
      && block "el agente $agent es de solo lectura"
    ;;
esac
exit 0
