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

# ── Helper functions ──────────────────────────────────────────────────────────
check_services_running() {
  # Check if any core services containers are running
  local running_count=$($COMPOSE -f "$SCRIPT_DIR/docker-compose.yml" ps --status running 2>/dev/null | grep -v "NAME" | wc -l | tr -d ' ')
  if [ "$running_count" -gt 0 ]; then
    return 0  # Running
  else
    return 1  # Not running
  fi
}

start_services() {
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
}

stop_services() {
  echo ""
  echo "================================================"
  echo "  Stopping Core Services"
  echo "================================================"
  
  $COMPOSE -f "$SCRIPT_DIR/docker-compose.yml" down

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Core Services Stopped"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

teardown_services() {
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
}

# ── Main logic ────────────────────────────────────────────────────────────────
echo ""
echo "================================================"
echo "  Core Services Management"
echo "================================================"
echo ""
echo "Checking status..."

if check_services_running; then
  # Services are running
  echo "Core services are currently RUNNING"
  echo ""
  $COMPOSE -f "$SCRIPT_DIR/docker-compose.yml" ps
  echo ""
  echo "What would you like to do?"
  echo "  1) Stop services"
  echo "  2) Teardown services"
  echo "  3) View logs"
  echo "  4) Exit"
  echo ""
  read -p "Enter your choice (1-4): " choice
  
  case $choice in
    1)
      stop_services
      ;;
    2)
      teardown_services
      ;;
    3)
      echo ""
      echo "Press Ctrl+C to exit logs"
      sleep 2
      $COMPOSE -f "$SCRIPT_DIR/docker-compose.yml" logs -f
      ;;
    4)
      echo "Exiting."
      exit 0
      ;;
    *)
      echo "Invalid choice. Exiting."
      exit 1
      ;;
  esac
else
  # Services are not running
  echo "Core services are currently STOPPED"
  echo ""
  echo "What would you like to do?"
  echo "  1) Start services"
  echo "  2) Teardown (remove all volumes and data)"
  echo "  3) Exit"
  echo ""
  read -p "Enter your choice (1-3): " choice
  
  case $choice in
    1)
      start_services
      ;;
    2)
      teardown_services
      ;;
    3)
      echo "Exiting."
      exit 0
      ;;
    *)
      echo "Invalid choice. Exiting."
      exit 1
      ;;
  esac
fi
