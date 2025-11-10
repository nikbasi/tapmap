-- Fix tag column length issue
-- Run this if you already created the database with the old schema

-- Alter the tag column to support longer values
ALTER TABLE fountain_tags ALTER COLUMN tag TYPE TEXT;


