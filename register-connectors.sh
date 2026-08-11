#!/bin/bash

#################################################
# Register Debezium Connectors
#################################################
# Registers the auth and users outbox connectors
# with Kafka Connect. Run this after starting
# core services and microservices.
#################################################

set -e

KAFKA_CONNECT_URL="http://localhost:8083"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo "================================================"
echo "  Registering Debezium Connectors"
echo "================================================"
echo ""

# Check if Kafka Connect is ready
echo -n "Checking Kafka Connect availability..."
if ! curl -s "${KAFKA_CONNECT_URL}" > /dev/null 2>&1; then
  echo -e "${RED}FAILED${NC}"
  echo ""
  echo "Kafka Connect is not available at ${KAFKA_CONNECT_URL}"
  echo "Make sure core services are running:"
  echo "  cd ${SCRIPT_DIR} && ./core-services.sh"
  exit 1
fi
echo -e "${GREEN}OK${NC}"

# Function to register a connector
register_connector() {
  local name=$1
  local hostname=$2
  local dbname=$3
  local topic_prefix=$4
  local route_replacement=$5

  echo ""
  echo "Registering ${name}..."
  
  response=$(curl -s -X POST "${KAFKA_CONNECT_URL}/connectors" \
    -H 'Content-Type: application/json' \
    -d '{
    "name": "'"${name}"'",
    "config": {
      "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
      "database.hostname": "'"${hostname}"'",
      "database.port": "5432",
      "database.user": "services_user",
      "database.password": "services_pass",
      "database.dbname": "'"${dbname}"'",
      "topic.prefix": "'"${topic_prefix}"'",
      "table.include.list": "public.outbox_events",
      "plugin.name": "pgoutput",
      "publication.autocreate.mode": "filtered",
      "transforms": "outbox",
      "transforms.outbox.type": "io.debezium.transforms.outbox.EventRouter",
      "transforms.outbox.table.field.event.id": "id",
      "transforms.outbox.table.field.event.key": "aggregate_id",
      "transforms.outbox.table.field.event.type": "event_type",
      "transforms.outbox.table.field.event.payload": "payload",
      "transforms.outbox.table.field.event.timestamp": "created_at",
      "transforms.outbox.route.by.field": "event_type",
      "transforms.outbox.route.topic.replacement": "'"${route_replacement}"'",
      "key.converter": "org.apache.kafka.connect.storage.StringConverter",
      "value.converter": "org.apache.kafka.connect.storage.StringConverter"
    }
  }' 2>&1)

  if echo "$response" | grep -q "error_code"; then
    # Check if it's just "already exists" error
    if echo "$response" | grep -q "already exists"; then
      echo -e "${YELLOW}Already registered${NC}"
      # Restart the connector to ensure it's working
      echo -n "  Restarting connector..."
      curl -s -X POST "${KAFKA_CONNECT_URL}/connectors/${name}/restart" > /dev/null 2>&1
      sleep 2
      echo -e "${GREEN}OK${NC}"
    else
      echo -e "${RED}FAILED${NC}"
      echo "$response" | jq .
      return 1
    fi
  else
    echo -e "${GREEN}Registered${NC}"
  fi

  # Check status
  sleep 1
  status=$(curl -s "${KAFKA_CONNECT_URL}/connectors/${name}/status" | jq -r '.connector.state')
  task_state=$(curl -s "${KAFKA_CONNECT_URL}/connectors/${name}/status" | jq -r '.tasks[0].state')
  
  if [ "$status" = "RUNNING" ] && [ "$task_state" = "RUNNING" ]; then
    echo -e "  Status: ${GREEN}${status}${NC}"
    echo -e "  Task:   ${GREEN}${task_state}${NC}"
  else
    echo -e "  Status: ${RED}${status}${NC}"
    echo -e "  Task:   ${RED}${task_state}${NC}"
  fi
}

# Register auth-service outbox connector
register_connector \
  "microservice-auth-outbox-connector" \
  "microservice-auth-service-db" \
  "auth_db" \
  "auth" \
  "\${routedByValue}"

# Register users-service outbox connector
register_connector \
  "microservice-users-outbox-connector" \
  "microservice-users-service-db" \
  "users_db" \
  "users" \
  "users.\${routedByValue}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${GREEN}Connectors registered successfully!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "View connector status:"
echo "  curl http://localhost:8083/connectors | jq ."
echo ""
