document.body.classList.add("dark-mode");
halfmoon.toggleDarkMode = function() {};

let doneOfflineWarning = false;

class Header extends HTMLElement {
    constructor() {
    super();
    }
  
    connectedCallback() {
        this.innerHTML = `
            <nav class="navbar">
                <div class="navbar-brand text-nowrap">
                    <img src="assets/pokemon-icon/201-27.png" class="icon" id="icon">
                    PokéBot NDS
                </div>
                <span class="navbar-text text-monospace font-size-12">v1.1-beta</span>
                <ul class="navbar-nav d-flex d-md-flex">
                    <li class="nav-item nav-link px-10">
                        <a href="dashboard.html">
                            <button type="button" class="btn position-relative px-10">
                                <i class="fa fa-user-circle"></i>
                                Dashboard
                                <span id="dashboard-badge" class="badge badge-primary translate-middle text-bg-primary px-5">
                                    0
                                </span>
                            </button>
                        </a>
                    </li>
                    <li class="nav-item nav-link px-10">
                        <a href="config.html">
                            <button type="button" class="btn position-relative px-10">
                                <i class="fa fa-gear"></i>
                                Config
                            </button>
                        </a>
                    </li>
                    <li class="nav-item nav-link px-10">
                        <a href="https://github.com/wyanido/pokebot-nds/" target="_blank">
                            <button type="button" class="btn position-relative px-10">
                                <i class="fa-brands fa-github"></i>
                                Github
                            </button>
                        </a>
                    </li>
                    <li class="nav-item nav-link px-10">
                        <a href="https://ko-fi.com/B0B7RMWPP" target="_blank">
                            <button type="button" class="btn position-relative px-10">
                                <i class="fa-solid fa-heart"></i>
                                Donate
                            </button>
                        </a>
                    </li>
                </ul>
                <div style="position: absolute; right: 15px; display: flex;">
                    <div class="text-center mx-5">
                        <i class="fa fa-stopwatch mr-10" style="margin-top: 3px"></i><span id="elapsed-time" class="badge text-bg-secondary">0s</span>
                    </div>
                    <div class="text-center mx-5">
                        <i class="fa fa-tachometer mr-10" style="margin-top: 3px"></i><span id="encounter-rate" class="badge text-bg-secondary">0/h</span>
                    </div>
                </div>
            </nav>
            `;
    }
}

customElements.define('header-component', Header);

function socketServerCommunicate(method, url, callback) {
    const http = new XMLHttpRequest();

    http.open(method, url);
    http.responseType = 'json';

    http.onload = function (e) {
        if (http.status === 200) {
            doneOfflineWarning = false;

            const response = http.response;
            callback(null, response);
        } else {
            callback(method + ' request failed. Status: ' + http.status, null);
        }
    };
    http.onerror = function () {
        if (!doneOfflineWarning) {
            halfmoon.initStickyAlert({
                content: 'NOTE: The dashboard cannot be accessed by opening the .html pages directly in the browser. The node backend must be running.',
                title: "Couldn't reach API endpoint",
                alertType: 'alert-danger',
                timeShown: 15000
            })

            doneOfflineWarning = true;
        }
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
                case 'D':
                case 'P':
                case 'PL':
                    icon = randomRange(387, 493);
                    break;
                case 'HG':
                case 'SS':
                    icon = randomRange(152, 251);
                    break;
                case 'B':
                case 'W':
                case 'B2':
                case 'W2':
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

const encounterRate = $('#encounter-rate');

function updateEncounterRate() {
    socketServerGet('encounter_rate', function (error, rate) {
        if (error) {
            console.error(error);
            return;
        }

        encounterRate.text(`${rate}/h`)
    })
}

let elapsedStart;
let elapsedInterval;
const elapsedTime = $('#elapsed-time');

function updateElapsedTime() {
    const elapsed = Math.floor((Date.now() - elapsedStart) / 1000);
    const s = elapsed;
    const m = Math.floor(s / 60);
    const h = Math.floor(m / 60);
    const time = `${h}h ${m % 60}m ${s % 60}s`;

    elapsedTime.text(time)
}

function updateStatBadges() {
    updateEncounterRate()
    updateElapsedTime()
}

randomisePageIcon();
