# Fountain Map Backend Setup Instructions

## Overview
This guide provides step-by-step instructions for setting up a complete backend system for the Fountain Map application on Oracle Cloud Infrastructure (OCI) ARM free-tier VM. The system is optimized for geohash-based queries with smooth zoom transitions.

## Prerequisites
- Oracle Cloud Infrastructure account with ARM-based VM (Ampere A1)
- Basic knowledge of Linux command line
- SSH access to your VM

## System Requirements
- **VM Specifications**: ARM-based (Ampere A1) with 24GB RAM, 4 OCPUs
- **OS**: Ubuntu 22.04 LTS (recommended)
- **Storage**: At least 50GB for database and application
- **Network**: Public IP with ports 22 (SSH), 80 (HTTP), 443 (HTTPS), 8000 (API) open

## Step 1: Initial Server Setup

### 1.1 Update System
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git unzip software-properties-common
```

### 1.2 Create Application User
```bash
sudo adduser tapmap
sudo usermod -aG sudo tapmap
sudo su - tapmap
```

### 1.3 Install Python and Dependencies
```bash
# Install Python 3.10+
sudo apt install -y python3 python3-pip python3-venv python3-dev

# Install system dependencies for psycopg2
sudo apt install -y libpq-dev build-essential
```

## Step 2: PostgreSQL Installation and Setup

### 2.1 Install PostgreSQL
```bash
# Install lsb-release first
sudo apt install -y lsb-release

# Add PostgreSQL repository
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Add PostgreSQL GPG key
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Update package list
sudo apt update

# Install PostgreSQL 15
sudo apt install -y postgresql-15 postgresql-contrib-15
```

### 2.2 Configure PostgreSQL
```bash
# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Switch to postgres user and configure
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'your_secure_password';"
```

### 2.3 Create Database and User
```bash
# Run the database setup script
cd /home/tapmap
sudo chmod +x setup_database.sh
./setup_database.sh
```

## Step 3: Backend Application Setup

### 3.1 Clone and Setup Application
```bash
cd /home/tapmap
git clone <your-repo-url> backend
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 3.2 Configure Environment
```bash
# Copy environment template
cp env.example .env

# Edit environment variables
nano .env
```

Update the `.env` file with your actual database credentials and configuration.

### 3.3 Test Application
```bash
# Test the application
python main.py

# In another terminal, test the API
curl http://localhost:8000/
```

## Step 4: Data Import

### 4.1 Prepare Your JSON Data
Ensure your JSON file is accessible on the server. The format should match the expected structure:

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

### 4.2 Import Data
```bash
# Activate virtual environment
source venv/bin/activate

# Import your JSON file
python import_fountains.py /path/to/your/fountains.json --batch-size 1000 --create-indexes --stats
```

**Important**: For large datasets (millions of fountains), consider:
- Using larger batch sizes (5000-10000)
- Running during off-peak hours
- Monitoring system resources

## Step 5: Production Deployment

### 5.1 Setup Systemd Service
```bash
# Copy service file
sudo cp fountain-api.service /etc/systemd/system/

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable fountain-api
sudo systemctl start fountain-api

# Check status
sudo systemctl status fountain-api
```

### 5.2 Install and Configure Nginx
```bash
# Install Nginx
sudo apt install -y nginx

# Copy configuration
sudo cp nginx-fountain.conf /etc/nginx/sites-available/fountain
sudo ln -s /etc/nginx/sites-available/fountain /etc/nginx/sites-enabled/

# Remove default site
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx
```

### 5.3 SSL Certificate (Let's Encrypt)
```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtain SSL certificate
sudo certbot --nginx -d your-domain.com

# Test auto-renewal
sudo certbot renew --dry-run
```

## Step 6: Monitoring and Maintenance

### 6.1 Log Management
```bash
# Create log directory
mkdir -p /home/tapmap/backend/logs

# View application logs
sudo journalctl -u fountain-api -f

# View Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### 6.2 Database Maintenance
```bash
# Connect to database
psql -h localhost -U fountain_user -d fountain_db

