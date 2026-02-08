#!/bin/bash
set -e

# =============================================================================
# Adventure Works LT Setup Script for MSSQL Example
# =============================================================================
# This script sets up the AdventureWorksLT database in SQL Server for the
# hugr MSSQL data source example.
#
# Prerequisites:
#   - Docker installed and running
#   - amd64 platform (Intel/AMD processor)
#   - Access to the hugr-lab/examples repository
#
# Usage:
#   ./setup.sh          # Set up database (skip if exists)
#   ./setup.sh --force  # Force recreate database
#   ./setup.sh --help   # Show this help message
# =============================================================================

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SQL_SCHEMAS_DIR="$SCRIPT_DIR/data/schemas"
DATABASE_NAME="AdventureWorksLT"

# Load environment variables
if [ -f "$ROOT_DIR/.env" ]; then
    set -a
    source <(grep -E '^[A-Z_]+=' "$ROOT_DIR/.env" | grep -v '^#')
    set +a
fi

# Default values
MSSQL_SA_PASSWORD="${MSSQL_SA_PASSWORD:-YourStrong@Passw0rd}"
MSSQL_PORT="${MSSQL_PORT:-18033}"
MSSQL_CONTAINER="hugr-mssql"

# =============================================================================
# Color Output Helpers
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# Help
# =============================================================================
show_help() {
    cat << EOF
Adventure Works LT Setup Script

Usage: ./setup.sh [OPTIONS]

Options:
    --force     Force recreate database (drops existing database)
    --help      Show this help message

Environment Variables:
    MSSQL_SA_PASSWORD   SA password for SQL Server (default: YourStrong@Passw0rd)
    MSSQL_PORT          External port for SQL Server (default: 18033)

Examples:
    ./setup.sh                    # Normal setup (skip if database exists)
    ./setup.sh --force            # Force recreate database
    MSSQL_PORT=1433 ./setup.sh    # Use custom port

Requirements:
    - amd64 platform (Intel/AMD processor)
    - Docker installed and running
    - SQL Server container available

EOF
    exit 0
}

# =============================================================================
# Platform Check
# =============================================================================
check_platform() {
    local arch=$(uname -m)

    if [[ "$arch" != "x86_64" && "$arch" != "amd64" ]]; then
        warn "Detected architecture: $arch"
        warn "SQL Server only runs on amd64 (Intel/AMD processors)."
        warn "If you're on Apple Silicon (M1/M2/M3), you'll need:"
        warn "  - A remote SQL Server instance"
        warn "  - Docker Desktop with Rosetta emulation (experimental)"
        warn ""
        warn "The container may fail to start on non-amd64 platforms."
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            error "Setup cancelled by user"
            exit 1
        fi
    else
        success "Platform check passed: $arch"
    fi
}

# =============================================================================
# Container Management
# =============================================================================
check_container_running() {
    if docker ps --format '{{.Names}}' | grep -q "^${MSSQL_CONTAINER}$"; then
        return 0
    else
        return 1
    fi
}

start_container() {
    info "Starting MSSQL container..."

    cd "$ROOT_DIR"

    if ! docker-compose --profile mssql up -d mssql; then
        error "Failed to start MSSQL container"
        error "Check if port $MSSQL_PORT is available: lsof -i :$MSSQL_PORT"
        exit 1
    fi

    success "MSSQL container started"
}

wait_for_sql_server() {
    info "Waiting for SQL Server to be ready..."

    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if docker exec "$MSSQL_CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C \
            -Q "SELECT 1" > /dev/null 2>&1; then
            success "SQL Server is ready"
            return 0
        fi

        echo -ne "\r  Attempt $attempt/$max_attempts..."
        sleep 2
        ((attempt++))
    done

    echo ""
    error "SQL Server failed to become ready after $max_attempts attempts"
    error "Check container logs: docker logs $MSSQL_CONTAINER"
    exit 1
}

# =============================================================================
# Database Operations
# =============================================================================
check_database_exists() {
    local result=$(docker exec "$MSSQL_CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C \
        -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name = '$DATABASE_NAME'" \
        -h -1 2>/dev/null | tr -d ' \r\n')

    if [ "$result" = "1" ]; then
        return 0
    else
        return 1
    fi
}

