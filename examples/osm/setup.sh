#!/bin/bash
# setup.sh
# Setup script for OSM DuckDB example

set -e

# Default values
REGION="bw"
TARGET="dev"
FORCE_CLONE="false"
SKIP_DEPS="false"

show_help() {
    echo "OSM DuckDB Example Setup"
    echo "========================"
    echo ""
    echo "Usage:"
    echo "  $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -r, --region REGION    OSM region to process (default: bw)"
    echo "  -t, --target TARGET    dbt target (default: dev)"
    echo "  -f, --force-clone      Force re-clone even if directory exists"
    echo "  --skip-deps            Skip dependency installation"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                     # Setup with default region (bw)"
    echo "  $0 --region berlin     # Setup with Berlin region"
    echo "  $0 --force-clone       # Force fresh clone"
    echo ""
    echo "Output:"
    echo "  Database will be created at: ../../data/osm/data/processed/\${REGION}.duckdb"
    echo ""
    echo "Requirements:"
    echo "  - Python 3.8+"
    echo "  - At least 16GB RAM for Baden-Württemberg"
    echo "  - At least 100GB disk space"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -t|--target)
            TARGET="$2"
            shift 2
            ;;
        -f|--force-clone)
            FORCE_CLONE="true"
            shift
            ;;
        --skip-deps)
            SKIP_DEPS="true"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

echo "=== OSM DuckDB Example Setup ==="
echo "Region: $REGION"
echo "Target: $TARGET"
echo "Working directory: ../../data/osm"
echo ""

# Create base directories
echo "📁 Creating directories..."
mkdir -p ../../data
cd ../../data

# Set working directory
WORK_DIR="$(pwd)/osm"
echo "Working in: $WORK_DIR"

# Clone or update repository
if [ -d "$WORK_DIR" ] && [ "$FORCE_CLONE" = "false" ]; then
    echo "📂 osm_dbt directory already exists, updating..."
    cd "$WORK_DIR"
    
    # Check if it's a git repository
    if [ -d ".git" ]; then
        echo "   Pulling latest changes..."
        git pull origin main || git pull origin master || echo "   ⚠️  Could not pull changes"
    else
        echo "   ⚠️  Directory exists but is not a git repository"
        echo "   Use --force-clone to recreate"
    fi
else
    if [ -d "$WORK_DIR" ]; then
        echo "🗑️  Removing existing directory (force clone)..."
        rm -rf "$WORK_DIR"
    fi
    
    echo "📥 Cloning osm_dbt repository..."
    git clone https://github.com/hugr-lab/osm_dbt.git "$WORK_DIR"
    cd "$WORK_DIR"
fi

# Verify we're in the right directory
if [ ! -f "dbt_project.yml" ]; then
    echo "❌ Error: dbt_project.yml not found. Are we in the right directory?"
    echo "Current directory: $(pwd)"
    echo "Directory contents:"
    ls -la
    exit 1
fi

echo "✅ Repository ready at: $(pwd)"
echo ""

# Check system requirements
echo "🔍 Checking system requirements..."

# Check Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d ' ' -f 2)
    echo "   ✅ Python: $PYTHON_VERSION"
else
    echo "   ❌ Python 3 not found. Please install Python 3.8+"
    exit 1
fi

# Check available memory (cross-platform)
if [ -f /proc/meminfo ]; then
    # Linux
    TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_MEM_GB=$((TOTAL_MEM_KB / 1024 / 1024))
    echo "   💾 Available RAM: ${TOTAL_MEM_GB}GB"
    
    if [ "$TOTAL_MEM_GB" -lt 16 ]; then
        echo "   ⚠️  Warning: Recommended minimum is 16GB RAM for region '$REGION'"
        echo "   Consider using a smaller region or adding more memory"
    fi
elif command -v sysctl >/dev/null 2>&1; then
    # macOS
    TOTAL_MEM_BYTES=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
    TOTAL_MEM_GB=$((TOTAL_MEM_BYTES / 1024 / 1024 / 1024))
    if [ "$TOTAL_MEM_GB" -gt 0 ]; then
        echo "   💾 Available RAM: ${TOTAL_MEM_GB}GB"
        
        if [ "$TOTAL_MEM_GB" -lt 16 ]; then
            echo "   ⚠️  Warning: Recommended minimum is 16GB RAM for region '$REGION'"
            echo "   Consider using a smaller region or adding more memory"
        fi
    else
        echo "   💾 Available RAM: Unable to detect"
    fi
else
    echo "   💾 Available RAM: Unable to detect"
fi

# Check disk space (cross-platform)
if df -h . >/dev/null 2>&1; then
    # Try df -h first (most compatible)
    DISK_INFO=$(df -h . | tail -1)
    AVAILABLE_SPACE=$(echo "$DISK_INFO" | awk '{print $4}' | sed 's/[^0-9]//g')
    SPACE_UNIT=$(echo "$DISK_INFO" | awk '{print $4}' | sed 's/[0-9]//g')
    
    if [ -n "$AVAILABLE_SPACE" ] && [ "$AVAILABLE_SPACE" -gt 0 ]; then
        echo "   💿 Available disk space: ${AVAILABLE_SPACE}${SPACE_UNIT}"
        
        # Convert to GB for comparison (rough)
        SPACE_GB="$AVAILABLE_SPACE"
        case "$SPACE_UNIT" in
            "T"|"TB") SPACE_GB=$((AVAILABLE_SPACE * 1024)) ;;
            "G"|"GB") SPACE_GB="$AVAILABLE_SPACE" ;;
            "M"|"MB") SPACE_GB=$((AVAILABLE_SPACE / 1024)) ;;
            "K"|"KB") SPACE_GB=$((AVAILABLE_SPACE / 1024 / 1024)) ;;
        esac
        
        if [ "$SPACE_GB" -lt 100 ]; then
            echo "   ⚠️  Warning: Recommended minimum is 100GB disk space"
            echo "   Consider freeing up space or using a smaller region"
        fi
    else
        echo "   💿 Available disk space: Unable to calculate"
    fi
