#!/bin/bash
set -e

# Configuration
REPO_URL="https://github.com/nikbasi/tapmap.git"
APP_DIR="/home/tapmap/Code/tapmap"
API_DIR="$APP_DIR/tapmap_api"
DB_DIR="$APP_DIR/tapmap_db"
USER="tapmap"
GROUP="www-data"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Starting TapMap Deployment...${NC}"

# 1. Install System Dependencies
echo -e "${YELLOW}📦 Installing system dependencies...${NC}"
sudo apt-get update
sudo apt-get install -y python3-pip python3-venv postgresql postgresql-contrib nginx git acl

# 2. Setup Application Directory
echo -e "${YELLOW}📂 Setting up application directory...${NC}"
mkdir -p ~/Code
if [ -d "$APP_DIR" ]; then
    echo "Pulling latest changes..."
    cd "$APP_DIR"
    git pull
else
    echo "Cloning repository..."
    git clone "$REPO_URL" "$APP_DIR"
fi

# 3. Setup Python Environment
echo -e "${YELLOW}🐍 Setting up Python environment...${NC}"
cd "$API_DIR"
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn psycopg2-binary python-dotenv

# 4. Configure Environment Variables
echo -e "${YELLOW}⚙️  Configuring .env...${NC}"
# Create .env if it doesn't exist (using the aligned credentials)
cat > .env << EOL
DB_HOST=localhost
DB_PORT=5432
DB_NAME=tapmap_db
DB_USER=tapmap_user
DB_PASSWORD=\$fountains2025\$
PORT=3000
FLASK_DEBUG=False
JWT_SECRET_KEY=prod-secret-key-change-this
EOL

# Also for DB scripts
cd "$DB_DIR"
cp "$API_DIR/.env" .env

# 5. Initialize Database
echo -e "${YELLOW}🗄️  Initializing Database...${NC}"
# We need to install deps for the db scripts too
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi
source .venv/bin/activate
pip install -r requirements.txt
# Run init_db.py (handles user creation and schema)
# We might need sudo -u postgres for the first run if password auth fails for postgres user
# But our script prompts for password, which might be tricky in non-interactive.
# Let's assume the user can enter it or we rely on peer auth if running locally?
# Actually, init_db.py tries to connect.
python3 scripts/init_db.py

# 6. Setup Gunicorn Service
echo -e "${YELLOW}🚀 Setting up Gunicorn...${NC}"
sudo tee /etc/systemd/system/tapmap.service > /dev/null << EOL
[Unit]
Description=Gunicorn instance to serve TapMap API
After=network.target

[Service]
User=$USER
Group=$GROUP
WorkingDirectory=$API_DIR
Environment="PATH=$API_DIR/.venv/bin"
ExecStart=$API_DIR/.venv/bin/gunicorn --workers 3 --bind unix:tapmap.sock -m 007 app:app

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl enable tapmap
sudo systemctl restart tapmap

# 7. Setup Nginx
echo -e "${YELLOW}🌐 Setting up Nginx...${NC}"
sudo tee /etc/nginx/sites-available/tapmap > /dev/null << EOL
server {
    listen 80 default_server;
    server_name _;  # Listen on all IPs

    location / {
        include proxy_params;
        proxy_pass http://unix:$API_DIR/tapmap.sock;
    }
}
EOL

if [ ! -f /etc/nginx/sites-enabled/tapmap ]; then
    sudo ln -s /etc/nginx/sites-available/tapmap /etc/nginx/sites-enabled
fi

# Remove default site if it exists
if [ -f /etc/nginx/sites-enabled/default ]; then
    sudo rm /etc/nginx/sites-enabled/default
fi

sudo nginx -t
sudo systemctl restart nginx

echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo -e "API should be accessible at http://<your-server-ip>/"
