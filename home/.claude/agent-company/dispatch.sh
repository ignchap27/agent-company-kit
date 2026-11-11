#!/bin/bash
# Despachador: busca issues agent:ready (creadas por ti) en todos tus repos y lanza
# una sesión de Claude Code en segundo plano por issue, cada una en su worktree.
# Lo ejecuta launchd cada 10 min y /feature al crear una issue.
set -uo pipefail
export LC_ALL=en_US.UTF-8                     # launchd arranca con locale C; el slug necesita UTF-8
STATE="$HOME/.claude/agent-company"
ROOT="${AGENT_REPOS_DIR:-$HOME/Developer}"   # dónde viven (o se clonan) tus repos
MAX="${AGENT_MAX_WIP:-2}"                     # sesiones de agentes simultáneas
mkdir "$STATE/.lock" 2>/dev/null || exit 0   # ponytail: lock por mkdir; si queda huérfano tras un kill -9, bórralo a mano
trap 'rmdir "$STATE/.lock"' EXIT
[ -e "$STATE/STOP" ] && exit 0

me=$(gh api user -q .login) || exit 1
owners="${AGENT_OWNERS:-$me}"                 # añade orgs: AGENT_OWNERS="yo mi-org"
log() { echo "$(date '+%F %T') $*"; }
# Aviso en el Mac y en el móvil. El push sale de una sesión mínima (con Remote Control) en un repo con trust.
# ponytail: una sesión haiku por aviso; vale porque solo avisa de feature terminado o bloqueos.
notify() {
  osascript -e "display notification \"$1\" with title \"Agentes\"" 2>/dev/null
  (cd "$2" && claude --bg --model haiku --name aviso \
    "Envía al dueño una notificación push al móvil con la herramienta PushNotification (cárgala con ToolSearch) con este texto exacto y termina: $1") >/dev/null 2>&1
}

# 1. Limpieza: worktrees de PRs ya mergeados o cerrados.
for wt in "$ROOT"/*/.claude/worktrees/issue-*; do
  [ -d "$wt" ] || continue
  repo_dir=${wt%/.claude/worktrees/*}; branch=$(git -C "$wt" branch --show-current)
  state=$(cd "$repo_dir" && gh pr view "$branch" --json state -q .state 2>/dev/null)
  if [ "$state" = MERGED ] || [ "$state" = CLOSED ]; then
    git -C "$repo_dir" worktree remove --force "$wt" && git -C "$repo_dir" branch -D "$branch" >/dev/null
    log "limpio $wt ($state)"
  fi
done
# Recolector: para (stop, no rm: la conversación se conserva) las sesiones en segundo plano
# inactivas cuyo worktree ya se limpió y los avisos terminados; luego poda la oficina.
claude agents --json 2>/dev/null | python3 -c '
import json, os, sys
for s in json.load(sys.stdin):
    if s.get("kind") == "background" and s.get("status") == "idle" and (s.get("name") == "aviso" or not os.path.isdir(s["cwd"])):
        print(s["id"])' | while read -r id; do claude stop "$id" >/dev/null 2>&1 && log "paro sesión inactiva $id"; done
"$STATE/board/office-gc.sh" 2>/dev/null | while read -r l; do log "$l"; done

# 2. Stacked PRs aprobados por el pipeline (etiqueta agent:stacked-ready): el despachador, no un agente,
#    los mergea en su rama de integración (merge-stacked.sh se niega con la rama por defecto),
#    cierra su sub-issue y, si era la última, abre el PR final a la rama por defecto para el dueño.
final_pr() {   # repo issue rama_integracion dir
  local repo=$1 n=$2 base=$3 dir=$4 parent def title subs url sha caps="" pbase
  parent=$(gh issue view "$n" -R "$repo" --json body -q .body | grep -Eo 'Parte de #[0-9]+' | head -1 | grep -Eo '[0-9]+')
  [ -n "$parent" ] || return 0
  # gh issue list (sin --search) no depende del índice de búsqueda: ve el cierre recién hecho.
  sel="select(.body | test(\"Parte de #$parent([^0-9]|\$)\"))"
  [ "$(gh issue list -R "$repo" --state open --limit 300 --json body -q "[.[] | $sel] | length")" = 0 ] || return 0
  def=$(gh repo view "$repo" --json defaultBranchRef -q .defaultBranchRef.name)
  title=$(gh issue view "$parent" -R "$repo" --json title -q .title)
  subs=$(gh issue list -R "$repo" --state closed --limit 300 --json number,title,body -q "[.[] | $sel | \"- #\(.number) \(.title)\"] | join(\"\n\")")
  # Epic anidado (la madre es a su vez sub-issue con "Base:"): su rama vuelve a la integración de arriba como
  # un apilado más; la próxima pasada lo mergea, cierra la madre y sube un nivel con final_pr.
  pbase=$(gh issue view "$parent" -R "$repo" --json body -q .body | grep -Eo '^Base: [^ ]+' | head -1 | cut -d' ' -f2)
  if [ -n "$pbase" ]; then
    [ -z "$(gh pr list -R "$repo" --head "$base" --base "$pbase" --state all --json number -q '.[].number')" ] || return 0
    url=$(gh pr create -R "$repo" --head "$base" --base "$pbase" --title "$title (#$parent)" --label agent:stacked-ready \
      --body "$(printf 'Closes #%s\n\nSub-epic completo, cada parte ya pasó el pipeline:\n\n%s' "$parent" "$subs")") || return 0
    log "PR de sub-epic $url"; return 0
  fi
  # PR final ya abierto: lo que se acaba de mergear eran correcciones del dueño (/corregir); el PR ya las tiene.
  url=$(gh pr list -R "$repo" --head "$base" --base "$def" --state open --json url -q '.[0].url')
  if [ -n "$url" ]; then
    gh pr comment "$url" --body "Correcciones aplicadas (#$n). Listo para otra revisión." >/dev/null
    notify "Correcciones aplicadas, listo para revisar: $url" "$dir"; return 0
  fi
  # Capturas que dejó el designer en la rama de integración, fijadas al commit para que sobrevivan al borrado de la rama.
  git -C "$dir" fetch -q origin "$base" && sha=$(git -C "$dir" rev-parse FETCH_HEAD) && \
  caps=$(git -C "$dir" ls-tree --name-only "$sha" docs/capturas/ | grep -i '\.png$' | while read -r f; do
    printf '![%s](https://github.com/%s/blob/%s/%s?raw=true)\n' "$(basename "$f" .png)" "$repo" "$sha" "$f"; done)
  url=$(gh pr create -R "$repo" --head "$base" --base "$def" --title "$title (#$parent)" \
    --body "$(printf 'Closes #%s\n\nFeature completo. Cada sub-issue pasó QA, diseño, revisión y calidad, y se mergeó en `%s`:\n\n%s\n\n%s\n\nRevisa y mergea tú.' "$parent" "$base" "$subs" "${caps:+## Capturas
$caps}")") || return 0
  gh label create agent:review -R "$repo" --force >/dev/null
  gh issue edit "$parent" -R "$repo" --remove-label agent:epic --add-label agent:review >/dev/null
  log "PR final $url"; notify "Feature completo para tu revisión: $url" "$dir"
}
# gh pr list y no gh search: el agente etiqueta y llama al despachador al instante, y la búsqueda tarda en ver la etiqueta.
# Los PRs apilados salen siempre de un worktree, así que basta mirar los repos que tienen worktrees.
gh_prs() { for d in "$ROOT"/*/.claude/worktrees; do
  r=$(cd "${d%/.claude/worktrees}" 2>/dev/null && gh repo view --json nameWithOwner -q .nameWithOwner) || continue
  gh pr list -R "$r" --author "$me" --label agent:stacked-ready --json number -q ".[] | \"$r \\(.number)\""
