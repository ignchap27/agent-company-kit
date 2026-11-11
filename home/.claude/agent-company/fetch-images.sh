#!/bin/bash
# Descarga las imágenes del cuerpo de una issue (las que adjuntó el dueño en GitHub) y imprime sus rutas.
# En repos privados esas URLs piden sesión: se usa el token de gh, solo hacia github.com.
# Uso: fetch-images.sh <owner/repo> <issue>
set -euo pipefail
repo=$1 n=$2 out="${TMPDIR:-/tmp}/feedback-${repo//\//-}-$n"
mkdir -p "$out"
i=0
gh issue view "$n" -R "$repo" --json body -q .body |
  grep -Eo 'https://(github\.com/user-attachments/assets/[A-Za-z0-9-]+|(private-)?user-images\.githubusercontent\.com/[^ )"]+)' |
  sort -u | while read -r url; do
    i=$((i + 1)); f="$out/imagen-$i"
    curl -fsSL -H "Authorization: Bearer $(gh auth token)" -o "$f" "$url" || { echo "no pude bajar $url" >&2; continue; }
    ext=$(file -b --mime-type "$f" | cut -d/ -f2); mv "$f" "$f.$ext"; echo "$f.$ext"
  done
