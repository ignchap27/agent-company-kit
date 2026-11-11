#!/bin/bash
# Levanta el tablero (127.0.0.1:4500) y Pixel Agents (127.0.0.1:4510) si no están corriendo.
up() { curl -s -o /dev/null "http://127.0.0.1:$1/"; }
up 4510 || (cd "${AGENT_REPOS_DIR:-$HOME/Developer}" && nohup pixel-agents --port 4510 >/tmp/pixel-agents.log 2>&1 &)
up 4500 || nohup python3 "$(dirname "$0")/board.py" >/tmp/agent-company-board.log 2>&1 &
