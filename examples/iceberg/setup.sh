#!/bin/bash
# Sets up the Iceberg example: Apache Polaris catalog + MinIO storage + weather data.
#
# Prerequisites:
#   - Docker Compose services running: sh scripts/start.sh
#   - Polaris services started: docker compose --profile iceberg up -d
#
# Usage:
#   cd examples && bash examples/iceberg/setup.sh [--force]
#
# Options:
#   --force    Re-seed data even if it already exists

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load environment
if [ -f "$ROOT_DIR/.env" ]; then
  set -a; source "$ROOT_DIR/.env"; set +a
fi

HUGR_URL="http://localhost:${HUGR_PORT:-18000}"
POLARIS_URL="http://localhost:${POLARIS_PORT:-18182}"
POLARIS_CLIENT_ID="${POLARIS_CLIENT_ID:-root}"
POLARIS_CLIENT_SECRET="${POLARIS_CLIENT_SECRET:-s3cr3t}"
MINIO_KEY="${MINIO_USER:-minio_admin}"
MINIO_SECRET="${MINIO_PASSWORD:-minio_password123}"
FORCE=false

for arg in "$@"; do
  case $arg in
    --force) FORCE=true ;;
  esac
done

# Helper: execute a GraphQL mutation/query
gql() {
  local result
  result=$(curl -sf -X POST "$HUGR_URL/query" \
    -H "Content-Type: application/json" \
    -d "{\"query\": \"$1\"}")
  echo "$result"
  if echo "$result" | jq -e '.errors | length > 0' > /dev/null 2>&1; then
    echo "  ERROR: $(echo "$result" | jq -r '.errors[0].message')" >&2
    return 1
  fi
  return 0
}

wait_for_service() {
  local url=$1 name=$2 max_attempts=${3:-30}
  echo "  Waiting for $name..."
  for i in $(seq 1 "$max_attempts"); do
    if curl -sf "$url" > /dev/null 2>&1; then
      echo "  $name is ready."
      return 0
    fi
    sleep 2
  done
  echo "  ERROR: $name did not start in time" >&2
  return 1
}

echo "=== Iceberg Example Setup (Apache Polaris) ==="
echo ""

# 1. Ensure Polaris services are running
echo "Step 1: Checking Polaris services..."
if ! curl -sf "${POLARIS_URL}/api/catalog/v1/config" > /dev/null 2>&1; then
  echo "  Polaris is not running. Starting iceberg profile..."
  docker compose -f "$ROOT_DIR/docker-compose.yaml" --profile iceberg up -d
  wait_for_service "${POLARIS_URL}/api/catalog/v1/config" "polaris" 60
  echo "  Waiting for polaris-setup to create catalog..."
  # Wait for the polaris-setup container to finish
  for i in $(seq 1 60); do
    if docker inspect hugr-polaris-setup --format '{{.State.Health.Status}}' 2>/dev/null | grep -q "healthy"; then
      echo "  Polaris catalog created."
      break
    fi
    sleep 2
  done
fi
echo "  Polaris is ready."

# 2. Register S3 storage in hugr
echo ""
echo "Step 2: Registering MinIO S3 storage in hugr..."
wait_for_service "$HUGR_URL/query" "hugr"

gql 'mutation { function { core { storage { register_object_storage(type: "S3", name: "iceberg_s3", scope: "s3://iceberg-warehouse", key: "'"$MINIO_KEY"'", secret: "'"$MINIO_SECRET"'", region: "us-east-1", endpoint: "minio:9000", use_ssl: false, url_style: "path") { success message } } } } }' || true

# 3. Seed test data via DuckDB connected to Polaris
echo ""
echo "Step 3: Seeding Iceberg test data via Polaris..."

# Obtain OAuth2 token for DuckDB connection
POLARIS_TOKEN=$(curl -sf \
  http://localhost:${POLARIS_PORT:-18182}/api/catalog/v1/oauth/tokens \
  --user "${POLARIS_CLIENT_ID}:${POLARIS_CLIENT_SECRET}" \
  -H "Polaris-Realm: POLARIS" \
  -d grant_type=client_credentials \
  -d scope=PRINCIPAL_ROLE:ALL | jq -r .access_token)

if [ -z "$POLARIS_TOKEN" ] || [ "$POLARIS_TOKEN" = "null" ]; then
  echo "  ERROR: Failed to obtain Polaris token" >&2
  exit 1
