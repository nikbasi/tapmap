#!/usr/bin/env python3
"""
SSH Tunnel Setup Helper for Oracle Cloud PostgreSQL Database
This script helps you set up the SSH tunnel to connect to your remote database
"""

import os
import subprocess
import sys
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def get_config():
    """Get configuration from environment variables"""
    return {
        'oracle_cloud_host': os.getenv('ORACLE_CLOUD_HOST'),
        'oracle_cloud_user': os.getenv('ORACLE_CLOUD_USER', 'ubuntu'),
        'oracle_cloud_ssh_password': os.getenv('ORACLE_CLOUD_SSH_PASSWORD'),
        'ssh_tunnel_local_port': int(os.getenv('SSH_TUNNEL_LOCAL_PORT', '5433')),
        'ssh_tunnel_remote_port': int(os.getenv('SSH_TUNNEL_REMOTE_PORT', '5432'))
    }

def check_config():
    """Check if configuration is properly set"""
    config = get_config()
    
    if not config['oracle_cloud_host'] or config['oracle_cloud_host'] == 'YOUR_VM_PUBLIC_IP':
        print("❌ Configuration not set up yet!")
        print("   Please copy env.example to .env and update:")
        print("   - ORACLE_CLOUD_HOST: Your VM's public IP address")
        print("   - ORACLE_CLOUD_USER: Your VM username (usually 'ubuntu')")
        print("   - ORACLE_CLOUD_SSH_PASSWORD: Your SSH password")
        return False
    
    if not config['oracle_cloud_ssh_password'] or config['oracle_cloud_ssh_password'] == 'YOUR_SSH_PASSWORD':
        print("❌ SSH password not configured!")
        print("   Please set ORACLE_CLOUD_SSH_PASSWORD in your .env file")
        return False
    
    print("✅ Configuration looks good!")
    print(f"   Host: {config['oracle_cloud_host']}")
    print(f"   User: {config['oracle_cloud_user']}")
    print(f"   Local Port: {config['ssh_tunnel_local_port']}")
    print(f"   Remote Port: {config['ssh_tunnel_remote_port']}")
    print(f"   SSH Auth: Password")
    return True

def generate_ssh_command():
    """Generate the SSH tunnel command"""
    config = get_config()
    
    # For password authentication, we'll use sshpass if available, otherwise manual
    print("\n🔗 SSH Tunnel Command (Password Authentication):")
    print("=" * 60)
    
    # Option 1: Using sshpass (if installed)
    sshpass_cmd = f"sshpass -p '{config['oracle_cloud_ssh_password']}' ssh -L {config['ssh_tunnel_local_port']}:localhost:{config['ssh_tunnel_remote_port']} {config['oracle_cloud_user']}@{config['oracle_cloud_host']}"
    print("Option 1 - Using sshpass (if installed):")
    print(sshpass_cmd)
    print()
    
    # Option 2: Manual password entry
    manual_cmd = f"ssh -L {config['ssh_tunnel_local_port']}:localhost:{config['ssh_tunnel_remote_port']} {config['oracle_cloud_user']}@{config['oracle_cloud_host']}"
    print("Option 2 - Manual password entry (recommended):")
    print(manual_cmd)
    print("   (You'll be prompted for password when connecting)")
    print("=" * 60)
    
    return manual_cmd

def test_connection():
    """Test if the tunnel is working by trying to connect to local port"""
    config = get_config()
    try:
        import socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex(('localhost', config['ssh_tunnel_local_port']))
        sock.close()
        
        if result == 0:
            print(f"✅ Port {config['ssh_tunnel_local_port']} is open - tunnel appears to be working!")
            return True
        else:
            print(f"❌ Port {config['ssh_tunnel_local_port']} is not accessible")
            print("   Make sure the SSH tunnel is running in another terminal")
            return False
    except Exception as e:
        print(f"❌ Error testing connection: {e}")
        return False

def check_sshpass_available():
    """Check if sshpass is available for automated password authentication"""
    try:
        result = subprocess.run(['sshpass', '-V'], capture_output=True, text=True)
        if result.returncode == 0:
            print("✅ sshpass is available - you can use automated password authentication")
            return True
        else:
            print("❌ sshpass not available - you'll need to enter password manually")
            return False
    except FileNotFoundError:
        print("❌ sshpass not installed - you'll need to enter password manually")
        print("   To install sshpass (Ubuntu/Debian): sudo apt install sshpass")
        print("   To install sshpass (macOS): brew install hudochenkov/sshpass/sshpass")
        return False

def main():
    """Main function to help set up SSH tunnel"""
    print("🔌 SSH Tunnel Setup for Oracle Cloud PostgreSQL Database")
    print("=" * 60)
    
    # Check configuration
    if not check_config():
        return
    
    print()
    
    # Check if sshpass is available
    sshpass_available = check_sshpass_available()
    
    print()
    
    # Generate SSH command
    ssh_cmd = generate_ssh_command()
    
    print("\n📋 Instructions:")
    if sshpass_available:
        print("1. Copy the sshpass command above (Option 1)")
        print("2. Open a new terminal/command prompt")
        print("3. Paste and run the sshpass command")
    else:
        print("1. Copy the manual SSH command above (Option 2)")
        print("2. Open a new terminal/command prompt")
        print("3. Paste and run the SSH command")
        print("4. Enter your SSH password when prompted")
    
    print("5. Keep that terminal open (the tunnel will stay active)")
    print("6. In this terminal, run: python connect_to_db.py")
    
    print("\n🔍 Testing tunnel connection...")
    if test_connection():
        print("\n🎉 Great! The tunnel is working. You can now run:")
        print("   python connect_to_db.py")
    else:
        print("\n⚠️  Tunnel not detected. Please:")
        print("   1. Run the SSH command in another terminal")
        print("   2. Wait for the connection to establish")
        print("   3. Run this script again to test")

if __name__ == "__main__":
    main() 