#!/usr/bin/env bash
set -euo pipefail

bootstrap_server="${1:-kafka:9092}"

topics=(
  "favorecidos-pj"
  "ceis"
  "lakehouse-dlq"
)

for topic in "${topics[@]}"; do
  kafka-topics.sh \
    --bootstrap-server "${bootstrap_server}" \
    --create \
    --if-not-exists \
    --topic "${topic}" \
    --partitions 1 \
    --replication-factor 1

done