fi
echo "  Obtained Polaris OAuth2 token."

DUCKDB_IMAGE="datacatering/duckdb:v1.5.0"
NETWORK=$(docker network ls --format '{{.Name}}' | grep -E "hugr-network" | head -1)
if [ -z "$NETWORK" ]; then
  NETWORK="hugr-network"
fi

if [ "$FORCE" = true ]; then
  echo "  Force mode: re-seeding data..."
fi

set +e
docker run --rm -i \
  --network "$NETWORK" \
  "$DUCKDB_IMAGE" \
  "" <<EOSQL
INSTALL iceberg; LOAD iceberg;

-- Create S3 secret for MinIO access
CREATE SECRET minio_s3 (
    TYPE s3,
    KEY_ID '$MINIO_KEY',
    SECRET '$MINIO_SECRET',
    ENDPOINT 'minio:9000',
    URL_STYLE 'path',
    USE_SSL false
);

-- Create Iceberg secret with OAuth2 token
CREATE SECRET polaris_secret (
    TYPE iceberg,
    TOKEN '$POLARIS_TOKEN'
);

-- Attach to Polaris catalog (note: /api/catalog prefix required for Polaris)
ATTACH 'iceberg_warehouse' AS ice_demo (
    TYPE iceberg,
    ENDPOINT 'http://polaris:8181/api/catalog',
    SECRET polaris_secret
);

-- Create namespace
CREATE SCHEMA IF NOT EXISTS ice_demo."demo";

-- Create weather stations table
DROP TABLE IF EXISTS ice_demo."demo".weather_stations;
CREATE TABLE ice_demo."demo".weather_stations (
    station_id BIGINT,
    name VARCHAR,
    city VARCHAR,
    country VARCHAR,
    latitude DOUBLE,
    longitude DOUBLE,
    elevation_m DOUBLE
);

INSERT INTO ice_demo."demo".weather_stations VALUES
    (1, 'Central Park',      'New York',   'US', 40.7829, -73.9654, 47.5),
    (2, 'Heathrow',          'London',     'GB', 51.4700, -0.4543,  25.0),
    (3, 'Narita',            'Tokyo',      'JP', 35.7720, 140.3929, 44.0),
    (4, 'Schiphol',          'Amsterdam',  'NL', 52.3105, 4.7683,   -3.4),
    (5, 'Changi',            'Singapore',  'SG', 1.3644,  103.9915, 16.0);

-- Create weather observations table
DROP TABLE IF EXISTS ice_demo."demo".observations;
CREATE TABLE ice_demo."demo".observations (
    id BIGINT,
    station_id BIGINT,
    observed_at TIMESTAMP,
    temperature_c DOUBLE,
    humidity_pct DOUBLE,
    pressure_hpa DOUBLE,
    wind_speed_ms DOUBLE,
    condition VARCHAR
);

-- Batch 1: January observations (snapshot 1)
INSERT INTO ice_demo."demo".observations VALUES
    (1,  1, '2025-01-15 08:00:00', -2.5, 78.0, 1013.2, 3.1, 'Snow'),
    (2,  1, '2025-01-15 14:00:00', 1.2,  65.0, 1012.8, 4.5, 'Cloudy'),
    (3,  2, '2025-01-15 08:00:00', 5.8,  82.0, 1020.1, 6.2, 'Rain'),
    (4,  2, '2025-01-15 14:00:00', 7.1,  75.0, 1019.5, 5.8, 'Overcast'),
    (5,  3, '2025-01-15 08:00:00', 3.2,  55.0, 1025.0, 2.1, 'Clear'),
    (6,  3, '2025-01-15 14:00:00', 8.4,  48.0, 1024.3, 3.0, 'Sunny'),
    (7,  4, '2025-01-15 08:00:00', 2.1,  88.0, 1015.5, 7.5, 'Fog'),
    (8,  4, '2025-01-15 14:00:00', 4.3,  80.0, 1015.0, 6.8, 'Cloudy'),
    (9,  5, '2025-01-15 08:00:00', 27.5, 85.0, 1010.2, 2.0, 'Sunny'),
    (10, 5, '2025-01-15 14:00:00', 31.2, 72.0, 1009.8, 3.5, 'Thunderstorm');

