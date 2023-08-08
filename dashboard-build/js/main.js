const { app, BrowserWindow, ipcMain } = require('electron')
const path = require('path')
const net = require('net');
const fs = require('fs');

let mainWindow;
let server;
let stats = {
    total: {
        max_iv_sum: 0,
        shiny: 0,
        seen: 0
    },
    phase: {
        lowest_sv: 65535,
        seen: 0
    }
};
let recents = [];
let targets = [];
let clients = [];

function writeJsonToFile(path, data) {
    fs.writeFile(path, JSON.stringify(data, null, '\t'), (err) => {
        if (err) {
            console.error(err);
            return;
        }
        console.log("File %s saved successfully!", path)
    });
}

// Create logs folder if it doesn't exist
if (!fs.existsSync('../logs')) {
    fs.mkdir('../logs', (err) => {
        if (err) {
            return;
        }
    });
}

fs.readFile('../logs/encounters.json', 'utf8', (err, data) => {
    if (err) {
        writeJsonToFile('../logs/encounters.json', recents)
        return;
    }
    
    recents = JSON.parse(data);
});

fs.readFile('../logs/target_log.json', 'utf8', (err, data) => {
    if (err) {
        writeJsonToFile("../logs/target_log.json", targets)
        return;
    }

    targets = JSON.parse(data);
});

fs.readFile('../logs/stats.json', 'utf8', (err, data) => {
    if (err) {
        fs.writeFile('../logs/stats.json', "[]", (err) => {
            if (err) {
                console.error(err);
                return;
            }
        });
        return;
    }

    stats = JSON.parse(data);
});

function hex_reverse(hex) {
    return hex.match(/[a-fA-F0-9]{2}/g).reverse().join('').padEnd(8, '0');
}

function format_mon_data(mon) {
    mon.gender = mon.gender.toLowerCase()
    
    if (mon.gender == "genderless") {
        mon.gender = "none" // Blank image filename
    }

    mon.pid = hex_reverse(mon.pid.toString(16).toUpperCase())
    mon.shiny = (mon.shinyValue < 8 ? "✨ " : "➖ ") + mon.shinyValue

    var s = "00" + mon.species.toString()
    mon.species = s.substr(s.length - 3)

    return mon
}

function update_encounter_log(mon) {
    recents.push(format_mon_data(mon))
    
    stats.phase.seen += 1
    stats.phase.lowest_sv = Math.min(mon.shinyValue, stats.phase.lowest_sv)

    if (mon.shiny == true || mon.shinyValue < 8) {
        stats.total.shiny = stats.total.shiny + 1
    }

    fs.writeFile('../logs/encounters.json', JSON.stringify(recents, null, '\t'), (err) => {
        if (err) {
            console.error(err);
            return;
        }
        console.log('Encounter log saved successfully!');
    });

    return recents
}

function update_target_log(mon) {
    targets.push(format_mon_data(mon))

    var iv_sum = mon.hp_iv + mon.attack_iv + mon.defense_iv + mon.sp_attack_iv + mon.sp_defense_iv + mon.speed_iv
    stats.total.max_iv_sum = Math.max(iv_sum, stats.total.max_iv_sum)
    stats.total.seen += 1

    // Reset target phase stats
    stats.phase.max_iv_sum = 0
    stats.phase.seen = 0
    stats.phase.lowest_sv = 65535

    writeJsonToFile("../logs/target_log.json", targets)

    return targets
}

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
    mainWindow.loadFile('dashboard.html')

    mainWindow.webContents.on('did-finish-load', () => {
        var page = mainWindow.webContents.getURL().match(/\/([^/]+)\.html$/)[1]
        console.log(page)

        if (clients.length > 0) {
            var data = JSON.stringify({
                "type": "init",
                "data": {
                    "page": page
                }
            })

            clients.forEach((client) => {
                client.write(data.length + " " + data);
            });
        }

        if (page == "config") {
            fs.readFile('../config.json', 'utf8', (err, data) => {
                if (err) {
                    console.error(err);
                    return;
                }

                mainWindow.webContents.send('set_config', JSON.parse(data));
            });
        } else if (page == "dashboard") {
            mainWindow.webContents.send('set_recents', recents);
            mainWindow.webContents.send('set_targets', targets);
            mainWindow.webContents.send('set_stats', stats);
        }
    });

    ipcMain.on('apply_config', (_event, config) => {
        // Send updated config to client
        var data = JSON.stringify({
            "type": "apply_config",
            "data": {
                "config": config
            }
        })

        if (clients.length > 0) {
            clients.forEach((client) => {
                client.write(data.length + " " + data);
            });
        }

        // Save to file
        fs.writeFile('../config.json', JSON.stringify(config, null, '\t'), (err) => {
            if (err) {
                console.error(err);
                return;
            }
            console.log('File saved successfully!');
        });
    });

    ipcMain.on('update_encounter_log', (_event, log) => {
        recents = log
    });

    const server = net.createServer((socket) => {  
        clients.push(socket)
        console.log('Client %d connected', clients.length);
        socketSetTimeout(socket)

        let buffer = '';
        socket.on('data', (data) => {
            buffer += data.toString();
            responses = buffer.split('\x00');

            for (let i = 0; i < responses.length - 1; i++) {
                var response = responses[i].trim();

                if (response.length > 0) {
                    clearTimeout(socket.inactivityTimeout);
                    socketSetTimeout(socket)
                    
                    var body = response.slice(response.indexOf(' ') + 1);

                    try {
                        var message = JSON.parse(body);
                        
                        // Snoop message sent to the page in order to handle encounters
                        if (message.type == "seen") {
                            message.data = update_encounter_log(message.data)
                            message.type = "set_recents"

                            mainWindow.webContents.send('set_stats', stats);
                            writeJsonToFile("../logs/stats.json", stats)
                        } else if (message.type == "seen_target") {
                            // Update regular encounter log first
                            mainWindow.webContents.send("set_recents", update_encounter_log(message.data));
                            
                            message.data = update_target_log(message.data)
                            message.type = "set_targets"

                            mainWindow.webContents.send('set_stats', stats);
                            writeJsonToFile("../logs/stats.json", stats)
                        }

                        mainWindow.webContents.send(message.type, message.data);
                    } catch (error) {
                        // console.error('Failed to parse JSON:', body);
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

    const port = 51055;
    server.listen(port, () => {
        console.log(`Server listening on port ${port}`);
    });
})

app.on('activate', function () {
    if (BrowserWindow.getAllWindows().length === 0) createWindow()
})

app.on('window-all-closed', function () {
    if (process.platform !== 'darwin') app.quit()
})

function socketSetTimeout(socket) {
    socket.inactivityTimeout = setTimeout(() => {
        const index = clients.indexOf(socket);
        if (index > -1) clients.splice(index, 1);
        
        socket.destroy()
        console.log("Removed inactive client %d", index)
    }, 1000)
}