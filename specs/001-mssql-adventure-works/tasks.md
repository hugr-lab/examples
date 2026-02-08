# Tasks: MSSQL Adventure Works Example

**Input**: Design documents from `/specs/001-mssql-adventure-works/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Not requested - manual validation via GraphQL queries in hugr GraphiQL.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Example directory**: `examples/mssql/`
- **Infrastructure**: Root `docker-compose.yaml` and `.env.example`
- **Schema**: `examples/mssql/schema/`
- **Data**: `examples/mssql/data/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and Docker infrastructure setup

- [ ] T001 Create example directory structure at examples/mssql/
- [ ] T002 [P] Add MSSQL environment variables to .env.example (MSSQL_PORT, MSSQL_SA_PASSWORD)
- [ ] T003 [P] Add MSSQL service to docker-compose.yaml with profile `mssql`, port 18033, health check

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data and schema that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 Create SQL script with Adventure Works LT schema (tables, constraints) in examples/mssql/data/adventureworks-lt.sql
- [ ] T005 Add sample data INSERT statements to examples/mssql/data/adventureworks-lt.sql
- [ ] T006 Create GraphQL schema for ProductCategory type in examples/mssql/schema/schema.graphql
- [ ] T007 [P] Create GraphQL schema for ProductModel type in examples/mssql/schema/schema.graphql
- [ ] T008 [P] Create GraphQL schema for Product type with @field_references in examples/mssql/schema/schema.graphql
- [ ] T009 [P] Create GraphQL schema for Customer type in examples/mssql/schema/schema.graphql
- [ ] T010 [P] Create GraphQL schema for Address type in examples/mssql/schema/schema.graphql
- [ ] T011 [P] Create GraphQL schema for CustomerAddress junction table in examples/mssql/schema/schema.graphql
- [ ] T012 [P] Create GraphQL schema for SalesOrderHeader type in examples/mssql/schema/schema.graphql
- [ ] T013 [P] Create GraphQL schema for SalesOrderDetail type in examples/mssql/schema/schema.graphql

**Checkpoint**: Foundation ready - database schema and GraphQL types defined

---

## Phase 3: User Story 1 - Set Up MSSQL Example Environment (Priority: P1) 🎯 MVP

**Goal**: Developer can run setup.sh to automatically start MSSQL container and create Adventure Works database with test data.

**Independent Test**: Run `./examples/mssql/setup.sh` and verify database is created with tables containing sample data.

### Implementation for User Story 1

- [ ] T014 [US1] Create setup.sh skeleton with shebang and set -e in examples/mssql/setup.sh
- [ ] T015 [US1] Add --help flag handling and usage documentation to examples/mssql/setup.sh
- [ ] T016 [US1] Add --force flag handling for database recreation to examples/mssql/setup.sh
- [ ] T017 [US1] Add platform architecture check (amd64 warning) to examples/mssql/setup.sh
- [ ] T018 [US1] Add colored terminal output helper functions to examples/mssql/setup.sh
- [ ] T019 [US1] Add MSSQL container status check and startup logic to examples/mssql/setup.sh
- [ ] T020 [US1] Add database existence check to examples/mssql/setup.sh
- [ ] T021 [US1] Add database creation and data loading execution to examples/mssql/setup.sh
- [ ] T022 [US1] Add post-setup statistics display (tables created, rows loaded) to examples/mssql/setup.sh
- [ ] T023 [US1] Add error handling for port conflicts and timeouts to examples/mssql/setup.sh

**Checkpoint**: User Story 1 complete - setup.sh fully functional and independently testable

---

## Phase 4: User Story 2 - Register MSSQL Data Source in Hugr (Priority: P2)

**Goal**: Developer can register the MSSQL data source in hugr using documented GraphQL mutation.

**Independent Test**: Execute registration mutation in GraphiQL and verify data source appears in data sources list.

### Implementation for User Story 2

- [ ] T024 [US2] Create README.md skeleton with title and purpose in examples/mssql/README.md
- [ ] T025 [US2] Add Prerequisites section (Docker, amd64 platform) to examples/mssql/README.md
- [ ] T026 [US2] Add Setup Instructions section with numbered steps to examples/mssql/README.md
- [ ] T027 [US2] Add Data Source Registration section with GraphQL mutation to examples/mssql/README.md
- [ ] T028 [US2] Document the mssql:// URI format in examples/mssql/README.md
- [ ] T029 [US2] Add load_data_sources mutation example to examples/mssql/README.md

**Checkpoint**: User Story 2 complete - developer can register data source following README

---

## Phase 5: User Story 3 - Query Adventure Works Data via GraphQL (Priority: P3)

