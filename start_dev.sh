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
flutter run -d chrome

# Cleanup when Flutter app exits
cleanup

