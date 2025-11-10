#!/usr/bin/env python3
"""
TapMap API Server
Flask API server that connects to PostgreSQL and exposes fountain data endpoints.
"""

import os
import psycopg2
from psycopg2.extras import RealDictCursor
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import logging

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database configuration
DB_CONFIG = {
    'dbname': os.getenv('DB_NAME', 'tapmap_db'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', ''),
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '5432')
}


def get_db_connection():
    """Get a database connection."""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        logger.error(f"Database connection error: {e}")
        raise


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint."""
    try:
        conn = get_db_connection()
        conn.close()
        return jsonify({'status': 'healthy', 'database': 'connected'}), 200
    except Exception as e:
        return jsonify({'status': 'unhealthy', 'error': str(e)}), 500


@app.route('/api/fountains/map-view', methods=['POST'])
def get_fountains_for_map_view():
    """
    Get fountains for map view.
    Automatically returns counts for low zoom or individual fountains for high zoom.
    
    Request body:
    {
        "min_lat": float,
        "max_lat": float,
        "min_lng": float,
        "max_lng": float
    }
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'Request body is required'}), 400
        
        min_lat = float(data.get('min_lat', 0))
        max_lat = float(data.get('max_lat', 0))
        min_lng = float(data.get('min_lng', 0))
        max_lng = float(data.get('max_lng', 0))
        
        if not all([min_lat, max_lat, min_lng, max_lng]):
            return jsonify({'error': 'All bounds parameters are required'}), 400
        
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Call the database function
        cursor.execute("""
            SELECT * FROM get_fountains_for_map_view(%s, %s, %s, %s, NULL)
        """, (min_lat, max_lat, min_lng, max_lng))
        
        results = cursor.fetchall()
        
        # Convert to list of dicts
        fountains = [dict(row) for row in results]
        
        cursor.close()
        conn.close()
        
        logger.info(f"Returned {len(fountains)} results for map view")
        return jsonify(fountains), 200
        
    except Exception as e:
        logger.error(f"Error in get_fountains_for_map_view: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/fountains/counts', methods=['POST'])
def get_fountain_counts():
    """
    Get fountain counts grouped by geohash prefix (for low zoom levels).
    
    Request body:
    {
        "min_lat": float,
        "max_lat": float,
        "min_lng": float,
        "max_lng": float,
        "geohash_precision": int (optional, default: 5)
    }
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'Request body is required'}), 400
        
        min_lat = float(data.get('min_lat', 0))
        max_lat = float(data.get('max_lat', 0))
        min_lng = float(data.get('min_lng', 0))
        max_lng = float(data.get('max_lng', 0))
        geohash_precision = int(data.get('geohash_precision', 5))
        
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        cursor.execute("""
            SELECT * FROM get_fountain_counts_by_area(%s, %s, %s, %s, %s)
        """, (min_lat, max_lat, min_lng, max_lng, geohash_precision))
        
        results = cursor.fetchall()
        counts = [dict(row) for row in results]
        
        cursor.close()
        conn.close()
        
        return jsonify(counts), 200
        
    except Exception as e:
        logger.error(f"Error in get_fountain_counts: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/fountains/bounds', methods=['POST'])
def get_fountains_in_bounds():
    """
    Get individual fountains in bounds (for high zoom levels).
    
    Request body:
    {
        "min_lat": float,
        "max_lat": float,
        "min_lng": float,
        "max_lng": float,
        "max_results": int (optional, default: 1000)
    }
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'Request body is required'}), 400
        
        min_lat = float(data.get('min_lat', 0))
        max_lat = float(data.get('max_lat', 0))
        min_lng = float(data.get('min_lng', 0))
        max_lng = float(data.get('max_lng', 0))
        max_results = int(data.get('max_results', 1000))
        
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        cursor.execute("""
            SELECT * FROM get_fountains_in_bounds(%s, %s, %s, %s, %s)
        """, (min_lat, max_lat, min_lng, max_lng, max_results))
        
        results = cursor.fetchall()
        fountains = [dict(row) for row in results]
        
        cursor.close()
        conn.close()
        
        return jsonify(fountains), 200
        
    except Exception as e:
        logger.error(f"Error in get_fountains_in_bounds: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/fountains/<fountain_id>', methods=['GET'])
def get_fountain_details(fountain_id):
    """Get detailed information about a specific fountain."""
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        cursor.execute("""
            SELECT * FROM get_fountain_details(%s)
        """, (fountain_id,))
        
        result = cursor.fetchone()
        
        cursor.close()
        conn.close()
        
        if result:
            return jsonify(dict(result)), 200
        else:
            return jsonify({'error': 'Fountain not found'}), 404
        
    except Exception as e:
        logger.error(f"Error in get_fountain_details: {e}")
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    port = int(os.getenv('PORT', 3000))
    debug = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    
    logger.info(f"Starting TapMap API server on port {port}")
    logger.info(f"Database: {DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['dbname']}")
    
    app.run(host='0.0.0.0', port=port, debug=debug)

