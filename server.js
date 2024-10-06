const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 3000 });

let timerData = {
    countdown: { minutes: 0, seconds: 0, status: 'stopped' },
    countup: { time: 0, status: 'stopped' },
    timeOfDay: ''
};

let countdownInterval;
let countupInterval;

// Broadcast message to all connected clients
function broadcast(message) {
    wss.clients.forEach(client => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(message);
        }
    });
}

// Function to update the real-time clock
function updateTimeOfDay() {
    const now = new Date();
    let hours = now.getHours();
    const minutes = now.getMinutes();
    const seconds = now.getSeconds();
    const amPm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12 || 12;
    timerData.timeOfDay = `${hours}:${minutes < 10 ? '0' + minutes : minutes}:${seconds < 10 ? '0' + seconds : seconds} ${amPm}`;
    broadcast(JSON.stringify(timerData));
}

setInterval(updateTimeOfDay, 1000);

wss.on('connection', (ws) => {
    console.log('New client connected');
    
    // Send the current timer data to the new client
    ws.send(JSON.stringify(timerData));

    ws.on('message', (message) => {
        const updatedData = JSON.parse(message);
        console.log('Received from client:', updatedData);

        // Handle countdown updates
        if (updatedData.countdown) {
            timerData.countdown = updatedData.countdown;

            if (updatedData.countdown.status === 'set') {
                broadcast(JSON.stringify(timerData)); // Broadcast the set time immediately
            }

            if (updatedData.countdown.status === 'running') {
                if (!countdownInterval) {
                    countdownInterval = setInterval(() => {
                        if (timerData.countdown.seconds > 0) {
                            timerData.countdown.seconds--;
                        } else if (timerData.countdown.minutes > 0) {
                            timerData.countdown.minutes--;
                            timerData.countdown.seconds = 59;
                        } else {
                            clearInterval(countdownInterval);
                            countdownInterval = null;
                        }
                        broadcast(JSON.stringify(timerData));
                    }, 1000);
                }
            } else if (updatedData.countdown.status === 'reset') {
                clearInterval(countdownInterval);
                countdownInterval = null;
                timerData.countdown.minutes = 0;
                timerData.countdown.seconds = 0;
                broadcast(JSON.stringify(timerData));
            }
        }

        // Handle countup updates
        if (updatedData.countup) {
            console.log('Handling countup status:', updatedData.countup.status);
            timerData.countup.status = updatedData.countup.status;

            if (updatedData.countup.status === 'running') {
                if (!countupInterval) {
                    countupInterval = setInterval(() => {
                        timerData.countup.time++;
                        broadcast(JSON.stringify(timerData));
                    }, 1000);
                }
            } else if (updatedData.countup.status === 'resetAndRun') {
                clearInterval(countupInterval);
                timerData.countup.time = 0; // Reset the time to 0
                countupInterval = setInterval(() => {
                    timerData.countup.time++;
                    broadcast(JSON.stringify(timerData));
                }, 1000); // Keep it running
            } else if (updatedData.countup.status === 'paused') {
                clearInterval(countupInterval);
                countupInterval = null;
            } else if (updatedData.countup.status === 'reset') {
                clearInterval(countupInterval);
                timerData.countup.time = 0;
                countupInterval = null;
            }
        }
    });

    ws.on('close', () => {
        console.log('Client disconnected');
    });
});
