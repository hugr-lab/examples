# Research: MSSQL Adventure Works Example

**Branch**: `001-mssql-adventure-works` | **Date**: 2026-02-02

## Technology Decisions

### 1. SQL Server Version

**Decision**: SQL Server 2022 (mcr.microsoft.com/mssql/server:2022-latest)

**Rationale**: Current LTS version with longest support lifecycle and best performance. Compatible with Adventure Works LT 2022 sample database.

**Alternatives considered**:
- SQL Server 2019: Older, shorter remaining support window
- Azure SQL Edge: ARM compatible but different feature set

### 2. Adventure Works Database Version

**Decision**: Adventure Works LT (Lightweight) 2022

**Rationale**:
- Focused SalesLT schema with 8 core tables (manageable complexity)
- Demonstrates key patterns: hierarchical categories, many-to-many relationships, order details
- Sufficient data volume for meaningful queries (~300 records)
- Official Microsoft sample with clear licensing

**Alternatives considered**:
- Full Adventure Works: Too complex for example (70+ tables)
- Custom schema: Would require maintenance, less recognizable

### 3. Database Setup Approach

**Decision**: SQL script with CREATE DATABASE + INSERT statements

**Rationale**:
- Self-contained in repository (no external downloads during setup)
- Transparent - users can review exact data
- Portable across container restarts
- Follows pattern of other examples (hr-crm uses schema.sql)

**Alternatives considered**:
- Backup restore (.bak file): Requires additional tooling, opaque
- Docker volume with pre-built database: Large, version-locked

### 4. MSSQL Data Source Type in Hugr

**Decision**: Use `mssql` data source type with URI format `mssql://user:password@host:port/database`

**Rationale**:
- Hugr's MSSQL support inherits from DuckDB's MSSQL extension
- DuckDB MSSQL extension supports projection and filter pushdown for efficient queries
- Connection string follows standard URI pattern consistent with other data sources

**Key Considerations** (DuckDB MSSQL Extension):
- Projection pushdown: Only requested columns are fetched from SQL Server
- Filter pushdown: WHERE conditions are pushed to SQL Server for server-side filtering
- Schema must be explicitly defined in GraphQL (not self-describing)
- Data types map through DuckDB's type system
- IDENTITY columns work for reads but may have limitations for writes

### 5. Docker Profile Strategy

**Decision**: Optional profile named `mssql`

**Rationale**:
- MSSQL Server is resource-intensive (2GB+ RAM minimum)
- Only needed when working with this specific example
- Follows pattern of other optional services (redis: cache, prometheus: monitoring)
- Users on ARM Macs cannot run MSSQL anyway

**Implementation**:
```yaml
profiles:
  - mssql
```

### 6. Port Assignment

**Decision**: Port 18033 (configurable via MSSQL_PORT)

**Rationale**:
- Follows existing port range pattern (18000-18099)
- Default SQL Server port 1433 often conflicts with local installations
- Consistent with PostgreSQL (18032), MySQL (18036) pattern

## Data Type Mappings

Adventure Works LT uses SQL Server types that map to hugr/GraphQL as follows:

| SQL Server Type | DuckDB Type | GraphQL Type | Notes |
|-----------------|-------------|--------------|-------|
| int | INTEGER | Int | Standard mapping |
| smallint | SMALLINT | Int | Maps to Int |
| tinyint | TINYINT | Int | Maps to Int |
| nvarchar(n) | VARCHAR | String | Unicode strings |
| varchar(n) | VARCHAR | String | ASCII strings |
| money | DECIMAL | Float | Currency values |
| decimal(p,s) | DECIMAL | Float | Precise decimals |
| datetime | TIMESTAMP | Timestamp | Date/time values |
| bit | BOOLEAN | Boolean | True/false |
| uniqueidentifier | UUID | String | GUIDs as strings |
| varbinary(max) | BLOB | N/A | Skip binary columns |
| xml | VARCHAR | String | Treat as text |

**Excluded Columns**:
- `rowguid` (uniqueidentifier): Internal tracking, not useful for queries
- `ThumbNailPhoto` (varbinary): Binary data, not supported
- `CatalogDescription` (xml): Complex XML, treat as String if needed

## Schema Design Decisions

### Primary Keys
All Adventure Works LT tables use IDENTITY columns for primary keys. In GraphQL schema:
- Mark with `@pk` directive
- Use `Int!` type (not auto-generated in mutations due to DuckDB limitation)

### Relationships
Define using `@field_references` directive following hr-crm pattern:
- Product → ProductCategory (many-to-one)
- Product → ProductModel (many-to-one)
- ProductCategory → ProductCategory (self-referencing hierarchy)
- CustomerAddress → Customer + Address (many-to-many junction)
- SalesOrderHeader → Customer (many-to-one)
- SalesOrderDetail → SalesOrderHeader (one-to-many with cascade)
- SalesOrderDetail → Product (many-to-one)

### Computed Columns
Adventure Works has computed columns (TotalDue, LineTotal, SalesOrderNumber):
- Option A: Define as regular fields (DuckDB will read computed values)
- Option B: Use `@sql` directive to recalculate
- **Decision**: Option A - read existing computed values, simpler and consistent

## Sample Queries to Demonstrate

1. **Basic Query**: List products with filtering and pagination
2. **Relationship Traversal**: Products with their categories and models
3. **Aggregation**: Sales totals by customer
4. **Nested Relationships**: Orders with details and product info
5. **Hierarchical Data**: Category tree traversal

## MSSQL-Specific Limitations to Document

1. **Platform Requirement**: amd64 only (no ARM/Apple Silicon native support)
2. **Schema Required**: Must define GraphQL schema explicitly (no self_defined: true)
3. **Write Limitations**: IDENTITY columns may not return generated IDs on insert
4. **Resource Usage**: SQL Server requires minimum 2GB RAM

**Note**: DuckDB's MSSQL extension supports projection and filter pushdown, so queries are efficiently executed on SQL Server.

## References

- [Microsoft Adventure Works Documentation](https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure)
- [GitHub: SQL Server Samples](https://github.com/microsoft/sql-server-samples)
- [DuckDB MSSQL Extension](https://duckdb.org/docs/extensions/mssql)
- [Hugr Data Sources Documentation](https://hugr-lab.github.io/docs/engine-configuration/data-sources/)
