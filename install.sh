#!/bin/bash

# Function to fix dpkg issues
fix_dpkg() {
    echo "Checking for dpkg issues..."
    sudo dpkg --configure -a
    if [ $? -ne 0 ]; then
        echo "Error: dpkg configuration failed. Please resolve manually."
        exit 1
    fi
    echo "dpkg issue resolved!"
}

# Function to prevent Raspberry Pi from sleeping/standby
prevent_sleep() {
    echo "Disabling standby and power-saving features..."

    # Disable screen blanking
    sudo sed -i 's/^#xserver-command=X$/xserver-command=X -s 0 dpms/' /etc/lightdm/lightdm.conf

    # Disable DPMS (Energy Star) features
    echo "Disabling DPMS (Display Power Management Signaling)..."
    cat <<EOL >> ~/.xinitrc
    xset s off      # Turn off screen saver
    xset -dpms      # Disable DPMS (Energy Star) features
    xset s noblank  # Disable screen blanking
EOL

    # Disable HDMI power saving by keeping the HDMI signal alive
    echo "Disabling HDMI power saving..."
    sudo sh -c "echo 'hdmi_blanking=1' >> /boot/config.txt"
    
    # Prevent console from going blank
    sudo sed -i 's/^#consoleblank=0/consoleblank=0/' /boot/cmdline.txt
    
    echo "All power-saving settings have been disabled."
}

# Function to check if hostname has been set successfully
check_hostname_set() {
    local desired_hostname="$1"
    local current_hostname="$(hostname)"
    
    if [ "$current_hostname" == "$desired_hostname" ]; then
        echo "Hostname has been successfully set to $desired_hostname"
        return 0
    else
        echo "Waiting for hostname to update..."
        return 1
    fi
}

# Fix dpkg issues first
fix_dpkg

# Prevent the Raspberry Pi from going into standby or sleep
prevent_sleep

# Update system
echo "Updating system..."
sudo apt update && sudo apt upgrade -y

# Set hostname
read -p "Enter a hostname for this Raspberry Pi (default: timer-pi): " new_hostname
new_hostname=${new_hostname:-timer-pi}

echo "Setting hostname to $new_hostname..."
sudo hostnamectl set-hostname "$new_hostname"

# Update /etc/hosts file to reflect the new hostname
sudo sed -i "s/127.0.1.1.*/127.0.1.1   $new_hostname/g" /etc/hosts
echo "Updated /etc/hosts with the new hostname."

# Wait for the hostname to take effect and check it
sleep 5  # Introduce a short delay
attempts=0
max_attempts=5
while ! check_hostname_set "$new_hostname"; do
    attempts=$((attempts + 1))
    if [ $attempts -ge $max_attempts ]; then
        echo "Hostname change failed after $max_attempts attempts. Exiting..."
        exit 1
    fi
    sleep 2
done

# Install Node.js, npm, and Chromium for browser in kiosk mode
echo "Installing Node.js, npm, and Chromium browser..."
sudo apt install -y nodejs npm chromium-browser
if [ $? -ne 0 ]; then
    echo "Error: Failed to install required packages. Please resolve manually."
    exit 1
fi

# Install http-server globally using npm
echo "Installing http-server..."
sudo npm install -g http-server
if [ $? -ne 0 ]; then
    echo "Error: Failed to install http-server. Please resolve manually."
    exit 1
fi

# Clone the project from GitHub into /var/www/html
echo "Cloning your project from GitHub into /var/www/html..."
sudo git clone https://github.com/uplinkpdx/studioTimer.git /var/www/html
if [ $? -ne 0 ]; then
    echo "Error: Failed to clone the repository. Please check the URL."
    exit 1
fi

# Replace placeholders in JavaScript files with the dynamically determined WebSocket server IP
echo "Replacing WebSocket placeholders with the actual server IP..."
server_ip=$(hostname -I | awk '{print $1}')
sed -i "s/%%WEBSOCKET_SERVER_IP%%/$server_ip/g" /var/www/html/*.js

# Create systemd service for WebSocket server
echo "Creating systemd service for WebSocket server..."
sudo bash -c 'cat <<EOL > /etc/systemd/system/studioTimerWebSocket.service
[Unit]
Description=Studio Timer WebSocket Server
After=network.target

[Service]
ExecStart=/usr/bin/node /var/www/html/server.js
Restart=always
User=pi
Environment=PATH=/usr/bin:/usr/local/bin
WorkingDirectory=/var/www/html

[Install]
WantedBy=multi-user.target
EOL'

# Enable and start WebSocket server service
sudo systemctl enable studioTimerWebSocket
sudo systemctl start studioTimerWebSocket

# Create systemd service for HTTP server
echo "Creating systemd service for HTTP server..."
sudo bash -c 'cat <<EOL > /etc/systemd/system/studioTimerHTTP.service
[Unit]
Description=Studio Timer HTTP Server
After=network.target

[Service]
ExecStart=/usr/local/bin/http-server /var/www/html -p 8090
Restart=always
User=pi
Environment=PATH=/usr/bin:/usr/local/bin
WorkingDirectory=/var/www/html

[Install]
WantedBy=multi-user.target
EOL'

# Enable and start HTTP server service
sudo systemctl enable studioTimerHTTP
sudo systemctl start studioTimerHTTP

# Set Chromium to start in kiosk mode at boot
echo "Configuring Chromium to launch in kiosk mode on boot..."
mkdir -p ~/.config/autostart
cat <<EOL > ~/.config/autostart/chromium-kiosk.desktop
[Desktop Entry]
Type=Application
Name=Chromium Kiosk
Exec=chromium-browser --kiosk http://localhost:8090/display.html
EOL

echo "=============================================="
echo "Installation complete! The Raspberry Pi will reboot shortly."
echo "=============================================="

# Reboot the Raspberry Pi to apply changes
sudo reboot
