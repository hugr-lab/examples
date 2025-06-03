#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DUMP_FILE="schema.sql"
FORCE=false

# Help function
show_help() {
    echo "HR CRM MySQL Database Deployment Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -f, --force         Force deployment without confirmation"
    echo "  -d, --dump-file     Specify custom dump file (default: hr_crm_full.sql)"
    echo ""
    echo "Examples:"
    echo "  $0                              # Deploy with default settings"
    echo "  $0 --force                      # Deploy without confirmation"
    echo "  $0 --dump-file custom_dump.sql  # Use custom dump file"
    echo ""
    echo "Note: This script uses the MySQL connection from the main .env file"
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

echo -e "${BLUE}🗄️  HR CRM MySQL Database Deployment${NC}"
echo "===================================="

# Check if we're in the right directory (should contain .env in parent directories)
if [ ! -f "../../.env" ]; then
    echo -e "${RED}❌ Main .env file not found!${NC}"
    echo "Please run this script from the examples/hr-crm/ directory"
    echo "and ensure hugr infrastructure is set up."
    exit 1
fi

# Load environment variables from main .env
source ../../.env
export EXAMPLE_DB_NAME="hr_crm"

echo -e "${BLUE}📋 Configuration:${NC}"
echo "   MySQL Container: hugr-mysql"
echo "   Database User: $MYSQL_USER"
echo "   MySQL Port: $MYSQL_PORT"
echo "   Database Name: $EXAMPLE_DB_NAME"
echo "   Dump File: $DUMP_FILE"

# Check if dump file exists
if [ ! -f "$DUMP_FILE" ]; then
    echo -e "${RED}❌ Dump file '$DUMP_FILE' not found!${NC}"
    echo "Please ensure the HR CRM dump file exists in the current directory."
    exit 1
fi

# Check if MySQL container is running
if ! docker ps --format "table {{.Names}}" | grep -q "hugr-mysql"; then
    echo -e "${RED}❌ MySQL container 'hugr-mysql' is not running!${NC}"
    echo "Please start hugr infrastructure first:"
    echo "  cd ../../"
    echo "  ./scripts/start.sh"
    exit 1
fi

# Test connection to MySQL
echo -e "${YELLOW}🔄 Testing MySQL connection...${NC}"
if ! docker-compose -f ../../docker-compose.yaml exec mysql mysqladmin ping -h localhost -u root -p"$MYSQL_ROOT_PASSWORD"  >/dev/null 2>&1; then
    echo -e "${RED}❌ Failed to connect to MySQL!${NC}"
    echo "Please ensure hugr infrastructure is running properly."
    exit 1
fi
echo -e "${GREEN}✅ MySQL connection successful${NC}"

# Check if hr_crm database exists
echo -e "${YELLOW}🔄 Checking if '$EXAMPLE_DB_NAME' database exists...${NC}"
DB_EXISTS=$(docker-compose -f ../../docker-compose.yaml exec -T mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD"  -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='$EXAMPLE_DB_NAME';" 2>/dev/null | grep -c "$EXAMPLE_DB_NAME" || echo "0")

if [ "$DB_EXISTS" -gt 0 ]; then
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
    
    # Drop the existing database
    echo -e "${YELLOW}🔄 Dropping existing database '$EXAMPLE_DB_NAME'...${NC}"
    docker-compose -f ../../docker-compose.yaml exec -T mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD"  -e "DROP DATABASE IF EXISTS $EXAMPLE_DB_NAME;" >/dev/null 2>&1
    echo -e "${GREEN}✅ Existing database '$EXAMPLE_DB_NAME' dropped${NC}"
fi

# Execute dump file to create database, tables and load data
echo -e "${YELLOW}🔄 Creating database and importing data from '$DUMP_FILE'...${NC}"
if docker-compose -f ../../docker-compose.yaml exec -T mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD"  < "$DUMP_FILE" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ HR CRM database and data imported successfully${NC}"
else
    echo -e "${RED}❌ Failed to import data from '$DUMP_FILE'!${NC}"
    echo "Please check the dump file format and content."
    exit 1
fi

# Verify the import by checking table count
echo -e "${YELLOW}🔄 Verifying import...${NC}"
TABLE_COUNT=$(docker-compose -f ../../docker-compose.yaml exec -T mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD"  "$EXAMPLE_DB_NAME" -e "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='$EXAMPLE_DB_NAME';" 2>/dev/null | tail -n 1 | tr -d '\r')

if [ "$TABLE_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ Import verified: $TABLE_COUNT tables found${NC}"
else
    echo -e "${RED}❌ Import verification failed: no tables found${NC}"
    exit 1
fi

# add privileges to the user
echo -e "${YELLOW}🔄 Granting privileges to user '$MYSQL_USER'${NC}"
if docker-compose exec mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON hr_crm.* TO 'hugr'@'%';"; then
    docker-compose exec mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"
    echo -e "${GREEN}✅ Privileges granted to user '$MYSQL_USER'${NC}"
else
    echo -e "${RED}❌ Failed to grant privileges to user '$MYSQL_USER'${NC}"
    exit 1
fi

# Show table list
echo -e "${BLUE}📊 Tables in '$EXAMPLE_DB_NAME' database:${NC}"
docker-compose -f ../../docker-compose.yaml exec -T mysql mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$EXAMPLE_DB_NAME" -e "SHOW TABLES;" 2>/dev/null | tail -n +2 | sed 's/^/ - /'

# Show some basic statistics
echo ""
echo -e "${BLUE}📈 Database Statistics:${NC}"

# Count records in key tables
CANDIDATES_COUNT=$(docker-compose -f ../../docker-compose.yaml exec -T mysql mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$EXAMPLE_DB_NAME" -e "SELECT COUNT(*) FROM candidates;" 2>/dev/null | tail -n 1 | tr -d '\r')
POSITIONS_COUNT=$(docker-compose -f ../../docker-compose.yaml exec -T mysql mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$EXAMPLE_DB_NAME" -e "SELECT COUNT(*) FROM positions;" 2>/dev/null | tail -n 1 | tr -d '\r')
APPLICATIONS_COUNT=$(docker-compose -f ../../docker-compose.yaml exec -T mysql mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$EXAMPLE_DB_NAME" -e "SELECT COUNT(*) FROM applications;" 2>/dev/null | tail -n 1 | tr -d '\r')
INTERVIEWS_COUNT=$(docker-compose -f ../../docker-compose.yaml exec -T mysql mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$EXAMPLE_DB_NAME" -e "SELECT COUNT(*) FROM interviews;" 2>/dev/null | tail -n 1 | tr -d '\r')

echo "   - Candidates: $CANDIDATES_COUNT"
echo "   - Positions: $POSITIONS_COUNT"
echo "   - Applications: $APPLICATIONS_COUNT"
echo "   - Interviews: $INTERVIEWS_COUNT"

echo ""
echo -e "${GREEN}🎉 HR CRM database deployment completed successfully!${NC}"
echo ""
echo -e "${BLUE}📝 Connection details:${NC}"
echo "   Database: $EXAMPLE_DB_NAME"
echo "   Host: localhost:${MYSQL_PORT}"
echo "   User: $MYSQL_USER"
echo ""
echo -e "${BLUE}🔗 Next steps:${NC}"
echo "   • Update hugr schema to connect to '$EXAMPLE_DB_NAME' database"
echo "   • Test connection: docker-compose -f ../../docker-compose.yaml exec mysql mysql -u $MYSQL_USER -p $EXAMPLE_DB_NAME"
echo ""
