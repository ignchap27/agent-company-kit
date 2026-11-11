# Investigación: features de Claude Code y buenas prácticas

Diseño + kit listo para copiar · investigado el **2026-10-20** contra docs oficiales (code.claude.com) · Claude Code v2.1.2xx–2.1.30x.

> Convención: **[doc]** = feature documentada (con URL). **[comunidad]** = workaround. **[no verificado]** = deducción mía que hay que probar.

---

Este archivo conserva la investigación (Fases 1 y 2). El diseño vigente (local, multi-repo) está en `README.md`.

---

## Fase 1 — Features de Claude Code

| Feature | Qué es | Estado | Encaje en la arquitectura |
|---|---|---|---|
| **Subagentes** `.claude/agents/*.md` | Workers con contexto propio, tools, modelo y effort por agente. Frontmatter: `name`, `description` (obligatorios), `tools`, `disallowedTools`, `model` (`sonnet/opus/haiku/fable`/ID/`inherit`), `effort` (`low…max`), `isolation: worktree`, `permissionMode`, `hooks`, `skills`, `mcpServers`, `memory`, `maxTurns`, `background`, `color`… Anidación hasta 3 niveles (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`), 20 concurrentes por defecto. `Stop` en frontmatter se convierte en `SubagentStop`. | GA [doc](https://code.claude.com/docs/en/sub-agents) | **Núcleo**: cada rol del organigrama es un subagente. |
| `isolation: worktree` | Worktree temporal, rama desde la default branch (no desde el HEAD del padre); se limpia si no hay cambios. | GA [doc](https://code.claude.com/docs/en/sub-agents) | **No lo uso para los devs**: un reintento crearía un worktree nuevo desde `main` y perdería el trabajo previo. La VM cloud por issue ya da el aislamiento. Úsalo si corres varias issues en local: `claude --worktree "#1234"` [doc](https://code.claude.com/docs/en/worktrees). |
| **Agent teams** | Lead + teammates con task list compartida y mailbox (`SendMessage`). | **Experimental**, off por defecto (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`). No funciona en `-p`/SDK; `/resume` no restaura teammates; sin worktrees por teammate; ~7× tokens en plan mode. [doc](https://code.claude.com/docs/en/agent-teams), [costos](https://code.claude.com/docs/en/costs) | **Descartado** para el loop 24/7: el flujo es secuencial (spec→dev→QA) y no necesita debate entre agentes. |
| **Mensajería entre sesiones** (`ListAgents`/`SendMessage`) | Mensajes de texto entre tus sesiones: locales por socket; otras máquinas/cloud vía Anthropic con Remote Control. Una sesión cloud **no puede responder** con `SendMessage`. `crossSessionInbound`: `accept/hold/refuse`. | GA, v2.1.224+ [doc](https://code.claude.com/docs/en/cross-session-messaging) | Opcional. No hace falta: el estado vive en GitHub (labels, comentarios, PR). |
| **Agent view** `claude agents` | Pantalla para lanzar/monitorizar sesiones en segundo plano **locales** (`claude --bg "…"`), cada una en su worktree. | Research preview [doc](https://code.claude.com/docs/en/agent-view) | Alternativa local al cloud; no muestra sesiones cloud. |
| **Projects** | Una conversación que lanza "threads" (sesiones cloud) paralelos con instrucciones y memoria compartidas. | Public beta, solo Pro/Max, rollout gradual [doc](https://code.claude.com/docs/en/claude-projects) | Buena opción manual si la tienes; no es programable como cola. |
| **Dynamic workflows** | Script que orquesta muchos subagentes y cruza resultados. `/workflows`. | Doc [doc](https://code.claude.com/docs/en/workflows) | Para auditorías/migraciones masivas, no para este flujo. |
| **Skills** `.claude/skills/<n>/SKILL.md` | Instrucciones/slash commands. Frontmatter: `description`, `argument-hint`, `disable-model-invocation`, `allowed-tools`, `model`, `effort`, `context: fork`, `agent`, `hooks`… `$ARGUMENTS`, `$0`. `.claude/commands/*.md` sigue funcionando. | GA [doc](https://code.claude.com/docs/en/skills) | `/feature` (entrada) y `/run-issue` (pipeline). |
| **Plugins / marketplaces** | Empaquetan skills, agentes, hooks, MCP y mods; se instalan con `/plugin install x@marketplace`. | GA [doc](https://code.claude.com/docs/en/plugins/overview) | Fase 3: empaquetar `template/.claude` como plugin para reutilizar en varios repos. |
| **Mods** | Plugins JS/TS que corren *dentro* de Claude Code: panes, bandas sobre el prompt, comandos sin turno, interceptar tool calls, timers, mensajes a otras sesiones. Dibujan en CLI/Desktop/VS Code; **no dibujan en `-p` ni en sesiones cloud** (los hooks sí corren). v2.1.287+. Sin sandbox. | Doc [overview](https://code.claude.com/docs/en/plugins/mods/overview), [API](https://code.claude.com/docs/en/plugins/mods/api) | **Tablero de control posible pero opcional**: un pane local que liste issues `agent:*`/PRs vía `gh api` en un timer. [no verificado] que un mod pueda leer el estado de sesiones cloud; usa GitHub como fuente. No lo pongas en el MVP. |
| **Hooks** (settings) | Eventos: `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Stop`, `SubagentStart/Stop`, `TaskCreated/Completed`, `TeammateIdle`, `WorktreeCreate`, `PreCompact`… Tipos `command/http/mcp_tool/prompt/agent`. Exit 2 bloquea; Stop acepta `{"decision":"block","reason":…}`; `stop_hook_active` evita bucles. | GA [doc](https://code.claude.com/docs/en/hooks) | `guard.sh` (PreToolUse) y `require-green.sh` (Stop de devs). |
| **Headless `claude -p`** | `--output-format json/stream-json`, `--json-schema`, `--max-turns`, `--max-budget-usd`, `--permission-mode auto/dontAsk/acceptEdits`, `--permission-prompts none`, `--bare`, `--resume`. Desde v2.1.302 arranca en Manual mode. | GA [doc](https://code.claude.com/docs/en/headless) | Plan B si montas tu propio runner (enfoque D). |
| **Agent SDK** (TS/Python) | El mismo loop de Claude Code como librería. | GA [doc](https://code.claude.com/docs/en/agent-sdk/overview) | Solo si necesitas orquestación propia. |
| **Managed Agents** (API) | Agente + entorno + sesión gestionados por Anthropic vía API (beta header `managed-agents-2026-04-01`). | Beta [doc](https://platform.claude.com/docs/en/managed-agents/overview) | Para producto propio; sus sesiones **no** aparecen en claude.ai/code [no verificado]. |
| **Sesiones cloud** | VM aislada por sesión; red Trusted por defecto; setup script cacheado; `gh`, Docker, Node/Python/Java… preinstalados. **GitHub GraphQL bloqueado** → `gh pr`/`gh issue` fallan; usar `gh api` REST. Commits con trailer `Claude-Session:` y link en el PR. `CLAUDE_CODE_REMOTE_SESSION_ID`. | GA (Pro/Max/Team/Ent) [doc](https://code.claude.com/docs/en/claude-code-on-the-web), [entornos](https://code.claude.com/docs/en/cloud-environments) | **Runtime del pipeline.** |
| **Scheduled tasks** (antes *routines*) | Prompt + repos + conectores; triggers: **schedule** (mín. 1 h), **API** (`POST …/routines/<id>/fire`, `text` llega como `<routine-fire-payload>` no confiable), **GitHub** (solo `pull_request` y `release`). Corren sin pedir permisos, **como tú** (commits/PRs con tu usuario). Límites: 100 runs/h por cuenta; 30/h por tarea para Run now+API. | **Research preview** [doc](https://code.claude.com/docs/en/routines) | **Motor del loop.** |
| **`/loop`, Desktop scheduled tasks** | Programación local dentro de una sesión / en la app. | Doc [doc](https://code.claude.com/docs/en/scheduled-tasks) | Alternativa si no quieres cloud. |
| **Remote Control** | Controla una sesión **local** desde web/móvil (`claude --remote-control`, `/rc`). | GA (Pro/Max/Team/Ent; no API keys) [doc](https://code.claude.com/docs/en/remote-control) | Para vigilar runs locales desde el móvil. |
| **Auto-fix de PRs** | Una sesión cloud vigila el PR y responde a fallos de CI y comentarios de review; `/autofix-pr` desde terminal. Requiere la Claude GitHub App. Responde **con tu cuenta**. | Doc [doc](https://code.claude.com/docs/en/claude-code-on-the-web#auto-fix-pull-requests) | Cierra el loop tras tu review. [no verificado] activarlo desde dentro de una ejecución programada. |
| **claude-code-action** `@v1` | Action de GitHub: modo interactivo (`@claude`) o automático (`prompt`). Inputs: `prompt`, `claude_args`, `anthropic_api_key`/`claude_code_oauth_token`, `plugins`, `settings`. Rechaza actores bot salvo `allowed_bots`. Actúa como la Claude GitHub App. | GA [doc](https://code.claude.com/docs/en/github-actions) | Enfoque C. Resultados en logs de Actions, **no** en claude.ai/code. |
| **Code Review** (app) | Review automática por PR con hallazgos inline; `REVIEW.md`. | Team/Enterprise [doc](https://code.claude.com/docs/en/code-review) | Opcional como segundo revisor. |
| **`/code-review`** y **`/code-review ultra`** | Local por niveles; *ultra* = flota de revisores en la nube con verificación, 15–25 min, 3 runs gratis (Pro/Max) y luego ~$5–25 en usage credits; `claude ultrareview <PR> --post`. Solo lo lanza el usuario. | Ultra: research preview [doc](https://code.claude.com/docs/en/ultrareview), [local](https://code.claude.com/docs/en/code-review-local) | Úsalo tú en PRs grandes antes de aprobar. No automatizable por el agente. |
| **MCP SonarQube** | `sonarsource/sonarqube-mcp` (Docker, stdio o HTTP). Env: `SONARQUBE_TOKEN` (user token), `SONARQUBE_URL` (Server), `SONARQUBE_ORG`, `SONARQUBE_PROJECT_KEY`, `SONARQUBE_READ_ONLY`, `SONARQUBE_TOOLSETS`. Tools: `get_project_quality_gate_status`, `search_sonar_issues_in_projects`, `show_rule`, `get_component_measures`… | Oficial SonarSource [repo](https://github.com/SonarSource/sonarqube-mcp-server) | Agente `quality`. |
| **MCP GitHub** | Remoto `https://api.githubcopilot.com/mcp/` (HTTP + Bearer PAT) o Docker `ghcr.io/github/github-mcp-server`; `GITHUB_TOOLSETS`, `--read-only`. | Oficial GitHub [repo](https://github.com/github/github-mcp-server) | Opcional en local; en cloud ya hay herramientas GitHub integradas + `gh api`. |
| Jira / Linear / Slack | Conectores de claude.ai (viajan por Anthropic, sin tocar el allowlist). | [doc](https://code.claude.com/docs/en/routines#connectors) | Slack para avisos; Jira/Linear si la cola vive allí. |
| **Permisos y modos** | `allow/ask/deny` con sintaxis `Bash(git push *)`; modos `default/acceptEdits/plan/auto/dontAsk/bypassPermissions`; precedencia managed > CLI > local > project > user. | GA [permisos](https://code.claude.com/docs/en/permissions), [modos](https://code.claude.com/docs/en/permission-modes), [settings](https://code.claude.com/docs/en/settings) | `deny` + hook como defensa en profundidad; la barrera real es GitHub. |
| **Visibilidad** | Sidebar de claude.ai/code; detalle de la tarea con lista de runs; `/schedule list`, `/schedule why did … ?`; `claude --teleport <id>`; `/tasks`; Desktop; app móvil. Estado verde = sin error de infraestructura, **no** = trabajo correcto. | [doc](https://code.claude.com/docs/en/routines#view-and-interact-with-runs) | Observabilidad principal. |
| **Costos** | Media empresas ~$13/dev/día activo; `/usage`; `total_cost_usd` en `-p --output-format json`; `--max-budget-usd`; OTel `claude_code.cost.usage`, `token.usage`, `pull_request.count`; límites de gasto por org/grupo/miembro (Team/Ent) o workspace (Console). | [doc](https://code.claude.com/docs/en/costs), [OTel](https://code.claude.com/docs/en/monitoring-usage) | Ver "Costos" abajo. |

---

## Fase 2 — Buenas prácticas aplicadas

| Práctica | Cómo queda en el kit |
|---|---|
| **CLAUDE.md corto** (<200 líneas; lo específico va a skills) [doc](https://code.claude.com/docs/en/costs#move-instructions-from-claudemd-to-skills) | `template/CLAUDE.md`: comandos vía `Makefile`, reglas duras, DoD, instrucciones de compactación. |
| **Spec-driven + TDD** [doc](https://code.claude.com/docs/en/best-practices) | tech-lead produce ACs verificables; los devs escriben primero el test que falla. |
| **PR pequeño** | Tope ~400 líneas; si no cabe, el tech-lead responde `SPLIT:` y se crean sub-issues. |
| **1 tarea = 1 rama = 1 entorno** | Rama `claude/issue-<n>` en una VM cloud propia. |
| **Quality gates** | CI: lint → typecheck → tests+cobertura → e2e → Sonar con `sonar.qualitygate.wait=true` (el job falla si el gate falla; parámetro documentado por SonarSource en docs.sonarsource.com, URL exacta no verificada) + [scan action](https://github.com/SonarSource/sonarqube-scan-action). |
| **Revisión cruzada** | `reviewer` (Opus, solo lectura, otro contexto) ≠ autor; QA no puede editar. Tú: revisión final (+ `/code-review ultra` opcional). |
| **Reintentos acotados** | 3 vueltas máx.; luego `agent:blocked` + mención al dueño. `maxTurns` en cada agente. |
| **Tests falsos** | QA busca tests borrados, `.skip`, asserts relajados, mocks del SUT, umbrales bajados; la cobertura de código nuevo la mide Sonar, no el agente. |
| **Alucinación de APIs** | Regla en CLAUDE.md + tech-lead y reviewer deben citar dónde existe cada API; typecheck en CI. |
| **Desbordar alcance** | QA y reviewer reportan `out_of_scope`. |
| **Loops infinitos** | Contador de vueltas, `stop_hook_active`, `maxTurns`, timeouts de CI, mín. 1 h entre runs programados. |
| **Conflictos entre agentes en paralelo** | Lock atómico por rama + WIP ≤ 3 PRs abiertos + devs secuenciales dentro de una issue (backend define contrato → frontend). |
| **El agente nunca hace merge** | Ruleset de GitHub (abajo) + `deny` + `guard.sh`. |

---

