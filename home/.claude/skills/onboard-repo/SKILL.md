---
name: onboard-repo
description: Prepara un repo para la empresa de agentes - si está vacío lo arranca con el stack por defecto; detecta stack y comandos, escribe CLAUDE.md y .claude/verify.sh, y abre un PR normal con ello.
disable-model-invocation: true
---

Prepara el repo actual para que los agentes trabajen en él.

0. **Repo vacío o sin frontend ni manifiestos:** pregúntame qué es el proyecto (una frase) y si lleva frontend. Si lo lleva, arráncalo con el stack por defecto: React + Vite + TypeScript + `motion` (`npm create vite@<versión> . -- --template react-ts`, luego `npm install --save-exact motion` y vitest + @testing-library/react como devDependencies). Versiones exactas: la última estable publicada hace al menos 2 semanas (`npm view <pkg> time`). Deja un test de ejemplo que pase y un `.gitignore`. Nada más: sin router, estado global ni UI kit hasta que una issue lo pida.
1. Detecta stack y comandos reales de lint, typecheck, tests y e2e (manifiestos, Makefile, CI en `.github/workflows/`). Ejecútalos una vez para confirmar que funcionan; anota los que fallan ya en la rama por defecto.
2. Escribe `CLAUDE.md` tú: secciones `## Comandos` (los confirmados), `## Estructura`, `## Convenciones` (lo que observes: estilo de tests, librerías, idioma del código, formato de commits) y `## Fuera de alcance` si lo sabes. Menos de 100 líneas. Si ya existe, compleméntalo sin borrar. Si no existe pero hubo uno (`git log --diff-filter=D --format=%h -1 -- CLAUDE.md`), léelo con `git show <hash>^:CLAUDE.md` y conserva las reglas y decisiones que sigan siendo ciertas (no se deducen del código), diciéndome cuáles mantuviste y cuáles descartaste.
3. Crea `.claude/verify.sh` ejecutable: corre lint + typecheck + tests rápidos (sin e2e) y sale con código ≠ 0 si algo falla. Es lo que el hook de los devs ejecuta antes de dejarles terminar. Si los comandos necesitan `.env` y este no se versiona, que el script lo copie del checkout principal cuando falte (`git worktree list | head -1`).
4. Muéstrame el diff y espera mi OK; luego rama `chore/agents-onboarding`, commit y `gh pr create`.
5. Dime qué falta para el resto del pipeline: ¿hay CI en PRs? ¿hay Sonar (`sonar-project.properties`)? Si no, el reviewer revisa estilo Sonar y QA exige cobertura ≥ 90 % del código cambiado. ¿Hay tests en todas las áreas? Sin tests, el tech-lead escalará cada issue.
