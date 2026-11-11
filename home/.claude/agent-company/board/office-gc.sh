#!/bin/bash
# Recolector de la oficina: quita de Pixel Agents los agentes cuyo transcript lleva más de
# OFFICE_GC_MIN minutos (30) sin escribirse, o ya no existe. Solo toca el estado de la oficina,
# nunca los transcripts ni las sesiones. Si no hay nada que quitar, no reinicia nada.
set -euo pipefail
state="$HOME/.pixel-agents/standalone-state.json"
[ -f "$state" ] || exit 0
prune() {  # $1=check: solo cuenta; $1=apply: reescribe el estado
  python3 - "$state" "${OFFICE_GC_MIN:-30}" "$1" <<'PY'
import json, os, sys, time
path, mins, mode = sys.argv[1], float(sys.argv[2]), sys.argv[3]
d = json.load(open(path))
def alive(a):
    f = a.get("jsonlFile", "")
    return os.path.exists(f) and time.time() - os.path.getmtime(f) < mins * 60
keep = [a for a in d["agents"] if alive(a)]
gone = len(d["agents"]) - len(keep)
if mode == "apply" and gone:
    ids = {str(a["id"]) for a in keep}
    d["agents"], d["seats"] = keep, {k: v for k, v in d["seats"].items() if k in ids}
    tmp = path + ".tmp"
    json.dump(d, open(tmp, "w"))
    os.replace(tmp, path)
print(gone)
PY
}
# Sin nada que podar, solo se asegura de que tablero y oficina estén arriba (start.sh no toca lo que ya corre).
n=$(prune check); [ "$n" -gt 0 ] || exec "$(dirname "$0")/start.sh" >/dev/null 2>&1 </dev/null
# Pixel Agents guarda su estado en memoria y lo reescribe: hay que pararlo antes de podar.
pkill -f 'pixel-agents --port 4510' || true
for _ in 1 2 3 4 5; do pgrep -f 'pixel-agents --port 4510' >/dev/null || break; sleep 1; done
prune apply >/dev/null
echo "oficina: quitados $n agentes inactivos"
"$(dirname "$0")/start.sh" >/dev/null 2>&1 </dev/null  # sin heredar la tubería del despachador: si no, la deja abierta y lo cuelga
