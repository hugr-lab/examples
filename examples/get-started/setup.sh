#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DB_NAME="northwind"
DUMP_FILE="northwind_dump.sql"
FORCE=false

# Help function
show_help() {
    echo "Northwind Database Deployment Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -f, --force         Force deployment without confirmation"
    echo "  -d, --dump-file     Specify custom dump file (default: northwind_dump.sql)"
    echo ""
    echo "Examples:"
    echo "  $0                              # Deploy with default settings"
    echo "  $0 --force                      # Deploy without confirmation"
    echo "  $0 --dump-file custom_dump.sql  # Use custom dump file"
    echo ""
    echo "Note: This script uses the PostgreSQL connection from the main .env file"
    echo "      Make sure hugr infrastructure is running before executing this script"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -d|--dump-file)
            DUMP_FILE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}🗄️  Northwind Database Deployment${NC}"
echo "================================="

# Check if we're in the right directory (should contain .env in parent directories)
if [ ! -f "../../.env" ]; then
    echo -e "${RED}❌ Main .env file not found!${NC}"
    echo "Please run this script from the examples/getting-started/ directory"
    echo "and ensure hugr infrastructure is set up."
    exit 1
fi

# Load environment variables from main .env
source ../../.env
export EXAMPLE_DB_NAME="northwind"
echo -e "${BLUE}📋 Configuration:${NC}"
echo "   PostgreSQL Container: hugr-postgres"
echo "   Database User: $POSTGRES_USER"
echo "   PostgreSQL Port: $POSTGRES_PORT"
echo "   Database Name: $EXAMPLE_DB_NAME"
echo "   Dump File: $DUMP_FILE"

# Check if dump file exists
if [ ! -f "$DUMP_FILE" ]; then
    echo -e "${RED}❌ Dump file '$DUMP_FILE' not found!${NC}"
    echo "Please ensure the Northwind dump file exists in the current directory."
    exit 1
fi

# Check if PostgreSQL container is running
if ! docker ps --format "table {{.Names}}" | grep -q "hugr-postgres"; then
    echo -e "${RED}❌ PostgreSQL container 'hugr-postgres' is not running!${NC}"
    echo "Please start hugr infrastructure first:"
    echo "  cd ../../"
    echo "  ./scripts/start.sh"
    exit 1
fi

# Test connection to PostgreSQL
echo -e "${YELLOW}🔄 Testing PostgreSQL connection...${NC}"
if ! docker-compose -f ../../docker-compose.yaml exec postgres pg_isready -U "$POSTGRES_USER" -d "postgres" > /dev/null 2>&1; then
    echo -e "${RED}❌ Failed to connect to PostgreSQL!${NC}"
    echo "Please ensure hugr infrastructure is running properly."
    exit 1
fi
echo -e "${GREEN}✅ PostgreSQL connection successful${NC}"

# Check if northwind database exists
echo -e "${YELLOW}🔄 Checking if '$DB_NAME' database exists...${NC}"
DB_EXISTS=$(docker-compose -f ../../docker-compose.yaml exec -T postgres psql -U "$POSTGRES_USER" -d "postgres" -t -c "SELECT 1 FROM pg_database WHERE datname='$EXAMPLE_DB_NAME';" | xargs || echo "")

if [ "$DB_EXISTS" = "1" ]; then
    echo -e "${YELLOW}⚠️  Database '$EXAMPLE_DB_NAME' already exists!${NC}"

    if [ "$FORCE" = false ]; then
        echo -e "${YELLOW}This will drop the existing database and recreate it.${NC}"
        echo -e "${RED}⚠️  ALL DATA IN '$EXAMPLE_DB_NAME' DATABASE WILL BE LOST!${NC}"
        echo ""
        echo -n "Are you sure you want to continue? (y/N): "
        read -r response
        
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Deployment cancelled."
            exit 0
        fi
    fi
    
    # Terminate existing connections to the database
    echo -e "${YELLOW}🔄 Terminating existing connections to '$EXAMPLE_DB_NAME'...${NC}"
    docker-compose -f ../../docker-compose.yaml exec -T postgres psql -U "$POSTGRES_USER" -d "postgres" -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$EXAMPLE_DB_NAME' AND pid <> pg_backend_pid();" > /dev/null 2>&1

    # Drop the existing database
    echo -e "${YELLOW}🔄 Dropping existing database '$EXAMPLE_DB_NAME'...${NC}"
    docker-compose -f ../../docker-compose.yaml exec -T postgres psql -U "$POSTGRES_USER" -d "postgres" -c "DROP DATABASE IF EXISTS $EXAMPLE_DB_NAME;" > /dev/null 2>&1
    echo -e "${GREEN}✅ Existing database '$EXAMPLE_DB_NAME' dropped${NC}"
fi

# Create the northwind database
echo -e "${YELLOW}🔄 Creating database '$EXAMPLE_DB_NAME'...${NC}"
docker-compose -f ../../docker-compose.yaml exec -T postgres psql -U "$POSTGRES_USER" -d "postgres" -c "CREATE DATABASE $EXAMPLE_DB_NAME;" > /dev/null 2>&1
echo -e "${GREEN}✅ Database '$EXAMPLE_DB_NAME' created${NC}"

# Import the dump file
echo -e "${YELLOW}🔄 Importing Northwind data from '$DUMP_FILE'...${NC}"
if docker-compose -f ../../docker-compose.yaml exec -T postgres psql -U "$POSTGRES_USER" -d "$EXAMPLE_DB_NAME" < "$DUMP_FILE" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Northwind data imported successfully${NC}"
else
    echo -e "${RED}❌ Failed to import data from '$DUMP_FILE'!${NC}"
    echo "Please check the dump file format and content."
    exit 1
fi

# Verify the import by checking table count
echo -e "${YELLOW}🔄 Verifying import...${NC}"
TABLE_COUNT=$(docker-compose -f ../../docker-compose.yaml exec -T postgres psql -U "$POSTGRES_USER" -d "$EXAMPLE_DB_NAME" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | xargs)

if [ "$TABLE_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ Import verified: $TABLE_COUNT tables found${NC}"
else
    echo -e "${RED}❌ Import verification failed: no tables found${NC}"
    exit 1
fi

# Show table list
echo -e "${BLUE}📊 Tables in '$EXAMPLE_DB_NAME' database:${NC}"
docker-compose -f ../../docker-compose.yaml exec -T postgres psql -U "$POSTGRES_USER" -d "$EXAMPLE_DB_NAME" -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;" -t | sed 's/^/ - /'

echo ""
echo -e "${GREEN}🎉 Northwind database deployment completed successfully!${NC}"
echo ""
echo -e "${BLUE}📝 Connection details:${NC}"
echo "   Database: $EXAMPLE_DB_NAME"
echo "   Host: localhost:${POSTGRES_PORT}"
echo "   User: $POSTGRES_USER"
echo ""
echo -e "${BLUE}🔗 Next steps:${NC}"
echo "   • Update hugr schema to connect to '$EXAMPLE_DB_NAME' database"
echo "   • Test connection: docker-compose -f ../../docker-compose.yaml exec postgres psql -U $POSTGRES_USER -d $EXAMPLE_DB_NAME"
echo ""