# Check table sizes
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

# Check index usage
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

### 6.3 Performance Monitoring
```bash
# Install monitoring tools
sudo apt install -y htop iotop nethogs

# Monitor system resources
htop
iotop
nethogs
```

## Step 7: Scaling Considerations

### 7.1 Database Optimization
- **Connection Pooling**: Consider using PgBouncer for connection management
- **Read Replicas**: For high-traffic applications, consider read replicas
- **Partitioning**: For very large datasets, consider table partitioning by geohash

### 7.2 Application Scaling
- **Load Balancing**: Use multiple API instances behind a load balancer
- **Caching**: Implement Redis for caching frequently accessed data
- **CDN**: Use CloudFlare or similar for static content delivery

### 7.3 Backup Strategy
```bash
# Create backup script
cat > /home/tapmap/backup_db.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/tapmap/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/fountain_db_$DATE.sql"

mkdir -p $BACKUP_DIR
pg_dump -h localhost -U fountain_user -d fountain_db > $BACKUP_FILE
gzip $BACKUP_FILE

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete
EOF

# Make executable and add to crontab
chmod +x /home/tapmap/backup_db.sh
crontab -e
# Add: 0 2 * * * /home/tapmap/backup_db.sh
```

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check PostgreSQL service status: `sudo systemctl status postgresql`
   - Verify connection parameters in `.env`
   - Check firewall settings

2. **Import Process Slow**
   - Increase batch size
   - Check system resources (CPU, RAM, disk I/O)
   - Verify database indexes are created

3. **API Not Responding**
   - Check service status: `sudo systemctl status fountain-api`
   - View logs: `sudo journalctl -u fountain-api -f`
   - Verify port 8000 is not blocked by firewall

4. **Nginx Issues**
   - Test configuration: `sudo nginx -t`
   - Check error logs: `sudo tail -f /var/log/nginx/error.log`
   - Verify site configuration is enabled

### Performance Tuning

1. **PostgreSQL Tuning**
   ```bash
   # Edit postgresql.conf
   sudo nano /etc/postgresql/15/main/postgresql.conf
   
   # Recommended settings for 24GB RAM:
   shared_buffers = 6GB
   effective_cache_size = 18GB
   maintenance_work_mem = 1GB
   checkpoint_completion_target = 0.9
   wal_buffers = 16MB
   default_statistics_target = 100
   ```

2. **System Tuning**
   ```bash
   # Edit sysctl.conf
   sudo nano /etc/sysctl.conf
   
   # Add:
   vm.swappiness = 10
   vm.dirty_ratio = 15
   vm.dirty_background_ratio = 5
   ```

## Security Considerations

1. **Firewall Configuration**
   ```bash
   # Install UFW
   sudo apt install -y ufw
   
   # Configure firewall
   sudo ufw default deny incoming
   sudo ufw default allow outgoing
   sudo ufw allow ssh
   sudo ufw allow 80
   sudo ufw allow 443
   sudo ufw enable
   ```

2. **Regular Updates**
   ```bash
   # Set up automatic security updates
   sudo apt install -y unattended-upgrades
   sudo dpkg-reconfigure -plow unattended-upgrades
   ```

3. **Database Security**
   - Use strong passwords
   - Limit database access to application only
   - Regular security updates

## Conclusion

This setup provides a production-ready backend for your Fountain Map application with:
- Efficient geohash-based queries for smooth zoom transitions
- Scalable PostgreSQL database with proper indexing
- FastAPI backend with automatic API documentation
- Nginx reverse proxy with SSL support
- Systemd service management
- Comprehensive monitoring and backup strategies

The system is designed to handle millions of fountains efficiently while providing smooth user experience across different zoom levels. Regular monitoring and maintenance will ensure optimal performance as your dataset grows.
