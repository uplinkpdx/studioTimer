#!/bin/bash

# Update and upgrade the system
echo "Updating system..."
sudo apt-get update -y && sudo apt-get upgrade -y

# Prompt for a hostname (default to 'timer-pi' if no input)
read -p "Enter a unique hostname for this Raspberry Pi (default: timer-pi): " HOSTNAME
HOSTNAME=${HOSTNAME:-timer-pi}

# Set the hostname using hostnamectl
echo "Setting hostname to $HOSTNAME..."
sudo hostnamectl set-hostname "$HOSTNAME"

# Update /etc/hosts with the new hostname
sudo sed -i "s/127.0.1.1 .*/127.0.1.1 $HOSTNAME/g" /etc/hosts

# Ensure avahi-daemon is installed and running for mDNS
echo "Installing avahi-daemon for mDNS (hostname.local resolution)..."
sudo apt-get install -y avahi-daemon
sudo systemctl enable avahi-daemon
sudo systemctl start avahi-daemon

# Install Node.js and npm
echo "Installing Node.js and npm..."
sudo apt-get install -y nodejs npm

# Install Chromium browser if not installed
echo "Installing Chromium browser..."
sudo apt-get install -y chromium-browser

# Create a directory for the project
echo "Setting up project directory..."
PROJECT_DIR="$HOME/studioTimer"
mkdir -p $PROJECT_DIR

# Navigate to the project directory
cd $PROJECT_DIR

# Clone the GitHub repository
echo "Cloning the project from GitHub..."
git clone https://github.com/uplinkpdx/studioTimer.git .

# Install project dependencies (e.g., for the WebSocket server)
echo "Installing project dependencies..."
npm install

# Install http-server globally to serve static files
echo "Installing http-server globally..."
sudo npm install -g http-server

# Start WebSocket server in the background on boot
echo "Setting up WebSocket server to start on boot..."
crontab -l > mycron
echo "@reboot node $PROJECT_DIR/websocket-server.js &" >> mycron
crontab mycron
rm mycron

# Serve the static files using http-server (both control and display on the same port 8080)
echo "Serving control.html and display.html on localhost port 8080..."
http-server -p 8080 -c-1 &

# Get the Raspberry Pi's IP address and hostname
IP_ADDRESS=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname)

# Set up the browser to open the display page in fullscreen on boot
echo "Setting up Chromium to autostart display page in fullscreen on boot..."
AUTOSTART_DIR="$HOME/.config/lxsession/LXDE-pi"
mkdir -p $AUTOSTART_DIR
echo "@chromium-browser --noerrdialogs --disable-infobars --kiosk http://$HOSTNAME.local:8080/display.html" > $AUTOSTART_DIR/autostart

# Output the URL for the control and display pages
echo "=============================================="
echo "Installation complete! You can access the control and display pages at:"
echo "Control Page: http://$HOSTNAME.local:8080/control.html"
echo "Display Page: http://$HOSTNAME.local:8080/display.html"
echo "=============================================="
