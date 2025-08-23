# Fountain Map Backend

A high-performance, geohash-optimized backend system for fountain mapping applications. Built with FastAPI and PostgreSQL, this system provides efficient spatial queries with smooth zoom transitions for Flutter map applications.

## 🚀 Features

- **Geohash-Optimized Queries**: Multi-precision geohash indexing for efficient map queries
- **Smooth Zoom Transitions**: Automatic precision selection based on zoom level
- **High Performance**: Optimized database schema with proper indexing
- **RESTful API**: Clean FastAPI endpoints with automatic documentation
- **Scalable Architecture**: Designed to handle millions of fountains efficiently
- **Production Ready**: Includes Nginx configuration, systemd service, and monitoring

## 🏗️ Architecture

### Database Design
- **Multi-precision Geohash Storage**: Stores geohash at 12 precision levels (1-12 characters)
- **Efficient Indexing**: Separate indexes for each precision level
- **JSONB Support**: Flexible storage for tags, OSM data, and metadata
- **Automatic Updates**: Triggers for timestamp management

### API Endpoints
- `GET /fountains/geohash/{prefix}` - Query by geohash prefix
- `POST /fountains/viewport` - Query by viewport with automatic precision selection
- `POST /fountains` - Add new fountains with automatic geohash calculation
- `GET /fountains/search` - Full-text search functionality
- `GET /stats` - Database statistics and performance metrics

### Geohash Precision Strategy
```
Zoom Level → Geohash Precision → Query Performance
1-3        → 1 character      → Very fast, few results
4-6        → 2-3 characters  → Fast, moderate results  
7-9        → 4-5 characters  → Balanced performance
10-12      → 6-7 characters  → Detailed results
13-15      → 8-9 characters  → High detail
16+        → 10+ characters  → Maximum detail
```

## 📋 Prerequisites

- **Server**: Oracle Cloud ARM VM (Ampere A1) or similar
- **OS**: Ubuntu 22.04 LTS (recommended)
- **RAM**: Minimum 8GB, recommended 24GB
- **Storage**: Minimum 50GB for database and application
- **Python**: 3.10+
- **PostgreSQL**: 15+

## 🛠️ Installation

### 1. Quick Start (Development)

```bash
# Clone the repository
git clone <your-repo> fountain-backend
cd fountain-backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set up environment variables
cp env.example .env
# Edit .env with your database credentials

# Run the application
python main.py
```

### 2. Production Deployment

Follow the complete setup instructions in [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) for production deployment on Oracle Cloud.

## 🗄️ Database Setup

### Automatic Setup
```bash
# Make script executable
chmod +x setup_database.sh

# Run database setup
./setup_database.sh
```

### Manual Setup
```sql
-- Connect to PostgreSQL as superuser
sudo -u postgres psql

-- Create database and user
CREATE DATABASE fountain_db;
CREATE USER fountain_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE fountain_db TO fountain_user;

-- Connect to fountain_db and run schema
\c fountain_db
\i schema.sql
```

## 📊 Data Import

### Import Your JSON Data
```bash
# Activate virtual environment
source venv/bin/activate

# Import fountains from JSON file
python import_fountains.py /path/to/your/fountains.json \
  --batch-size 1000 \
  --create-indexes \
  --stats
```

### Import Options
- `--batch-size`: Number of fountains to process per batch (default: 1000)
- `--create-indexes`: Create database indexes after import
- `--stats`: Show import statistics after completion

### Expected JSON Format
```json
{
  "osm_node_123": {
    "id": "osm_node_123",
    "name": "Fountain Name",
    "location": {
      "latitude": 40.7128,
      "longitude": -74.0060
    },
    "type": "fountain",
    "status": "active",
    "waterQuality": "potable",
    "accessibility": "public",
    "tags": ["amenity:drinking_water"],
    "osmData": {...}
  }
}
```

## 🔧 Configuration

### Environment Variables
```bash
# Database Configuration
DB_HOST=localhost
DB_NAME=fountain_db
DB_USER=fountain_user
DB_PASSWORD=fountain_password
DB_PORT=5432

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
API_DEBUG=false
```

### Database Tuning
For optimal performance with large datasets, adjust PostgreSQL settings:

```bash
# Edit postgresql.conf
sudo nano /etc/postgresql/15/main/postgresql.conf

# Recommended settings for 24GB RAM:
shared_buffers = 6GB
effective_cache_size = 18GB
maintenance_work_mem = 1GB
checkpoint_completion_target = 0.9
```

## 🚀 API Usage

### Query by Geohash
```bash
# Get fountains in a specific geohash area
curl "http://localhost:8000/fountains/geohash/dr5?limit=100"
```

