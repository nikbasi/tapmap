#!/bin/bash

# TapMap Database Setup Script
# This script helps set up the local PostgreSQL database for development

set -e

echo "🚰 TapMap Database Setup"
echo "========================"
echo ""

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "⚠️  psql not found in PATH"
    
    # Check for Postgres.app on macOS
    POSTGRES_APP_PATH=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -d "/Applications/Postgres.app" ]; then
            # Find the latest version of psql in Postgres.app
            POSTGRES_APP_PATH=$(find /Applications/Postgres.app/Contents/Versions -name psql -type f 2>/dev/null | head -1)
            if [ -n "$POSTGRES_APP_PATH" ]; then
                POSTGRES_BIN_DIR=$(dirname "$POSTGRES_APP_PATH")
                echo "✓ Found Postgres.app at /Applications/Postgres.app"
                echo "  PostgreSQL binaries found at: $POSTGRES_BIN_DIR"
                echo ""
                echo "To use PostgreSQL, we need to add it to your PATH."
                echo ""
                read -p "Add to PATH (t)emporarily or (p)ermanently? [t]: " PATH_CHOICE
                PATH_CHOICE=${PATH_CHOICE:-t}
                
                if [[ "$PATH_CHOICE" == "p" ]] || [[ "$PATH_CHOICE" == "P" ]]; then
                    # Add permanently to ~/.zshrc
                    SHELL_CONFIG="$HOME/.zshrc"
                    if [ -f "$HOME/.bash_profile" ] && [ ! -f "$HOME/.zshrc" ]; then
                        SHELL_CONFIG="$HOME/.bash_profile"
                    fi
                    
                    EXPORT_LINE="export PATH=\"$POSTGRES_BIN_DIR:\$PATH\""
                    
                    # Check if it's already in the config file
                    if grep -q "$POSTGRES_BIN_DIR" "$SHELL_CONFIG" 2>/dev/null; then
                        echo "✓ PATH already configured in $SHELL_CONFIG"
                    else
                        echo "" >> "$SHELL_CONFIG"
                        echo "# Postgres.app PATH" >> "$SHELL_CONFIG"
                        echo "$EXPORT_LINE" >> "$SHELL_CONFIG"
                        echo "✓ Added to $SHELL_CONFIG"
                        echo "  Run 'source $SHELL_CONFIG' or restart your terminal to apply."
                    fi
                    
                    # Also add to current session
                    export PATH="$POSTGRES_BIN_DIR:$PATH"
                    echo "✓ Added to PATH for this session"
                else
                    # Add temporarily to current session
                    export PATH="$POSTGRES_BIN_DIR:$PATH"
                    echo "✓ Added to PATH for this session only"
                fi
                echo ""
            fi
        fi
    fi
    
    # Check again if psql is now available
    if ! command -v psql &> /dev/null; then
        echo "❌ PostgreSQL is not installed or not accessible."
        echo "Please install PostgreSQL 18 first:"
        echo "  macOS:"
        echo "    - Postgres.app: https://postgresapp.com/"
        echo "    - Homebrew: brew install postgresql@18"
        echo "  Ubuntu: sudo apt-get install postgresql-18 postgresql-contrib"
        exit 1
    fi
fi

# Check PostgreSQL version
PG_VERSION=$(psql --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
echo "✓ PostgreSQL found (version $PG_VERSION)"

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed."
    exit 1
fi

echo "✓ Python 3 found"

# Get database credentials
read -p "Database name [tapmap_db]: " DB_NAME
DB_NAME=${DB_NAME:-tapmap_db}

read -p "Database user [postgres]: " DB_USER
DB_USER=${DB_USER:-postgres}

read -sp "Database password: " DB_PASSWORD
echo ""

read -p "Database host [localhost]: " DB_HOST
DB_HOST=${DB_HOST:-localhost}

read -p "Database port [5432]: " DB_PORT
DB_PORT=${DB_PORT:-5432}

# Install Python dependencies
echo ""
echo "📦 Installing Python dependencies..."
pip3 install -r requirements.txt

# Create database (if it doesn't exist)
echo ""
echo "🗄️  Creating database..."
export PGPASSWORD=$DB_PASSWORD
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "CREATE DATABASE $DB_NAME;" 2>/dev/null || echo "Database already exists or creation failed (this is OK if it already exists)"

# Create schema
echo ""
echo "📋 Creating database schema..."
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f sql/schema.sql

# Load query helpers
echo ""
echo "🔧 Loading query helper functions..."
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f sql/query_helpers.sql

# Ask about importing data
echo ""
read -p "Do you want to import fountain data now? (y/n) [y]: " IMPORT_DATA
IMPORT_DATA=${IMPORT_DATA:-y}

if [ "$IMPORT_DATA" = "y" ] || [ "$IMPORT_DATA" = "Y" ]; then
    JSON_FILE="data/world_fountains_combined.json"
    if [ ! -f "$JSON_FILE" ]; then
        echo "❌ JSON file not found: $JSON_FILE"
        echo "Skipping data import."
    else
        echo ""
        echo "📥 Importing fountain data (this may take a while)..."
        python3 scripts/import_data.py \
            --json "$JSON_FILE" \
            --dbname "$DB_NAME" \
            --user "$DB_USER" \
            --password "$DB_PASSWORD" \
            --host "$DB_HOST" \
            --port "$DB_PORT"
    fi
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Your database is ready. Connection details:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo ""
echo "To test the connection:"
echo "  psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME"
echo ""
echo "To query nearby fountains:"
echo "  SELECT * FROM find_fountains_nearby(37.7749, -122.4194, 5.0, 50);"


