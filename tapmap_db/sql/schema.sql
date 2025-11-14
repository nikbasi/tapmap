-- Fountain Database Schema
-- PostgreSQL database schema for TapMap fountain database

-- Main fountains table
CREATE TABLE IF NOT EXISTS fountains (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(500),
    description TEXT,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    geohash VARCHAR(12),  -- Stored at precision 10, can be queried at any prefix length
    type VARCHAR(50) DEFAULT 'fountain',
    status VARCHAR(50) DEFAULT 'active',
    water_quality VARCHAR(50),
    accessibility VARCHAR(50),
    added_by VARCHAR(255),
    added_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create spatial index for location-based queries (PostgreSQL)
-- Note: Requires PostGIS extension for full spatial support
-- To enable: CREATE EXTENSION IF NOT EXISTS postgis;
-- Then use: CREATE INDEX idx_fountains_location ON fountains USING GIST (
--     ST_MakePoint(longitude, latitude)
-- );

-- B-tree indexes for latitude/longitude (fast and works without PostGIS)
CREATE INDEX IF NOT EXISTS idx_fountains_lat ON fountains(latitude);
CREATE INDEX IF NOT EXISTS idx_fountains_lng ON fountains(longitude);

-- Composite index for location queries
CREATE INDEX IF NOT EXISTS idx_fountains_lat_lng ON fountains(latitude, longitude);

-- Geohash index for fast proximity searches
-- Geohash length determines precision: 7 chars ≈ 153m, 8 chars ≈ 19m, 9 chars ≈ 2.4m
CREATE INDEX IF NOT EXISTS idx_fountains_geohash ON fountains(geohash);

-- Index for status and accessibility filters
CREATE INDEX IF NOT EXISTS idx_fountains_status ON fountains(status);
CREATE INDEX IF NOT EXISTS idx_fountains_accessibility ON fountains(accessibility);

-- Tags table (many-to-many relationship)
CREATE TABLE IF NOT EXISTS fountain_tags (
    id SERIAL PRIMARY KEY,
    fountain_id VARCHAR(255) NOT NULL REFERENCES fountains(id) ON DELETE CASCADE,
    tag TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(fountain_id, tag)
);

CREATE INDEX IF NOT EXISTS idx_fountain_tags_fountain_id ON fountain_tags(fountain_id);
CREATE INDEX IF NOT EXISTS idx_fountain_tags_tag ON fountain_tags(tag);

-- OSM data table
CREATE TABLE IF NOT EXISTS fountain_osm_data (
    id SERIAL PRIMARY KEY,
    fountain_id VARCHAR(255) NOT NULL REFERENCES fountains(id) ON DELETE CASCADE,
    osm_id VARCHAR(255),
    source VARCHAR(100),
    last_updated TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(fountain_id)
);

CREATE INDEX IF NOT EXISTS idx_fountain_osm_fountain_id ON fountain_osm_data(fountain_id);
CREATE INDEX IF NOT EXISTS idx_fountain_osm_osm_id ON fountain_osm_data(osm_id);

-- Validations table
CREATE TABLE IF NOT EXISTS fountain_validations (
    id SERIAL PRIMARY KEY,
    fountain_id VARCHAR(255) NOT NULL REFERENCES fountains(id) ON DELETE CASCADE,
    validated_by VARCHAR(255),
    validation_date TIMESTAMP,
    validation_type VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_fountain_validations_fountain_id ON fountain_validations(fountain_id);

-- Photos table
CREATE TABLE IF NOT EXISTS fountain_photos (
    id SERIAL PRIMARY KEY,
    fountain_id VARCHAR(255) NOT NULL REFERENCES fountains(id) ON DELETE CASCADE,
    photo_url VARCHAR(1000),
    photo_path VARCHAR(1000),
    uploaded_by VARCHAR(255),
    uploaded_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_fountain_photos_fountain_id ON fountain_photos(fountain_id);

-- Function to update updated_at timestamp (PostgreSQL)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
CREATE TRIGGER update_fountains_updated_at BEFORE UPDATE ON fountains
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Users table for authentication
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,  -- bcrypt hash
    display_name VARCHAR(255),
    provider VARCHAR(50) DEFAULT 'email',  -- 'email', 'google', 'apple'
    provider_id VARCHAR(255),  -- OAuth provider user ID
    avatar_url VARCHAR(1000),
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_provider ON users(provider, provider_id);

-- Trigger to automatically update updated_at for users
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