else
    echo "   💿 Available disk space: Unable to detect"
fi

echo ""

# Install dependencies
if [ "$SKIP_DEPS" = "false" ]; then
    echo "📦 Installing dependencies..."
    
    # Check if requirements.txt exists
    if [ -f "requirements.txt" ]; then
        echo "   Installing Python packages..."
        pip3 install -r requirements.txt
    else
        echo "   Installing core dbt dependencies..."
        pip3 install dbt-duckdb dbt-core
    fi
    
    # Install dbt packages
    echo "   Installing dbt packages..."
    make install || {
        echo "   ⚠️  make install failed, trying dbt deps directly..."
        dbt deps || echo "   ⚠️  dbt deps also failed"
    }
    
    echo "   ✅ Dependencies installed"
else
    echo "⏭️  Skipping dependency installation"
fi

echo ""

# Setup environment
echo "⚙️  Setting up environment..."

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "   Creating .env file..."
    cat > .env << EOF
# OSM Processing Configuration
OSM_REGION_NAME="$REGION"
DBT_TARGET="$TARGET"

# Performance settings
DUCKDB_MEMORY_LIMIT="16GB"
DUCKDB_THREADS="4"

# Processing options
MAX_RELATION_DEPTH="10"
ENABLE_COMPLEX_MULTIPOLYGONS="true"

# Paths (will be set by scripts)
OSM_PBF_PATH=""
OSM_DOWNLOAD_URL=""
EOF
    echo "   ✅ .env file created"
else
    echo "   ✅ .env file already exists"
fi

# Load environment variables from .env file
echo "   Loading environment variables..."
if [ -f ".env" ]; then
    set -a  # automatically export all variables
    source .env
    set +a  # stop automatically exporting
    echo "   ✅ Environment variables loaded"
else
    echo "   ⚠️  .env file not found"
fi

# Check available regions
echo ""
echo "📋 Checking available regions..."
if make list-regions 2>/dev/null; then
    echo "   ✅ Region list available"
else
    echo "   ⚠️  Could not list regions, continuing anyway..."
fi

echo ""

# Start processing
echo "🚀 Starting OSM data processing for region: $REGION"
echo "   This may take 10-30 minutes depending on your system..."
echo "   Processing will download ~2GB and create ~5GB database"
echo ""

# Set environment variables for make command
export OSM_REGION_NAME="$REGION"
export DBT_TARGET="$TARGET"
export REGION="$REGION"
export TARGET="$TARGET"

# Use make quick-region to download and process
echo "📥 Running: make quick-region REGION=$REGION TARGET=$TARGET"
if make quick-region REGION="$REGION" TARGET="$TARGET"; then
    echo ""
    echo "✅ OSM data processing completed successfully!"
else
    echo ""
    echo "❌ OSM data processing failed!"
    echo "   Check the error messages above"
    echo "   You can try running individual steps:"
    echo "     make download-region REGION=$REGION"
    echo "     make process-region REGION=$REGION TARGET=$TARGET"
    echo "   Or check if OSM_PBF_PATH is set correctly:"
    echo "     echo \$OSM_PBF_PATH"
    exit 1
fi

# Verify database creation
DB_PATH="./data/processed/${REGION}"
if [ "$TARGET" != "dev" ]; then
    DB_PATH="${DB_PATH}_${TARGET}"
fi
DB_PATH="${DB_PATH}.duckdb"

echo ""
echo "🔍 Verifying database creation..."
if [ -f "$DB_PATH" ]; then
    DB_SIZE=$(du -h "$DB_PATH" | cut -f1)
    echo "   ✅ Database created: $DB_PATH"
    echo "   📏 Database size: $DB_SIZE"
else
    echo "   ❌ Database not found at: $DB_PATH"
    echo "   Check the processing logs above"
    exit 1
fi

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📋 Summary:"
echo "   Region: $REGION"
echo "   Target: $TARGET" 
echo "   Database: $DB_PATH"
echo "   Working directory: $(pwd)"
echo ""
echo "🔗 Next steps for hugr integration:"
echo ""
echo "1. Start hugr server (if not already running)"
echo ""
echo "2. Add data source via GraphQL mutation:"
echo ""
cat << EOF
mutation addOSMDataSource {
  core {
    insert_data_sources(data: {
      name: "osm.${REGION}"
      description: "OpenStreetMap data ${REGION}"
      type: "duckdb"
      prefix: "osm_${REGION}"
      path: "/workspace/data/osm/data/processed/${REGION}.duckdb"
      read_only: true
      as_module: true
      self_defined: true
    }) {
      name type description path
    }
  }
}
EOF
echo ""
echo "3. Load the data source:"
echo ""
cat << EOF
mutation loadOSMDataSource {
  function {
    core {
      load_data_source(name: "osm.${REGION}") {
        success
        message
      }
    }
  }
}
EOF
echo ""
echo "4. Test with a simple query:"
echo ""
cat << EOF
query testOSMData {
  osm{
    ${REGION} {
      osm_buildings(limit: 10) {
        osm_id
        name
        building_type
      }
    }
  }
}
EOF
echo ""
echo "💡 Tips:"
echo "   - Database path in hugr should match your deployment setup"
echo "   - Use read_only: true for production environments"
echo "   - Adjust prefix to avoid naming conflicts"
echo ""
echo "📚 For more examples and advanced usage, see the README.md"
echo ""
echo "✨ Happy mapping! 🗺️"