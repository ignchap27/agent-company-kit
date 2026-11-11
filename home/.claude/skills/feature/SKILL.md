---
name: feature
description: Entrada del dueño. Convierte una descripción de feature en una issue agent:ready en el repo indicado (o el actual) y despacha a los agentes.
argument-hint: "[owner/repo] <descripción del feature>"
disable-model-invocation: true
allowed-tools: Bash(gh *), Bash(~/.claude/agent-company/dispatch.sh *)
---

Entrada: $ARGUMENTS

1. Repo destino: si la entrada empieza por `owner/repo` o por el nombre de un repo, úsalo; si no, el repo del directorio actual (`gh repo view --json nameWithOwner -q .nameWithOwner`). Si no hay ninguno, pregúntame cuál.
2. Redacta título (≤ 70 caracteres) y cuerpo: Contexto, Comportamiento esperado, Criterios de aceptación tentativos, Fuera de alcance, Dudas. No inventes requisitos: lo que no esté en mi descripción va a "Dudas".
3. Muéstrame repo, título y cuerpo, y sigue sin esperar confirmación (el dueño lo lanza desde agent view y revisa en el PR). Título con prefijo Conventional (`feat: …`, `fix: …`): de ahí sale el nombre de la rama.
4. Asegura las etiquetas y crea la issue:
   `for l in agent:ready agent:in-progress agent:review agent:blocked; do gh label create "$l" -R <repo> --force >/dev/null; done`
   `gh issue create -R <repo> --title "<título>" --body "<cuerpo>" --label agent:ready`
5. **Obligatorio, no lo omitas:** despacha ya sin esperar al ciclo con `~/.claude/agent-company/dispatch.sh <owner/repo> <n>` (espera hasta 2 min a que GitHub indexe la issue) y confirma con `gh issue view <n> -R <repo> --json labels` que pasó a `agent:in-progress` (si sigue en `agent:ready`, dímelo con la última línea de `/tmp/agent-company-dispatch.log`). Excepción: si en "Dudas" hay algo que cambia el alcance, no despaches y dime que responda en un comentario y abra `jefe`.
6. Devuelve la URL de la issue y dime que la sigo con `claude agents`.
