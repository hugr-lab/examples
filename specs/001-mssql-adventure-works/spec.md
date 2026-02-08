# Feature Specification: MSSQL Adventure Works Example

**Feature Branch**: `001-mssql-adventure-works`
**Created**: 2026-02-02
**Status**: Draft
**Input**: Implement MSSQL example with Adventure Works database for hugr platform demonstration

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Set Up MSSQL Example Environment (Priority: P1)

A developer exploring hugr wants to try the MSSQL data source integration. They run the setup script which automatically starts the MSSQL container (if on amd64 platform), creates the Adventure Works database with test data, and verifies the installation is complete.

**Why this priority**: Without infrastructure setup, no other features can be demonstrated. This is the foundational step that enables all subsequent interactions.

**Independent Test**: Can be fully tested by running `./setup.sh` in the mssql example directory and verifying that the database is created with tables containing sample data.

**Acceptance Scenarios**:

1. **Given** a developer has cloned the examples repository and Docker is running, **When** they execute `./examples/mssql/setup.sh`, **Then** the MSSQL container starts (if amd64) and the Adventure Works database is created with test data
2. **Given** the MSSQL database already exists with data, **When** the developer runs the setup script, **Then** the script detects existing data and skips recreation unless forced
3. **Given** the developer is on a non-amd64 platform (e.g., ARM Mac), **When** they run the setup script, **Then** they receive a clear message about platform requirements and next steps

---

### User Story 2 - Register MSSQL Data Source in Hugr (Priority: P2)

A developer wants to connect the MSSQL Adventure Works database to hugr. They follow the README instructions to register the data source using a GraphQL mutation with the URI-style connection string format.

**Why this priority**: Data source registration is required before any queries can be executed. This is the bridge between the database and hugr's GraphQL API.

**Independent Test**: Can be tested by executing the registration mutation in hugr's GraphiQL interface and verifying the data source appears in the data sources list.

**Acceptance Scenarios**:

1. **Given** hugr server is running and MSSQL database is set up, **When** the developer executes the data source registration mutation with URI `mssql://user:password@host:port/database`, **Then** the data source is registered successfully
2. **Given** the data source is registered, **When** the developer loads the data source, **Then** the GraphQL schema includes Adventure Works tables and relationships
3. **Given** invalid connection credentials, **When** the developer attempts to register, **Then** a clear error message indicates the connection failure

---

### User Story 3 - Query Adventure Works Data via GraphQL (Priority: P3)

A developer wants to explore the Adventure Works data using GraphQL queries. They follow the sample queries in the README to understand query patterns including basic queries, relationships, filtering, and aggregations.

**Why this priority**: Query execution is the primary value demonstration of hugr. Sample queries teach developers how to use the platform effectively.

**Independent Test**: Can be tested by executing each sample query in GraphiQL and verifying results match expected output shown in documentation.

**Acceptance Scenarios**:

1. **Given** the MSSQL data source is loaded in hugr, **When** the developer executes a simple query for products, **Then** product data is returned with expected fields
2. **Given** the data source is loaded, **When** the developer executes a query with relationship traversal (e.g., products with categories), **Then** nested data from related tables is returned correctly
3. **Given** the data source is loaded, **When** the developer executes an aggregation query, **Then** aggregated results (counts, sums, averages) are calculated and returned

---

### User Story 4 - Understand MSSQL Schema Definition (Priority: P4)

A developer wants to understand how to define GraphQL schemas for MSSQL databases. They study the provided schema.graphql files to learn directive usage, relationship definitions, and MSSQL-specific patterns.

**Why this priority**: Schema understanding enables developers to create their own MSSQL integrations. This is educational value that extends beyond the example.

**Independent Test**: Can be tested by reviewing schema files and verifying all directives are documented with examples in the README.

**Acceptance Scenarios**:

1. **Given** the schema files exist, **When** a developer reads them, **Then** they find clear documentation of table definitions with `@table`, `@pk`, `@field_references` directives
2. **Given** the schema files, **When** the developer looks for relationship examples, **Then** they find both one-to-many and many-to-many relationship patterns demonstrated
3. **Given** the schema files, **When** comparing to other examples (MySQL, PostgreSQL), **Then** the patterns are consistent with established conventions

---

### Edge Cases

- What happens when MSSQL container fails to start due to resource constraints?
  - Setup script provides clear error message and suggests checking Docker resources
- What happens when port 18033 is already in use?
  - Setup script detects port conflict and suggests resolution steps
