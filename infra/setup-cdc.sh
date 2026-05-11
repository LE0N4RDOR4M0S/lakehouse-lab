#!/bin/bash
# Setup de CDC (Change Data Capture) com Debezium
# Monitora alterações no MariaDB e publica eventos no Kafka

set -e

DEBEZIUM_API="http://localhost:8083"
CONNECTOR_NAME="fiplan-cdc"

echo "⏳ Aguardando Debezium Connect estar pronto..."
for i in {1..30}; do
  if curl -s "$DEBEZIUM_API/connectors" > /dev/null 2>&1; then
    echo "✅ Debezium Connect está pronto!"
    break
  fi
  echo "  Tentativa $i/30... aguardando em 2s"
  sleep 2
done

echo ""
echo "📋 Configurando conector CDC para Fiplan..."

# Configura o conector MySQL para Debezium
# TODO: Ajuste database, table, e server.id conforme necessário
curl -s -X POST "$DEBEZIUM_API/connectors" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "'$CONNECTOR_NAME'",
    "config": {
      "connector.class": "io.debezium.connector.mysql.MySqlConnector",
      "database.hostname": "metastore-db",
      "database.port": 3306,
      "database.user": "admin",
      "database.password": "password",
      "database.server.id": 1,
      "database.server.name": "fiplan_db",
      "database.include.list": "metastore_db",
      "table.include.list": "metastore_db.fiplan",
      "topic.prefix": "fiplan",
      "include.schema.changes": true,
      "schema.history.internal.kafka.bootstrap.servers": "kafka:9092",
      "schema.history.internal.kafka.topic": "schema-changes.fiplan",
      "transforms": "route",
      "transforms.route.type": "org.apache.kafka.connect.transforms.RegexRouter",
      "transforms.route.regex": "([^.]+)\\.([^.]+)\\.([^.]+)",
      "transforms.route.replacement": "fiplan",
      "decimal.handling.mode": "string"
    }
  }' | jq .

echo ""
echo "✅ Conector '$CONNECTOR_NAME' criado!"
echo ""
echo "📊 Status dos conectores:"
curl -s "$DEBEZIUM_API/connectors" | jq .
echo ""
echo "🔗 REST API do Debezium: $DEBEZIUM_API"
echo "💡 Qualquer mudança em metastore_db.fiplan gerará eventos no tópico 'fiplan'"
echo ""
echo "Para verificar conectores:"
echo "  curl http://localhost:8083/connectors | jq"
echo ""
echo "Para deletar o conector:"
echo "  curl -X DELETE http://localhost:8083/connectors/$CONNECTOR_NAME"
