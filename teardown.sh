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
echo "  Tearing Down Core Services"
echo "================================================"
echo ""
echo "⚠️  WARNING: This will remove all Docker volumes!"
echo "   - Kafka topics, offsets, configs"
echo "   - Any other Docker-managed volumes"
echo ""
echo "Note: CloudBeaver workspace directory will be preserved."
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
	echo "Teardown cancelled."
	exit 0
fi

echo ""
echo "Tearing down shared infra stack and volumes..."
$COMPOSE -f "$SCRIPT_DIR/docker-compose.yml" down -v --remove-orphans

# Remove shared Docker network if present
if docker network inspect microservices-net &>/dev/null; then
	echo "Removing Docker network 'microservices-net'..."
	docker network rm microservices-net
	echo "Network removed."
else
	echo "Network 'microservices-net' does not exist — skipping."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Core Services Torn Down"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Docker volumes and network removed."
echo " CloudBeaver workspace preserved in environment/cloudbeaver-workspace-data/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
