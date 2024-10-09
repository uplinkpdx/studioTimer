const socket = new WebSocket(`ws://${window.location.hostname}:3000`);

let countupInterval;
let countdownInterval;
let isCountupRunning = false;

socket.onopen = function() {
    console.log('WebSocket connection established');
};

socket.onerror = function(error) {
    console.error('WebSocket error:', error);
};

socket.onmessage = function(event) {
    const data = JSON.parse(event.data);
    console.log('Received data on display page:', data);

    if (data.countdown) {
        const { minutes, seconds, status } = data.countdown;
        updateCountdownDisplay(minutes, seconds, status);
    }

    if (data.countup) {
        const { status, time } = data.countup;
        if (status === 'resetAndRun') {
            clearInterval(countupInterval);
            document.getElementById('countup-timer').innerText = "00:00";
            startCountupFromServer(0);
        } else if (status === 'running' && !isCountupRunning) {
            clearInterval(countupInterval);
            isCountupRunning = true;
            startCountupFromServer(time);
        } else if (status === 'paused') {
            clearInterval(countupInterval);
            isCountupRunning = false;
        }
    }

    if (data.timeOfDay) {
        document.getElementById('current-time').innerText = data.timeOfDay;
    }
};

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

function updateCountdownDisplay(minutes, seconds, status) {
    const countdownDisplay = document.getElementById('countdown-timer');
    const topBarElement = document.getElementById('countdown-bar-top');
    const bottomBarElement = document.getElementById('countdown-bar-bottom');

    if (minutes === 0 && seconds === 0) {
        countdownDisplay.innerText = `:00`;
        countdownDisplay.classList.add('flash');
    } else {
        countdownDisplay.innerText = `${minutes}:${seconds < 10 ? '0' + seconds : seconds}`;
        countdownDisplay.classList.remove('flash');
    }
}
