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

# ── Tear down shared infra stack and volumes ─────────────────────────────────
echo ""
echo "Tearing down shared infra stack and volumes..."
$COMPOSE -f "$SCRIPT_DIR/docker-compose.yml" down -v

# ── Remove shared Docker network if present ──────────────────────────────────
if docker network inspect microservices-net &>/dev/null; then
  echo "Removing Docker network 'microservices-net'..."
  docker network rm microservices-net
  echo "Network removed."
else
  echo "Network 'microservices-net' does not exist — skipping."
fi

echo ""
echo "Infra stack, volumes, and shared network have been removed."