done; }
while read -r repo pr <&3; do
  dir="$ROOT/${repo#*/}"
  issue=$(gh pr view "$pr" -R "$repo" --json body -q .body | grep -Eio 'closes #[0-9]+' | head -1 | grep -Eo '[0-9]+')
  base=$(gh pr view "$pr" -R "$repo" --json baseRefName -q .baseRefName)
  gh pr edit "$pr" -R "$repo" --remove-label agent:stacked-ready >/dev/null
  if "$STATE/merge-stacked.sh" "$pr" "$repo" >/dev/null; then
    log "mergeado $repo#$pr en $base"
    if [ -n "$issue" ]; then
      gh issue close "$issue" -R "$repo" -c "Mergeado en \`$base\` vía #$pr" >/dev/null
      gh issue edit "$issue" -R "$repo" --remove-label agent:in-progress >/dev/null
      final_pr "$repo" "$issue" "$base" "$dir"
    fi
  else
    log "ERROR mergeando $repo#$pr en $base"
    [ -n "$issue" ] && gh issue edit "$issue" -R "$repo" --remove-label agent:in-progress --add-label agent:blocked >/dev/null
    notify "No pude mergear $repo#$pr en $base (¿conflictos?). Issue bloqueada." "$dir"
  fi
done 3< <(gh_prs)

