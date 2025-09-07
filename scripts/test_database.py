#!/usr/bin/env python3
"""
Simple script to test PostgreSQL database connection and show fountain data
"""

import psycopg2
import psycopg2.extras
from psycopg2.extras import RealDictCursor
import sys
import os
from dotenv import load_dotenv

def test_database():
    # Environment variables are already loaded in main()
    
    # Database connection parameters from environment
    db_config = {
        'host': os.getenv('DB_HOST', 'localhost'),
        'port': int(os.getenv('SSH_TUNNEL_LOCAL_PORT', '5433')),  # SSH tunnel local port
        'database': os.getenv('DB_NAME', 'tapmap_db'),
        'user': os.getenv('DB_USER', 'tapmap_user'),
        'password': os.getenv('DB_PASSWORD'),
    }
    
    # Check if required environment variables are set
    if not db_config['password']:
        print("❌ DB_PASSWORD not found in .env file!")
        print("   Please create a .env file with your database credentials:")
        print("   DB_HOST=localhost")
        print("   DB_PORT=5433")
        print("   DB_NAME=tapmap")
        print("   DB_USER=tapmap_user")
        print("   DB_PASSWORD=your_actual_password")
        return
    
    print(f"🔌 Connecting to PostgreSQL database...")
    print(f"   Host: {db_config['host']}:{db_config['port']}")
    print(f"   Database: {db_config['database']}")
    print(f"   User: {db_config['user']}")
    
    try:
        connection = psycopg2.connect(**db_config)
        cursor = connection.cursor(cursor_factory=RealDictCursor)
        
        print("✅ Connected successfully!")
        
        # Test basic connection
        cursor.execute("SELECT version()")
        version = cursor.fetchone()
        print(f"📊 PostgreSQL version: {version['version']}")
        
        # Check if fountains table exists
        cursor.execute("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name = 'fountains'
            );
        """)
        table_exists = cursor.fetchone()['exists']
        print(f"📋 Fountains table exists: {table_exists}")
        
        if not table_exists:
            print("❌ Fountains table not found!")
            return
        
        # Get total count
        cursor.execute("SELECT COUNT(*) as total FROM fountains")
        total_count = cursor.fetchone()['total']
        print(f"📊 Total fountains: {total_count}")
        
        # Get count by status
        cursor.execute("SELECT status, COUNT(*) as count FROM fountains GROUP BY status")
        status_counts = cursor.fetchall()
        print("📊 Fountains by status:")
        for row in status_counts:
            print(f"   {row['status']}: {row['count']}")
        
        # Get count with geohash fields
        cursor.execute("""
            SELECT 
                COUNT(*) as total,
                COUNT(CASE WHEN geohash IS NOT NULL THEN 1 END) as with_geohash,
                COUNT(CASE WHEN geohash_4 IS NOT NULL THEN 1 END) as with_geohash4,
                COUNT(CASE WHEN geohash_3 IS NOT NULL THEN 1 END) as with_geohash3,
                COUNT(CASE WHEN geohash_2 IS NOT NULL THEN 1 END) as with_geohash2,
                COUNT(CASE WHEN geohash_1 IS NOT NULL THEN 1 END) as with_geohash1
            FROM fountains
        """)
        geohash_stats = cursor.fetchone()
        print("🔍 Geohash field statistics:")
        print(f"   Total: {geohash_stats['total']}")
        print(f"   With geohash: {geohash_stats['with_geohash']}")
        print(f"   With geohash4: {geohash_stats['with_geohash4']}")
        print(f"   With geohash3: {geohash_stats['with_geohash3']}")
        print(f"   With geohash2: {geohash_stats['with_geohash2']}")
        print(f"   With geohash1: {geohash_stats['with_geohash1']}")
        
        # Show sample fountains
        cursor.execute("""
            SELECT id, name, latitude, longitude, status, 
                   geohash, geohash_4, geohash_3, geohash_2, geohash_1,
                   added_date
            FROM fountains 
            LIMIT 10
        """)
        sample_fountains = cursor.fetchall()
        
        print(f"\n📄 Sample fountains (showing {len(sample_fountains)}):")
        for i, fountain in enumerate(sample_fountains, 1):
            print(f"   {i}. {fountain['name']}")
            print(f"      Location: ({fountain['latitude']}, {fountain['longitude']})")
            print(f"      Status: {fountain['status']}")
            print(f"      Geohash: {fountain['geohash']} | {fountain['geohash_4']} | {fountain['geohash_3']} | {fountain['geohash_2']} | {fountain['geohash_1']}")
            print(f"      Added: {fountain['added_date']}")
            print()
        
        # Test geohash query (similar to what the app does)
        print("🧪 Testing geohash query (like the app does):")
        
        # Test with precision 3 (zoom level 8-12)
        cursor.execute("""
            SELECT COUNT(*) as count 
            FROM fountains 
            WHERE status = 'active' 
            AND geohash_3 IS NOT NULL
        """)
        active_with_geohash3 = cursor.fetchone()['count']
        print(f"   Active fountains with geohash3: {active_with_geohash3}")
        
        # Test specific geohash query
        if active_with_geohash3 > 0:
            cursor.execute("""
                SELECT geohash_3, COUNT(*) as count 
                FROM fountains 
                WHERE status = 'active' 
                AND geohash_3 IS NOT NULL
                GROUP BY geohash_3 
                LIMIT 5
            """)
            geohash3_counts = cursor.fetchall()
            print("   Sample geohash3 values:")
            for row in geohash3_counts:
                print(f"      {row['geohash_3']}: {row['count']} fountains")
        
        # Test viewport query (similar to app)
        print("\n🧪 Testing viewport query (Italy bounds):")
        north_lat, south_lat = 47.0, 35.0
        east_lon, west_lon = 18.0, 6.0
        
        cursor.execute("""
            SELECT COUNT(*) as count 
            FROM fountains 
            WHERE status = 'active' 
            AND latitude BETWEEN %s AND %s 
            AND longitude BETWEEN %s AND %s
        """, (south_lat, north_lat, west_lon, east_lon))
        
        viewport_count = cursor.fetchone()['count']
        print(f"   Fountains in Italy viewport: {viewport_count}")
        
        if viewport_count > 0:
            cursor.execute("""
                SELECT name, latitude, longitude, geohash_3
                FROM fountains 
                WHERE status = 'active' 
                AND latitude BETWEEN %s AND %s 
                AND longitude BETWEEN %s AND %s
                LIMIT 5
            """, (south_lat, north_lat, west_lon, east_lon))
            
            viewport_fountains = cursor.fetchall()
            print("   Sample fountains in viewport:")
            for fountain in viewport_fountains:
                print(f"      {fountain['name']} at ({fountain['latitude']}, {fountain['longitude']}) -> geohash3: {fountain['geohash_3']}")
        
        cursor.close()
        connection.close()
        print("\n✅ Database test completed!")
        
    except psycopg2.Error as e:
        print(f"❌ Database error: {e}")
        print(f"   Error code: {e.pgcode}")
        print(f"   Error message: {e.pgerror}")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
    finally:
        if 'connection' in locals():
            connection.close()

if __name__ == "__main__":
    print("🚰 TapMap Database Test Script")
    print("=" * 40)
    
    # Check if .env file exists in backend directory
    env_path = os.path.join('backend', '.env')
    if not os.path.exists(env_path):
        print("⚠️  .env file not found in scripts/backend/!")
        print("   Please create a .env file in scripts/backend/ with:")
        print("   DB_HOST=localhost")
        print("   SSH_TUNNEL_LOCAL_PORT=5433")
        print("   DB_NAME=tapmap_db")
        print("   DB_USER=tapmap_user")
        print("   DB_PASSWORD=your_actual_password")
        sys.exit(1)
    
    # Load environment variables from backend/.env file
    load_dotenv(env_path)
    
    test_database()
