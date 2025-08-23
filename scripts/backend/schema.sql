-- Fountain Database Schema for Geohash-based Queries
-- Optimized for multi-zoom map applications

-- Enable PostGIS extension for advanced spatial operations (optional) 
-- CREATE EXTENSION IF NOT EXISTS postgis;

-- Main fountains table
CREATE TABLE fountains (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(500),
    description TEXT,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    type VARCHAR(100) DEFAULT 'fountain',
    status VARCHAR(100) DEFAULT 'active',
    water_quality VARCHAR(100) DEFAULT 'potable',
    accessibility VARCHAR(100) DEFAULT 'public',
    added_by VARCHAR(255) DEFAULT 'osm_import',
    added_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,     
    validations JSONB DEFAULT '[]',
    photos JSONB DEFAULT '[]',
    tags JSONB DEFAULT '[]',
    osm_data JSONB,
    geohash VARCHAR(12) NOT NULL,

    -- Geohash precision levels for efficient zoom queries
    geohash_1 VARCHAR(1),
    geohash_2 VARCHAR(2),
    geohash_3 VARCHAR(3),
    geohash_4 VARCHAR(4),
    geohash_5 VARCHAR(5),
    geohash_6 VARCHAR(6),
    geohash_7 VARCHAR(7),
    geohash_8 VARCHAR(8),
    geohash_9 VARCHAR(9),
    geohash_10 VARCHAR(10),
    geohash_11 VARCHAR(11),
    geohash_12 VARCHAR(12),

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,     
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP      
);

-- Indexes for fast geohash prefix queries
-- These indexes support efficient zoom-based queries
CREATE INDEX idx_fountains_geohash_1 ON fountains(geohash_1);
CREATE INDEX idx_fountains_geohash_2 ON fountains(geohash_2);
CREATE INDEX idx_fountains_geohash_3 ON fountains(geohash_3);
CREATE INDEX idx_fountains_geohash_4 ON fountains(geohash_4);
CREATE INDEX idx_fountains_geohash_5 ON fountains(geohash_5);
CREATE INDEX idx_fountains_geohash_6 ON fountains(geohash_6);
CREATE INDEX idx_fountains_geohash_7 ON fountains(geohash_7);
CREATE INDEX idx_fountains_geohash_8 ON fountains(geohash_8);
CREATE INDEX idx_fountains_geohash_9 ON fountains(geohash_9);
CREATE INDEX idx_fountains_geohash_10 ON fountains(geohash_10);        
CREATE INDEX idx_fountains_geohash_11 ON fountains(geohash_11);        
CREATE INDEX idx_fountains_geohash_12 ON fountains(geohash_12);        

-- Composite indexes for common query patterns
CREATE INDEX idx_fountains_location ON fountains(latitude, longitude); 
CREATE INDEX idx_fountains_status ON fountains(status);
CREATE INDEX idx_fountains_type ON fountains(type);
CREATE INDEX idx_fountains_water_quality ON fountains(water_quality);  

-- Full text search on name and description
CREATE INDEX idx_fountains_name_search ON fountains USING gin(to_tsvector('english', name));
CREATE INDEX idx_fountains_description_search ON fountains USING gin(to_tsvector('english', description));

-- JSONB indexes for tags and other JSON fields
CREATE INDEX idx_fountains_tags ON fountains USING gin(tags);
CREATE INDEX idx_fountains_osm_data ON fountains USING gin(osm_data);  

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
CREATE TRIGGER update_fountains_updated_at
    BEFORE UPDATE ON fountains
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate geohash precision levels
CREATE OR REPLACE FUNCTION calculate_geohash_precisions(geohash_input VARCHAR(12))
RETURNS TABLE(
    precision_1 VARCHAR(1),
    precision_2 VARCHAR(2),
    precision_3 VARCHAR(3),
    precision_4 VARCHAR(4),
    precision_5 VARCHAR(5),
    precision_6 VARCHAR(6),
    precision_7 VARCHAR(7),
    precision_8 VARCHAR(8),
    precision_9 VARCHAR(9),
    precision_10 VARCHAR(10),
    precision_11 VARCHAR(11),
    precision_12 VARCHAR(12)
) AS $$
BEGIN
    RETURN QUERY SELECT
        LEFT(geohash_input, 1),
        LEFT(geohash_input, 2),
        LEFT(geohash_input, 3),
        LEFT(geohash_input, 4),
        LEFT(geohash_input, 5),
        LEFT(geohash_input, 6),
        LEFT(geohash_input, 7),
        LEFT(geohash_input, 8),
        LEFT(geohash_input, 9),
        LEFT(geohash_input, 10),
        LEFT(geohash_input, 11),
        LEFT(geohash_input, 12);
END;
$$ LANGUAGE plpgsql;

-- View for fountain statistics by geohash precision
CREATE VIEW fountain_stats_by_precision AS
SELECT
    '1' as precision,
    COUNT(*) as fountain_count,
    COUNT(DISTINCT geohash_1) as unique_geohashes
FROM fountains
UNION ALL
SELECT
    '2' as precision,
    COUNT(*) as fountain_count,
    COUNT(DISTINCT geohash_2) as unique_geohashes
FROM fountains
UNION ALL
SELECT
    '3' as precision,
    COUNT(*) as fountain_count,
    COUNT(DISTINCT geohash_3) as unique_geohashes
FROM fountains
UNION ALL
SELECT
    '4' as precision,
    COUNT(*) as fountain_count,
    COUNT(DISTINCT geohash_4) as unique_geohashes
FROM fountains
UNION ALL
SELECT
    '5' as precision,
    COUNT(*) as fountain_count,
    COUNT(DISTINCT geohash_5) as unique_geohashes
FROM fountains
UNION ALL
SELECT
    '6' as precision,
    COUNT(*) as fountain_count,
    COUNT(DISTINCT geohash_6) as unique_geohashes
FROM fountains
UNION ALL
SELECT
    '7' as precision,
    COUNT(*) as fountain_count,
    COUNT(DISTINCT geohash_7) as unique_geohashes
FROM fountains
UNION ALL
SELECT
    '8' as precision,
    COUNT(*) as fountain_count,
    COUNT(DISTINCT geohash_8) as unique_geohashes
FROM fountains
UNION ALL
SELECT
    '9' as precision,
    COUNT(*) as fountain_count,
    COUNT(DISTINCT geohash_9) as unique_geohashes
FROM fountains
UNION ALL
SELECT
    '10' as precision,
    COUNT(*) as fountain_count,
    COUNT(DISTINCT geohash_10) as unique_geohashes
FROM fountains
UNION ALL
SELECT
    '11' as precision,
    COUNT(*) as fountain_count,
    COUNT(DISTINCT geohash_11) as unique_geohashes
FROM fountains
UNION ALL
SELECT
    '12' as precision,
    COUNT(*) as fountain_count,
    COUNT(DISTINCT geohash_12) as unique_geohashes
FROM fountains