#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$SCRIPT_DIR/../../data/taxi"
BUCKET="ducklake-taxi"

# Defaults
YEARS="2024"
FORCE=false

# MinIO settings (from .env or defaults)
MINIO_ENDPOINT="${MINIO_ENDPOINT:-http://localhost:18080}"
MINIO_USER="${MINIO_USER:-minio_admin}"
MINIO_PASSWORD="${MINIO_PASSWORD:-minio_password123}"

# PostgreSQL settings for DuckLake metadata
PG_HOST="${PG_HOST:-localhost}"
PG_PORT="${PG_PORT:-18032}"
PG_USER="${PG_USER:-hugr}"
PG_PASSWORD="${PG_PASSWORD:-hugr_password}"
PG_DATABASE="${PG_DATABASE:-ducklake_taxi}"

BASE_URL="https://d37ci6vzurychx.cloudfront.net/trip-data"
ZONES_URL="https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv"

show_help() {
    echo "DuckLake NYC Yellow Taxi Setup Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -f, --force         Force re-download and recreate DuckLake"
    echo "  --years YEARS       Comma-separated years to load (default: 2024)"
    echo "                      Examples: 2024, 2023,2024"
    echo ""
    echo "Examples:"
    echo "  $0                          # Load 2024 (12 months, ~36M trips, ~550 MB)"
    echo "  $0 --years 2023,2024        # Load 2023-2024 (24 months, ~70M trips, ~1.1 GB)"
    echo "  $0 --force                  # Force re-download and recreate"
    echo ""
    echo "Environment variables:"
    echo "  MINIO_ENDPOINT    MinIO API endpoint (default: http://localhost:18080)"
    echo "  MINIO_USER        MinIO user (default: minio_admin)"
    echo "  MINIO_PASSWORD    MinIO password (default: minio_password123)"
    echo "  PG_HOST           PostgreSQL host for metadata (default: localhost)"
    echo "  PG_PORT           PostgreSQL port (default: 18032)"
    echo "  PG_USER           PostgreSQL user (default: hugr)"
    echo "  PG_PASSWORD       PostgreSQL password (default: hugr_password)"
    echo "  PG_DATABASE       PostgreSQL database for metadata (default: ducklake_taxi)"
    echo ""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --years) YEARS="$2"; shift 2 ;;
        -f|--force) FORCE=true; shift ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

# Build month list from years
MONTHS=()
IFS=',' read -ra YEAR_LIST <<< "$YEARS"
for year in "${YEAR_LIST[@]}"; do
    year=$(echo "$year" | tr -d ' ')
    for m in $(seq -w 1 12); do
        MONTHS+=("${year}-${m}")
    done
done

echo -e "${BLUE}NYC Yellow Taxi DuckLake Setup${NC}"
echo "=============================="
echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "   Years:          $YEARS"
echo "   Months:         ${#MONTHS[@]}"
echo "   Expected trips: ~$((${#MONTHS[@]} * 3))M"
echo "   Data dir:       $DATA_DIR"
echo "   Metadata:       PostgreSQL ($PG_HOST:$PG_PORT/$PG_DATABASE)"
echo "   MinIO bucket:   s3://$BUCKET/data/"
echo "   MinIO endpoint: $MINIO_ENDPOINT"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v duckdb &> /dev/null; then
    echo -e "${RED}DuckDB CLI is not installed!${NC}"
    echo "Install: brew install duckdb (macOS) or see https://duckdb.org/docs/installation/"
    exit 1
fi
echo "   duckdb: $(duckdb --version 2>/dev/null | head -1)"

if ! command -v curl &> /dev/null; then
    echo -e "${RED}curl is not installed!${NC}"
    exit 1
fi
echo "   curl: OK"

echo ""

# Check if DuckLake already exists (check PG database for ducklake tables)
if [ "$FORCE" = false ]; then
    TABLE_COUNT=$(docker exec hugr-postgres psql -U "$PG_USER" -d "$PG_DATABASE" -tAc "SELECT count(*) FROM information_schema.tables WHERE table_name = 'ducklake_metadata'" 2>/dev/null || echo "0")
    if [ "$TABLE_COUNT" -gt 0 ] 2>/dev/null; then
        echo -e "${YELLOW}DuckLake metadata already exists in PostgreSQL ($PG_DATABASE).${NC}"
        echo "Use --force to recreate."
        exit 0
    fi
fi

# Step 1: Download Parquet files
echo -e "${YELLOW}Step 1: Downloading NYC Yellow Taxi Parquet files...${NC}"
mkdir -p "$DATA_DIR"

