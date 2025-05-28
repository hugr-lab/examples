#!/bin/bash

set -e

# Default values
REMOVE_VOLUMES=false
HELP=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--volumes)
      REMOVE_VOLUMES=true
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
    echo "hugr Infrastructure Stop Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -v, --volumes       Also remove volumes (WARNING: deletes all data)"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Stop all services"
    echo "  $0 -v               # Stop services and remove volumes"
    echo ""
    exit 0
fi

echo "🛑 Stopping hugr Infrastructure"
echo "==============================="

# Stop all services with all profiles
echo "🔄 Stopping all services..."
docker-compose --profile cache --profile monitoring down

if [ "$REMOVE_VOLUMES" = true ]; then
    echo "⚠️  Removing volumes (this will delete all data)..."
    echo "   Are you sure? This action cannot be undone! (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        docker-compose --profile cache --profile monitoring down -v
        echo "🗑️  Volumes removed"
    else
        echo "Volume removal cancelled"
    fi
fi

# Clean up any orphaned containers
echo "🧹 Cleaning up orphaned containers..."
docker-compose --profile cache --profile monitoring down --remove-orphans

echo ""
echo "✅ hugr Infrastructure Stopped"
echo ""
echo "📝 Available commands:"
echo "   • Restart: './scripts/start.sh'"
echo "   • View remaining containers: 'docker ps'"
echo "   • Remove everything: './scripts/stop.sh -v'"
echo ""