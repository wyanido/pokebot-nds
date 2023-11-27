randomisePageIcon();

let pollInterval;

RequestAPI('config', function (error, config) {
    if (error) {
        console.error(error);
        return;
    }

    pollInterval = config.dashboard_poll_interval;
});

function RequestAPI(endpoint, callback) {
    const http = new XMLHttpRequest();
    http.open('GET', `http://localhost:3000/api/${encodeURIComponent(endpoint)}`);
    http.responseType = 'json';

    http.onload = function (e) {
        // Handle response
        if (http.status === 200) {
            const response = http.response;
            callback(null, response); // Pass the response data to the callback
        } else {
            callback('Failed to fetch data. Status: ' + http.status, null);
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

function PostAPI(endpoint, data, callback) {
    const http = new XMLHttpRequest();
    http.open('POST', `http://localhost:3000/api/${encodeURIComponent(endpoint)}?data=${JSON.stringify(data)}`);
    http.responseType = 'json';

    http.onload = function (e) {
        // Handle response
        if (http.status === 200) {
            const response = http.response;
            callback(null, response); // Pass the response data to the callback
        } else {
            callback('Failed to POST data. Status: ' + http.status, null);
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
    RequestAPI('clients', function (error, clients) {
        if (error) {
            console.error(error);
            return;
        }

        if (Array.isArray(clients) && clients.length > 0) {
            const game = clients[0].game;
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
            console.error('No clients found or the response is not an array.');
        }
    });
}

function setBadgeClientCount(clients) {
    $('#home-button').empty()

    if (clients > 0) {
        $('#home-button').append('<span style="bottom:16px; right:-10px; font-size:10px" class="badge badge-primary position-absolute translate-middle text-bg-primary px-5">' + clients.toString() + '</span>')
    }
}