#!/bin/bash

set -e

# Default values
MONITORING=false
CACHE=false
DETACHED=true
HELP=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -m|--monitoring)
      MONITORING=true
      shift
      ;;
    -c|--cache)
      CACHE=true
      shift
      ;;
    -f|--foreground)
      DETACHED=false
      shift
      ;;
    -h|--help)
      HELP=true
      shift
      ;;
    *)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

# Show help
if [ "$HELP" = true ]; then
    echo "hugr Infrastructure Startup Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -m, --monitoring    Enable monitoring stack (Grafana + Prometheus)"
    echo "  -c, --cache         Enable Redis L2 cache"
    echo "  -f, --foreground    Run in foreground (default: detached)"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Start basic hugr infrastructure"
    echo "  $0 -m               # Start with monitoring"
    echo "  $0 -c -m            # Start with cache and monitoring"
    echo "  $0 -f               # Start in foreground"
    echo ""
    exit 0
fi

# Load environment variables
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from .env.example..."
    cp .env.example .env
fi

source .env

echo "🚀 Starting hugr Infrastructure"
echo "================================"

# Update environment based on flags
if [ "$CACHE" = true ]; then
    echo "🔄 Enabling L2 Cache (Redis)..."
    sed -i.bak 's/^CACHE_L2_ENABLED=.*/CACHE_L2_ENABLED=true/' .env && rm .env.bak
    export CACHE_L2_ENABLED=true
else
    sed -i.bak 's/^CACHE_L2_ENABLED=.*/CACHE_L2_ENABLED=false/' .env && rm .env.bak
    export CACHE_L2_ENABLED=false
fi

# Prepare docker-compose command
COMPOSE_CMD="docker-compose"
PROFILES=""

# Add profiles based on flags
if [ "$CACHE" = true ]; then
    PROFILES="$PROFILES --profile cache"
    echo "✅ Redis L2 cache will be started"
fi

if [ "$MONITORING" = true ]; then
    PROFILES="$PROFILES --profile monitoring"
    echo "✅ Monitoring stack will be started"
fi

# Set detached flag
if [ "$DETACHED" = true ]; then
    DETACH_FLAG="-d"
else
    DETACH_FLAG=""
    echo "ℹ️  Running in foreground mode (Ctrl+C to stop)"
fi

# Create necessary directories
echo "📁 Creating data directories..."
mkdir -p ./data/hugr
mkdir -p ./data/postgres
mkdir -p ./data/mysql
mkdir -p ./data/redis
mkdir -p ./data/minio

# Start core services first
echo "🔄 Starting core services (PostgreSQL, MySQL, MinIO)..."
$COMPOSE_CMD up $DETACH_FLAG postgres mysql minio

if [ "$DETACHED" = true ]; then
    # Wait for core services
    echo "⏳ Waiting for core services to be ready..."
    
    echo "   - PostgreSQL..."
    until docker-compose exec postgres pg_isready -U ${POSTGRES_USER:-hugr} -d ${POSTGRES_DB:-hugr} >/dev/null 2>&1; do
        sleep 2
    done
    echo "   ✅ PostgreSQL ready"
    
    echo "   - MinIO..."
    until curl -sf http://localhost:${MINIO_API_PORT:-9000}/minio/health/live >/dev/null 2>&1; do
        sleep 2
    done
    echo "   ✅ MinIO ready"
fi

# Start cache if enabled
if [ "$CACHE" = true ]; then
    echo "🔄 Starting Redis cache..."
    $COMPOSE_CMD $PROFILES up $DETACH_FLAG redis
    
    if [ "$DETACHED" = true ]; then
        echo "⏳ Waiting for Redis to be ready..."
        until docker-compose exec redis redis-cli --no-auth-warning -a "${REDIS_PASSWORD:-redis_password}" ping >/dev/null 2>&1; do
            sleep 2
        done
        echo "   ✅ Redis ready"
    fi
