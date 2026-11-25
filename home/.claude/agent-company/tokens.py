#!/usr/bin/env python3
"""Coste por issue y fase a partir de los transcripts de ~/.claude/projects/*worktrees-issue-*.

Uso: tokens.py [<repo> <n>]   sin argumentos recorre todas las issues.
Añade una línea por issue a ~/.claude/agent-company/tokens.log y la imprime.
"""
import glob, json, os, sys, time

# $ por Mtok: input, cache read, cache write, output (precios de API; el plan no cobra así, sirve para comparar).
PRICE = {"opus": (5, 0.5, 6.25, 25), "sonnet": (3, 0.3, 3.75, 15), "haiku": (1, 0.1, 1.25, 5)}
PHASE = {"tech-lead": "planificar", "backend-dev": "codear", "frontend-dev": "codear",
         "qa": "revisar", "reviewer": "revisar", "designer": "revisar", "quality": "revisar"}
LOG = os.path.expanduser("~/.claude/agent-company/tokens.log")


def cost(path):
    total = 0.0
    for line in open(path):
        try:
            m = json.loads(line).get("message") or {}
        except ValueError:
            continue
        u = m.get("usage") if isinstance(m, dict) else None
        if not u:
            continue
        p = next((v for k, v in PRICE.items() if k in m.get("model", "")), PRICE["sonnet"])
        total += (u.get("input_tokens", 0) * p[0] + u.get("cache_read_input_tokens", 0) * p[1]
                  + u.get("cache_creation_input_tokens", 0) * p[2] + u.get("output_tokens", 0) * p[3]) / 1e6
    return total


def issue(d):
    phases = {}
    for f in glob.glob(d + "/**/*.jsonl", recursive=True):
        agent = "orquestar"
        if "/subagents/" in f:
            try:
                agent = json.load(open(f.replace(".jsonl", ".meta.json"))).get("agentType", "")
            except (OSError, ValueError):
                agent = ""
        ph = PHASE.get(agent, "orquestar" if agent == "orquestar" else "otros")
        phases[ph] = phases.get(ph, 0) + cost(f)
    return phases


ROOT = os.environ.get("AGENT_REPOS_DIR", os.path.expanduser("~/Developer")).replace("/", "-") + "-"
dirs = glob.glob(os.path.expanduser("~/.claude/projects/*worktrees-issue-*"))
if len(sys.argv) == 3:
    repo, n = sys.argv[1].split("/")[-1], sys.argv[2]
    dirs = [d for d in dirs if f"-{repo}--claude-worktrees-issue-{n}" in d]
with open(LOG, "a") as log:
    for d in sorted(dirs):
        name = os.path.basename(d).replace(ROOT, "", 1).split("--claude-worktrees-issue-")
        ph = issue(d)
        parts = " ".join(f"{k}=${v:.2f}" for k, v in sorted(ph.items()))
        line = f"{time.strftime('%F %T')} {name[0]}#{name[1]} total=${sum(ph.values()):.2f} {parts}"
        print(line)
        log.write(line + "\n")
