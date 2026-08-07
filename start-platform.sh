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

# ── Create shared Docker network (idempotent) ─────────────────────────────────
if docker network inspect microservices-net &>/dev/null; then
  echo "Network 'microservices-net' already exists — skipping."
else
  echo "Creating Docker network 'microservices-net'..."
  docker network create microservices-net
  echo "Network created."
fi

# ── Start shared infra stack ──────────────────────────────────────────────────
echo ""
echo "Starting shared infra stack..."
$COMPOSE -f "$SCRIPT_DIR/docker-compose.yml" up -d

echo ""`
echo "Infra stack is up. Services:"
$COMPOSE -f "$SCRIPT_DIR/docker-compose.yml" ps

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Next: open a service in VS Code Dev Container"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo " Each service has its own devcontainer and can be opened"
echo " independently in VS Code."
echo ""
echo " Option A — VS Code UI:"
echo "   1. Open VS Code"
echo "   2. File → Open Folder → select a service folder:"
echo "        $(pwd)/microservice-auth-service"
echo "        $(pwd)/microservice-users-service"
echo "   3. When prompted, click 'Reopen in Container'"
echo "      (or open the Command Palette → 'Dev Containers: Reopen in Container')"
echo ""
echo " Option B — VS Code CLI:"
echo "   code --folder-uri vscode-remote://dev-container+\$(pwd | xxd -p)/workspace auth-service"
echo ""
echo " Option C — from the terminal:"
echo "   cd microservice-auth-service  && code ."
echo "   cd microservice-users-service && code ."
echo "   Then: Command Palette → 'Dev Containers: Reopen in Container'"
echo ""
echo "━━━━━━━━━━━━━━━━━ Connect from host ━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Kafka UI:      http://localhost:8080"
echo " Kafka Connect: http://localhost:8083"
echo " API Gateway:   http://localhost:80"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "━━━━━━━━━━━━━━━━━ Connect inside container ━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Kafka UI:      http://infra-kafka-ui:8080"
echo " Kafka Connect: http://infra-kafka-connect:8083"
echo " API Gateway:   http://infra-api-gateway:80"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
