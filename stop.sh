#!/bin/bash

set -e

# ── Detect script directory ───────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Detect compose command ────────────────────────────────────────────────────
if docker compose version &>/dev/null 2>&1; then
	COMPOSE="docker compose"
elif command -v docker-compose &>/dev/null; then
	COMPOSE="docker-compose"
else
	echo "Error: neither 'docker compose' nor 'docker-compose' found."
	exit 1
fi

echo ""
echo "================================================"
echo "  Stopping Core Services"
echo "================================================"

$COMPOSE -f "$SCRIPT_DIR/docker-compose.yml" down

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Core Services Stopped"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
