#!/bin/bash
# Mergea un PR apilado (stacked) en su rama de integración, autorizado por el dueño.
# Se niega si el PR apunta a la rama por defecto: ese merge es solo del dueño.
# Uso: merge-stacked.sh <pr> <owner/repo>
set -euo pipefail
pr=$1; repo=$2
base=$(gh pr view "$pr" -R "$repo" --json baseRefName -q .baseRefName)
def=$(gh repo view "$repo" --json defaultBranchRef -q .defaultBranchRef.name)
[ "$base" != "$def" ] || { echo "merge-stacked: el PR #$pr apunta a $def; ese merge es del dueño" >&2; exit 2; }
gh pr ready "$pr" -R "$repo" >/dev/null 2>&1 || true   # ya listo = no-op
gh pr merge "$pr" -R "$repo" --squash
