#!/usr/bin/env python3
"""
Apply SQL function update to the database.
Updates the get_fountains_for_map_view function to support filters.
"""

import os
import sys
import psycopg2
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Database configuration
DB_CONFIG = {
    'dbname': os.getenv('DB_NAME', 'tapmap_db'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', ''),
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '5432')
}

# The complete SQL function definition
SQL_FUNCTION = """
CREATE OR REPLACE FUNCTION get_fountains_for_map_view(
    min_lat DECIMAL,
    max_lat DECIMAL,
    min_lng DECIMAL,
    max_lng DECIMAL,
    return_counts BOOLEAN DEFAULT NULL,
    filter_statuses TEXT[] DEFAULT NULL,
    filter_water_qualities TEXT[] DEFAULT NULL,
    filter_accessibilities TEXT[] DEFAULT NULL,
    filter_types TEXT[] DEFAULT NULL
)
RETURNS TABLE (
    result_type VARCHAR,
    geohash_prefix VARCHAR,
    fountain_count BIGINT,
    center_lat DECIMAL,
    center_lng DECIMAL,
    fountain_id VARCHAR,
    fountain_name VARCHAR,
    latitude DECIMAL,
    longitude DECIMAL,
    geohash VARCHAR,
    status VARCHAR,
    water_quality VARCHAR,
    accessibility VARCHAR
) AS $$
DECLARE
    lat_range DECIMAL;
    lng_range DECIMAL;
    area_km2 DECIMAL;
    should_count BOOLEAN;
    precision_level INTEGER;
BEGIN
    -- Calculate area
    lat_range := max_lat - min_lat;
    lng_range := max_lng - min_lng;
    -- Approximate area in km² (rough calculation)
    area_km2 := lat_range * 111.0 * lng_range * 111.0 * COS(RADIANS((min_lat + max_lat) / 2));
    
    -- Auto-determine if we should return counts
    IF return_counts IS NULL THEN
        -- Return counts if area > 1000 km² (roughly country/region level)
        should_count := area_km2 > 1000;
    ELSE
        should_count := return_counts;
    END IF;
    
    -- Determine geohash precision based on area
    IF area_km2 > 1000000 THEN
        precision_level := 2;
    ELSIF area_km2 > 100000 THEN
        precision_level := 3;
    ELSIF area_km2 > 10000 THEN
        precision_level := 4;
    ELSIF area_km2 > 1000 THEN
        precision_level := 5;
    ELSIF area_km2 > 100 THEN
        precision_level := 6;
    ELSIF area_km2 > 10 THEN
        precision_level := 7;
    ELSE
        precision_level := 8;
        should_count := FALSE;
    END IF;
    
    IF should_count THEN
        -- Return counts grouped by geohash prefix
        RETURN QUERY
        SELECT 
            'count'::VARCHAR as result_type,
            LEFT(f.geohash, precision_level)::VARCHAR as geohash_prefix,
            COUNT(*)::BIGINT as fountain_count,
            AVG(f.latitude) as center_lat,
            AVG(f.longitude) as center_lng,
            NULL::VARCHAR as fountain_id,
            NULL::VARCHAR as fountain_name,
            NULL::DECIMAL as latitude,
            NULL::DECIMAL as longitude,
            NULL::VARCHAR as geohash,
            NULL::VARCHAR as status,
            NULL::VARCHAR as water_quality,
            NULL::VARCHAR as accessibility
        FROM fountains f
        WHERE 
            f.latitude BETWEEN min_lat AND max_lat
            AND f.longitude BETWEEN min_lng AND max_lng
            AND f.geohash IS NOT NULL
            AND (filter_statuses IS NULL AND f.status = 'active' OR filter_statuses IS NOT NULL AND f.status = ANY(filter_statuses))
            AND (filter_water_qualities IS NULL OR f.water_quality = ANY(filter_water_qualities))
            AND (filter_accessibilities IS NULL OR f.accessibility = ANY(filter_accessibilities))
            AND (filter_types IS NULL OR f.type = ANY(filter_types))
        GROUP BY LEFT(f.geohash, precision_level);
    ELSE
        -- Return individual fountains
        RETURN QUERY
        SELECT 
            'fountain'::VARCHAR as result_type,
            NULL::VARCHAR as geohash_prefix,
            NULL::BIGINT as fountain_count,
            NULL::DECIMAL as center_lat,
            NULL::DECIMAL as center_lng,
            f.id as fountain_id,
            f.name as fountain_name,
            f.latitude,
            f.longitude,
            f.geohash,
            f.status,
            f.water_quality,
            f.accessibility
        FROM fountains f
        WHERE 
            f.latitude BETWEEN min_lat AND max_lat
            AND f.longitude BETWEEN min_lng AND max_lng
            AND (filter_statuses IS NULL AND f.status = 'active' OR filter_statuses IS NOT NULL AND f.status = ANY(filter_statuses))
            AND (filter_water_qualities IS NULL OR f.water_quality = ANY(filter_water_qualities))
            AND (filter_accessibilities IS NULL OR f.accessibility = ANY(filter_accessibilities))
            AND (filter_types IS NULL OR f.type = ANY(filter_types))
        ORDER BY f.latitude, f.longitude
        LIMIT 5000;
    END IF;
END;
$$ LANGUAGE plpgsql;
"""

def apply_sql_update():
    """Apply the SQL function update to the database"""
    try:
        print("Connecting to database...")
        conn = psycopg2.connect(**DB_CONFIG)
        conn.autocommit = True
        cursor = conn.cursor()
        
        print("Applying SQL function update with filter support...")
        cursor.execute(SQL_FUNCTION)
        
        print("✓ Successfully updated get_fountains_for_map_view function!")
        
        # Verify the function exists with correct parameters
        cursor.execute("""
            SELECT pg_get_function_arguments(oid) 
            FROM pg_proc 
            WHERE proname = 'get_fountains_for_map_view'
        """)
        result = cursor.fetchone()
        if result:
            print(f"✓ Function verified with parameters: {result[0]}")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Error applying SQL update: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    apply_sql_update()
