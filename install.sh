#!/bin/bash

# Update and upgrade the system
echo "Updating system..."
sudo apt-get update -y && sudo apt-get upgrade -y

# Function to display a list of common timezones
function show_common_timezones() {
    echo "Please choose a timezone from the following common options:"
    echo "1) America/New_York (Eastern Time)"
    echo "2) America/Chicago (Central Time)"
    echo "3) America/Denver (Mountain Time)"
    echo "4) America/Los_Angeles (Pacific Time)"
    echo "5) Europe/London"
    echo "6) Europe/Berlin"
    echo "7) UTC"
    echo "8) Enter manually (you can see a full list using 'timedatectl list-timezones')"
    echo
}

# Prompt for a timezone
show_common_timezones
read -p "Enter the number corresponding to your timezone (or enter manually): " tz_choice

case $tz_choice in
    1) TIMEZONE="America/New_York" ;;
    2) TIMEZONE="America/Chicago" ;;
    3) TIMEZONE="America/Denver" ;;
    4) TIMEZONE="America/Los_Angeles" ;;
    5) TIMEZONE="Europe/London" ;;
    6) TIMEZONE="Europe/Berlin" ;;
    7) TIMEZONE="UTC" ;;
    8) 
        read -p "Enter your timezone manually (use 'timedatectl list-timezones' to see all options): " TIMEZONE ;;
    *)
        echo "Invalid option. Defaulting to UTC."
        TIMEZONE="UTC" ;;
esac

# Set the timezone
echo "Setting timezone to $TIMEZONE..."
sudo timedatectl set-timezone "$TIMEZONE"

# Confirm the timezone is set
timedatectl

# Prompt for a hostname (default to 'timer-pi' if no input)
read -p "Enter a unique hostname for this Raspberry Pi (default: timer-pi): " HOSTNAME
HOSTNAME=${HOSTNAME:-timer-pi}

# Set the hostname using hostnamectl
echo "Setting hostname to $HOSTNAME..."
sudo hostnamectl set-hostname "$HOSTNAME"

# Update /etc/hosts to reflect the new hostname
echo "Updating /etc/hosts to reflect the new hostname..."
sudo sed -i "/127.0.1.1/c\127.0.1.1\t$HOSTNAME" /etc/hosts

# Check if the change was successful, if not, append it
if ! grep -q "127.0.1.1 $HOSTNAME" /etc/hosts; then
    echo "Adding new hostname to /etc/hosts..."
    echo "127.0.1.1 $HOSTNAME" | sudo tee -a /etc/hosts
fi

# Confirm the changes made to /etc/hosts
echo "Current /etc/hosts content:"
cat /etc/hosts

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

# Create the WebSocket systemd service
echo "Creating systemd service for WebSocket server..."
sudo bash -c 'cat <<EOF > /etc/systemd/system/websocket-server.service
[Unit]
Description=Node.js WebSocket Server
After=network.target

[Service]
ExecStart=/usr/bin/node /var/www/html/studioTimer/websocket-server.js
WorkingDirectory=/var/www/html/studioTimer
Restart=always
User=root
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF'

# Enable and start the WebSocket service
sudo systemctl daemon-reload
sudo systemctl enable websocket-server.service
sudo systemctl start websocket-server.service

# Create the http-server systemd service
echo "Creating systemd service for http-server..."
sudo bash -c 'cat <<EOF > /etc/systemd/system/http-server.service
[Unit]
Description=HTTP Server for Serving Static Files
After=network.target

[Service]
ExecStart=/usr/local/bin/http-server -p 8080 -c-1 /var/www/html/studioTimer
WorkingDirectory=/var/www/html/studioTimer
Restart=always
User=root
Environment=PATH=/usr/local/bin:/usr/bin:/bin

[Install]
WantedBy=multi-user.target
EOF'

# Enable and start the http-server service
sudo systemctl daemon-reload
sudo systemctl enable http-server.service
sudo systemctl start http-server.service

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