### Query by Viewport
```bash
# Get fountains in a viewport with automatic precision selection
curl -X POST "http://localhost:8000/fountains/viewport" \
  -H "Content-Type: application/json" \
  -d '{
    "north": 40.8,
    "south": 40.7,
    "east": -74.0,
    "west": -74.1,
    "zoom_level": 12,
    "limit": 500
  }'
```

### Add New Fountain
```bash
# Add a new fountain with automatic geohash calculation
curl -X POST "http://localhost:8000/fountains" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Fountain",
    "description": "A beautiful new fountain",
    "location": {
      "latitude": 40.7589,
      "longitude": -73.9851
    },
    "type": "fountain",
    "status": "active",
    "water_quality": "potable",
    "accessibility": "public",
    "tags": ["amenity:drinking_water"]
  }'
```

### Search Fountains
```bash
# Search fountains by text
curl "http://localhost:8000/fountains/search?query=fountain&limit=100"
```

## 📱 Flutter Integration

See [flutter_integration_example.dart](flutter_integration_example.dart) for complete Flutter integration examples.

### Basic Usage
```dart
// Get fountains by viewport
final fountains = await FountainApiService.getFountainsByViewport(
  north: 40.8,
  south: 40.7,
  east: -74.0,
  west: -74.1,
  zoomLevel: 12,
  limit: 500,
);

// Get fountains by geohash
final fountains = await FountainApiService.getFountainsByGeohash(
  'dr5',
  limit: 1000,
);
```

## 🧪 Testing

### Performance Testing
```bash
# Run comprehensive performance tests
python performance_test.py http://localhost:8000 --test-count 20

# Quick test mode
python performance_test.py http://localhost:8000 --quick-test

# Save results to file
python performance_test.py http://localhost:8000 --output-file results.json
```

### API Documentation
Visit `http://localhost:8000/docs` for interactive API documentation (Swagger UI).

## 📈 Monitoring

### Application Logs
```bash
# View application logs
sudo journalctl -u fountain-api -f

# View Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Database Performance
```sql
-- Check table sizes
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check index usage
SELECT schemaname, tablename, indexname, 
       idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

### System Resources
```bash
# Monitor system resources
htop
iotop
nethogs

# Check disk usage
df -h
du -sh /var/lib/postgresql/
```

## 🔒 Security

### Firewall Configuration
```bash
# Install and configure UFW
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
```

### SSL/TLS Setup
```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Obtain SSL certificate
sudo certbot --nginx -d your-domain.com

# Test auto-renewal
sudo certbot renew --dry-run
```

## 📚 API Reference

### Response Format
All endpoints return JSON responses with consistent structure:

```json
[
  {
    "id": "osm_node_123",
    "name": "Fountain Name",
    "description": "Description",
    "location": {
      "latitude": 40.7128,
      "longitude": -74.0060
    },
    "type": "fountain",
    "status": "active",
    "water_quality": "potable",
    "accessibility": "public",
    "added_by": "osm_import",
    "added_date": "2025-01-20T10:00:00Z",
    "validations": [],
    "photos": [],
    "tags": ["amenity:drinking_water"],
    "osm_data": {...},
    "geohash": "dr5ruj",
    "created_at": "2025-01-20T10:00:00Z",
    "updated_at": "2025-01-20T10:00:00Z"
  }
]
```

### Error Responses
```json
{
  "detail": "Error message description"
}
```

## 🚀 Performance Optimization

### Database Optimization
- **Connection Pooling**: Consider PgBouncer for high-traffic applications
- **Read Replicas**: Implement read replicas for scaling
- **Partitioning**: Table partitioning by geohash for very large datasets

### Application Optimization
- **Caching**: Implement Redis for frequently accessed data
- **Load Balancing**: Multiple API instances behind a load balancer
- **CDN**: Use CloudFlare for static content delivery

### Monitoring and Tuning
- Regular performance testing with `performance_test.py`
- Monitor database query performance
- Adjust PostgreSQL settings based on workload
- Monitor system resources and scale accordingly

## 🐛 Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check PostgreSQL service status
   - Verify connection parameters in `.env`
   - Check firewall settings

2. **Import Process Slow**
   - Increase batch size
   - Check system resources
   - Verify database indexes

3. **API Not Responding**
   - Check service status
   - View application logs
   - Verify port accessibility

4. **Performance Issues**
   - Run performance tests
   - Check database indexes
   - Monitor system resources

### Getting Help
- Check the logs: `sudo journalctl -u fountain-api -f`
- Review the setup instructions: [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md)
- Run performance tests: `python performance_test.py`
- Check API documentation: `http://localhost:8000/docs`

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📞 Support

For support and questions:
- Check the documentation
- Review the setup instructions
- Run performance tests to identify issues
- Check system logs for error details

---

**Built with ❤️ for efficient fountain mapping applications**





