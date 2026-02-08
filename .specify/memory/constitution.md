<!--
SYNC IMPACT REPORT
==================
Version change: 1.0.0 → 1.1.0
Modified principles: N/A
Added sections:
  - Hugr GraphQL Query Syntax (under Documentation Standards)
  - MSSQL to Supported Data Source Types table
Removed sections: N/A
Templates requiring updates: None
Follow-up TODOs: None

Previous changes (1.0.0):
  - Core Principles (6 principles)
  - Project Structure section
  - Documentation Standards section
  - Governance section
-->

# Hugr Examples Repository Constitution

## Core Principles

### I. Example-First Demonstration

Every example MUST serve as a complete, working demonstration of a specific hugr integration pattern. Examples are the primary documentation for the hugr platform and MUST be:

- Self-contained with clear setup instructions
- Independently executable without other examples
- Focused on demonstrating one primary integration pattern
- Accompanied by sample queries showing practical usage

**Rationale**: Users learn best from working examples. Each example serves as both documentation and a validation that the integration works correctly.

### II. Consistent Structure

All examples MUST follow a consistent directory and file structure:

- `README.md` - Comprehensive documentation with prerequisites, setup, and queries
- `setup.sh` - Automated data loading script (when data initialization required)
- `schema.graphql` or `schema/` - GraphQL SDL schema definitions
- Data files as appropriate (`.sql`, `.csv`, `.duckdb`, etc.)

Setup scripts MUST:

- Use colored terminal output for status visibility
- Check prerequisites before operations
- Support `--help` flag for usage information
- Verify successful completion with post-setup statistics

**Rationale**: Consistency reduces cognitive load when exploring multiple examples and ensures reliable automation.

### III. GraphQL Schema Quality

GraphQL schema definitions MUST be complete and well-documented:

- Use descriptive doc strings for all types and fields
- Apply appropriate directives (`@table`, `@pk`, `@field_references`, etc.)
- Define relationships explicitly with proper cardinality
- Include views for complex query patterns when beneficial

Schema files MUST NOT contain:

- Undefined references to non-existent types
- Incomplete relationship definitions
- Missing primary key specifications

**Rationale**: The schema is the contract between hugr and the data source. Complete, accurate schemas prevent runtime errors and confusion.

### IV. Documentation Completeness

Every example README MUST include:

- Prerequisites section listing required services and tools
- Step-by-step setup instructions
- GraphQL mutation for data source registration
- At least 4 sample queries demonstrating different capabilities
- Expected output samples for key queries
- Key features highlighted with explanations

Documentation MUST be written assuming the reader:

- Has basic GraphQL knowledge
- Has Docker installed and running
- Is unfamiliar with the specific data domain

**Rationale**: Comprehensive documentation enables self-service learning and reduces support burden.

### V. Infrastructure Isolation

Examples MUST NOT:

- Modify shared infrastructure configuration without explicit justification
- Require changes to the root `docker-compose.yaml` for basic operation
- Store sensitive credentials in committed files
- Create dependencies between examples that require specific execution order

Examples MAY:

- Use shared services (PostgreSQL, MySQL, DuckDB, MinIO) as data stores
- Reference environment variables from the root `.env` file
- Add optional monitoring or debugging configurations

**Rationale**: Examples should be additive and safe. Breaking isolation risks cascading failures across the example set.

### VI. Data Source Diversity

The examples collection MUST demonstrate the breadth of hugr's capabilities:

- **Database backends**: PostgreSQL, MySQL, DuckDB (minimum coverage)
- **Data patterns**: Relational, analytical, geospatial, time-series
- **Integration types**: Database schemas, self-describing data, REST APIs, object storage
- **Query patterns**: Simple CRUD, joins, aggregations, spatial queries

New examples SHOULD fill gaps in coverage rather than duplicate existing patterns.

**Rationale**: Diverse examples showcase hugr's flexibility and provide reference implementations for common integration scenarios.

## Project Structure

### Repository Layout