# 2b. Feedback del dueño: un comentario suyo que empieza por /corregir en un PR que espera su revisión
#     (su issue tiene agent:review) se vuelve una issue de corrección sobre la rama del PR. Pasa el
#     pipeline, vuelve como apilado y el PR se actualiza solo. 👀 marca los comentarios ya convertidos.
while read -r repo pr <&3; do
  n=$(gh pr view "$pr" -R "$repo" --json body -q .body | grep -Eio 'closes #[0-9]+' | head -1 | grep -Eo '[0-9]+') || continue
  gh issue view "$n" -R "$repo" --json labels -q '.labels[].name' | grep -qx agent:review || continue
  gh label create agent:ready -R "$repo" --force >/dev/null
  head=$(gh pr view "$pr" -R "$repo" --json headRefName -q .headRefName)
  while read -r cid <&4; do
    body=$(gh api "repos/$repo/issues/comments/$cid" -q .body)
    url=$(gh issue create -R "$repo" --label agent:ready --title "fix: correcciones del dueño en #$pr" --body "$(printf \
      'Parte de #%s\nBase: %s\n\nCorrecciones que pide el dueño al revisar #%s. Las imágenes son capturas suyas de lo que está mal o de cómo lo quiere: míralas antes de escribir el spec.\n\n%s' \
      "$n" "$head" "$pr" "${body#/corregir}")") || continue
    gh api -X POST "repos/$repo/issues/comments/$cid/reactions" -f content=eyes >/dev/null
    gh pr comment "$pr" -R "$repo" --body "Recibido. Los agentes lo corrigen en $url; este PR se actualiza solo al terminar y te aviso." >/dev/null
    log "feedback de $repo#$pr → $url"
  done 4< <(gh api "repos/$repo/issues/$pr/comments" --paginate \
    -q ".[] | select(.user.login == \"$me\" and (.body | startswith(\"/corregir\")) and .reactions.eyes == 0) | .id")
done 3< <(for o in $owners; do gh search prs --owner "$o" --author "$me" --state open --json number,repository \
  -q '.[] | "\(.repository.nameWithOwner) \(.number)"'; done)

# 3. Cupo disponible.
q() { for o in $owners; do gh search issues --owner "$o" --author "$me" --state open --label "$1" \
        --sort created --order asc --limit 50 --json number,repository,title,labels \
        -q '.[] | "\(.repository.nameWithOwner) \(.number) \(
              if (.title | test("^(feat|fix|chore|refactor|docs|test|perf|ci|build)\\b")) then (.title | capture("^(?<t>[a-z]+)").t)
              elif ([.labels[].name] | index("bug")) then "fix" else "feat" end) \(.title)"'; done; }
# Rama coloquial: feat/12-panel-admin (sin el prefijo Conventional del título).
branch_for() { printf '%s/%s-%s' "$1" "$2" "$(sed -E 's/^[a-z]+(\([^)]*\))?!?: *//' <<<"$3" | sed "y/áéíóúüñÁÉÍÓÚÜÑ/aeiouunAEIOUUN/" \
  | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed -E 's/^-+//' | cut -c1-40 | sed -E 's/-+$//')"; }
# /feature pasa "owner/repo n": la issue recién creada tarda en aparecer en la búsqueda de GitHub.
if [ $# -eq 2 ]; then
  for _ in $(seq 24); do q agent:ready | grep -q "^$1 $2 " && break; sleep 5; done
fi
running=$(q agent:in-progress | wc -l | tr -d ' ')
slots=$((MAX - running)); [ "$slots" -le 0 ] && exit 0

# 4. Despachar.
# La lista va por el descriptor 3: claude/gh dentro del bucle leen stdin y se comerían el resto.
while read -r repo n type title <&3; do
  [ "$slots" -le 0 ] && break
  # Sub-issues de un SPLIT: esperar a que se cierren las issues de las que dependen.
  body=$(gh issue view "$n" -R "$repo" --json body -q .body)
  deps=$(grep -Eo 'Depende de #[0-9]+' <<<"$body" | grep -Eo '[0-9]+')
  base=$(grep -Eo '^Base: [^ ]+' <<<"$body" | head -1 | cut -d' ' -f2)   # sub-issue apilada: parte de la rama de integración
  for d in $deps; do [ "$(gh issue view "$d" -R "$repo" --json state -q .state)" = CLOSED ] || continue 2; done
  slots=$((slots - 1))
  dir="$ROOT/${repo#*/}"   # ponytail: colisión si dos owners tienen un repo con el mismo nombre
  [ -d "$dir/.git" ] || gh repo clone "$repo" "$dir" -- -q || continue
  wt="$dir/.claude/worktrees/issue-$n"
  git -C "$dir" fetch -q origin && git -C "$dir" remote set-head origin -a >/dev/null
  grep -qx '.claude/worktrees/' "$dir/.git/info/exclude" 2>/dev/null || echo '.claude/worktrees/' >>"$dir/.git/info/exclude"
  [ -d "$wt" ] || git -C "$dir" worktree add -q -b "$(branch_for "$type" "$n" "$title")" "$wt" "origin/${base:-HEAD}" || continue
  gh label create agent:in-progress -R "$repo" --force >/dev/null
  gh issue edit "$n" -R "$repo" --remove-label agent:ready --add-label agent:in-progress >/dev/null || continue
  (cd "$wt" && claude --bg --model sonnet --name "${repo#*/}#$n" --settings "$STATE/bg-settings.json" "/run-issue $n") \
    && log "despachado $repo#$n" \
    || { log "ERROR despachando $repo#$n (¿repo sin trust? abre 'claude' una vez en $dir)"
         gh issue edit "$n" -R "$repo" --remove-label agent:in-progress --add-label agent:ready >/dev/null
         osascript -e "display notification \"No pude lanzar $repo#$n: abre claude una vez en $dir\" with title \"Agentes\""; }
done 3< <(q agent:ready)
