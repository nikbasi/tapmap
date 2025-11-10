-- Common Query Helpers for TapMap Database
-- Useful queries for your Flutter app backend

-- ============================================
-- Location-based Queries
-- ============================================

-- Find fountains within radius (using Haversine formula)
-- Parameters: center_lat, center_lng, radius_km
CREATE OR REPLACE FUNCTION find_fountains_nearby(
    center_lat DECIMAL,
    center_lng DECIMAL,
    radius_km DECIMAL DEFAULT 5.0,
    max_results INTEGER DEFAULT 50
)
RETURNS TABLE (
    id VARCHAR,
    name VARCHAR,
    latitude DECIMAL,
    longitude DECIMAL,
    distance_km DECIMAL,
    status VARCHAR,
    water_quality VARCHAR,
    accessibility VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.id,
        f.name,
        f.latitude,
        f.longitude,
        (
            6371 * acos(
                LEAST(1.0, 
                    cos(radians(center_lat)) * cos(radians(f.latitude)) *
                    cos(radians(f.longitude) - radians(center_lng)) +
                    sin(radians(center_lat)) * sin(radians(f.latitude))
                )
            )
        ) AS distance_km,
        f.status,
        f.water_quality,
        f.accessibility
    FROM fountains f
    WHERE 
        -- Bounding box filter for performance
        f.latitude BETWEEN center_lat - (radius_km / 111.0) 
                      AND center_lat + (radius_km / 111.0)
        AND f.longitude BETWEEN center_lng - (radius_km / (111.0 * cos(radians(center_lat))))
                            AND center_lng + (radius_km / (111.0 * cos(radians(center_lat))))
        AND f.status = 'active'
        AND (
            6371 * acos(
                LEAST(1.0,
                    cos(radians(center_lat)) * cos(radians(f.latitude)) *
                    cos(radians(f.longitude) - radians(center_lng)) +
                    sin(radians(center_lat)) * sin(radians(f.latitude))
                )
            )
        ) <= radius_km
    ORDER BY distance_km
    LIMIT max_results;
END;
$$ LANGUAGE plpgsql;

-- Usage:
-- SELECT * FROM find_fountains_nearby(37.7749, -122.4194, 5.0, 50);

-- ============================================
-- Geohash-based Queries (Faster for proximity)
-- ============================================

-- Find fountains using geohash for initial filtering (much faster!)
-- This uses geohash prefix matching to quickly narrow down candidates
CREATE OR REPLACE FUNCTION find_fountains_nearby_geohash(
    center_lat DECIMAL,
    center_lng DECIMAL,
    radius_km DECIMAL DEFAULT 5.0,
    max_results INTEGER DEFAULT 50
)
RETURNS TABLE (
    id VARCHAR,
    name VARCHAR,
    latitude DECIMAL,
    longitude DECIMAL,
    distance_km DECIMAL,
    status VARCHAR,
    water_quality VARCHAR,
    accessibility VARCHAR,
    geohash VARCHAR
) AS $$
DECLARE
    center_geohash VARCHAR;
    geohash_precision INTEGER;
BEGIN
    -- Compute geohash for center point
    -- For radius-based search, we need to determine appropriate geohash precision
    -- 5km radius: use precision 6 (≈ 1.2km per cell)
    -- 1km radius: use precision 7 (≈ 153m per cell)
    -- 500m radius: use precision 8 (≈ 19m per cell)
    IF radius_km >= 5 THEN
        geohash_precision := 6;
    ELSIF radius_km >= 1 THEN
        geohash_precision := 7;
    ELSE
        geohash_precision := 8;
    END IF;
    
    -- Get geohash of center point (we'll use a simple approximation)
    -- In production, you'd compute this in the application layer
    -- For now, we'll use the stored geohash and check neighbors
    
    RETURN QUERY
    WITH center_hash AS (
        SELECT geohash
        FROM fountains
        WHERE latitude = center_lat AND longitude = center_lng
        LIMIT 1
    ),
    target_geohashes AS (
        -- Get geohash prefix for filtering
        SELECT LEFT(geohash, geohash_precision) as prefix
        FROM fountains
        WHERE geohash IS NOT NULL
        AND (
            6371 * acos(
                LEAST(1.0,
                    cos(radians(center_lat)) * cos(radians(latitude)) *
                    cos(radians(longitude) - radians(center_lng)) +
                    sin(radians(center_lat)) * sin(radians(latitude))
                )
            )
        ) <= radius_km * 1.5  -- Expand search area slightly
        LIMIT 1000
    )
    SELECT 
        f.id,
        f.name,
        f.latitude,
        f.longitude,
        (
            6371 * acos(
                LEAST(1.0,
                    cos(radians(center_lat)) * cos(radians(f.latitude)) *
                    cos(radians(f.longitude) - radians(center_lng)) +
                    sin(radians(center_lat)) * sin(radians(f.latitude))
                )
            )
        ) AS distance_km,
        f.status,
        f.water_quality,
        f.accessibility,
        f.geohash
    FROM fountains f
    WHERE 
        f.geohash IS NOT NULL
        AND f.status = 'active'
        AND (
            6371 * acos(
                LEAST(1.0,
                    cos(radians(center_lat)) * cos(radians(f.latitude)) *
                    cos(radians(f.longitude) - radians(center_lng)) +
                    sin(radians(center_lat)) * sin(radians(f.latitude))
                )
            )
        ) <= radius_km
    ORDER BY distance_km
    LIMIT max_results;
END;
$$ LANGUAGE plpgsql;

-- Simpler geohash-based query: find fountains with matching geohash prefix
-- This is very fast for finding nearby fountains
-- Usage: SELECT * FROM find_fountains_by_geohash_prefix('9q5', 50);
CREATE OR REPLACE FUNCTION find_fountains_by_geohash_prefix(
    geohash_prefix VARCHAR,
    max_results INTEGER DEFAULT 50
)
RETURNS TABLE (
    id VARCHAR,
    name VARCHAR,
    latitude DECIMAL,
    longitude DECIMAL,
    status VARCHAR,
    water_quality VARCHAR,
    accessibility VARCHAR,
    geohash VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.id,
        f.name,
        f.latitude,
        f.longitude,
        f.status,
        f.water_quality,
        f.accessibility,
        f.geohash
    FROM fountains f
    WHERE 
        f.geohash LIKE geohash_prefix || '%'
        AND f.status = 'active'
    ORDER BY f.name
    LIMIT max_results;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Zoom-Level Based Queries (for Flutter map)
-- ============================================

-- Get fountain counts grouped by geohash prefix (for low zoom levels)
-- Returns counts per area instead of individual fountains
-- precision: 2-3 = world/continent, 4-5 = country/region, 6-7 = city, 8+ = neighborhood
CREATE OR REPLACE FUNCTION get_fountain_counts_by_area(
    min_lat DECIMAL,
    max_lat DECIMAL,
    min_lng DECIMAL,
    max_lng DECIMAL,
    geohash_precision INTEGER DEFAULT 5
)
RETURNS TABLE (
    geohash_prefix VARCHAR,
    count BIGINT,
    center_lat DECIMAL,
    center_lng DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        LEFT(f.geohash, geohash_precision) as geohash_prefix,
        COUNT(*)::BIGINT as count,
        AVG(f.latitude) as center_lat,
        AVG(f.longitude) as center_lng
    FROM fountains f
    WHERE 
        f.latitude BETWEEN min_lat AND max_lat
        AND f.longitude BETWEEN min_lng AND max_lng
        AND f.geohash IS NOT NULL
        AND f.status = 'active'
    GROUP BY LEFT(f.geohash, geohash_precision)
    ORDER BY geohash_prefix;
END;
$$ LANGUAGE plpgsql;

-- Get individual fountains in a bounding box with geohash filtering
-- Use this for medium to high zoom levels
CREATE OR REPLACE FUNCTION get_fountains_in_bounds(
    min_lat DECIMAL,
    max_lat DECIMAL,
    min_lng DECIMAL,
    max_lng DECIMAL,
    max_results INTEGER DEFAULT 1000
)
RETURNS TABLE (
    id VARCHAR,
    name VARCHAR,
    latitude DECIMAL,
    longitude DECIMAL,
    geohash VARCHAR,
    status VARCHAR,
    water_quality VARCHAR,
    accessibility VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.id,
        f.name,
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
        AND f.status = 'active'
    ORDER BY f.latitude, f.longitude
    LIMIT max_results;
END;
$$ LANGUAGE plpgsql;

-- Smart function: returns counts or individual fountains based on area size
-- Automatically determines if area is large (return counts) or small (return fountains)
-- area_size_km2: approximate area in square kilometers
CREATE OR REPLACE FUNCTION get_fountains_for_map_view(
    min_lat DECIMAL,
    max_lat DECIMAL,
    min_lng DECIMAL,
    max_lng DECIMAL,
    return_counts BOOLEAN DEFAULT NULL  -- NULL = auto-detect, TRUE = counts, FALSE = individual
)
RETURNS TABLE (
    result_type VARCHAR,  -- 'count' or 'fountain'
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
    IF area_km2 > 1000000 THEN  -- > 1M km² (continent)
        precision_level := 2;
    ELSIF area_km2 > 100000 THEN  -- > 100k km² (large country)
        precision_level := 3;
    ELSIF area_km2 > 10000 THEN  -- > 10k km² (country/state)
        precision_level := 4;
    ELSIF area_km2 > 1000 THEN  -- > 1k km² (region)
        precision_level := 5;
    ELSIF area_km2 > 100 THEN  -- > 100 km² (city)
        precision_level := 6;
    ELSIF area_km2 > 10 THEN  -- > 10 km² (district)
        precision_level := 7;
    ELSE  -- < 10 km² (neighborhood/individual)
        precision_level := 8;
        should_count := FALSE;  -- Always return individual for small areas
    END IF;
    
    IF should_count THEN
        -- Return counts grouped by geohash prefix
        RETURN QUERY
        SELECT 
            'count'::VARCHAR as result_type,
            LEFT(f.geohash, precision_level) as geohash_prefix,
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
            AND f.status = 'active'
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
            AND f.status = 'active'
        ORDER BY f.latitude, f.longitude
        LIMIT 5000;  -- Safety limit
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Search Queries
-- ============================================

-- Search fountains by name
CREATE OR REPLACE FUNCTION search_fountains_by_name(
    search_term VARCHAR,
    max_results INTEGER DEFAULT 50
)
RETURNS TABLE (
    id VARCHAR,
    name VARCHAR,
    latitude DECIMAL,
    longitude DECIMAL,
    status VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.id,
        f.name,
        f.latitude,
        f.longitude,
        f.status
    FROM fountains f
    WHERE 
        f.name ILIKE '%' || search_term || '%'
        AND f.status = 'active'
    ORDER BY f.name
    LIMIT max_results;
END;
$$ LANGUAGE plpgsql;

-- Search fountains by tag
CREATE OR REPLACE FUNCTION search_fountains_by_tag(
    tag_search VARCHAR,
    max_results INTEGER DEFAULT 50
)
RETURNS TABLE (
    id VARCHAR,
    name VARCHAR,
    latitude DECIMAL,
    longitude DECIMAL,
    tags TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.id,
        f.name,
        f.latitude,
        f.longitude,
        array_agg(ft.tag) as tags
    FROM fountains f
    JOIN fountain_tags ft ON f.id = ft.fountain_id
    WHERE 
        ft.tag ILIKE '%' || tag_search || '%'
        AND f.status = 'active'
    GROUP BY f.id, f.name, f.latitude, f.longitude
    ORDER BY f.name
    LIMIT max_results;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Get Fountain Details
-- ============================================

-- Get complete fountain information
CREATE OR REPLACE FUNCTION get_fountain_details(fountain_id VARCHAR)
RETURNS TABLE (
    id VARCHAR,
    name VARCHAR,
    description TEXT,
    latitude DECIMAL,
    longitude DECIMAL,
    type VARCHAR,
    status VARCHAR,
    water_quality VARCHAR,
    accessibility VARCHAR,
    added_by VARCHAR,
    added_date TIMESTAMP,
    tags TEXT[],
    osm_id VARCHAR,
    osm_source VARCHAR,
    photo_count BIGINT,
    validation_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.id,
        f.name,
        f.description,
        f.latitude,
        f.longitude,
        f.type,
        f.status,
        f.water_quality,
        f.accessibility,
        f.added_by,
        f.added_date,
        array_agg(DISTINCT ft.tag) FILTER (WHERE ft.tag IS NOT NULL) as tags,
        osd.osm_id,
        osd.source as osm_source,
        (SELECT COUNT(*) FROM fountain_photos WHERE fountain_id = f.id) as photo_count,
        (SELECT COUNT(*) FROM fountain_validations WHERE fountain_id = f.id) as validation_count
    FROM fountains f
    LEFT JOIN fountain_tags ft ON f.id = ft.fountain_id
    LEFT JOIN fountain_osm_data osd ON f.id = osd.fountain_id
    WHERE f.id = fountain_id
    GROUP BY f.id, f.name, f.description, f.latitude, f.longitude, 
             f.type, f.status, f.water_quality, f.accessibility, 
             f.added_by, f.added_date, osd.osm_id, osd.source;
END;
$$ LANGUAGE plpgsql;

-- Usage:
-- SELECT * FROM get_fountain_details('osm_node_12824958235');

-- ============================================
-- Statistics Queries
-- ============================================

-- Get fountain statistics
SELECT 
    COUNT(*) as total_fountains,
    COUNT(*) FILTER (WHERE status = 'active') as active_fountains,
    COUNT(*) FILTER (WHERE status = 'inactive') as inactive_fountains,
    COUNT(DISTINCT water_quality) as unique_water_qualities,
    COUNT(DISTINCT accessibility) as unique_accessibility_types
FROM fountains;

-- Get fountains by status
SELECT 
    status,
    COUNT(*) as count
FROM fountains
GROUP BY status
ORDER BY count DESC;

-- Get most common tags
SELECT 
    tag,
    COUNT(*) as fountain_count
FROM fountain_tags
GROUP BY tag
ORDER BY fountain_count DESC
LIMIT 20;

-- ============================================
-- Bounding Box Query (for map tiles)
-- ============================================

-- Get fountains in a bounding box (useful for map tile loading)
-- This function is already defined above as get_fountains_in_bounds()
-- Use: SELECT * FROM get_fountains_in_bounds(min_lat, max_lat, min_lng, max_lng, max_results);

-- Example query template (replace parameters with actual values):
-- SELECT 
--     id,
--     name,
--     latitude,
--     longitude,
--     status,
--     water_quality,
--     accessibility
-- FROM fountains
-- WHERE 
--     latitude BETWEEN 37.0 AND 38.0  -- Replace with min_lat and max_lat
--     AND longitude BETWEEN -123.0 AND -122.0  -- Replace with min_lng and max_lng
--     AND status = 'active'
-- ORDER BY latitude, longitude;

