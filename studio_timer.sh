#!/bin/bash

# Update and upgrade the system
echo "Updating system..."
sudo apt-get update -y && sudo apt-get upgrade -y

# Prompt for a hostname (default to 'timer-pi' if no input)
read -p "Enter a hostname for this Raspberry Pi (default: timer-pi): " HOSTNAME
HOSTNAME=${HOSTNAME:-timer-pi}

# Set the hostname using hostnamectl
echo "Setting hostname to $HOSTNAME..."
sudo hostnamectl set-hostname "$HOSTNAME"

# Update /etc/hosts with the new hostname
sudo sed -i "s/127.0.1.1 .*/127.0.1.1 $HOSTNAME/g" /etc/hosts

# Install Node.js and npm
echo "Installing Node.js and npm..."
sudo apt-get install -y nodejs npm

# Create a directory for the project
echo "Setting up project directory..."
PROJECT_DIR="$HOME/timer_project"
mkdir -p $PROJECT_DIR

# Navigate to the project directory
cd $PROJECT_DIR

# Install http-server to serve the static files (control.html, display.html)
echo "Installing http-server..."
sudo npm install -g http-server

# Set up the WebSocket server
echo "Setting up WebSocket server..."
cat <<EOF > websocket-server.js
const WebSocket = require('ws');

// Create WebSocket server
const wss = new WebSocket.Server({ port: 3000 });

wss.on('connection', function connection(ws) {
    ws.on('message', function incoming(message) {
        console.log('received:', message);
        // Broadcast the message to all connected clients
        wss.clients.forEach(function each(client) {
            if (client.readyState === WebSocket.OPEN) {
                client.send(message);
            }
        });
    });

    ws.send('WebSocket server connected.');
});
EOF

# Install WebSocket module for Node.js
npm install ws

# Set up control.html and display.html
echo "Creating HTML files for control and display pages..."

# control.html (no checkboxes)
cat <<EOF > control.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Timer Control</title>
    <link rel="stylesheet" href="control-style.css">
</head>
<body>
    <div class="container">
        <h2>Countdown Timer</h2>
        <div>
            <input type="number" id="minutes" placeholder="MM" min="0" max="59">
            <input type="number" id="seconds" placeholder="SS" min="0" max="59">
        </div>
        <button onclick="setCountdown()">Set Countdown</button>
        <button onclick="startCountdown()">Start Countdown</button>
        <button onclick="resetCountdown()">Reset Countdown</button>

        <h2>Countup Timer</h2>
        <button onclick="startCountup()">Start Countup</button>
        <button onclick="pauseCountup()">Pause Countup</button>
        <button onclick="resetCountup()">Reset Countup</button>
    </div>
    <script src="control.js"></script>
</body>
</html>
EOF

# display.html (no checkbox-related elements)
cat <<EOF > display.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Timer Display</title>
    <link rel="stylesheet" href="display-style.css">
</head>
<body>
    <div id="countdown-timer">00:00</div>
    <div id="countup-timer">00:00</div>
    <div id="current-time"></div>
    <script src="display.js"></script>
</body>
</html>
EOF

# Create control.js (without visibility checkboxes)
cat <<EOF > control.js
const socket = new WebSocket('ws://192.168.1.61:3000');

function updateTimer(type, data) {
    const update = {};
    update[type] = data;
    socket.send(JSON.stringify(update));
    console.log('Sent message:', update);
}

function setCountdown() {
    let minutes = parseInt(document.getElementById('minutes').value || 0);
    let seconds = parseInt(document.getElementById('seconds').value || 0);
    updateTimer('countdown', { minutes, seconds, status: 'set' });
}

function startCountdown() {
    let minutes = parseInt(document.getElementById('minutes').value || 0);
    let seconds = parseInt(document.getElementById('seconds').value || 0);
    updateTimer('countdown', { minutes, seconds, status: 'running' });
}

function resetCountdown() {
    updateTimer('countdown', { minutes: 0, seconds: 0, status: 'reset' });
}

function startCountup() {
    updateTimer('countup', { status: 'running' });
}

function pauseCountup() {
    updateTimer('countup', { status: 'paused' });
}

function resetCountup() {
    updateTimer('countup', { status: 'resetAndRun' });
}

socket.onopen = function() {
    console.log('WebSocket connection established from control page');
};

socket.onerror = function(error) {
    console.error('WebSocket error:', error);
};
EOF

# Create display.js
cat <<EOF > display.js
const socket = new WebSocket('ws://192.168.1.61:3000');

socket.onmessage = function(event) {
    const data = JSON.parse(event.data);
    const countdownTimer = document.getElementById('countdown-timer');
    const countupTimer = document.getElementById('countup-timer');

    if (data.countdown) {
        const { minutes, seconds, status } = data.countdown;
        updateCountdownDisplay(minutes, seconds, status);
    }

    if (data.countup) {
        const { status, time } = data.countup;
        if (status === 'resetAndRun') {
            countupTimer.innerText = "00:00";  // Reset to zero
            startCountupFromServer(0);  // Start counting up again from zero
        } else if (status === 'running') {
            startCountupFromServer(time);
        } else if (status === 'paused') {
            clearInterval(countupInterval);
        }
    }
};

function updateCountdownDisplay(minutes, seconds, status) {
    const countdownDisplay = document.getElementById('countdown-timer');
    countdownDisplay.innerText = `${minutes}:${seconds < 10 ? '0' + seconds : seconds}`;
}

let countupInterval;
function startCountupFromServer(serverTime = 0) {
    let countupTime = serverTime;
    countupInterval = setInterval(() => {
        countupTime++;
        const hours = Math.floor(countupTime / 3600);
        const minutes = Math.floor((countupTime % 3600) / 60);
        const seconds = countupTime % 60;
        document.getElementById('countup-timer').innerText =
            `${hours < 10 ? '0' + hours : hours}:${minutes < 10 ? '0' + minutes : minutes}:${seconds < 10 ? '0' + seconds : seconds}`;
    }, 1000);
}
EOF

# Start WebSocket server in the background on boot
echo "Setting up WebSocket server to start on boot..."
crontab -l > mycron
echo "@reboot node $PROJECT_DIR/websocket-server.js &" >> mycron
crontab mycron
rm mycron

# Serve the static files using http-server
echo "Serving control.html and display.html on localhost ports 8080 and 8081..."
http-server -p 8080 -c-1 &
http-server -p 8081 -c-1 &

# Get the Raspberry Pi's IP address
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Output the URLs for control and display pages
echo "=============================================="
echo "Installation complete! You can access the pages at:"
echo "Control Page: http://$IP_ADDRESS:8080/control.html"
echo "Display Page: http://$IP_ADDRESS:8081/display.html"
echo "=============================================="
