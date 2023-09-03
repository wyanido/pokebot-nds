// === INITIALISATION ===
const { app, BrowserWindow, ipcMain } = require('electron')
const net = require('net');
const fs = require('fs');
const home = 'dashboard.html'
const port = 51055;

let mainWindow;
let clientCooldown = false;
let refreshTimeout;
var elapsedStart;
var timeSinceStart;

var lastEncounter;
var sinceLastEncounter;

const rateHistorySample = 20;
let rateHistory = [];
let encounterRate = 0;


function clientMessage(data) {
    var msg = JSON.stringify(data);

    return msg.length + ' ' + msg;
}

function randomRange(minValue, maxValue) {
    return minValue + Math.floor(Math.random() * (maxValue - minValue))
}

function getPageIcon(game) {
    // Set an icon that matches the first loaded game
    var icon = 0;

    if (game.includes("Gold") || game.includes("Silver")) {
        icon = randomRange(152, 251)
    } else if (game.includes("Diamond") || game.includes("Pearl") || game.includes("Platinum")) {
        icon = randomRange(387, 493)
    } else if (game.includes("Black") || game.includes("White")) {
        icon = randomRange(494, 649)
    }

    return 'images/pokemon-icon/' + icon.toString().padStart(3, '0') + '.png'
}

function recursiveSubstitute(src, sub) {
    for (var key in sub) {
        if (sub.hasOwnProperty(key)) {
            if (src[key] === undefined) {
                src[key] = sub[key];
            } else if (typeof src[key] === 'object' && typeof sub[key] === 'object') {
                recursiveSubstitute(src[key], sub[key]);
            }
        }
    }
}

function writeJSONToFile(filePath, data) {
    const jsonData = JSON.stringify(data, null, '\t');
    fs.writeFileSync(filePath, jsonData, 'utf8');
}

function readJSONFromFile(filePath, defaultValue) {
    try {
        const data = fs.readFileSync(filePath, 'utf8');
        return JSON.parse(data);
    } catch (err) {
        console.error(`Error reading ${filePath}: ${err.message}`);
        writeJSONToFile(filePath, defaultValue);
        return defaultValue;
    }
}

function formatMonData(mon) {
    mon.gender = mon.gender.toLowerCase();

    if (mon.gender == 'genderless') {
        mon.gender = 'none' // Blank image filename
    }

    mon.pid = mon.pid.toString(16).toUpperCase().padEnd(8, '0');
    mon.shiny = (mon.shinyValue < 8 ? '✨ ' : '➖ ') + mon.shinyValue;

    var s = '00' + mon.species.toString();
    mon.species = s.substr(s.length - 3);

    return mon
}

function updateEncounterRate() {
    var now = Date.now() / 1000
    sinceLastEncounter = now - lastEncounter

    if (!isNaN(lastEncounter) && !isNaN(sinceLastEncounter)) {
        rateHistory.push(sinceLastEncounter);

        if (rateHistory.length > rateHistorySample) rateHistory.shift();

        var sum = 0;
        for (var i = 0; i < rateHistory.length; i++) {
            sum += rateHistory[i];
        }

        encounterRate = sum / rateHistory.length; // Average out the most recent x encounters
        encounterRate = Math.floor(1 / (encounterRate / 3600)); // Convert average encounter time to encounters/h

        mainWindow.webContents.send('set_encounter_rate', encounterRate)
    }

    lastEncounter = now
}

function updateEncounterLog(mon) {
    recents.push(formatMonData(mon));
    recents = recents.slice(-config.encounter_log_limit);

    updateEncounterRate()

    stats.total.seen += 1;
    stats.phase.seen += 1;

    stats.phase.lowest_sv = typeof (stats.phase.lowest_sv) != 'number' ? mon.shinyValue : Math.min(mon.shinyValue, stats.phase.lowest_sv);

    var iv_sum = mon.hp_iv + mon.attack_iv + mon.defense_iv + mon.sp_attack_iv + mon.sp_defense_iv + mon.speed_iv;
    stats.total.max_iv_sum = typeof (stats.total.max_iv_sum) != 'number' ? iv_sum : Math.max(iv_sum, stats.total.max_iv_sum);
    stats.total.min_iv_sum = typeof (stats.total.min_iv_sum) != 'number' ? iv_sum : Math.min(iv_sum, stats.total.min_iv_sum);

    if (mon.shiny == true || mon.shinyValue < 8) {
        stats.total.shiny = stats.total.shiny + 1;
    }

    writeJSONToFile('../logs/encounters.json', recents);

    return recents;
}

