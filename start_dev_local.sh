#!/bin/bash

# TapMap Development Script
# Starts both the API server and Flutter app

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR"

# Function to cleanup background processes
cleanup() {
    echo -e "\n${YELLOW}Stopping services...${NC}"
    if [ ! -z "$API_PID" ]; then
        kill $API_PID 2>/dev/null || true
        echo -e "${GREEN}✓ API server stopped${NC}"
    fi
    exit 0
}

# Trap Ctrl+C and cleanup
trap cleanup INT TERM

# Function to check if PostgreSQL is running
check_postgres() {
    # Try to find pg_isready
    PG_ISREADY=""
    
    # Check for Postgres.app on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -d "/Applications/Postgres.app" ]; then
            PG_ISREADY=$(find /Applications/Postgres.app/Contents/Versions -name pg_isready -type f 2>/dev/null | head -1)
        fi
    fi
    
    # Check for system PostgreSQL (Homebrew or system install)
    if [ -z "$PG_ISREADY" ]; then
        if command -v pg_isready &> /dev/null; then
            PG_ISREADY="pg_isready"
        fi
    fi
    
    if [ -z "$PG_ISREADY" ]; then
        return 1
    fi
    
    # Check if PostgreSQL is accepting connections
    $PG_ISREADY -h localhost -p 5432 > /dev/null 2>&1
}

# Function to start PostgreSQL
start_postgres() {
    echo -e "${YELLOW}Starting PostgreSQL...${NC}"
    
    # Try Postgres.app on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -d "/Applications/Postgres.app" ]; then
            open -a Postgres.app > /dev/null 2>&1
            echo -e "${GREEN}✓ Started Postgres.app${NC}"
            return 0
        fi
    fi
    
    # Try Homebrew PostgreSQL
    if command -v brew &> /dev/null; then
        # Check for PostgreSQL service
        if brew services list 2>/dev/null | grep -q postgresql; then
            brew services start postgresql > /dev/null 2>&1
            echo -e "${GREEN}✓ Started PostgreSQL via Homebrew${NC}"
            return 0
        fi
    fi
    
    # Try systemctl (Linux)
    if command -v systemctl &> /dev/null; then
        if systemctl is-enabled postgresql > /dev/null 2>&1; then
            sudo systemctl start postgresql > /dev/null 2>&1
            echo -e "${GREEN}✓ Started PostgreSQL via systemctl${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}✗ Could not start PostgreSQL automatically${NC}"
    echo -e "${YELLOW}Please start PostgreSQL manually and try again${NC}"
    return 1
}

# Check and start PostgreSQL if needed
if ! check_postgres; then
    echo -e "${YELLOW}PostgreSQL is not running${NC}"
    if start_postgres; then
        echo -e "${YELLOW}Waiting for PostgreSQL to start...${NC}"
        # Wait up to 15 seconds for PostgreSQL to be ready
        for i in {1..15}; do
            if check_postgres; then
                echo -e "${GREEN}✓ PostgreSQL is ready${NC}"
                break
            fi
            sleep 1
        done
        
        if ! check_postgres; then
            echo -e "${RED}✗ PostgreSQL failed to start. Please start it manually and try again.${NC}"
            exit 1
        fi
    else
        exit 1
    fi
else
    echo -e "${GREEN}✓ PostgreSQL is running${NC}"
fi

# Check if API server is already running
if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${YELLOW}API server is already running on port 3000${NC}"
else
    echo -e "${GREEN}Starting API server...${NC}"
    cd "$PROJECT_ROOT/tapmap_api"
    
    # Check if .env exists
    if [ ! -f .env ]; then
        echo -e "${YELLOW}Warning: .env file not found. Using defaults.${NC}"
    fi
    
    # Start API server in background
    python3 app.py > /tmp/tapmap_api.log 2>&1 &
    API_PID=$!
    
    # Wait for API server to start
    echo -e "${YELLOW}Waiting for API server to start...${NC}"
    for i in {1..10}; do
        if curl -s http://localhost:3000/health > /dev/null 2>&1; then
            echo -e "${GREEN}✓ API server started (PID: $API_PID)${NC}"
            break
        fi
        sleep 1
    done
    
    if ! curl -s http://localhost:3000/health > /dev/null 2>&1; then
        echo -e "${RED}✗ Failed to start API server. Check /tmp/tapmap_api.log${NC}"
        exit 1
    fi
fi

# Start Flutter app
echo -e "${GREEN}Starting Flutter app...${NC}"
cd "$PROJECT_ROOT/tapmap_app"
flutter run -d chrome --dart-define=API_URL=http://localhost:3000/api

# Cleanup when Flutter app exits
cleanup

