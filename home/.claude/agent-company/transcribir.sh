#!/bin/zsh
# Transcribe un audio con el Whisper local (contenedor agent-company-whisper). Uso: transcribir.sh <archivo> [idioma=es]
# Si el contenedor está parado lo levanta. Imprime solo el texto.
f="$1"; lang="${2:-es}"
[ -f "$f" ] || { echo "uso: transcribir.sh <archivo> [idioma]" >&2; exit 1; }
curl -sf -m 2 http://127.0.0.1:9100/docs >/dev/null || docker compose -f ~/.claude/agent-company/whisper/compose.yaml up -d >/dev/null
curl -sf -m 600 -F audio_file=@"$f" "http://127.0.0.1:9100/asr?language=$lang&output=txt&task=transcribe"
