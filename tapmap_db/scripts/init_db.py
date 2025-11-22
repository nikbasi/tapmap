#!/usr/bin/env python3
import os
import sys
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def get_db_config():
    return {
        'dbname': os.getenv('DB_NAME', 'tapmap_db'),
        'user': os.getenv('DB_USER', 'postgres'),
        'password': os.getenv('DB_PASSWORD', ''),
        'host': os.getenv('DB_HOST', 'localhost'),
        'port': os.getenv('DB_PORT', '5432')
    }

def create_database(config):
    """Create database if it doesn't exist."""
    dbname = config['dbname']
    print(f"Checking if database '{dbname}' exists...")
    
    # Connect to 'postgres' db to create new db
    try:
        conn = psycopg2.connect(
            dbname='postgres',
            user=config['user'],
            password=config['password'],
            host=config['host'],
            port=config['port']
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cur = conn.cursor()
        
        # Check if db exists
        cur.execute(f"SELECT 1 FROM pg_catalog.pg_database WHERE datname = '{dbname}'")
        exists = cur.fetchone()
        
        if not exists:
            print(f"Creating database '{dbname}'...")
            cur.execute(f"CREATE DATABASE {dbname}")
            print("✅ Database created successfully.")
        else:
            print(f"Database '{dbname}' already exists.")
            
        cur.close()
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Error creating database: {e}")
        return False

def run_sql_file(conn, file_path):
    """Execute SQL file."""
    print(f"Executing {file_path}...")
    try:
        with open(file_path, 'r') as f:
            sql = f.read()
        
        cur = conn.cursor()
        cur.execute(sql)
        conn.commit()
        cur.close()
        print(f"✅ Successfully executed {file_path}")
        return True
    except Exception as e:
        print(f"❌ Error executing {file_path}: {e}")
        conn.rollback()
        return False

def init_db():
    config = get_db_config()
    
    # 1. Create Database
    if not create_database(config):
        sys.exit(1)
    
    # 2. Connect to new database
    try:
        print(f"Connecting to '{config['dbname']}'...")
        conn = psycopg2.connect(**config)
    except Exception as e:
        print(f"❌ Error connecting to database: {e}")
        sys.exit(1)
        
    # 3. Apply Schema
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    schema_path = os.path.join(base_dir, 'sql', 'schema.sql')
    helpers_path = os.path.join(base_dir, 'sql', 'query_helpers.sql')
    
    if not run_sql_file(conn, schema_path):
        conn.close()
        sys.exit(1)
        
    if not run_sql_file(conn, helpers_path):
        conn.close()
        sys.exit(1)
        
    conn.close()
    print("\n✨ Database initialization complete!")

if __name__ == "__main__":
    init_db()