function updateTargetLog(mon) {
    targets.push(formatMonData(mon))
    targets = targets.slice(-config.target_log_limit)

    // Reset target phase stats
    stats.phase.seen = 0
    stats.phase.lowest_sv = '--'

    writeJSONToFile('../logs/target_log.json', targets)

    return targets
}

function socketSetTimeout(socket) {
    socket.inactivityTimeout = setTimeout(() => {
        const index = clients.indexOf(socket);
        if (index > -1) {
            clients.splice(index, 1);
            clientData.splice(index, 1);
        }

        socket.destroy()
        console.log('Removed inactive client %d', index)

        mainWindow.webContents.send('clients_updated', clientData);
        mainWindow.webContents.send('set_clients', clientData);

    }, config.inactive_client_timeout)
}

function interpretClientMessage(socket, message) {
    var index = clients.indexOf(socket);
    var client = clientData[index];
    var data = message.data;

    switch (message.type) {
        case 'seen':
            mainWindow.webContents.send('set_recents', updateEncounterLog(data));
            mainWindow.webContents.send('set_stats', stats);

            writeJSONToFile('../logs/stats.json', stats);
            return;
        case 'seen_target':
            mainWindow.webContents.send('set_recents', updateEncounterLog(data));
            mainWindow.webContents.send('set_targets', updateTargetLog(data));
            mainWindow.webContents.send('set_stats', stats);

            writeJSONToFile('../logs/stats.json', stats);
            return;
        case 'party':
            client.party = data;
            mainWindow.webContents.send('set_client_party', index, client.party);
            return;
        case 'init':
            client.gen = data.gen;
            client.game = data.game;

            mainWindow.webContents.send('clients_updated', clientData);

            if (clients.length == 1) {
                mainWindow.webContents.send('set_page_icon', getPageIcon(clientData[0].game));

                elapsedStart = Date.now();
                timeSinceStart = new Date('2023-08-31');
                mainWindow.webContents.send('set_elapsed_start', elapsedStart)
                mainWindow.webContents.send('set_time_since_start', timeSinceStart)
            }
            return;
        case 'game':
            client.map = data.map_name + " (" + data.map_header.toString() + ")";
            client.position = data.trainer_x.toString() + ", " + data.trainer_y.toString() + ", " + data.trainer_z.toString();

            // Parse additional data as a special category
            delete data['map_name'];
            delete data['map_header'];
            delete data['trainer_x'];
            delete data['trainer_y'];
            delete data['trainer_z'];
            delete data['in_game'];
            delete data['in_battle'];
            delete data['in_starter_battle']

            // Reformat phenomenon if present
            if ('phenomenon_x' in data) {
                data.Phenomenon = data.phenomenon_x.toString() + ", --, " + data.phenomenon_z.toString();
                delete data['phenomenon_x'];
                delete data['phenomenon_z'];
            }

            client.other = data;

            // Add a minimum update interval
            if (!clientCooldown) {
                mainWindow.webContents.send('set_client_game_info', index, client);
                clientCooldown = true;

                refreshTimeout = setTimeout(() => {
                    clientCooldown = false;
                }, config.game_refresh_cooldown);
            }
            return;
    }

    mainWindow.webContents.send(message.type, message.data);
}

// === FILE SETUP ===
var statsTemplate = {
    total: {
        max_iv_sum: '--',
        min_iv_sum: '--',
        shiny: 0,
        seen: 0
    },
    phase: {
        lowest_sv: '--',
        seen: 0
    }
};
var clients = [];
var clientData = [];

// Create logs folder if it doesn't exist
if (!fs.existsSync('../logs')) {
    fs.mkdir('../logs', (err) => {
        if (err) {
            console.log(err)
            return;
        }
    });
}

var recents = readJSONFromFile('../logs/encounters.json', []);
var targets = readJSONFromFile('../logs/target_log.json', []);
var config = readJSONFromFile('../config.json', {});
var stats = readJSONFromFile('../logs/stats.json', statsTemplate);

// Update stats to track values not included in older versions
recursiveSubstitute(stats, statsTemplate)
writeJSONToFile('../logs/stats.json', stats)

app.on('activate', function () {
    if (BrowserWindow.getAllWindows().length === 0) createWindow()
})

