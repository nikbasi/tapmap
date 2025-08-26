# SSH Tunnel Setup for Oracle Cloud PostgreSQL Database

This guide will help you connect to your PostgreSQL database running on Oracle Cloud Infrastructure (OCI) through an SSH tunnel using password authentication.

## Prerequisites

1. **Oracle Cloud VM Access**: You need SSH access to your Oracle Cloud VM
2. **SSH Password**: The password for your VM user account
3. **VM Details**: Public IP address and username of your VM
4. **Python Environment**: Virtual environment with required packages

## Step 1: Update Configuration

Copy `env.example` to `.env` and update the following values:

```bash
cp env.example .env
```

Edit the `.env` file with your actual VM details:

```bash
# Oracle Cloud SSH Tunnel Configuration
ORACLE_CLOUD_HOST=YOUR_ACTUAL_VM_IP      # Replace with your VM's public IP
ORACLE_CLOUD_USER=ubuntu                  # Usually 'ubuntu' for Ubuntu VMs
ORACLE_CLOUD_SSH_PASSWORD=YOUR_SSH_PASSWORD  # Your SSH password
SSH_TUNNEL_LOCAL_PORT=5433                # Local port for tunnel
SSH_TUNNEL_REMOTE_PORT=5432               # Remote DB port on VM

# Database Configuration
DB_NAME=tapmap_db                         # Database name on your VM
DB_USER=tapmap_user                       # Database user on your VM
DB_PASSWORD=tapmap_password               # Database password on your VM
```

## Step 2: Test SSH Connection

First, test that you can SSH to your VM:

```bash
ssh ubuntu@YOUR_VM_IP
```

If this works, you should see a login prompt. Enter your password and then exit with `exit` or `Ctrl+D`.

## Step 3: Set Up SSH Tunnel

Run the setup helper script:

```bash
python setup_ssh_tunnel.py
```

This will:
- Verify your configuration
- Check if sshpass is available (optional)
- Generate the SSH tunnel command
- Test the connection

## Step 4: Create the Tunnel

### Option 1: Manual Password Entry (Recommended)

Copy the SSH command from the output and run it in a **new terminal**:

```bash
ssh -L 5433:localhost:5432 ubuntu@YOUR_VM_IP
```

**Important**: Keep this terminal open! The tunnel will stay active as long as this SSH connection is maintained.

### Option 2: Automated with sshpass (Optional)

If you have `sshpass` installed, you can use automated password authentication:

```bash
# Install sshpass (Ubuntu/Debian)
sudo apt install sshpass

# Install sshpass (macOS)
brew install hudochenkov/sshpass/sshpass

# Then use the sshpass command from the setup script
sshpass -p 'YOUR_PASSWORD' ssh -L 5433:localhost:5432 ubuntu@YOUR_VM_IP
```

## Step 5: Connect to Database

In your original terminal, run:

```bash
python connect_to_db.py
```

This script will:
- Connect to the database through the SSH tunnel
- Show database structure and statistics
- Display sample data
- Provide insights about your fountain data

## How the Tunnel Works

```
Your Local Machine                    Oracle Cloud VM
┌─────────────────┐                 ┌─────────────────┐
│                 │                 │                 │
│  localhost:5433 │◄─── SSH ───────►│ localhost:5432  │
│                 │    Tunnel       │                 │
│  Your Script    │                 │  PostgreSQL DB  │
│                 │                 │                 │
└─────────────────┘                 └─────────────────┘
```

- Port 5433 on your local machine forwards to port 5432 on the remote VM
- Your database connection script connects to `localhost:5433`
- The SSH tunnel automatically forwards this to the remote PostgreSQL server

## Troubleshooting

### Connection Refused
- Make sure the SSH tunnel is running in another terminal
- Verify the tunnel port (5433) is not blocked by firewall
- Check that PostgreSQL is running on the remote VM

### Authentication Failed
- Verify your SSH password in the .env file
- Check that the username is correct
- Ensure SSH access is enabled on your VM

### Database Connection Error
- Verify database credentials in the .env file
- Check that the database exists and is accessible
- Ensure PostgreSQL is configured to accept local connections

### Port Already in Use
- Change the `SSH_TUNNEL_LOCAL_PORT` in the .env file to an unused port
- Kill any existing processes using the port: `lsof -ti:5433 | xargs kill`

## Security Notes

- The SSH tunnel encrypts all database traffic
- Only local connections to port 5433 are forwarded
- The tunnel is only active while the SSH connection is maintained
- Close the SSH tunnel when not in use
- **Never commit your .env file to version control** - it contains sensitive passwords

## Alternative: Direct Connection (Not Recommended for Production)

If you want to test without SSH tunnel (for development only), you can:

1. Configure PostgreSQL to accept external connections
2. Update firewall rules to allow port 5432
3. Use the VM's public IP directly in your database connection

**Warning**: This exposes your database to the internet and should only be used for testing.

## Next Steps

Once connected, you can:
- Explore your fountain data
- Run queries to analyze the data
- Import additional data using the import scripts
- Test the API endpoints

Happy database exploring! 🏛️💧 