for month in "${MONTHS[@]}"; do
    FILE="$DATA_DIR/yellow_tripdata_${month}.parquet"
    if [ -f "$FILE" ] && [ "$FORCE" = false ]; then
        SIZE=$(du -h "$FILE" | cut -f1)
        echo "   Already exists: yellow_tripdata_${month}.parquet ($SIZE)"
    else
        echo "   Downloading yellow_tripdata_${month}.parquet..."
        curl -L --progress-bar -o "$FILE" "${BASE_URL}/yellow_tripdata_${month}.parquet"
    fi
done

# Download zones lookup CSV
ZONES_CSV="$SCRIPT_DIR/taxi_zone_lookup.csv"
if [ ! -f "$ZONES_CSV" ] || [ "$FORCE" = true ]; then
    echo "   Downloading taxi_zone_lookup.csv..."
    curl -sL -o "$ZONES_CSV" "$ZONES_URL"
fi
echo -e "${GREEN}Downloads complete.${NC}"
echo ""

# Step 2: Create MinIO bucket via S3 API (AWS4-HMAC-SHA256 signed)
echo -e "${YELLOW}Step 2: Creating MinIO bucket '$BUCKET'...${NC}"
python3 -c "
import urllib.request, hashlib, hmac, datetime, sys
endpoint = '${MINIO_ENDPOINT}'
bucket = '${BUCKET}'
access_key = '${MINIO_USER}'
secret_key = '${MINIO_PASSWORD}'
region = 'us-east-1'
host = endpoint.split('://')[1]
now = datetime.datetime.now(datetime.UTC)
ds = now.strftime('%Y%m%d')
amz = now.strftime('%Y%m%dT%H%M%SZ')
ph = hashlib.sha256(b'').hexdigest()
ch = f'host:{host}\nx-amz-content-sha256:{ph}\nx-amz-date:{amz}\n'
sh = 'host;x-amz-content-sha256;x-amz-date'
cr = f'PUT\n/{bucket}\n\n{ch}\n{sh}\n{ph}'
scope = f'{ds}/{region}/s3/aws4_request'
sts = f'AWS4-HMAC-SHA256\n{amz}\n{scope}\n' + hashlib.sha256(cr.encode()).hexdigest()
def s(k,m): return hmac.new(k,m.encode(),hashlib.sha256).digest()
sk = s(s(s(s(('AWS4'+secret_key).encode(),ds),region),'s3'),'aws4_request')
sig = hmac.new(sk,sts.encode(),hashlib.sha256).hexdigest()
auth = f'AWS4-HMAC-SHA256 Credential={access_key}/{scope}, SignedHeaders={sh}, Signature={sig}'
req = urllib.request.Request(f'{endpoint}/{bucket}', method='PUT')
req.add_header('x-amz-date', amz)
req.add_header('x-amz-content-sha256', ph)
req.add_header('Authorization', auth)
try:
    urllib.request.urlopen(req); print('created')
except urllib.error.HTTPError as e:
    if e.code == 409: print('exists')
    else: print(f'error:{e.code}',file=sys.stderr); sys.exit(1)
except Exception as e: print(f'error:{e}',file=sys.stderr); sys.exit(1)
" && echo -e "${GREEN}MinIO bucket ready.${NC}" || { echo -e "${RED}Failed to create MinIO bucket. Is MinIO running at $MINIO_ENDPOINT?${NC}"; exit 1; }
echo ""

# Step 3: Create DuckLake with PostgreSQL metadata
echo -e "${YELLOW}Step 3: Creating DuckLake and loading data...${NC}"

# Create PG database if it doesn't exist
docker exec hugr-postgres psql -U "$PG_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${PG_DATABASE}'" 2>/dev/null | grep -q 1 || \
    docker exec hugr-postgres psql -U "$PG_USER" -d postgres -c "CREATE DATABASE ${PG_DATABASE}" 2>/dev/null

# Clean PG metadata if force
if [ "$FORCE" = true ]; then
    docker exec hugr-postgres psql -U "$PG_USER" -d "$PG_DATABASE" -c "DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;" 2>/dev/null || true
fi

# Extract MinIO host:port from endpoint URL
MINIO_HOST_PORT=$(echo "$MINIO_ENDPOINT" | sed 's|https\?://||')
PG_CONNSTR="host=${PG_HOST} port=${PG_PORT} dbname=${PG_DATABASE} user=${PG_USER} password=${PG_PASSWORD}"

# Build INSERT statements for each month
INSERT_STMTS=""
for i in "${!MONTHS[@]}"; do
    month="${MONTHS[$i]}"
    n=$((i + 1))
    INSERT_STMTS+="
