#!/bin/bash
# Analiza el worktree actual con el SonarQube local y reporta solo los issues en las
# líneas que cambió la rama respecto a la base (origin/HEAD, o la rama de integración en sub-issues apiladas).
# Uso: sonar-scan.sh [rama base]
# Salida: 0 sin issues graves · 1 hay issues graves (JSON en stdout) · 2 no se pudo analizar.
set -uo pipefail
S="$HOME/.claude/agent-company/sonar"
URL=http://127.0.0.1:9000
SCANNER=sonarsource/sonar-scanner-cli:12.2.0.4256_8.1.0
fail() { echo "sonar-scan: $1" >&2; exit 2; }
base="origin/${1:-HEAD}"

docker info >/dev/null 2>&1 || fail "Docker no está corriendo"
root=$(git rev-parse --show-toplevel) || fail "no es un repo git"
key="$(basename "$(git rev-parse --path-format=absolute --git-common-dir | xargs dirname)")-$(basename "$root")"

# 1. Servidor arriba (la primera vez tarda 1–2 min).
docker compose -f "$S/compose.yaml" -p agent-company-sonar up -d >&2 || fail "no pude levantar SonarQube"
for _ in $(seq 60); do
  curl -s "$URL/api/system/status" | grep -q '"status":"UP"' && break; sleep 5
done
curl -s "$URL/api/system/status" | grep -q '"status":"UP"' || fail "SonarQube no arrancó (docker logs agent-company-sonarqube)"

# 2. Credenciales propias la primera vez: contraseña de admin aleatoria y token, solo en $S.
if [ ! -s "$S/token" ]; then
  umask 077
  pass="$(openssl rand -base64 24 | tr -d '/+=')Aa1!"
  curl -sf -u admin:admin -X POST "$URL/api/users/change_password" \
    --data-urlencode login=admin --data-urlencode previousPassword=admin --data-urlencode "password=$pass" \
    || fail "admin ya no usa la contraseña por defecto; crea un token a mano y guárdalo en $S/token"
  echo "$pass" >"$S/admin-password"
  curl -sf -u "admin:$pass" -X POST "$URL/api/user_tokens/generate" --data-urlencode name=agents \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])' >"$S/token" || fail "no pude crear el token"
fi
token=$(cat "$S/token")

# 3. Análisis. Sin SCM (el .git del worktree apunta fuera del contenedor) y sin ensuciar el árbol.
docker run --rm -e SONAR_HOST_URL=http://host.docker.internal:9000 -e SONAR_TOKEN="$token" \
  -v "$root:/usr/src" "$SCANNER" -Dsonar.projectKey="$key" -Dsonar.scm.disabled=true \
  -Dsonar.working.directory=/tmp/scannerwork -Dsonar.qualitygate.wait=true \
  -Dsonar.exclusions='**/node_modules/**,**/dist/**,**/build/**,**/.venv/**,**/*.min.js' \
  >/tmp/agent-company-sonar-"$key".log 2>&1
# El gate global puede fallar por código ajeno a la rama: basta con que el reporte esté procesado; el filtro decide.
grep -q "QUALITY GATE STATUS:" /tmp/agent-company-sonar-"$key".log || fail "falló el análisis (log: /tmp/agent-company-sonar-$key.log)"

# 4. Issues abiertos → solo los de líneas cambiadas.
# ponytail: una página de 500 issues; paginar si un repo supera eso.
tmp=$(mktemp)
curl -sf -u "$token:" "$URL/api/issues/search?components=$key&resolved=false&ps=500" \
  | python3 -c 'import json,sys; json.dump(json.load(sys.stdin)["issues"], sys.stdout)' >"$tmp" || fail "no pude leer los issues"
git -C "$root" diff -U0 "$base"...HEAD | python3 "$S/filter.py" "$tmp"; rc=$?
rm -f "$tmp"
echo "Proyecto: $URL/dashboard?id=$key" >&2
exit $rc
