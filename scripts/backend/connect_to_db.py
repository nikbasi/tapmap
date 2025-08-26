#!/usr/bin/env python3
"""
Connect to Oracle Cloud PostgreSQL Database via SSH Tunnel
This script connects to your remote database and explores the data
"""

import psycopg2
from psycopg2.extras import RealDictCursor
import json
import os
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def get_config():
    """Get configuration from environment variables"""
    return {
        'db_host': os.getenv('DB_HOST', 'localhost'),
        'db_name': os.getenv('DB_NAME', 'tapmap_db'),
        'db_user': os.getenv('DB_USER', 'tapmap_user'),
        'db_password': os.getenv('DB_PASSWORD', 'tapmap_password'),
        'db_port': int(os.getenv('DB_PORT', '5432')),
        'ssh_tunnel_local_port': int(os.getenv('SSH_TUNNEL_LOCAL_PORT', '5433')),
        'oracle_cloud_host': os.getenv('ORACLE_CLOUD_HOST'),
        'oracle_cloud_user': os.getenv('ORACLE_CLOUD_USER', 'ubuntu'),
        'oracle_cloud_ssh_password': os.getenv('ORACLE_CLOUD_SSH_PASSWORD')
    }

def connect_to_database(config):
    """Connect to the database through SSH tunnel"""
    try:
        # Connect through the local tunnel port
        conn = psycopg2.connect(
            host=config['db_host'],  # Localhost on the tunnel
            port=config['ssh_tunnel_local_port'],  # Local tunnel port
            database=config['db_name'],
            user=config['db_user'],
            password=config['db_password']
        )
        print(f"✅ Successfully connected to database: {config['db_name']}")
        return conn
    except Exception as e:
        print(f"❌ Failed to connect to database: {e}")
        print("\nMake sure you have the SSH tunnel running:")
        print(f"ssh -L {config['ssh_tunnel_local_port']}:localhost:5432 {config['oracle_cloud_user']}@{config['oracle_cloud_host']}")
        print("   (You'll be prompted for your SSH password)")
        return None

def explore_database(conn):
    """Explore the database structure and data"""
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Get database version
        cursor.execute("SELECT version();")
        version = cursor.fetchone()
        print(f"\n📊 Database Version: {version['version']}")
        
        # List all tables
        cursor.execute("""
            SELECT table_name, table_type 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
            ORDER BY table_name;
        """)
        tables = cursor.fetchall()
        
        print(f"\n📋 Tables in database:")
        for table in tables:
            print(f"  - {table['table_name']} ({table['table_type']})")
        
        # Check if fountains table exists and get its structure
        if any(table['table_name'] == 'fountains' for table in tables):
            print(f"\n🏛️  Fountains table structure:")
            cursor.execute("""
                SELECT column_name, data_type, is_nullable, column_default
                FROM information_schema.columns 
                WHERE table_name = 'fountains'
                ORDER BY ordinal_position;
            """)
            columns = cursor.fetchall()
            
            for col in columns:
                nullable = "NULL" if col['is_nullable'] == 'YES' else "NOT NULL"
                default = f" DEFAULT {col['column_default']}" if col['column_default'] else ""
                print(f"  - {col['column_name']}: {col['data_type']} {nullable}{default}")
            
            # Get fountain count
            cursor.execute("SELECT COUNT(*) as count FROM fountains;")
            count = cursor.fetchone()
            print(f"\n📈 Total fountains in database: {count['count']:,}")
            
            # Get sample fountains
            cursor.execute("""
                SELECT id, name, latitude, longitude, geohash, type, status, created_at
                FROM fountains 
                LIMIT 5;
            """)
            sample_fountains = cursor.fetchall()
            
            print(f"\n🔍 Sample fountains:")
            for fountain in sample_fountains:
                print(f"  - {fountain['id']}: {fountain['name']} at ({fountain['latitude']}, {fountain['longitude']})")
                print(f"    Geohash: {fountain['geohash']}, Type: {fountain['type']}, Status: {fountain['status']}")
                print(f"    Created: {fountain['created_at']}")
                print()
            
            # Get geohash distribution
            cursor.execute("""
                SELECT 
                    LENGTH(geohash) as precision,
                    COUNT(*) as fountain_count,
                    COUNT(DISTINCT geohash) as unique_geohashes
                FROM fountains 
                GROUP BY LENGTH(geohash)
                ORDER BY LENGTH(geohash);
            """)
            geohash_stats = cursor.fetchall()
            
            print(f"🗺️  Geohash distribution:")
            for stat in geohash_stats:
                print(f"  - Precision {stat['precision']}: {stat['fountain_count']:,} fountains in {stat['unique_geohashes']:,} unique geohashes")
            
            # Get fountain types distribution
            cursor.execute("""
                SELECT type, COUNT(*) as count
                FROM fountains 
                GROUP BY type
                ORDER BY count DESC;
            """)
            type_stats = cursor.fetchall()
            
            print(f"\n🚰 Fountain types:")
            for stat in type_stats:
                print(f"  - {stat['type']}: {stat['count']:,}")
            
            # Get status distribution
            cursor.execute("""
                SELECT status, COUNT(*) as count
                FROM fountains 
                GROUP BY status
                ORDER BY count DESC;
            """)
            status_stats = cursor.fetchall()
            
            print(f"\n✅ Status distribution:")
            for stat in status_stats:
                print(f"  - {stat['status']}: {stat['count']:,}")
                
        else:
            print("\n❌ Fountains table not found. The database might be empty or not set up yet.")
            
    except Exception as e:
        print(f"❌ Error exploring database: {e}")
    finally:
        cursor.close()

def main():
    """Main function to connect and explore the database"""
    print("🔌 Connecting to Oracle Cloud PostgreSQL Database...")
    print("=" * 60)
    
    # Load configuration
    config = get_config()
    
    # Check if SSH tunnel is configured
    if not config['oracle_cloud_host'] or config['oracle_cloud_host'] == 'YOUR_VM_PUBLIC_IP':
        print("❌ Please update your .env file with your actual VM details first!")
        print("   - Replace 'YOUR_VM_PUBLIC_IP' with your VM's public IP address")
        print("   - Update username and SSH password if needed")
        print("   - Copy env.example to .env and edit the values")
        return
    
    print(f"✅ Configuration loaded:")
    print(f"   Host: {config['oracle_cloud_host']}")
    print(f"   User: {config['oracle_cloud_user']}")
    print(f"   Local Port: {config['ssh_tunnel_local_port']}")
    print(f"   Database: {config['db_name']}")
    print(f"   SSH Auth: Password")
    
    # Connect to database
    conn = connect_to_database(config)
    if not conn:
        return
    
    try:
        # Explore the database
        explore_database(conn)
        
    finally:
        conn.close()
        print("\n🔌 Database connection closed.")

if __name__ == "__main__":
    main() 