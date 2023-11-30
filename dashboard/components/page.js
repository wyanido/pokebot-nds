
function socketServerCommunicate(method, url, callback) {
    const http = new XMLHttpRequest();

    http.open(method, url);
    http.responseType = 'json';

    http.onload = function (e) {
        // Handle response
        if (http.status === 200) {
            const response = http.response;
            callback(null, response); // Pass the response data to the callback
        } else {
            callback(method + ' request failed. Status: ' + http.status, null);
        }
    };
    http.onerror = function () {
        halfmoon.initStickyAlert({
            content: 'NOTE: The dashboard cannot be accessed by opening the .html pages directly in the browser. The node backend must be running.',
            title: "Couldn't reach API endpoint",
            alertType: 'alert-danger',
        })
    }

    http.send();
}

function socketServerGet(endpoint, callback) {
    const method = 'GET'
    const url = `http://localhost:3000/api/${encodeURIComponent(endpoint)}`
    
    socketServerCommunicate(method, url, callback)   
}

function socketServerSend(endpoint, data, callback) {
    const method = 'POST'
    const url = `http://localhost:3000/api/${encodeURIComponent(endpoint)}?data=${JSON.stringify(data)}`
    
    socketServerCommunicate(method, url, callback)
}

const Version = {
    DIAMOND: 0,
    PEARL: 1,
    PLATINUM: 2,
    HEARTGOLD: 3,
    SOULSILVER: 4,
    BLACK: 5,
    WHITE: 6,
    BLACK2: 7,
    WHITE2: 8
}

function randomisePageIcon() {
    const randomRange = (min, max) => min + Math.floor(Math.random() * (max - min));

    // Make the API request and handle the response in a callback
    socketServerGet('clients', function (error, clients) {
        if (error) {
            console.error(error);
            return;
        }

        if (Array.isArray(clients) && clients.length > 0) {
            let icon = 0;
            
            switch (clients[0].version) {
                case Version.DIAMOND:
                case Version.PEARL:
                case Version.PLATINUM:
                    icon = randomRange(387, 493);
                    break;
                case Version.HEARTGOLD:
                case Version.SOULSILVER:
                    icon = randomRange(152, 251);
                    break;
                case Version.BLACK:
                case Version.WHITE:
                case Version.BLACK2:
                case Version.WHITE2:
                    icon = randomRange(494, 649);
                    break;
            }
            
            const iconURL = 'assets/pokemon-icon/' + icon.toString().padStart(3, '0') + '.png';
            document.getElementById('icon').src = iconURL;
        } else {
            console.error('No clients connected.');
        }
    });
}

const dashboardBadge = $('#dashboard-badge');

function setBadgeClientCount(clientCount) {
    if (clientCount == 0) {
        dashboardBadge.text('0')
        dashboardBadge.hide()
        return
    }

    const value = clientCount.toString()

    if (dashboardBadge.text() != value) {
        dashboardBadge.text(value)
        dashboardBadge.show()
    }
}

randomisePageIcon();

let pollInterval;

socketServerGet('config', function (error, config) {
    if (error) {
        console.error(error);
        return;
    }

    pollInterval = config.dashboard_poll_interval;
});