**Goal**: Developer can execute sample queries to explore Adventure Works data patterns.

**Independent Test**: Execute each sample query in GraphiQL and verify results match expected output.

### Implementation for User Story 3

- [ ] T030 [US3] Add sample query 1: Basic product listing with filtering in examples/mssql/README.md
- [ ] T031 [US3] Add sample query 2: Products with categories (relationship traversal) in examples/mssql/README.md
- [ ] T032 [US3] Add sample query 3: Customer orders with details (nested relationships) in examples/mssql/README.md
- [ ] T033 [US3] Add sample query 4: Sales aggregation by customer in examples/mssql/README.md
- [ ] T034 [US3] Add sample query 5: Category hierarchy traversal in examples/mssql/README.md
- [ ] T035 [US3] Add expected output JSON for each sample query in examples/mssql/README.md

**Checkpoint**: User Story 3 complete - 5 sample queries documented with expected output

---

## Phase 6: User Story 4 - Understand MSSQL Schema Definition (Priority: P4)

**Goal**: Developer understands how to define GraphQL schemas for MSSQL databases.

**Independent Test**: Review schema files and verify all directives are documented with examples.

### Implementation for User Story 4

- [ ] T036 [US4] Add Key Features section explaining demonstrated patterns in examples/mssql/README.md
- [ ] T037 [US4] Document @table directive usage for MSSQL tables in examples/mssql/README.md
- [ ] T038 [US4] Document @field_references directive for relationships in examples/mssql/README.md
- [ ] T039 [US4] Document self-referencing relationship pattern (ProductCategory hierarchy) in examples/mssql/README.md
- [ ] T040 [US4] Document many-to-many relationship pattern (CustomerAddress) in examples/mssql/README.md
- [ ] T041 [US4] Add MSSQL-specific limitations section in examples/mssql/README.md
- [ ] T042 [US4] Add schema comments explaining each entity in examples/mssql/schema/schema.graphql

**Checkpoint**: User Story 4 complete - schema fully documented with explanations

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and cleanup

- [ ] T043 Validate setup.sh executes successfully on amd64 platform
- [ ] T044 Validate all sample queries return expected results
- [ ] T045 Review README against constitution principle IV (Documentation Completeness)
- [ ] T046 Review schema against constitution principle III (GraphQL Schema Quality)
- [ ] T047 Run quickstart.md validation steps end-to-end
- [ ] T048 Update root README.md to include mssql example in examples list

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Phase 2 - creates setup.sh
- **User Story 2 (Phase 4)**: Depends on Phase 2 - documents registration
- **User Story 3 (Phase 5)**: Depends on US2 - documents queries (needs registration first)
- **User Story 4 (Phase 6)**: Depends on Phase 2 - documents schema patterns
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational - Independent of US1
- **User Story 3 (P3)**: Depends on US2 (queries require registered data source)
- **User Story 4 (P4)**: Can start after Foundational - Independent of other stories

### Within Each User Story

- Tasks are ordered by logical dependency
- [P] marked tasks can run in parallel within that story
- Complete story before moving to next priority

### Parallel Opportunities

- T002, T003 can run in parallel (different files)
- T006-T013 can run in parallel (appending to same schema file, different types)
- US1 and US2 can run in parallel after Foundational
- US4 can run in parallel with US1, US2, US3

---

## Parallel Example: Foundational Phase

```bash
# After T004-T005 complete (SQL script), launch schema tasks in parallel:
Task: "Create GraphQL schema for ProductModel type"
Task: "Create GraphQL schema for Product type with @field_references"
Task: "Create GraphQL schema for Customer type"
Task: "Create GraphQL schema for Address type"
Task: "Create GraphQL schema for CustomerAddress junction table"
Task: "Create GraphQL schema for SalesOrderHeader type"
Task: "Create GraphQL schema for SalesOrderDetail type"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T013)
3. Complete Phase 3: User Story 1 (T014-T023)
4. **STOP and VALIDATE**: Run setup.sh and verify database creation
5. Can demo database setup capability

### Incremental Delivery

1. Setup + Foundational → Infrastructure ready
2. Add User Story 1 → Test setup.sh → Demo database setup (MVP!)
3. Add User Story 2 → Test registration → Demo hugr integration
4. Add User Story 3 → Test queries → Demo full functionality
5. Add User Story 4 → Review docs → Complete example
6. Polish → Validate all → Production ready

### Single Developer Strategy

Execute phases sequentially:
1. Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- SQL script (T004-T005) must be complete before GraphQL schema tasks
- GraphQL schema file is cumulative - tasks append types to same file
