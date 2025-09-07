#!/usr/bin/env python3
"""
Script to create the .env file for the Flutter app
"""

import os

def create_env_file():
    """Create the .env file with database configuration"""
    
    env_content = """# Database Configuration for Flutter App
# These are the database credentials for your PostgreSQL database
DB_HOST=localhost
DB_NAME=tapmap_db
DB_USER=tapmap_user
DB_PASSWORD=your_actual_password_here

# SSH Tunnel Configuration
# Your VM's public IP address
ORACLE_CLOUD_HOST=YOUR_VM_PUBLIC_IP
# SSH username (usually 'ubuntu' for Ubuntu VMs)
ORACLE_CLOUD_USER=ubuntu
# SSH password (leave empty if using SSH key)
ORACLE_CLOUD_SSH_PASSWORD=YOUR_SSH_PASSWORD
# Local port for SSH tunnel (forwarded to remote DB port)
SSH_TUNNEL_LOCAL_PORT=5433
# Remote database port on the VM
SSH_TUNNEL_REMOTE_PORT=5432
"""
    
    env_path = os.path.join('backend', '.env')
    
    try:
        with open(env_path, 'w') as f:
            f.write(env_content)
        print(f"✅ Created .env file at: {env_path}")
        print("\n📝 IMPORTANT: Update the following values in the .env file:")
        print("   - DB_PASSWORD: Your actual database password")
        print("   - ORACLE_CLOUD_HOST: Your VM's public IP address")
        print("   - ORACLE_CLOUD_USER: Your SSH username (usually 'ubuntu')")
        print("   - ORACLE_CLOUD_SSH_PASSWORD: Your SSH password (if using password auth)")
        print("\n🔒 The .env file is now in your .gitignore, so it won't be committed to version control.")
        
    except Exception as e:
        print(f"❌ Error creating .env file: {e}")

if __name__ == "__main__":
    create_env_file()


