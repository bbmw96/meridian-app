#!/usr/bin/env bash
# MERIDIAN Kafka Topic Configuration
# Run after Kafka is healthy: bash infrastructure/kafka-topics.sh

set -euo pipefail

KAFKA_BROKERS="${KAFKA_BROKERS:-localhost:9092}"
REPLICATION="${REPLICATION_FACTOR:-1}"

echo "Creating MERIDIAN Kafka topics on ${KAFKA_BROKERS}..."

# Currency rate updates (high throughput, short retention)
kafka-topics.sh --bootstrap-server "${KAFKA_BROKERS}" \
  --create --if-not-exists \
  --topic meridian.currency.rates \
  --partitions 3 \
  --replication-factor "${REPLICATION}" \
  --config retention.ms=3600000 \
  --config cleanup.policy=delete \
  --config compression.type=lz4

# Domain scan results (medium throughput, longer retention)
kafka-topics.sh --bootstrap-server "${KAFKA_BROKERS}" \
  --create --if-not-exists \
  --topic meridian.intelligence.scans \
  --partitions 6 \
  --replication-factor "${REPLICATION}" \
  --config retention.ms=86400000 \
  --config cleanup.policy=delete \
  --config compression.type=lz4

# Opportunity signals (low throughput, longer retention)
kafka-topics.sh --bootstrap-server "${KAFKA_BROKERS}" \
  --create --if-not-exists \
  --topic meridian.radar.opportunities \
  --partitions 3 \
  --replication-factor "${REPLICATION}" \
  --config retention.ms=604800000 \
  --config cleanup.policy=delete

# Alert triggers (critical, low volume)
kafka-topics.sh --bootstrap-server "${KAFKA_BROKERS}" \
  --create --if-not-exists \
  --topic meridian.alerts.triggered \
  --partitions 1 \
  --replication-factor "${REPLICATION}" \
  --config retention.ms=86400000 \
  --config cleanup.policy=delete

# MQL execution events (audit log)
kafka-topics.sh --bootstrap-server "${KAFKA_BROKERS}" \
  --create --if-not-exists \
  --topic meridian.mql.executions \
  --partitions 3 \
  --replication-factor "${REPLICATION}" \
  --config retention.ms=604800000 \
  --config cleanup.policy=delete \
  --config compression.type=gzip

echo "All MERIDIAN Kafka topics created successfully."
kafka-topics.sh --bootstrap-server "${KAFKA_BROKERS}" --list | grep meridian