-- Load month ${n}/${#MONTHS[@]}: ${month}
INSERT INTO taxi.trips
SELECT * FROM read_parquet('${DATA_DIR}/yellow_tripdata_${month}.parquet');
SELECT '   Loaded ${month} (snapshot ' || (SELECT max(snapshot_id) FROM ducklake_snapshots('taxi')) || ')' AS status;
"
done

duckdb <<SQL
INSTALL ducklake;
LOAD ducklake;
INSTALL httpfs;
LOAD httpfs;
INSTALL postgres;
LOAD postgres;

-- Create S3 secret for MinIO
CREATE SECRET _taxi_s3 (
    TYPE s3,
    KEY_ID '${MINIO_USER}',
    SECRET '${MINIO_PASSWORD}',
    ENDPOINT '${MINIO_HOST_PORT}',
    USE_SSL false,
    URL_STYLE 'path'
);

-- Create PostgreSQL secret for DuckLake metadata
CREATE SECRET _taxi_pg (
    TYPE postgres,
    HOST '${PG_HOST}',
    PORT '${PG_PORT}',
    DATABASE '${PG_DATABASE}',
    USER '${PG_USER}',
    PASSWORD '${PG_PASSWORD}'
);

-- Create DuckLake secret (PG metadata + S3 data)
CREATE SECRET _taxi_ducklake (
    TYPE ducklake,
    METADATA_PATH '${PG_CONNSTR}',
    DATA_PATH 's3://${BUCKET}/data/',
    METADATA_PARAMETERS MAP {'TYPE': 'postgres', 'SECRET': '_taxi_pg'}
);

-- Attach DuckLake catalog
ATTACH 'ducklake:_taxi_ducklake' AS taxi;

-- Create zones table
CREATE TABLE taxi.zones (
    LocationID INTEGER,
    Borough VARCHAR,
    Zone VARCHAR,
    service_zone VARCHAR
);
INSERT INTO taxi.zones SELECT * FROM read_csv_auto('${ZONES_CSV}');
SELECT '   Loaded ' || count(*) || ' zones' AS status FROM taxi.zones;

-- Create trips table
CREATE TABLE taxi.trips (
    VendorID INTEGER,
    tpep_pickup_datetime TIMESTAMP,
    tpep_dropoff_datetime TIMESTAMP,
    passenger_count DOUBLE,
    trip_distance DOUBLE,
    RatecodeID DOUBLE,
    store_and_fwd_flag VARCHAR,
    PULocationID INTEGER,
    DOLocationID INTEGER,
    payment_type BIGINT,
    fare_amount DOUBLE,
    extra DOUBLE,
    mta_tax DOUBLE,
    tip_amount DOUBLE,
    tolls_amount DOUBLE,
    improvement_surcharge DOUBLE,
    total_amount DOUBLE,
    congestion_surcharge DOUBLE,
    Airport_fee DOUBLE
);

${INSERT_STMTS}

-- Summary
SELECT '';
SELECT '=== Summary ===' AS info;
SELECT 'Total zones: ' || count(*) AS info FROM taxi.zones;
SELECT 'Total trips: ' || count(*) AS info FROM taxi.trips;
SELECT '';
SELECT 'Snapshots:' AS info;
SELECT '   #' || snapshot_id || ' at ' || snapshot_time || ' (schema v' || schema_version || ')'
FROM ducklake_snapshots('taxi') ORDER BY snapshot_id;

DETACH taxi;
SQL

echo ""
echo -e "${GREEN}DuckLake NYC Taxi created successfully!${NC}"
echo ""
echo -e "${BLUE}Summary:${NC}"
echo "   Months loaded:  ${#MONTHS[@]}"
echo "   Metadata:       PostgreSQL ($PG_HOST:$PG_PORT/$PG_DATABASE)"
echo "   Data storage:   s3://$BUCKET/data/ (MinIO)"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "   1. Start hugr: cd ../../ && sh scripts/start.sh"
echo "   2. Register S3 storage in hugr (if not already done)"
echo "   3. Register DuckLake source:"
echo '      mutation { core { insert_data_sources(data: {'
echo '        name: "taxi", type: "ducklake", prefix: "taxi",'
echo "        path: \"postgres://${PG_USER}:${PG_PASSWORD}@postgres:5432/${PG_DATABASE}?data_path=s3://${BUCKET}/data/\","
echo '        self_defined: true, as_module: true, read_only: false,'
echo '        description: "NYC Yellow Taxi Trip Data (DuckLake)"'
echo '      }) { name type } } }'
echo "   4. Open GraphQL playground: http://localhost:18000/admin"
echo ""
