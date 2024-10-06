const websocketPort = '3000'; // WebSocket server port
const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';

let countupInterval;
let countdownInterval;
let isCountupRunning = false;

// Placeholder for WebSocket server IP, replaced during installation
const websocketURL = `${wsProtocol}//%%WEBSOCKET_SERVER_IP%%:${websocketPort}`;

// Create a WebSocket connection
const ws = new WebSocket(websocketURL);

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


// Handle incoming WebSocket messages
socket.onmessage = function (event) {
    const data = JSON.parse(event.data);
    console.log('Received data on display page:', data);  // Check if data is received

    // Handle countdown updates
    if (data.countdown) {
        const { minutes, seconds, status } = data.countdown;
        updateCountdownDisplay(minutes, seconds, status);
    }

    // Handle countup updates
    if (data.countup) {
        const { status, time } = data.countup;
        console.log('Received countup status:', status);  // Debug the countup status
        console.log('Received countup time:', time);  // Debug the countup time

        if (status === 'resetAndRun') {
            clearInterval(countupInterval);
            document.getElementById('countup-timer').innerText = "00:00";  // Reset to zero
            startCountupFromServer(0);  // Start counting up again from zero
        } else if (status === 'running' && !isCountupRunning) {
            clearInterval(countupInterval);  // Clear existing interval
            isCountupRunning = true;         // Set running state
            startCountupFromServer(time);    // Start counting from server time
        } else if (status === 'paused') {
            clearInterval(countupInterval);  // Pause the countup
            isCountupRunning = false;        // Set running state to false
        }
    }

    // Update the real-time clock
    if (data.timeOfDay) {
        document.getElementById('current-time').innerText = data.timeOfDay;
    }
};

// Start countup timer from a given time (synchronized with server)
function startCountupFromServer(serverTime = 0) {
    console.log('Starting countup from server time:', serverTime);  // Debug start time
    let countupTime = serverTime;
    countupInterval = setInterval(() => {
        countupTime++;
        
        const hours = Math.floor(countupTime / 3600); // 3600 seconds in an hour
        const minutes = Math.floor((countupTime % 3600) / 60); // Remaining minutes
        const seconds = countupTime % 60; // Remaining seconds

        // Display the time in HH:MM:SS format
        document.getElementById('countup-timer').innerText = 
            `${hours < 10 ? '0' + hours : hours}:${minutes < 10 ? '0' + minutes : minutes}:${seconds < 10 ? '0' + seconds : seconds}`;

        console.log('Countup time updated to:', hours, minutes, seconds);  // Debug time update
    }, 1000);
}


// Update countdown timer display
function updateCountdownDisplay(minutes, seconds, status) {
    const countdownDisplay = document.getElementById('countdown-timer');
    const topBarElement = document.getElementById('countdown-bar-top');
    const bottomBarElement = document.getElementById('countdown-bar-bottom');

    // When the timer reaches 0, trigger the flashing effect
    if (minutes == 0 && seconds == 0) {
        countdownDisplay.innerText = `:00`;
        countdownDisplay.classList.add('flash');  // Add the flash class to make it flash
    } else {
        // Remove leading zero for seconds when less than 1 minute
        if (minutes == 0 && seconds < 60) {
            if (seconds < 10) {
                countdownDisplay.innerText = `:0${seconds}`;  // Display leading zero for single-digit seconds
            } else {
                countdownDisplay.innerText = `:${seconds}`;   // Display seconds without leading zero
            }
        } else {
            countdownDisplay.innerText = `${minutes}:${seconds < 10 ? '0' + seconds : seconds}`;  // Normal minute:second format
        }
        
        countdownDisplay.classList.remove('flash');  // Remove the flash class if not zero
    }

    if (status === 'running') {
        // Logic to update the visual indicator based on time remaining
        if (minutes == 0 && seconds <= 5) {
            topBarElement.style.backgroundColor = 'red';
            bottomBarElement.style.backgroundColor = 'red';
            topBarElement.classList.remove('pulse'); // Remove pulsing effect
            bottomBarElement.classList.remove('pulse');
        } else if (minutes == 0 && seconds <= 15) {
            topBarElement.style.backgroundColor = 'yellow';
            bottomBarElement.style.backgroundColor = 'yellow';
            topBarElement.classList.add('pulse');   // Add pulsing effect
            bottomBarElement.classList.add('pulse');
        } else {
            topBarElement.style.backgroundColor = 'green';
            bottomBarElement.style.backgroundColor = 'green';
            topBarElement.classList.remove('pulse'); // Remove pulsing effect
            bottomBarElement.classList.remove('pulse');
        }
    }
}
