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

#Download Part 2 of the install
echo "Downloading the next step..."
wait 3
wget https://raw.githubusercontent.com/uplinkpdx/studioTimer/main/install.sh

# Schedule the second script to run after reboot using cron
echo "Scheduling the second script to run after reboot..."
sudo crontab -l > mycron
echo "@reboot /bin/bash /var/www/html/install_studio_timer.sh" >> mycron
sudo crontab mycron
rm mycron

# Reboot the system to apply the hostname changes
echo "Rebooting the system to apply hostname changes..."
sudo reboot
