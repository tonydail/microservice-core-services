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
echo "  Starting Core Services"
echo "================================================"

# Create shared Docker network (idempotent)
if docker network inspect microservices-net &>/dev/null; then
	echo "Network 'microservices-net' already exists — skipping."
else
	echo "Creating Docker network 'microservices-net'..."
	docker network create microservices-net
	echo "Network created."
fi

# Start shared infra stack
echo ""
echo "Starting shared infra stack..."
$COMPOSE -f "$SCRIPT_DIR/docker-compose.yml" up -d

echo ""
echo "Infra stack is up. Services:"
$COMPOSE -f "$SCRIPT_DIR/docker-compose.yml" ps

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Core Services Started"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo " Connect from host:"
echo "   CloudBeaver:   http://localhost:8978"
echo "   Kafka UI:      http://localhost:8080"
echo "   Kafka Connect: http://localhost:8083"
echo "   API Gateway:   http://localhost:80"
echo ""
echo " Next steps:"
echo "   • Start microservices: cd .. && ./start-services.sh"
echo "   • Open in Dev Container: Open service folder in VS Code"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