app.on('window-all-closed', function () {
    if (process.platform !== 'darwin') {
        var msg = clientMessage({
            'type': 'disconnect'
        })

        clients.forEach((client) => {
            client.write(msg);
        });

        // Wait an arbitrary 500ms for clients to safely disconnect before closing
        setTimeout(() => {
            app.quit()
        }, 500);
    }
})

app.whenReady().then(() => {
    mainWindow = new BrowserWindow({
        width: 1024,
        height: 576,
        minWidth: 900,
        minHeight: 500,
        webPreferences: {
            contextIsolation: false,
            nodeIntegration: true
        }
    })

    // mainWindow.setMenuBarVisibility(false)
    mainWindow.loadFile(home)

    mainWindow.webContents.on('did-finish-load', () => {
        var page = mainWindow.webContents.getURL().match(/\/([^/]+)\.html$/)[1]

        if (clients.length > 0) {
            mainWindow.webContents.send('set_page_icon', getPageIcon(clientData[0].game));
        }

        switch (page) {
            case 'config':
                mainWindow.webContents.send('set_config', config);
                mainWindow.webContents.send('clients_updated', clientData);
                break;
            case 'dashboard':
                mainWindow.webContents.send('set_recents', recents);
                mainWindow.webContents.send('set_targets', targets);
                mainWindow.webContents.send('set_stats', stats);
                mainWindow.webContents.send('set_clients', clientData);
                mainWindow.webContents.send('set_encounter_rate', encounterRate)

                if (clients.length > 0) {
                    mainWindow.webContents.send('set_elapsed_start', elapsedStart);
                    mainWindow.webContents.send('set_time_since_start', timeSinceStart)
                    if (!isNaN(lastEncounter) && !isNaN(sinceLastEncounter)) mainWindow.webContents.send('set_latest_encounter', sinceLastEncounter)
                }
                break;
            case 'overlay':
                mainWindow.webContents.send('set_recents', recents);
                mainWindow.webContents.send('set_targets', targets);
                mainWindow.webContents.send('set_stats', stats);
                mainWindow.webContents.send('set_clients', clientData);
                mainWindow.webContents.send('set_encounter_rate', encounterRate)

                if (clients.length > 0) {
                    mainWindow.webContents.send('set_elapsed_start', elapsedStart);
                    mainWindow.webContents.send('set_time_since_start', timeSinceStart)
                    if (!isNaN(lastEncounter) && !isNaN(sinceLastEncounter)) mainWindow.webContents.send('set_latest_encounter', sinceLastEncounter)
                }
                break;
        }
    });

    ipcMain.on('apply_config', (_event, new_config, target) => {
        // Send updated config to all clients
        if (clients.length > 0) {
            var msg = clientMessage({
                'type': 'apply_config',
                'data': {
                    'config': new_config
                }
            })

            if (target == "all") {
                clients.forEach((client) => {
                    client.write(msg);
                });
            } else {
                clients[target].write(msg);
            }
        }

        // Save to file and update main.js reference of config
        config = new_config
        writeJSONToFile('../config.json', new_config)
    });

    ipcMain.on('refresh_editable_games', (_event) => {
        mainWindow.webContents.send('set_editable_games', clientData);
    });

    const server = net.createServer((socket) => {
        console.log('Client %d connected', clients.length);
        clients.push(socket);
        clientData.push({})
        socketSetTimeout(socket);

        // Send config to newly connected lient
        socket.write(clientMessage({
            'type': 'apply_config',
            'data': {
                'config': config
            }
        }));

        let buffer = '';
        socket.on('data', (data) => {
            buffer += data.toString();
            let responses = buffer.split('\x00');

            for (let i = 0; i < responses.length - 1; i++) {
                var response = responses[i].trim();

                if (response.length > 0) {
                    clearTimeout(socket.inactivityTimeout);
                    socketSetTimeout(socket);

                    var body = response.slice(response.indexOf(' ') + 1);

                    try {
                        var message = JSON.parse(body);
                        interpretClientMessage(socket, message);
                    } catch (error) {
                        console.error(error);
                    }
                }
            }

            buffer = responses[responses.length - 1];
        });

        socket.on('error', (error) => {
            // No error here :^]
            // console.error('Client error:', error);
        });
    });

    server.listen(port, () => {
        console.log(`Server listening on port ${port}`);
    });
})
