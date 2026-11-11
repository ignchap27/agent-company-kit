#!/usr/bin/env python3
"""Tablero del pipeline en http://127.0.0.1:4500: issues y PRs de GitHub de cada repo con
.claude/verify.sh, y la fase de cada sesión leída de su transcript (qué subagente lanzó el último)."""
import json
import os
import re
import subprocess
import time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(os.environ.get("AGENT_REPOS_DIR", Path.home() / "Developer"))
PROJECTS = Path.home() / ".claude" / "projects"
PHASE = {"dev": "dev", "tech-lead": "spec", "backend-dev": "dev", "frontend-dev": "dev", "qa": "qa", "designer": "qa", "reviewer": "review", "quality": "review"}
TTL = 15  # segundos de caché: 2 llamadas a gh por repo como mucho cada TTL
_cache = {"t": 0.0, "data": None}
_last_good = {}


def gh(cwd, *args):
    out = subprocess.run(["gh", *args], cwd=cwd, capture_output=True, text=True, check=True).stdout
    return json.loads(out or "null")


def session(repo_dir, n):
    """Fase de la sesión de la issue n según los subagentes que lanzó (Agent tool_use en su transcript)."""
    wt = f"{repo_dir}/.claude/worktrees/issue-{n}"
    files = sorted((PROJECTS / re.sub(r"[/.]", "-", wt)).glob("*.jsonl"), key=lambda f: f.stat().st_mtime)
    if not files:
        return None
    agents = []
    with files[-1].open() as fh:
        for line in fh:
            if '"tool_use"' not in line:
                continue
            try:
                rec = json.loads(line)
            except ValueError:
                continue
            if rec.get("type") != "assistant":  # los api-request repiten mensajes anteriores
                continue
            content = (rec.get("message") or {}).get("content")
            if not isinstance(content, list):
                continue
            for b in content:
                if isinstance(b, dict) and b.get("type") == "tool_use":
                    if b.get("name") in ("Agent", "Task"):
                        agents.append(b["input"].get("subagent_type"))
                    elif b.get("name") == "SendMessage":  # el orquestador reanuda al dev con feedback
                        agents.append("dev")
    last = agents[-1] if agents else None
    return {"phase": PHASE.get(last, "spec"), "agent": last, "round": agents.count("qa"),
            "maxRounds": 5 if agents.count("tech-lead") > 1 else 3,
            "active": time.time() - files[-1].stat().st_mtime < 120}


def repo_state(d):
    issues = gh(d, "issue", "list", "--state", "all", "--limit", "200", "--json", "number,title,state,labels,body")
    prs = gh(d, "pr", "list", "--state", "all", "--limit", "100", "--json", "number,state,isDraft,url,body")
    pr_of = {}
    for p in prs:  # gh devuelve el más reciente primero
        m = re.search(r"closes #(\d+)", p["body"] or "", re.I)
        if m:
            pr_of.setdefault(int(m[1]), {"n": p["number"], "url": p["url"], "state": p["state"], "draft": p["isDraft"]})
    items = []
    for i in issues:
        labels = [l["name"] for l in i["labels"]]
        body = i["body"] or ""
        parent = re.search(r"Parte de #(\d+)", body)
        if not parent and not any(l.startswith("agent:") for l in labels):
            continue
        n, closed = i["number"], i["state"] == "CLOSED"
        item = {"n": n, "title": i["title"], "closed": closed, "parent": int(parent[1]) if parent else None,
                "deps": [int(x) for x in re.findall(r"Depende de #(\d+)", body)], "pr": pr_of.get(n),
                "blocked": "agent:blocked" in labels, "epic": "agent:epic" in labels, "session": None}
        if closed:
            item["col"] = "done"
        elif "agent:ready" in labels:
            item["col"] = "queue"
        elif "agent:review" in labels:
            item["col"] = "owner"
        else:
            item["session"] = session(d, n)
            item["col"] = item["session"]["phase"] if item["session"] else "spec"
        items.append(item)
    parents = {i["parent"] for i in items if i["parent"]}
    for i in items:
        i["epic"] = i["epic"] or i["n"] in parents
    # Sub-epic (una sub-issue que se volvió a partir): en su epic madre va en Dev con su progreso,
    # no en Spec por ser el tech-lead lo último que lanzó; sus partes salen en su propio grupo.
    for i in items:
        if i["epic"] and i["parent"] and not i["closed"]:
            kids = [k for k in items if k["parent"] == i["n"]]
            i["col"] = "dev"
            i["session"] = {"agent": f"sub-epic {sum(k['closed'] for k in kids)}/{len(kids)}", "round": 0, "active": False}
    # Solo trabajo vivo: lo abierto y las sub-issues de epics abiertos.
    open_epics = {i["n"] for i in items if i["epic"] and not i["closed"]}
    items = [i for i in items if not i["closed"] or i["parent"] in open_epics]
    return {"name": d.name, "items": items}


def state():
    if _cache["data"] is None or time.time() - _cache["t"] > TTL:
        repos = []
        for v in sorted(ROOT.glob("*/.claude/verify.sh")):
            d = v.parent.parent
            try:
                repos.append(repo_state(d))
                _last_good[d.name] = repos[-1]
            except (subprocess.CalledProcessError, ValueError) as e:
                # Un corte de red no borra el tablero: se queda la última lectura buena, marcada como desactualizada.
                prev = _last_good.get(d.name)
                repos.append({**prev, "stale": True} if prev else {"name": d.name, "items": [], "error": str(e)})
        _cache.update(t=time.time(), data={"repos": repos, "updated": int(time.time())})
    return _cache["data"]


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=str(Path(__file__).parent), **k)

    def do_GET(self):
        if self.path != "/api/state":
            return super().do_GET()
        body = json.dumps(state()).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *a):
        pass


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", int(os.environ.get("BOARD_PORT", 4500))), Handler).serve_forever()