- What happens when connection to MSSQL times out during setup?
  - Setup script retries with increasing intervals and provides troubleshooting guidance
- What happens when Adventure Works data import fails midway?
  - Setup script cleans up partial state and allows retry

## Requirements *(mandatory)*

### Functional Requirements

#### Infrastructure Requirements

- **FR-001**: Example MUST include a docker-compose service definition for MSSQL Server using the official Microsoft SQL Server image
- **FR-002**: MSSQL service MUST use port 18033 by default (configurable via environment variable)
- **FR-003**: MSSQL service MUST be optional, using Docker Compose profile named `mssql`
- **FR-004**: MSSQL service MUST include health check for startup verification
- **FR-004a**: MSSQL SA password MUST be configurable via `MSSQL_SA_PASSWORD` environment variable with a default value in `.env.example`

#### Setup Script Requirements

- **FR-005**: Example MUST include `setup.sh` script that automates database creation and data loading
- **FR-006**: Setup script MUST check platform architecture and warn if not amd64 (MSSQL Server only supports amd64)
- **FR-007**: Setup script MUST check if MSSQL container is running and start it if needed (via docker-compose profile)
- **FR-008**: Setup script MUST check if database already exists before creating
- **FR-009**: Setup script MUST support `--force` flag to recreate database even if exists
- **FR-010**: Setup script MUST support `--help` flag showing usage information
- **FR-011**: Setup script MUST use colored terminal output for status visibility
- **FR-012**: Setup script MUST display post-setup statistics (tables created, rows loaded)

#### Schema Requirements

- **FR-013**: Example MUST include GraphQL schema definition files for Adventure Works database
- **FR-014**: Schema MUST define core Adventure Works entities: Products, Categories, Customers, Sales Orders
- **FR-015**: Schema MUST include proper relationship definitions using `@field_references` directive
- **FR-016**: Schema MUST include documentation strings for all types and significant fields
- **FR-017**: Schema MUST follow existing examples patterns (consistent with hr-crm, get-started)

#### Documentation Requirements

- **FR-018**: Example MUST include comprehensive README.md following established template
- **FR-019**: README MUST include Prerequisites section with Docker, platform requirements
- **FR-020**: README MUST include step-by-step setup instructions
- **FR-021**: README MUST include data source registration mutation with URI-style path: `mssql://user:password@host:port/database`
- **FR-022**: README MUST include at least 4 sample GraphQL queries demonstrating different capabilities
- **FR-023**: README MUST include expected output for sample queries
- **FR-024**: README MUST include key features section explaining demonstrated patterns
- **FR-025**: README MUST document any MSSQL-specific limitations or considerations

### Key Entities

Adventure Works database subset focused on Sales domain:

- **Product**: Merchandise available for sale (name, number, price, category, description)
- **ProductCategory**: Hierarchical classification of products (parent/child categories)
- **ProductModel**: Product design template grouping variants
- **Customer**: Person or business who purchases products (name, email, contact info)
- **SalesOrderHeader**: Sales transaction metadata (order date, status, totals, customer reference)
- **SalesOrderDetail**: Individual line items in a sales order (product, quantity, price)
- **Address**: Customer shipping/billing locations
- **CustomerAddress**: Association between customers and their addresses

## Clarifications

### Session 2026-02-02

- Q: Which MSSQL Server version to use? → A: SQL Server 2022 (mcr.microsoft.com/mssql/server:2022-latest)
- Q: SA Password configuration approach? → A: Use environment variable `MSSQL_SA_PASSWORD` with default in .env.example

## Assumptions

- Adventure Works LT (lightweight) version will be used as it provides sufficient complexity for demonstration while having manageable data size
- MSSQL Server 2022 image (mcr.microsoft.com/mssql/server:2022-latest) will be used for current LTS support and performance
- The `SA` (System Administrator) account will be used for simplicity, with password configured via `MSSQL_SA_PASSWORD` environment variable (default provided in .env.example)
- UTF-8 collation will be used for international character support
- The example prioritizes educational clarity over production-ready configuration

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developer can complete full setup (container start, database creation, data load) within 5 minutes on standard hardware
- **SC-002**: Setup script provides clear success/failure indication with actionable error messages for all failure modes
- **SC-003**: All 4+ sample queries in README execute successfully and return expected results
- **SC-004**: Developer new to hugr can follow README from start to running queries without external assistance
- **SC-005**: Schema definitions pass consistency review against project constitution principles
- **SC-006**: Example demonstrates at least 3 distinct query patterns: basic retrieval, relationship traversal, aggregation