fi

# Start monitoring if enabled
if [ "$MONITORING" = true ]; then
    echo "🔄 Starting monitoring stack..."
    $COMPOSE_CMD $PROFILES up $DETACH_FLAG prometheus
    
    if [ "$DETACHED" = true ]; then
        echo "⏳ Waiting for Prometheus to be ready..."
        until curl -sf http://localhost:${PROMETHEUS_PORT:-18090}/-/ready >/dev/null 2>&1; do
            sleep 2
        done
        echo "   ✅ Prometheus ready"
    fi
fi

# Start hugr server
echo "🔄 Starting hugr server..."
$COMPOSE_CMD up $DETACH_FLAG hugr --build

if [ "$DETACHED" = true ]; then
    echo "⏳ Waiting for hugr to be ready..."
    echo "http://localhost:${HUGR_METRICS_PORT:-18001}/health"
    until curl -sf http://localhost:${HUGR_METRICS_PORT:-18001}/health >/dev/null 2>&1; do
        sleep 2
    done
    echo "   ✅ hugr server ready"
fi

# Start Grafana last if monitoring enabled
if [ "$MONITORING" = true ]; then
    echo "🔄 Starting Grafana..."
    $COMPOSE_CMD $PROFILES up $DETACH_FLAG grafana
    
    if [ "$DETACHED" = true ]; then
        echo "⏳ Waiting for Grafana to be ready..."
        until curl -sf http://localhost:${GRAFANA_PORT:-18091}/api/health >/dev/null 2>&1; do
            sleep 2
        done
        echo "   ✅ Grafana ready"
    fi
fi

if [ "$DETACHED" = true ]; then
    echo ""
    echo "🎉 hugr Infrastructure Started Successfully!"
    echo "=========================================="
    echo ""
    echo "🔗 Available Services:"
    echo "   🌐 hugr GraphiQL:  http://localhost:${HUGR_PORT:-18000}/admin"
    echo "   📊 hugr Metrics:   http://localhost:${HUGR_METRICS_PORT:-18001}/metrics"
    echo "   💚 hugr Health:    http://localhost:${HUGR_METRICS_PORT:-18001}/health"
    echo "   🗄️  PostgreSQL:     postgres://${POSTGRES_USER:-hugr}:${POSTGRES_PASSWORD:-hugr_password}@localhost:${POSTGRES_PORT:-5432}"
    echo "   🗄️  MySQL:          mysql://${MYSQL_USER:-hugr}:${MYSQL_PASSWORD:-hugr_password}@localhost:${MYSQL_PORT:-18036}"
    echo "   📦 MinIO Console:   http://localhost:${MINIO_CONSOLE_PORT:-18081} (${MINIO_USER:-minio_admin}/${MINIO_PASSWORD:-minio_password123})"
    
    if [ "$CACHE" = true ]; then
        echo "   🔄 Redis Cache:     localhost:${REDIS_PORT:-18079}"
    fi
    
    if [ "$MONITORING" = true ]; then
        echo "   📈 Grafana:        http://localhost:${GRAFANA_PORT:-18091} (admin/${GRAFANA_PASSWORD:-admin})"
        echo "   📊 Prometheus:     http://localhost:${PROMETHEUS_PORT:-18090}"
    fi
    
    echo ""
    echo "📝 Next Steps:"
    echo "   • Load an example: './scripts/load-example.sh getting-started'"
    echo "   • View logs: 'docker-compose logs -f hugr'"
    echo "   • Stop services: './scripts/stop.sh'"
    
    if [ "$MONITORING" = false ]; then
        echo "   • Add monitoring: './scripts/start.sh -m'"
    fi
    
    if [ "$CACHE" = false ]; then
        echo "   • Enable cache: './scripts/start.sh -c'"
    fi
    
    echo ""
else
    echo ""
    echo "🎉 Services started in foreground mode"
    echo "Press Ctrl+C to stop all services"
fi