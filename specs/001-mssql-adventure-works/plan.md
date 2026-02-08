# Implementation Plan: MSSQL Adventure Works Example

**Branch**: `001-mssql-adventure-works` | **Date**: 2026-02-02 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-mssql-adventure-works/spec.md`

## Summary

Implement a complete MSSQL example for the hugr platform using the Adventure Works LT database. This example will demonstrate MSSQL data source integration with GraphQL schema definitions, automated setup, and comprehensive documentation following the established examples pattern.

## Technical Context

**Language/Version**: Bash (setup scripts), GraphQL SDL (schema)
**Primary Dependencies**: Docker, SQL Server 2022, sqlcmd CLI
**Storage**: Microsoft SQL Server 2022 (mcr.microsoft.com/mssql/server:2022-latest)
**Testing**: Manual validation via GraphQL queries in hugr GraphiQL
**Target Platform**: Linux/macOS with Docker (amd64 architecture required for MSSQL)
**Project Type**: Example/documentation project
**Performance Goals**: Setup completion within 5 minutes
**Constraints**: amd64 platform only (MSSQL Server limitation)
**Scale/Scope**: ~300 sample data records across 8 tables

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Example-First Demonstration | ✅ PASS | Self-contained example with setup.sh, schema, README, sample queries |
| II. Consistent Structure | ✅ PASS | Follows examples/[name]/ layout with README.md, setup.sh, schema.graphql |
| III. GraphQL Schema Quality | ✅ PASS | Schema will include doc strings, @table, @pk, @field_references directives |
| IV. Documentation Completeness | ✅ PASS | README includes prerequisites, setup, registration mutation, 4+ queries |
| V. Infrastructure Isolation | ✅ PASS | Uses optional Docker profile `mssql`, env vars for credentials |
| VI. Data Source Diversity | ✅ PASS | Adds MSSQL coverage (previously missing from examples) |

**Gate Status**: PASSED - No violations requiring justification.

## Project Structure

### Documentation (this feature)

```text
specs/001-mssql-adventure-works/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (GraphQL schema)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
examples/mssql/
├── README.md                    # Comprehensive documentation
├── setup.sh                     # Automated setup script
├── schema/
│   └── schema.graphql           # GraphQL schema definitions
└── data/
    └── adventureworks-lt.sql    # Database creation and sample data
```

### Infrastructure Changes

```text
docker-compose.yaml              # Add mssql service with profile
.env.example                     # Add MSSQL_* environment variables
```

**Structure Decision**: Single example directory following existing patterns (get-started, hr-crm). Infrastructure additions to root docker-compose.yaml with optional profile.

## Complexity Tracking

> No Constitution Check violations - section not applicable.
