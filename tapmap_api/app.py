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
import jwt
import bcrypt
from datetime import datetime, timedelta
from functools import wraps

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

# JWT configuration
JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'your-secret-key-change-in-production')
JWT_ALGORITHM = 'HS256'
JWT_EXPIRATION_HOURS = 24 * 7  # 7 days


def get_db_connection():
    """Get a database connection."""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        logger.error(f"Database connection error: {e}")
        raise


def generate_jwt_token(user_id, email):
    """Generate a JWT token for a user."""
    payload = {
        'user_id': user_id,
        'email': email,
        'exp': datetime.utcnow() + timedelta(hours=JWT_EXPIRATION_HOURS),
        'iat': datetime.utcnow()
    }
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)


def verify_jwt_token(token):
    """Verify and decode a JWT token."""
    try:
        payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None


def get_token_from_request():
    """Extract JWT token from request headers."""
    auth_header = request.headers.get('Authorization')
    if auth_header and auth_header.startswith('Bearer '):
        return auth_header.split(' ')[1]
    return None


def require_auth(f):
    """Decorator to require authentication for an endpoint."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        token = get_token_from_request()
        if not token:
            return jsonify({'error': 'Authentication required'}), 401
        
        payload = verify_jwt_token(token)
        if not payload:
            return jsonify({'error': 'Invalid or expired token'}), 401
        
        # Add user info to request context
        request.user_id = payload['user_id']
        request.user_email = payload['email']
        
        return f(*args, **kwargs)
    return decorated_function


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
        
        # Extract filter parameters - only use if they exist and are not empty
        # PostgreSQL's ANY(ARRAY[]) returns false for empty arrays, so we must pass None
        filter_statuses = data.get('statuses')
        if filter_statuses is not None and len(filter_statuses) == 0:
            filter_statuses = None
            
        filter_water_qualities = data.get('water_qualities')
        if filter_water_qualities is not None and len(filter_water_qualities) == 0:
            filter_water_qualities = None
            
        filter_accessibilities = data.get('accessibilities')
        if filter_accessibilities is not None and len(filter_accessibilities) == 0:
            filter_accessibilities = None
            
        filter_types = data.get('types')
        if filter_types is not None and len(filter_types) == 0:
            filter_types = None
        
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Call the database function with filters
        cursor.execute("""
            SELECT * FROM get_fountains_for_map_view(
                %s, %s, %s, %s, NULL,
                %s, %s, %s, %s
            )
        """, (
            min_lat, max_lat, min_lng, max_lng,
            filter_statuses, filter_water_qualities,
            filter_accessibilities, filter_types
        ))
        
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


# ============================================================================
# Authentication Endpoints
# ============================================================================

@app.route('/api/auth/signup', methods=['POST'])
def signup():
    """Register a new user with email and password."""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'Request body is required'}), 400
        
        email = data.get('email', '').strip().lower()
        password = data.get('password', '')
        display_name = data.get('display_name', '').strip()
        
        if not email or not password:
            return jsonify({'error': 'Email and password are required'}), 400
        
        if len(password) < 6:
            return jsonify({'error': 'Password must be at least 6 characters'}), 400
        
        # Hash password
        password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        try:
            # Check if user already exists
            cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
            if cursor.fetchone():
                cursor.close()
                conn.close()
                return jsonify({'error': 'Email already registered'}), 400
            
            # Create user
            cursor.execute("""
                INSERT INTO users (email, password_hash, display_name, provider)
                VALUES (%s, %s, %s, 'email')
                RETURNING id, email, display_name, created_at
            """, (email, password_hash, display_name or None))
            
            user = cursor.fetchone()
            conn.commit()
            
            # Generate JWT token
            token = generate_jwt_token(user['id'], user['email'])
            
            cursor.close()
            conn.close()
            
            return jsonify({
                'token': token,
                'user': {
                    'id': user['id'],
                    'email': user['email'],
                    'display_name': user['display_name'],
                }
            }), 201
            
        except psycopg2.IntegrityError:
            conn.rollback()
            cursor.close()
            conn.close()
            return jsonify({'error': 'Email already registered'}), 400
        
    except Exception as e:
        logger.error(f"Error in signup: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/auth/login', methods=['POST'])
def login():
    """Login with email and password."""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'Request body is required'}), 400
        
        email = data.get('email', '').strip().lower()
        password = data.get('password', '')
        
        if not email or not password:
            return jsonify({'error': 'Email and password are required'}), 400
        
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Get user by email
        cursor.execute("""
            SELECT id, email, password_hash, display_name, provider
            FROM users WHERE email = %s
        """, (email,))
        
        user = cursor.fetchone()
        
        if not user:
            cursor.close()
            conn.close()
            return jsonify({'error': 'Invalid email or password'}), 401
        
        # Verify password
        if not bcrypt.checkpw(password.encode('utf-8'), user['password_hash'].encode('utf-8')):
            cursor.close()
            conn.close()
            return jsonify({'error': 'Invalid email or password'}), 401
        
        # Update last login
        cursor.execute("""
            UPDATE users SET last_login = CURRENT_TIMESTAMP
            WHERE id = %s
        """, (user['id'],))
        conn.commit()
        
        # Generate JWT token
        token = generate_jwt_token(user['id'], user['email'])
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'token': token,
            'user': {
                'id': user['id'],
                'email': user['email'],
                'display_name': user['display_name'],
                'provider': user['provider'],
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Error in login: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/auth/me', methods=['GET'])
@require_auth
def get_current_user():
    """Get current authenticated user information."""
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        cursor.execute("""
            SELECT id, email, display_name, provider, avatar_url, email_verified, created_at
            FROM users WHERE id = %s
        """, (request.user_id,))
        
        user = cursor.fetchone()
        
        cursor.close()
        conn.close()
        
        if user:
            return jsonify(dict(user)), 200
        else:
            return jsonify({'error': 'User not found'}), 404
        
    except Exception as e:
        logger.error(f"Error in get_current_user: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/api/auth/verify-token', methods=['POST'])
def verify_token():
    """Verify if a JWT token is valid."""
    try:
        data = request.get_json()
        token = data.get('token') if data else get_token_from_request()
        
        if not token:
            return jsonify({'valid': False, 'error': 'Token required'}), 400
        
        payload = verify_jwt_token(token)
        if not payload:
            return jsonify({'valid': False, 'error': 'Invalid or expired token'}), 401
        
        return jsonify({
            'valid': True,
            'user_id': payload['user_id'],
            'email': payload['email']
        }), 200
        
    except Exception as e:
        logger.error(f"Error in verify_token: {e}")
        return jsonify({'valid': False, 'error': str(e)}), 500


if __name__ == '__main__':
    port = int(os.getenv('PORT', 3000))
    debug = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    
    logger.info(f"Starting TapMap API server on port {port}")
    logger.info(f"Database: {DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['dbname']}")
    
    app.run(host='0.0.0.0', port=port, debug=debug)