```text
/
├── docker-compose.yaml    # Shared infrastructure services
├── .env.example           # Environment variable template
├── scripts/               # Infrastructure management
│   ├── start.sh          # Start all services
│   └── stop.sh           # Stop all services
├── examples/              # Individual example projects
│   └── [example-name]/   # Each example directory
├── config/                # Service configurations
├── hugr/                  # Hugr server configuration
└── data/                  # Runtime data volumes
```

### Example Directory Layout

```text
examples/[name]/
├── README.md              # Documentation (required)
├── setup.sh               # Data loading (if data needed)
├── schema.graphql         # GraphQL schema (or schema/ directory)
└── [data files]           # SQL dumps, CSV, DuckDB files, etc.
```

### Supported Data Source Types

| Type | Extension/Format | Example |
|------|-----------------|---------|
| PostgreSQL | `.sql` dumps | get-started, sales |
| MySQL | `.sql` dumps | hr-crm |
| MSSQL | `.sql` dumps | mssql |
| DuckDB | `.duckdb`, `.csv` | h3, open-payments, osm |
| REST API | OpenAPI `.yaml` | openweathermap |

## Documentation Standards

### README Structure

1. **Title and Purpose** - One-line description of what the example demonstrates
2. **Prerequisites** - Services, tools, and setup requirements
3. **Setup Instructions** - Numbered steps with code blocks
4. **Data Source Registration** - GraphQL mutation with explanation
5. **Sample Queries** - Progressive complexity (simple → advanced)
6. **Key Features** - Highlighted capabilities demonstrated
7. **Limitations** (optional) - Known constraints or edge cases

### Code Block Standards

- Use triple backticks with language identifier (`sql`, `graphql`, `bash`)
- Include expected output for queries
- Annotate complex queries with inline comments

### Hugr GraphQL Query Syntax

Sample queries in README files MUST use correct hugr query syntax:

**Filtering**:
- Use `filter` (not `where`)
- Operators: `eq`, `gt`, `gte`, `lt`, `lte`, `like`, `in`, `is_null`
- Example: `filter: { status: { eq: 5 }, total: { gt: 1000 } }`

**Ordering**:
- Use `order_by: [{ field: "fieldName", direction: ASC|DESC }]`
- Array of objects with `field` and `direction` keys

**Counting**:
- Use `_rows_count` field on any collection
- Example: `products { _rows_count }`

**Aggregation**:
- Use `<table>_aggregation` with field-level functions
- Functions: `sum`, `avg`, `min`, `max`, `count`
- Example: `orders_aggregation { total { sum avg } }`

**Bucket Aggregation**:
- Use `<table>_bucket_aggregation` with `key {}` and `aggregations {}` blocks
- Group by fields in `key`, apply aggregations in `aggregations`

**Distinct**:
- Use `distinct_on: ["field"]` parameter
- **IMPORTANT**: The `distinct_on` field MUST be present in the selection set

**Nested Limits**:
- Use `nested_order_by` and `nested_limit` on related collections
- Example: `orders(nested_limit: 5, nested_order_by: [{ field: "date", direction: DESC }])`

**Module Naming**:
- Use the module `name` (not `prefix`) as the top-level query field
- Example: If module is `@module(name: "mymodule", prefix: "mm")`, query via `mymodule { ... }`

## Governance

### Constitution Authority

This constitution supersedes all informal practices. When conflict arises between existing examples and constitutional principles, the constitution prevails and examples SHOULD be updated.

### Amendment Process

1. Propose changes via pull request modifying this file
2. Include rationale for each change
3. Update version number following semantic versioning:
   - MAJOR: Principle removal or incompatible redefinition
   - MINOR: New principle or significant expansion
   - PATCH: Clarifications, typo fixes, non-semantic changes
4. Update dependent templates if principles affect their structure

### Compliance Review

- New examples MUST be reviewed against all principles before merge
- Existing examples SHOULD be audited when principles change
- Template updates MUST maintain alignment with constitutional principles

### Guidance Files

- Use this constitution for principle verification
- Use `.specify/templates/` for implementation patterns
- Use individual example READMEs as reference implementations

**Version**: 1.1.0 | **Ratified**: 2026-02-02 | **Last Amended**: 2026-02-02