drop_database() {
    info "Dropping existing database..."

    docker exec "$MSSQL_CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C \
        -Q "IF EXISTS (SELECT name FROM sys.databases WHERE name = '$DATABASE_NAME') BEGIN ALTER DATABASE [$DATABASE_NAME] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$DATABASE_NAME]; END"

    success "Database dropped"
}

create_database() {
    info "Creating database $DATABASE_NAME..."

    docker exec "$MSSQL_CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C \
        -Q "CREATE DATABASE [$DATABASE_NAME]"

    success "Database created"
}

load_schema_and_data() {
    info "Loading schema and sample data..."

    if [ ! -d "$SQL_SCHEMAS_DIR" ]; then
        error "SQL schemas directory not found: $SQL_SCHEMAS_DIR"
        exit 1
    fi

    # Get list of SQL files sorted by name
    local sql_files=$(ls -1 "$SQL_SCHEMAS_DIR"/*.sql 2>/dev/null | sort)

    if [ -z "$sql_files" ]; then
        error "No SQL files found in: $SQL_SCHEMAS_DIR"
        exit 1
    fi

    # Create temporary directory in container
    docker exec "$MSSQL_CONTAINER" mkdir -p /tmp/schemas

    # Copy all SQL files to container
    for sql_file in $sql_files; do
        local filename=$(basename "$sql_file")
        docker cp "$sql_file" "$MSSQL_CONTAINER:/tmp/schemas/$filename"
    done

    # Execute SQL files in order
    for sql_file in $sql_files; do
        local filename=$(basename "$sql_file")
        info "  Loading $filename..."

        docker exec "$MSSQL_CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C \
            -d "$DATABASE_NAME" \
            -i "/tmp/schemas/$filename"
    done

    # Clean up
    docker exec "$MSSQL_CONTAINER" rm -rf /tmp/schemas

    success "Schema and data loaded"
}

# =============================================================================
# Statistics Display
# =============================================================================
show_statistics() {
    info "Database statistics:"
    echo ""

    # Get table counts per schema
    docker exec "$MSSQL_CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C \
        -d "$DATABASE_NAME" \
        -Q "
SET NOCOUNT ON;
SELECT
    s.name AS SchemaName,
    COUNT(*) AS TableCount
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name IN ('Person', 'HumanResources', 'Production', 'Purchasing', 'Sales')
GROUP BY s.name
ORDER BY s.name;
"

    echo ""
    info "Sample row counts:"
    docker exec "$MSSQL_CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C \
        -d "$DATABASE_NAME" \
        -Q "
SET NOCOUNT ON;
SELECT
    'Production.Product' as TableName, COUNT(*) as [Rows] FROM Production.Product
UNION ALL SELECT 'Sales.Customer', COUNT(*) FROM Sales.Customer
UNION ALL SELECT 'Sales.SalesOrderHeader', COUNT(*) FROM Sales.SalesOrderHeader
UNION ALL SELECT 'HumanResources.Employee', COUNT(*) FROM HumanResources.Employee
UNION ALL SELECT 'Purchasing.Vendor', COUNT(*) FROM Purchasing.Vendor;
"

    echo ""
    success "Setup complete!"
    echo ""
    info "Next steps:"
    echo "  1. Open hugr GraphiQL at http://localhost:18000/admin"
    echo "  2. Register the data source (see README.md)"
    echo "  3. Run sample queries"
    echo ""
    info "Connection details:"
    echo "  Host: localhost"
    echo "  Port: $MSSQL_PORT"
    echo "  Database: $DATABASE_NAME"
    echo "  User: sa"
    echo "  Password: (from MSSQL_SA_PASSWORD)"
}

# =============================================================================
# Main
# =============================================================================
main() {
    local force=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force=true
                shift
                ;;
            --help|-h)
                show_help
                ;;
            *)
                error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║       Adventure Works LT - MSSQL Example Setup             ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    # Platform check
    check_platform

    # Check and start container
    if ! check_container_running; then
        start_container
    else
        success "MSSQL container is running"
    fi

    # Wait for SQL Server to be ready
    wait_for_sql_server

    # Check if database exists
    if check_database_exists; then
        if [ "$force" = true ]; then
            warn "Database exists, --force specified, recreating..."
            drop_database
            create_database
            load_schema_and_data
        else
            warn "Database '$DATABASE_NAME' already exists"
            info "Use --force to recreate"
            echo ""
            show_statistics
            exit 0
        fi
    else
        create_database
        load_schema_and_data
    fi

    show_statistics
}

main "$@"
