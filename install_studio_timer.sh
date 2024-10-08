#!/bin/bash

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
echo "Setting up project directory at /var/www/html/..."
PROJECT_DIR="/var/www/html/studioTimer"
sudo mkdir -p $PROJECT_DIR
sudo chown -R $USER:$USER $PROJECT_DIR

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
echo "@chromium-browser --noerrdialogs --disable-infobars --kiosk http://$HOSTNAME.local:8080/display.html" > $AUTOSTART_DIR/a
