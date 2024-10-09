const socket = new WebSocket(`ws://${window.location.hostname}:3000`);

// Function to send WebSocket updates
function updateTimer(type, data) {
    const update = {};
    update[type] = data;
    socket.send(JSON.stringify(update));
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
    updateTimer('countup', { status: 'resetAndRun' });
}

// WebSocket connection opened
socket.onopen = function() {
    console.log('WebSocket connection established from control page');
};

// WebSocket error handling
socket.onerror = function(error) {
    console.error('WebSocket error:', error);
};
