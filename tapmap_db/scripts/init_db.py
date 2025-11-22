#!/usr/bin/env python3
import os
import sys
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def get_target_config():
    """Get the configuration for the database we want to create/use."""
    return {
        'dbname': os.getenv('DB_NAME', 'tapmap_db'),
        'user': os.getenv('DB_USER', 'postgres'),
        'password': os.getenv('DB_PASSWORD', ''),
        'host': os.getenv('DB_HOST', 'localhost'),
        'port': os.getenv('DB_PORT', '5432')
    }

def get_superuser_connection(host, port):
    """Try to connect as postgres superuser."""
    try:
        # Try connecting as 'postgres' with no password (common local setup)
        conn = psycopg2.connect(
            dbname='postgres',
            user='postgres',
            host=host,
            port=port,
            password=''
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        return conn
    except psycopg2.OperationalError as e:
        # If that fails, it might need a password
        print(f"⚠️  Could not connect to 'postgres' without password.")
        print(f"   Error: {e}")
        
        import getpass
        print("\nPlease enter the password for the 'postgres' superuser:")
        password = getpass.getpass("Password: ")
        
        try:
            conn = psycopg2.connect(
                dbname='postgres',
                user='postgres',
                host=host,
                port=port,
                password=password
            )
            conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
            return conn
        except Exception as e2:
            print(f"❌ Could not connect to 'postgres' database with provided password.")
            print(f"   Error: {e2}")
            return None

def create_role_if_missing(conn, user, password):
    """Create the database user if it doesn't exist."""
    if user == 'postgres':
        return True
        
    cur = conn.cursor()
    cur.execute("SELECT 1 FROM pg_roles WHERE rolname=%s", (user,))
    exists = cur.fetchone()
    
    if not exists:
        print(f"Creating user '{user}'...")
        try:
            # Parameterized queries for CREATE ROLE are tricky in psycopg2, 
            # but rolname/password are from config/env, so we trust them reasonably.
            # Still, let's be careful.
            cur.execute(f"CREATE USER {user} WITH PASSWORD '{password}'")
            print(f"✅ User '{user}' created.")
        except Exception as e:
            print(f"❌ Error creating user '{user}': {e}")
            return False
    else:
        print(f"User '{user}' already exists.")
        # Optional: Update password? Better not to overwrite blindly.
    
    cur.close()
    return True

def create_database(conn, dbname, owner):
    """Create database if it doesn't exist."""
    cur = conn.cursor()
    
    # Check if db exists
    cur.execute(f"SELECT 1 FROM pg_catalog.pg_database WHERE datname = '{dbname}'")
    exists = cur.fetchone()
    
    if not exists:
        print(f"Creating database '{dbname}' owned by '{owner}'...")
        try:
            cur.execute(f"CREATE DATABASE {dbname} OWNER {owner}")
            print(f"✅ Database '{dbname}' created successfully.")
        except Exception as e:
            print(f"❌ Error creating database: {e}")
            return False
    else:
        print(f"Database '{dbname}' already exists.")
            
    cur.close()
    return True

def run_sql_file(conn, file_path):
    """Execute SQL file."""
    print(f"Executing {os.path.basename(file_path)}...")
    try:
        with open(file_path, 'r') as f:
            sql = f.read()
        
        cur = conn.cursor()
        cur.execute(sql)
        conn.commit()
        cur.close()
        print(f"✅ Successfully executed {os.path.basename(file_path)}")
        return True
    except Exception as e:
        print(f"❌ Error executing {os.path.basename(file_path)}: {e}")
        conn.rollback()
        return False

def init_db():
    print("🚀 Initializing TapMap Database...")
    config = get_target_config()
    
    # 1. Connect as Superuser
    print("Connecting to PostgreSQL server...")
    su_conn = get_superuser_connection(config['host'], config['port'])
    if not su_conn:
        sys.exit(1)
        
    # 2. Create User (Role)
    if not create_role_if_missing(su_conn, config['user'], config['password']):
        su_conn.close()
        sys.exit(1)
        
    # 3. Create Database
    if not create_database(su_conn, config['dbname'], config['user']):
        su_conn.close()
        sys.exit(1)
        
    su_conn.close()
    
    # 4. Connect to new database to apply schema
    try:
        print(f"Connecting to '{config['dbname']}' as '{config['user']}'...")
        conn = psycopg2.connect(**config)
    except Exception as e:
        print(f"❌ Error connecting to database: {e}")
        print("   Double check your password in .env matches the database user.")
        sys.exit(1)
        
    # 5. Apply Schema
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
