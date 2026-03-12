# Iceberg: Weather Observations with Time-Travel

This example demonstrates Apache Iceberg as a data source in hugr using a weather observations dataset. It showcases:

- **Apache Polaris** as an Iceberg REST catalog with OAuth2 authentication
- **Self-describing Iceberg data source** (auto-generated GraphQL schema via `self_defined: true`)
- **Time-travel queries** with `@at` directive across monthly snapshots
- **Namespace-to-module mapping** (Iceberg namespace `demo` becomes GraphQL module)
- **Relationships** via extension catalog (observations → weather stations)
- **Standard DML** (INSERT, UPDATE, DELETE) on Iceberg tables

## Architecture

```
┌─────────┐     ┌──────────────┐     ┌───────────┐
│  hugr   │────▶│   Apache     │────▶│   MinIO   │
│ server  │     │   Polaris    │     │ (S3 data) │
└─────────┘     └──────────────┘     └───────────┘
```

- **Apache Polaris** — Iceberg REST catalog with OAuth2 authentication and catalog management
- **MinIO** — S3-compatible storage for Iceberg data files (Parquet)
- **hugr** — GraphQL API server with Iceberg data source

## Dataset

**Weather Stations** — 5 stations across 5 cities:
| Station | City | Country |
|---------|------|---------|
| Central Park | New York | US |
| Heathrow | London | GB |
| Narita | Tokyo | JP |
| Schiphol | Amsterdam | NL |
| Changi | Singapore | SG |

**Observations** — 30 weather readings across 3 monthly snapshots:
- **Snapshot 1**: January 2025 (10 readings)
- **Snapshot 2**: February 2025 (10 readings)
- **Snapshot 3**: March 2025 (10 readings)

## Prerequisites

- Docker and Docker Compose
- Environment running: `sh scripts/start.sh`

## Setup

```bash
cd examples

# Start the Polaris services (iceberg profile)
docker compose --profile iceberg up -d

# Run the setup script
bash examples/iceberg/setup.sh
```

The setup script will:
1. Start Polaris + MinIO bucket initialization + catalog creation
2. Register S3 storage credentials in hugr
3. Seed weather data via DuckDB connected to Polaris (3 monthly snapshots)
4. Register and load the Iceberg data source with OAuth2 credentials

### Connection Details

hugr connects to Polaris using OAuth2 client credentials:

```
iceberg+http://polaris:8181/api/catalog/iceberg_warehouse?client_id=root&client_secret=s3cr3t&oauth2_server_uri=http://polaris:8181/api/catalog/v1/oauth/tokens&oauth2_scope=PRINCIPAL_ROLE:ALL&access_delegation_mode=vended_credentials
```

| Parameter | Value | Description |
|-----------|-------|-------------|
| `client_id` | `root` | Polaris service principal |
| `client_secret` | `s3cr3t` | Polaris service principal secret |
| `oauth2_server_uri` | `.../oauth/tokens` | Polaris token endpoint |
| `oauth2_scope` | `PRINCIPAL_ROLE:ALL` | Required scope for catalog access |

## Example Queries

Open the hugr admin UI at http://localhost:18000 and try these queries.

### 1. List weather stations

```graphql
query {
  ice_demo {
    demo {
      demo_weather_stations {
        station_id
        name
        city
        country
        latitude
        longitude
        elevation_m
      }
    }
  }
}
```

### 2. Query observations with filters

```graphql
query {
  ice_demo {
    demo {
      demo_observations(
        filter: { temperature_c: { gt: 20.0 } }
        order_by: { temperature_c: desc }
      ) {
        id
        station_id
        observed_at
        temperature_c
        humidity_pct
        condition
      }
    }
  }
}
```

### 3. Time-travel: query January snapshot only

Each batch insert creates a new Iceberg snapshot. Use `@at(version: N)` to query historical data:

```graphql
query {
  ice_demo {
    demo {
      # Version 3 = first observations batch (after stations + observations DDL snapshots)
      demo_observations @at(version: 3) {
        id
        station_id
        temperature_c
        condition
        observed_at
      }
    }
  }
}
```

This returns only the 10 January observations, even though February and March data has been added since.

