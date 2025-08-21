#!/bin/bash

# Database Setup Script for Fountain Map Application
# This script sets up PostgreSQL database and user for the fountain application

set -e

# Configuration
DB_NAME="tapmap_db"
DB_USER="tapmap_user"
DB_PASSWORD="tapmap_password"
DB_HOST="localhost"
DB_PORT="5432"

echo "Setting up PostgreSQL database for Fountain Map Application..."

# Check if PostgreSQL is running
if ! pg_isready -h $DB_HOST -p $DB_PORT -U postgres > /dev/null 2>&1; then
    echo "Error: PostgreSQL is not running or not accessible"
    echo "Please start PostgreSQL service and ensure it's accessible"
    exit 1
fi

echo "PostgreSQL is running. Proceeding with setup..."

# Create database user
echo "Creating database user..."
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" || echo "User already exists or error occurred"

# Create database
echo "Creating database..."
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" || echo "Database already exists or error occurred"

# Grant privileges
echo "Granting privileges..."
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

# Connect to the new database and create schema
echo "Creating database schema..."
sudo -u postgres psql -d $DB_NAME -f schema.sql

echo "Database setup completed successfully!"
echo ""
echo "Database Information:"
echo "  Name: $DB_NAME"
echo "  User: $DB_USER"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo ""
echo "You can now run the import script to populate the database with fountain data."
