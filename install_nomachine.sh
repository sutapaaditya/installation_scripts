#!/bin/bash

# NoMachine Installation Script for Ubuntu
# This script downloads and installs NoMachine remote desktop software

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user."
   exit 1
fi

# Check if Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    print_warning "This script is designed for Ubuntu. It may work on other Debian-based systems."
    read -p "Do you want to continue? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

print_status "Starting NoMachine installation..."

# Update package list
print_status "Updating package list..."
sudo apt update

# Install required dependencies
print_status "Installing dependencies..."
sudo apt install -y wget curl

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        NOMACHINE_ARCH="amd64"
        ;;
    aarch64|arm64)
        NOMACHINE_ARCH="arm64"
        ;;
    armv7l)
        NOMACHINE_ARCH="armhf"
        ;;
    i386|i686)
        NOMACHINE_ARCH="i386"
        ;;
    *)
        print_error "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

print_status "Detected architecture: $ARCH (using $NOMACHINE_ARCH package)"

# NoMachine download URL (latest version)
NOMACHINE_VERSION="9.0.188_11"
NOMACHINE_URL="https://download.nomachine.com/download/9.0/Linux/nomachine_${NOMACHINE_VERSION}_${NOMACHINE_ARCH}.deb"
NOMACHINE_FILE="nomachine_${NOMACHINE_VERSION}_${NOMACHINE_ARCH}.deb"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

print_status "Downloading NoMachine from: $NOMACHINE_URL"

# Download NoMachine
print_status "Downloading NoMachine..."
if ! wget --progress=bar:force -O "$NOMACHINE_FILE" "$NOMACHINE_URL"; then
    print_error "Failed to download NoMachine. Please check your internet connection."
    exit 1
fi

# Verify download is a valid .deb file
if ! file "$NOMACHINE_FILE" | grep -q "Debian binary package"; then
    print_error "Downloaded file is not a valid Debian package. URL may be incorrect."
    print_error "Downloaded file type: $(file "$NOMACHINE_FILE")"
    exit 1
fi

# Verify download
if [[ ! -f "$NOMACHINE_FILE" ]]; then
    print_error "Download failed - file not found"
    exit 1
fi

print_status "Download completed successfully"

# Install NoMachine
print_status "Installing NoMachine..."
if sudo dpkg -i "$NOMACHINE_FILE"; then
    print_status "NoMachine installed successfully"
else
    print_warning "dpkg reported issues, attempting to fix dependencies..."
    sudo apt-get install -f -y
    print_status "Dependencies fixed"
fi

# Clean up
cd /
rm -rf "$TEMP_DIR"

print_status "Cleaning up temporary files..."

# Check if NoMachine service is running
print_status "Checking NoMachine service..."
if systemctl list-units --full -all | grep -q "nxserver.service"; then
    if systemctl is-active --quiet nxserver; then
        print_status "NoMachine service is already running"
    else
        print_status "Starting NoMachine service..."
        sudo systemctl start nxserver
        sudo systemctl enable nxserver
    fi
else
    # Try alternative service names
    if systemctl list-units --full -all | grep -q "nomachine.service"; then
        print_status "Starting NoMachine service (nomachine.service)..."
        sudo systemctl start nomachine
        sudo systemctl enable nomachine
    elif [ -f "/etc/init.d/nxserver" ]; then
        print_status "Starting NoMachine service via init.d..."
        sudo service nxserver start
        sudo update-rc.d nxserver defaults
    else
        print_warning "NoMachine service not found. Trying to start manually..."
        if [ -f "/usr/NX/bin/nxserver" ]; then
            sudo /usr/NX/bin/nxserver --startup
        fi
    fi
fi

# Display service status
print_status "Checking NoMachine service status..."
if systemctl list-units --full -all | grep -q "nxserver.service"; then
    systemctl status nxserver --no-pager -l
elif systemctl list-units --full -all | grep -q "nomachine.service"; then
    systemctl status nomachine --no-pager -l
elif [ -f "/etc/init.d/nxserver" ]; then
    service nxserver status
else
    print_status "Checking if NoMachine is running..."
    if pgrep -x "nxd" > /dev/null; then
        print_status "NoMachine daemon is running"
    else
        print_warning "NoMachine daemon may not be running"
    fi
fi

# Get IP address for connection info
IP_ADDRESS=$(hostname -I | awk '{print $1}')

print_status "Installation completed successfully!"
echo
echo "=================================================="
echo "             NoMachine Setup Complete"
echo "=================================================="
echo
echo "Connection Information:"
echo "- Server Address: $IP_ADDRESS"
echo "- Port: 4000 (default)"
echo "- Protocol: NX"
echo
echo "Next Steps:"
echo "1. Install NoMachine client on your remote device"
echo "2. Download client from: https://www.nomachine.com/download"
echo "3. Create a new connection using the server address above"
echo "4. Use your Ubuntu username and password to connect"
echo
echo "Firewall Configuration (if needed):"
echo "- sudo ufw allow 4000/tcp"
echo "- sudo ufw allow 4011:4999/tcp"
echo
echo "Service Management:"
echo "- Start:   sudo systemctl start nxserver"
echo "- Stop:    sudo systemctl stop nxserver"
echo "- Restart: sudo systemctl restart nxserver"
echo "- Status:  sudo systemctl status nxserver"
echo
echo "Configuration files location: /usr/NX/etc/"
echo "Log files location: /usr/NX/var/log/"
echo
print_status "Enjoy your remote desktop experience!"
