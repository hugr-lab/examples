# DuckLake: NYC Yellow Taxi

This example demonstrates **DuckLake** as a data source in hugr using the NYC Yellow Taxi trip dataset — a real, well-known public dataset with millions of taxi trip records.

**What you'll learn:**
- Self-describing DuckLake data source (auto-generated GraphQL schema)
- Time-travel queries with `@at` directive
- Relationships via extension catalog
- DDL operations (add columns, create tables)
- DuckLake management functions (maintenance, snapshots, metadata)
- Aggregation and bucket aggregation queries

**Dataset:** Full year 2024, ~36M trips across 16 snapshots (12 monthly data loads). Data stored in MinIO S3, metadata in PostgreSQL.

## Prerequisites

- Example environment running: `cd ../../ && sh scripts/start.sh`
- [DuckDB CLI](https://duckdb.org/docs/installation/) installed locally
- `curl` installed

## Setup

Run the setup script from this directory:

```bash
cd examples/ducklake
sh setup.sh
```

This will:
1. Download 12 months of NYC Yellow Taxi Parquet files (~550 MB total)
2. Download the taxi zone lookup CSV (265 zones)
3. Create a MinIO bucket `ducklake-taxi`
4. Create a DuckLake with local metadata DB + S3 data storage
5. Load zones table, then load trips month-by-month (one snapshot per month)

**Options:**
```bash
sh setup.sh --years 2023,2024    # Load 2 years (~70M trips, ~1.1 GB)
sh setup.sh --force              # Force re-download and recreate
```

## Register DuckLake Data Source

### 1. Register MinIO Storage

If MinIO storage is not already registered in hugr, register it first:

```graphql
mutation registerMinioStorage {
  function {
    core {
      storage {
        register_storage(
          type: "s3"
          key_id: "minio_admin"
          secret: "minio_password123"
          endpoint: "minio:9000"
          use_ssl: false
          url_style: "path"
        ) { success message }
      }
    }
  }
}
```

### 2. Create DuckLake Data Source

```graphql
mutation addTaxiDuckLake {
  core {
    insert_data_sources(data: {
      name: "taxi"
      type: "ducklake"
      path: "postgres://hugr:hugr_password@postgres:5432/ducklake_taxi?data_path=s3://ducklake-taxi/data/"
      prefix: "taxi"
      description: "NYC Yellow Taxi Trip Data (DuckLake with PostgreSQL metadata)"
      read_only: false
      self_defined: true
      as_module: true
    }) {
      name type prefix self_defined
    }
  }
}
```

### 3. Load Data Source

```graphql
mutation loadTaxi {
  core {
    load_data_sources(name: "taxi") {
      success message
    }
  }
}
```

The `self_defined: true` flag means hugr auto-generates the GraphQL schema from DuckLake metadata — no manual schema definition needed for basic queries.

## Basic Queries

### Select Trips

```graphql
query longTrips {
  taxi {
    trips(
      filter: { trip_distance: { gt: 10 }, fare_amount: { gt: 50 } }
      order_by: [{ field: "total_amount", direction: DESC }]
      limit: 20
    ) {
      tpep_pickup_datetime
      tpep_dropoff_datetime
      trip_distance
      passenger_count
      fare_amount
      tip_amount
      total_amount
      PULocationID
      DOLocationID
    }
  }
}
```

### Aggregation — Total Revenue and Average Fare

```graphql
query tripStats {
  taxi {
    trips_aggregation {
      _rows_count
      fare_amount { sum avg min max }
      tip_amount { sum avg }
      total_amount { sum avg }
      trip_distance { avg max }
    }
  }
}
```

### Bucket Aggregation — Daily Revenue

```graphql
query dailyRevenue {
  taxi {
    trips_bucket_aggregation(
      order_by: [{ field: "key.tpep_pickup_datetime", direction: ASC }]
      limit: 365
    ) {
      key {
        tpep_pickup_datetime(bucket: day)
      }
      aggregations {
        _rows_count
        total_amount { sum avg }
        trip_distance { avg }
      }
    }
  }
}
```

### Payment Type Distribution

```graphql
query paymentTypes {
  taxi {
    trips_bucket_aggregation(
      order_by: [{ field: "aggregations._rows_count", direction: DESC }]
    ) {
      key { payment_type }
      aggregations {
        _rows_count
        total_amount { sum avg }
        tip_amount { avg }
      }
    }
  }
}
```

## Time Travel

DuckLake creates a snapshot each time data is modified. Since we loaded data month-by-month, each month is a separate snapshot. Use the `@at` directive to query historical states.

### View Snapshot History

```graphql
query snapshotHistory {
  function {
    core {
      ducklake {
        snapshots(name: "taxi") {
          snapshot_id
          snapshot_time
          schema_version
        }
      }
    }
  }
}
```

### Compare Data Across Snapshots

Query the same aggregation at different points in time — after loading January only vs all 12 months:

```graphql
query timeTravelComparison {
  taxi {
    january: trips_aggregation @at(version: 4) {
      _rows_count
      total_amount { sum }
    }
    first_quarter: trips_aggregation @at(version: 6) {
      _rows_count
      total_amount { sum }
    }
    all: trips_aggregation {
      _rows_count
      total_amount { sum }
    }
  }
}
```

> **Note:** Snapshots 0-3 are DDL (create tables, insert zones). Snapshot 4 is January trips, 5 is February, etc. Use `snapshotHistory` to see exact version numbers.

### Query Historical Data by Timestamp

```graphql
query atTimestamp {
  taxi {
    trips_aggregation @at(timestamp: "2025-01-01T00:00:00Z") {
      _rows_count
      total_amount { sum avg }
    }
  }
}
```

### Time Travel with Bucket Aggregation

See daily revenue distribution when only January data was loaded:

```graphql
query januaryOnly {
  taxi {
    trips_bucket_aggregation @at(version: 4) {
      key { tpep_pickup_datetime(bucket: day) }
      aggregations {
        _rows_count
        total_amount { sum }
      }
    }
  }
}
```

## Add Relationships (Extension Catalog)

The self-described schema provides basic table access. To add relationships between `trips` and `zones`, register the included `schema.graphql` as an extension catalog:

### 1. Register Catalog Source

```graphql
mutation addCatalogSource {
  core {
    insert_catalog_sources(data: {
      name: "taxi_relations"
      type: "uriFile"
      description: "Taxi zone relationships and computed fields"
      path: "/workspace/examples/ducklake/schema.graphql"
    }) { name }
  }
}
```

### 2. Link Catalog to Data Source

```graphql
mutation linkCatalog {
  core {
    insert_catalogs(data: {
      data_source_name: "taxi"
      catalog_name: "taxi_relations"
    }) { data_source_name catalog_name }
  }
}
```

### 3. Reload Data Source

```graphql
mutation reloadTaxi {
  core {
    load_data_sources(name: "taxi") {
      success message
    }
  }
}
```

### 4. Query with Relationships

```graphql
query tripsWithZones {
  taxi {
    trips(
      filter: { trip_distance: { gt: 20 } }
      order_by: [{ field: "total_amount", direction: DESC }]
      limit: 10
    ) {
      tpep_pickup_datetime
      trip_distance
      total_amount
      duration_minutes
      pickup_zone { Borough Zone }
      dropoff_zone { Borough Zone }
    }
  }
}
```

### Top Pickup Zones by Revenue

```graphql
query topPickupZones {
  taxi {
    zones(limit: 20) {
      Borough
      Zone
      pickup_trips_aggregation {
        _rows_count
        total_amount { sum avg }
        tip_amount { avg }
        trip_distance { avg }
      }
    }
  }
}
```

## DDL Operations

DuckLake supports schema evolution through hugr's management functions.

### Add a Column

```graphql
mutation addColumn {
  function {
    core {
      ducklake {
        add_column(
          name: "taxi"
          table_name: "trips"
          column_name: "is_long_trip"
          column_type: BOOLEAN
        ) { success message }
      }
    }
  }
}
```

### Create a New Table

```graphql
mutation createTable {
  function {
    core {
      ducklake {
        create_table(
          name: "taxi"
          table_name: "daily_summary"
          columns: [
            { name: "date", type: DATE }
            { name: "total_trips", type: INTEGER }
            { name: "total_revenue", type: DOUBLE }
            { name: "avg_distance", type: DOUBLE }
          ]
        ) { success message }
      }
    }
  }
}
```

After DDL changes, reload the data source to pick up schema changes:

```graphql
mutation reloadTaxi {
  core {
    load_data_sources(name: "taxi") {
      success message
    }
  }
}
```

## Management Functions

### DuckLake Info

```graphql
query ducklakeInfo {
  function {
    core {
      ducklake {
        info(name: "taxi") {
          name
          snapshot_count
          current_snapshot
          table_count
          schema_version
          data_path
          metadata_backend
          ducklake_version
          created_at
          last_modified_at
        }
      }
    }
  }
}
```

### Table Statistics

```graphql
query tableStats {
  core {
    ducklake {
      table_stats(args: { name: "taxi" }) {
        table_name
        file_count
        file_size_bytes
        delete_file_count
        delete_file_size_bytes
      }
    }
  }
}
```

### Maintenance Operations

```graphql
mutation maintenance {
  function {
    core {
      ducklake {
        checkpoint(name: "taxi") { success message }
      }
    }
  }
}
```

### Set DuckLake Options

```graphql
mutation setCompression {
  function {
    core {
      ducklake {
        set_option(name: "taxi", option: parquet_compression, value: "zstd") {
          success message
        }
      }
    }
  }
}
```

## Query Performance

Use the `@stats` directive to measure query performance:

```graphql
query tripsWithStats {
  taxi {
    trips_aggregation @stats {
      _rows_count
      fare_amount { sum avg }
      total_amount { sum }
    }
  }
}
```

The `extensions` field in the response will include `compile_time`, `planning_time`, and `exec_time` metrics.

## Cleanup

To remove the DuckLake data source:

```graphql
mutation removeTaxi {
  core {
    unload_data_sources(name: "taxi") { success message }
    delete_data_sources(name: "taxi") { name }
  }
}
```

To remove the MinIO bucket, PostgreSQL metadata, and local files:

```bash
# Remove MinIO data
python3 -c "
import urllib.request, hashlib, hmac, datetime
# ... (use S3 API or MinIO console to delete bucket)
"

# Remove PostgreSQL metadata database
docker exec hugr-postgres psql -U hugr -d postgres -c 'DROP DATABASE IF EXISTS ducklake_taxi'

# Remove downloaded Parquet files
rm -rf ../../data/taxi
```
