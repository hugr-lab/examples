# The `hugr` examples

This repository contains examples of how to use the [hugr](https://hugr-lab.github.io) platform for various use-cases: setting up data sources, creating GraphQL schemas, and integrating with different services.

## Set up the environment

The examples run on Docker and Docker Compose.

```bash
git clone https://github.com/hugr-lab/examples.git
cd examples
sh scripts/start.sh
```

To stop the environment:

```bash
sh scripts/stop.sh
```

The base environment includes:

- PostgreSQL (with TimescaleDB and PostGIS)
- MySQL
- MinIO (S3-compatible object storage)
- Redis
- hugr server
- Prometheus + Grafana (monitoring)

Some examples require additional services started via Docker Compose profiles (see individual example READMEs).

## Examples

### 1. Get Started

Folder: `get-started/`

Set up a Northwind database on PostgreSQL and create a GraphQL SDL schema for it. A good starting point for learning hugr basics.

### 2. PostgreSQL

Folder: `postgres-examples/`

Create an empty PostgreSQL database, describe it in GraphQL SDL, and attach it to hugr as a data source.

### 3. Sales (PostgreSQL + PostGIS)

Folder: `sales/`

E-commerce sales system on PostgreSQL with PostGIS geospatial support. Showcases:
- Many-to-many relationships (products ↔ tags)
- Geospatial fields (customer addresses, order locations)
- Composite primary keys
- Time-windowed aggregations (top customers by date range)

### 4. HR-CRM (MySQL)

Folder: `hr-crm/`

Human Resources & recruitment management system on MySQL. Showcases:
- MySQL data source configuration
- Complex many-to-many relationships (candidates ↔ skills)
- Pipeline stage tracking (applications → interviews → hiring)
- Aggregations on applications and interview scoring

### 5. MSSQL Adventure Works

Folder: `mssql/`

Microsoft SQL Server with the Adventure Works Lightweight sample database. Showcases:
- MSSQL data source with the `mssql://` URI format
- DuckDB MSSQL extension with projection and filter pushdown
- Hierarchical data (self-referencing categories)
- Many-to-many relationships (CustomerAddress junction table)

**Note**: Requires amd64 platform (Intel/AMD processor).

### 6. Fabric Warehouse

Folder: `fabric-warehouse/`

Microsoft Fabric Warehouse as a cloud data source via `azure://` URI with Azure AD authentication. Showcases:
- Azure AD service principal credentials
- `@field_source` directive for simplifying column names
- `@field_references` for star schema relationships
- NYC taxi star schema (Date, Trip, Medallion, Geography, Weather)

**Note**: Requires an active Microsoft Fabric Warehouse instance.

### 7. OpenWeatherMap (HTTP API)

Folder: `openweathermap/`

Real-time weather data from the OpenWeatherMap REST API. Showcases:
- HTTP data source connector
- OpenAPI specification parsing with `x-hugr-type` / `x-hugr-name` extensions
- Function definitions with SQL expressions

**Note**: Requires an OpenWeatherMap API key.

### 8. OSM (OpenStreetMap + Geospatial)

Folder: `osm/`

OpenStreetMap geospatial data (roads, amenities, administrative boundaries). Showcases:
- Self-describing DuckDB data source
- Geospatial queries (intersects, centroid, length measurement)
- Aggregations by administrative boundaries
- S3 object storage integration

### 9. H3 Geospatial Indexing

Folder: `h3/`

German census population data with H3 geospatial indexing. Showcases:
- DuckDB data source with H3 extension
- OSM data extension with computed fields
- Geospatial aggregation at different H3 resolutions

### 10. Open Payments (Large Dataset)

Folder: `open-payments/`

US healthcare Open Payments dataset (~1.3 GB). Showcases:
- Self-describing DuckDB data source
- Time-travel queries
- Large-scale payment analytics
- State/quarter aggregations with reference fields

### 11. DuckLake: NYC Yellow Taxi

Folder: `ducklake/`

DuckLake data source with the NYC Yellow Taxi trip dataset (~36M trips). Showcases:
- Self-describing DuckLake data source (auto-generated GraphQL schema)
- Time-travel queries with `@at` directive across monthly snapshots
- Relationships via extension catalog (`trips` → `zones`)
- DDL operations (add columns, create tables)
- DuckLake management functions (maintenance, snapshots, metadata views)
- Data stored in MinIO S3, metadata in PostgreSQL

### 12. Iceberg: Weather Observations with Time-Travel

Folder: `iceberg/`

Apache Iceberg data source with a weather observations dataset. Showcases:
- Apache Polaris as Iceberg REST catalog with OAuth2 authentication
- Self-describing Iceberg data source (auto-generated GraphQL schema)
- Time-travel queries with `@at` directive across monthly snapshots
- Namespace-to-module mapping (Iceberg namespaces become GraphQL modules)
- Relationships via extension catalog (observations → weather stations)
- Data stored in MinIO S3

**Note**: Requires `--profile iceberg` to start Polaris services: `docker compose --profile iceberg up -d`
