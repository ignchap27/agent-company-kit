"""Filtra issues de SonarQube a las líneas añadidas/modificadas por el diff.

Uso: git diff -U0 origin/HEAD...HEAD | python3 filter.py issues.json
Imprime JSON con los issues en líneas cambiadas; sale 1 si alguno es grave.
Autoprueba: python3 filter.py --test
"""
import json
import re
import sys

GRAVE = {"BLOCKER", "CRITICAL", "MAJOR", "HIGH", "MEDIUM"}


def lineas_cambiadas(diff):
    cambios, archivo = {}, None
    for l in diff.splitlines():
        if l.startswith("+++ "):
            archivo = None if l == "+++ /dev/null" else l[6:]
        elif l.startswith("@@") and archivo:
            m = re.match(r"@@ -\S+ \+(\d+)(?:,(\d+))? @@", l)
            ini, n = int(m[1]), int(m[2] or 1)
            cambios.setdefault(archivo, set()).update(range(ini, ini + n))
    return cambios


def filtrar(issues, cambios):
    out = []
    for i in issues:
        ruta = i["component"].split(":", 1)[1]
        if i.get("line") in cambios.get(ruta, ()):
            sev = {i.get("severity")} | {x["severity"] for x in i.get("impacts", [])}
            out.append({"rule": i["rule"], "severity": "/".join(sorted(s for s in sev if s)),
                        "file": ruta, "line": i["line"], "message": i["message"],
                        "grave": bool(sev & GRAVE)})
    return out


def _test():
    diff = "+++ b/a.py\n@@ -1,0 +3,2 @@\n+x\n+y\n+++ b/b.py\n@@ -5 +5 @@\n-z\n+w\n+++ /dev/null\n@@ -1 +0,0 @@\n"
    c = lineas_cambiadas(diff)
    assert c == {"a.py": {3, 4}, "b.py": {5}}, c
    iss = [{"component": "k:a.py", "line": 4, "rule": "r1", "message": "m", "severity": "MAJOR"},
           {"component": "k:a.py", "line": 9, "rule": "r2", "message": "m", "severity": "BLOCKER"},
           {"component": "k:b.py", "line": 5, "rule": "r3", "message": "m",
            "impacts": [{"severity": "LOW"}]},
           {"component": "k", "rule": "r4", "message": "sin línea"}]
    iss[3]["component"] = "k:c.py"
    f = filtrar(iss, c)
    assert [x["rule"] for x in f] == ["r1", "r3"], f
    assert [x["grave"] for x in f] == [True, False], f
    print("ok")


if __name__ == "__main__":
    if sys.argv[1:] == ["--test"]:
        _test()
        sys.exit()
    with open(sys.argv[1]) as fh:
        issues = json.load(fh)
    res = filtrar(issues, lineas_cambiadas(sys.stdin.read()))
    print(json.dumps(res, ensure_ascii=False, indent=1))
    sys.exit(1 if any(x["grave"] for x in res) else 0)
