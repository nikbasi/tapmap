#!/bin/bash

# TapMap Production Mode Script
# Starts the Flutter app connected to the REMOTE production server
# Does NOT start a local API server or database

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}🚀 Starting TapMap in Production Mode...${NC}"
echo -e "${GREEN}Connecting to remote server: http://129.158.216.36/api${NC}"

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR"

cd "$PROJECT_ROOT/tapmap_app"

# Run Flutter app pointing to production API
flutter run -d chrome --dart-define=API_URL=http://129.158.216.36/api
