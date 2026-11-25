#!/bin/bash
# PreToolUse(Read): prohibido abrir imágenes de más de 1600 px; cada una se queda en el contexto.
path=$(jq -r '.tool_input.file_path // ""')
case "$(tr "[:upper:]" "[:lower:]" <<<"$path")" in *.png|*.jpg|*.jpeg|*.webp|*.gif) ;; *) exit 0 ;; esac
[ -f "$path" ] || exit 0
max=$(sips -g pixelWidth -g pixelHeight "$path" 2>/dev/null | awk '/pixel/ {if ($2 > m) m = $2} END {print m + 0}')
[ "$max" -le 1600 ] && exit 0
echo "BLOQUEADO por no-big-images.sh: $path mide ${max}px. Redimensiona antes: sips -Z 768 \"$path\" --out /tmp/\$(basename \"$path\") y lee esa, o captura por viewport/sección en vez de fullPage." >&2
exit 2
