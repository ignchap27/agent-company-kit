#!/bin/bash
# Stop de backend-dev/frontend-dev (corre como SubagentStop): si el repo tiene
# .claude/verify.sh y falla, el dev no puede terminar. Una sola insistencia.
input=$(cat)
[ "$(jq -r '.stop_hook_active' <<<"$input")" = "true" ] && exit 0
cd "$(jq -r '.cwd // "."' <<<"$input")" || exit 0
[ -x .claude/verify.sh ] || exit 0
if ! out=$(./.claude/verify.sh 2>&1); then
  jq -n --arg r ".claude/verify.sh falla. Corrige antes de terminar:
$(tail -n 40 <<<"$out")" '{decision:"block", reason:$r}'
fi
exit 0