> **Note**: Version numbers depend on the catalog implementation. DDL operations (CREATE TABLE) also create snapshots. Check the actual snapshot versions using the admin UI or by querying with different version numbers.

### 4. Compare snapshots

Query different time periods side by side using aliases:

```graphql
query {
  ice_demo {
    demo {
      january: demo_observations @at(version: 3) {
        id
        temperature_c
        condition
      }
      latest: demo_observations {
        id
        temperature_c
        condition
      }
    }
  }
}
```

### 5. Aggregations

```graphql
query {
  ice_demo {
    demo {
      demo_observations_aggregation {
        avg {
          temperature_c
          humidity_pct
          pressure_hpa
        }
        min {
          temperature_c
        }
        max {
          temperature_c
        }
        count
      }
    }
  }
}
```

### 6. Bucket aggregation by condition

```graphql
query {
  ice_demo {
    demo {
      demo_observations_bucket_aggregation(
        bucket: { condition: {} }
      ) {
        key {
          condition
        }
        aggregation {
          avg {
            temperature_c
            humidity_pct
          }
          count
        }
      }
    }
  }
}
```

### 7. Insert new observations

> **Note**: DuckDB's Iceberg extension does not yet support targeted inserts (inserting into specific columns). This mutation may fail with current DuckDB versions. Use DuckDB SQL directly for inserts if needed.

```graphql
mutation {
  ice_demo {
    demo {
      insert_demo_observations(data: {
        id: 31
        station_id: 1
        observed_at: "2025-04-15T08:00:00Z"
        temperature_c: 15.5
        humidity_pct: 55.0
        pressure_hpa: 1012.0
        wind_speed_ms: 3.2
        condition: "Sunny"
      }) {
        success
      }
    }
  }
}
```

## Adding Relationships (Optional)

The `schema.graphql` in this folder defines an extension catalog that adds a relationship between observations and weather stations. To use it:

1. Register the extension catalog:

```graphql
mutation {
  core {
    insert_data_sources(data: {
      name: "ice_relations"
      type: "extension"
      prefix: "ice_demo"
      as_module: false
      self_defined: false
      catalogs: [{
        name: "ice_relations"
        type: "localFS"
        path: "/workspace/examples/iceberg/schema.graphql"
      }]
    }) { name }
  }
}
```

2. Load the extension:

```graphql
mutation {
  function {
    core {
      load_data_source(name: "ice_relations") { success message }
    }
  }
}
```

3. Query with relationships:

```graphql
query {
  ice_demo {
    demo {
      demo_observations(limit: 5) {
        id
        temperature_c
        condition
        station {
          name
          city
          country
        }
      }
    }
  }
}
```

## Troubleshooting

### "Polaris is not running"
Start the iceberg profile: `docker compose --profile iceberg up -d`

### "Failed to obtain Polaris token"
Wait for the `polaris-setup` container to finish creating the catalog. Check its logs:
```bash
docker logs hugr-polaris-setup
```

### "Storage credentials not found"
Register MinIO S3 storage before loading the Iceberg source. The setup script does this automatically, but you can also run it manually:
```graphql
mutation { function { core { storage {
  register_object_storage(type: "S3", name: "iceberg_s3", scope: "s3://iceberg-warehouse",
    key: "minio_admin", secret: "minio_password123", region: "us-east-1",
    endpoint: "minio:9000", use_ssl: false, url_style: "path") { success message }
}}}}
```

### Time-travel version numbers
Iceberg snapshot version numbers are assigned by the catalog. DDL operations (CREATE TABLE, CREATE SCHEMA) also create snapshots. The first data insert may not be at version 1. Query the Iceberg metadata to find exact snapshot versions.

## About Apache Polaris

[Apache Polaris](https://polaris.apache.org/) is an open-source Iceberg catalog that implements the Iceberg REST API. It provides:
- OAuth2-based authentication and authorization
- Catalog and namespace management via REST API
- Support for S3, GCS, and Azure storage backends
- Multi-engine interoperability (Spark, Trino, DuckDB, etc.)

In this example, Polaris runs with in-memory persistence (suitable for demos). For production, configure PostgreSQL or another persistent backend.
