# The `hugr` examples

This repository contains examples of how to use the `hugr` platform for various use-cases, including setting up data sources, creating GraphQL schemas, and integrating with different services like PostgreSQL, Redis, and MinIO.

For more information about the `hugr` platform, please visit the [Web site](https://hugr-lab.github.io).

This repo contains examples of hugr use-cases.

## Set up the environment

To run the examples, you need to set up the environment. The examples are based on Docker and Docker Compose.
To set up the environment, run the following command:

```bash
git clone git://git@github.com:hugr-lab/examples.git
cd examples
sh scripts/start.sh
```

To down the environment, run:

```bash
sh scripts/stop.sh
```

The environment contains the following services:

- PostgreSQL database
- MinIO object storage
- Redis
- Hugr server
- Prometheus for monitoring
- Grafana for visualization

## Examples

### 1. Get started

Folder: get-started/

In this example we will set up a Northwind database on PostgreSQL and create GraphQL SDL schema for it.

### 2. PostgresSQL example

In this example we will create an empty data PostgreSQL data base, describe it in GraphQL SDL and attach it into Hugr as a data source.
Folder: postgres-examples/

### 3. MSSQL Adventure Works Example

Folder: mssql/

This example demonstrates how to use hugr with Microsoft SQL Server as a data source, featuring the Adventure Works Lightweight (LT) sample database. It showcases:
- MSSQL data source configuration with the `mssql://` URI format
- DuckDB MSSQL extension with projection and filter pushdown
- GraphQL schema patterns: `@table`, `@pk`, `@field_references`
- Hierarchical data (self-referencing categories)
- Many-to-many relationships (CustomerAddress junction table)

**Note**: Requires amd64 platform (Intel/AMD processor).

### 4. Fabric Warehouse Example

Folder: fabric-warehouse/

This example demonstrates how to use hugr with Microsoft Fabric Warehouse as a cloud data source, connecting via the `azure://` URI scheme with Azure AD service principal authentication. It showcases:
- Fabric Warehouse connection via `azure://` URI format with Azure AD credentials
- Catalog-based schema loading with GraphQL SDL
- `@field_source` directive for simplifying column names in queries
- `@field_references` for star schema relationships (7 dimension references on Trip)
- GraphQL schema patterns: `@table`, `@pk`, `@field_source`, `@field_references`
- Filtering by relationships, aggregation, and bucket aggregation queries
- NYC taxi star schema: Date, Trip, Medallion, HackneyLicense, Geography, Time, Weather

**Note**: Requires an active Microsoft Fabric Warehouse instance with Azure AD service principal credentials.

### 5. DuckLake: NYC Yellow Taxi

Folder: ducklake/

This example demonstrates DuckLake as a data source in hugr using the NYC Yellow Taxi trip dataset (~36M real trips). It showcases:
- Self-describing DuckLake data source (auto-generated GraphQL schema)
- Time-travel queries with `@at` directive across monthly snapshots
- Relationships via extension catalog (`trips` → `zones` for pickup/dropoff)
- DDL operations (add columns, create tables)
- DuckLake management functions (maintenance, snapshots, metadata views)
- Data stored in MinIO S3, metadata in PostgreSQL
