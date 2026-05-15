#!/usr/bin/env bash
set -euo pipefail

# ITER MVP — Development Environment Startup
# This script starts the Rust server and Flutter app (Supabase cloud DB, no local Postgres)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env exists
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    echo -e "${RED}❌ .env file not found. Please copy .env.example to .env and configure your Supabase credentials.${NC}"
    echo -e "${YELLOW}📝 Run: cp .env.example .env && edit .env${NC}"
    exit 1
fi

echo "🚀 Starting ITER MVP development environment..."
echo "📦 Using Supabase cloud database (no local Postgres needed)"

# Start Rust server (background)
echo "🦀 Starting Rust server..."
cd "$PROJECT_ROOT/server"
cargo run &
SERVER_PID=$!
echo -e "${GREEN}✅ Rust server started (PID: $SERVER_PID)${NC}"

# Wait for server to be ready
echo "⏳ Waiting for Rust server..."
until curl -s http://localhost:8080/health > /dev/null 2>&1; do
    sleep 1
done
echo -e "${GREEN}✅ Rust server ready at http://localhost:8080${NC}"

# Start Flutter app (foreground)
echo "📱 Starting Flutter app..."
cd "$PROJECT_ROOT/app"
flutter run

# Cleanup on exit
echo ""
echo "🛑 Shutting down..."
kill $SERVER_PID 2>/dev/null || true
echo -e "${GREEN}✅ Cleanup complete${NC}"
