const websocketPort = '3000';
const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
const websocketURL = `${wsProtocol}//%%WEBSOCKET_SERVER_IP%%:${websocketPort}`;

// Create WebSocket connection
const ws = new WebSocket(websocketURL);

// Send updated countdown or countup data to the WebSocket server
function updateTimer(type, data) {
    const update = {};
    update[type] = data;
    ws.send(JSON.stringify(update)); // Use ws instead of socket
    console.log('Sent message:', update);
}

// Countdown Timer Controls
function setCountdown() {
    let minutes = parseInt(document.getElementById('minutes').value || 0);
    let seconds = parseInt(document.getElementById('seconds').value || 0);
    
    // Send 'set' status to display the time immediately
    updateTimer('countdown', { minutes, seconds, status: 'set' });
}

function startCountdown() {
    let minutes = parseInt(document.getElementById('minutes').value || 0);
    let seconds = parseInt(document.getElementById('seconds').value || 0);
    
    // Change the status to 'running'
    updateTimer('countdown', { minutes, seconds, status: 'running' });
}

function resetCountdown() {
    updateTimer('countdown', { minutes: 0, seconds: 0, status: 'reset' });
}

// Countup Timer Controls
function startCountup() {
    console.log('Sending start command for countup');
    updateTimer('countup', { status: 'running' });
}

function pauseCountup() {
    updateTimer('countup', { status: 'paused' });
}

function resetCountup() {
    // Send reset command but keep status as 'resetAndRun' to reset to 00:00 and keep running
    updateTimer('countup', { status: 'resetAndRun' });
}

// WebSocket event listeners
ws.onopen = () => {
  console.log('WebSocket connection opened.');
};

ws.onmessage = (event) => {
  console.log('Message from server:', event.data);
};

ws.onclose = () => {
  console.log('WebSocket connection closed.');
};

ws.onerror = (error) => {
  console.error('WebSocket error:', error);
};
