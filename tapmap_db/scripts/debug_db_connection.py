#!/usr/bin/env python3
import os
import sys
import psycopg2
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def test_connection():
    print("--- Database Connection Debugger ---")
    
    # Get config
    dbname = os.getenv('DB_NAME', 'tapmap_db')
    user = os.getenv('DB_USER', 'postgres')
    password = os.getenv('DB_PASSWORD', '')
    host = os.getenv('DB_HOST', 'localhost')
    port = os.getenv('DB_PORT', '5432')
    
    print(f"Attempting connection with:")
    print(f"  Host: {host}")
    print(f"  Port: {port}")
    print(f"  Database: {dbname}")
    print(f"  User: {user}")
    print(f"  Password: {'*' * len(password) if password else '<EMPTY>'}")
    
    try:
        conn = psycopg2.connect(
            dbname=dbname,
            user=user,
            password=password,
            host=host,
            port=port
        )
        print("\n✅ SUCCESS: Connected to database successfully!")
        
        # Get server version
        cur = conn.cursor()
        cur.execute("SELECT version();")
        version = cur.fetchone()[0]
        print(f"Server Version: {version}")
        
        # Check current user
        cur.execute("SELECT current_user;")
        current_user = cur.fetchone()[0]
        print(f"Authenticated as: {current_user}")
        
        conn.close()
        
    except psycopg2.OperationalError as e:
        print("\n❌ CONNECTION FAILED")
        print(f"Error type: {type(e).__name__}")
        print(f"Error message:\n{e}")
        
        print("\n--- Troubleshooting Tips ---")
        if "password authentication failed" in str(e):
            print("1. The password in .env does not match the database user's password.")
            print("2. Check for trailing spaces in .env DB_PASSWORD.")
            print("3. Verify pg_hba.conf allows md5/scram-sha-256 authentication for this user/host.")
        elif "Connection refused" in str(e):
            print("1. Is PostgreSQL running?")
            print("2. Is it listening on the correct port?")
            
    except Exception as e:
        print(f"\n❌ UNEXPECTED ERROR: {e}")

if __name__ == "__main__":
    test_connection()