-- Batch 2: February observations (snapshot 2 — for time-travel testing)
INSERT INTO ice_demo."demo".observations VALUES
    (11, 1, '2025-02-15 08:00:00', -5.1, 70.0, 1018.5, 5.2, 'Snow'),
    (12, 1, '2025-02-15 14:00:00', -1.3, 62.0, 1017.9, 4.0, 'Cloudy'),
    (13, 2, '2025-02-15 08:00:00', 4.2,  85.0, 1022.3, 8.1, 'Rain'),
    (14, 2, '2025-02-15 14:00:00', 6.5,  78.0, 1021.8, 7.2, 'Overcast'),
    (15, 3, '2025-02-15 08:00:00', 5.8,  50.0, 1023.0, 1.8, 'Clear'),
    (16, 3, '2025-02-15 14:00:00', 10.2, 45.0, 1022.5, 2.5, 'Sunny'),
    (17, 4, '2025-02-15 08:00:00', 1.0,  90.0, 1012.0, 9.0, 'Storm'),
    (18, 4, '2025-02-15 14:00:00', 3.5,  83.0, 1011.5, 8.3, 'Rain'),
    (19, 5, '2025-02-15 08:00:00', 28.0, 88.0, 1008.5, 1.5, 'Sunny'),
    (20, 5, '2025-02-15 14:00:00', 32.5, 70.0, 1008.0, 4.0, 'Thunderstorm');

-- Batch 3: March observations (snapshot 3)
INSERT INTO ice_demo."demo".observations VALUES
    (21, 1, '2025-03-15 08:00:00', 4.5,  60.0, 1010.0, 3.8, 'Cloudy'),
    (22, 1, '2025-03-15 14:00:00', 10.2, 52.0, 1009.5, 5.0, 'Sunny'),
    (23, 2, '2025-03-15 08:00:00', 9.0,  70.0, 1018.0, 4.5, 'Overcast'),
    (24, 2, '2025-03-15 14:00:00', 12.5, 60.0, 1017.5, 3.8, 'Sunny'),
    (25, 3, '2025-03-15 08:00:00', 10.5, 55.0, 1020.0, 2.0, 'Clear'),
    (26, 3, '2025-03-15 14:00:00', 15.8, 48.0, 1019.5, 2.8, 'Sunny'),
    (27, 4, '2025-03-15 08:00:00', 6.0,  75.0, 1016.0, 5.5, 'Rain'),
    (28, 4, '2025-03-15 14:00:00', 9.5,  65.0, 1015.5, 4.0, 'Cloudy'),
    (29, 5, '2025-03-15 08:00:00', 28.5, 82.0, 1010.0, 2.2, 'Sunny'),
    (30, 5, '2025-03-15 14:00:00', 33.0, 68.0, 1009.5, 3.0, 'Clear');

DETACH ice_demo;
EOSQL
set -eo pipefail

echo "  Iceberg data seeded (3 monthly snapshots)."

# 4. Clean up existing sources
echo ""
echo "Step 4: Registering Iceberg data source in hugr..."

gql "mutation { core { delete_catalog_sources(filter: { name: { eq: \\\\\"ice_demo\\\\\" } }) { success } }" > /dev/null 2>&1 || true
gql "mutation { core { delete_data_sources(filter: { name: { eq: \\\\\"ice_demo\\\\\" } }) { success } }" > /dev/null 2>&1 || true

# 5. Register Iceberg data source with OAuth2 credentials
gql 'mutation { core { insert_data_sources(data: { name: "ice_demo", prefix: "ice_demo", type: "iceberg", path: "iceberg+http://polaris:8181/api/catalog/iceberg_warehouse?client_id='"$POLARIS_CLIENT_ID"'&client_secret='"$POLARIS_CLIENT_SECRET"'&oauth2_server_uri=http://polaris:8181/api/catalog/v1/oauth/tokens&oauth2_scope=PRINCIPAL_ROLE:ALL&access_delegation_mode=vended_credentials", as_module: true, self_defined: true }) { name } } }'

# 6. Load the source
echo "  Loading ice_demo..."
gql 'mutation { function { core { load_data_source(name: "ice_demo") { success message } } } }'

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Open the hugr admin UI at: http://localhost:${HUGR_PORT:-18000}"
echo "Try the example queries from the README!"
