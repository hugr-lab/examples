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
