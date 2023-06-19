const { app, BrowserWindow, ipcMain } = require('electron')
const path = require('path')
const net = require('net');
const fs = require('fs');

let mainWindow;
let server;
let client;

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

        if (client) {
            var data = JSON.stringify({
                "type": "init",
                "data": {
                    "page": page
                }
            })

            client.write(data.length + " " + data);
        } else {
            // If the client is not connected to the main script, load the config manually
            if (page == "config") {
                fs.readFile('../config.json', 'utf8', (err, data) => {
                    if (err) {
                        console.error(err);
                        return;
                    }

                    mainWindow.webContents.send('set_config', JSON.parse(data));
                });
            }
        }
    });

    ipcMain.on('apply_config', (_event, config) => {
        var data = JSON.stringify({
            "type": "apply_config",
            "data": {
                "config": config
            }
        })

        // Send to client lua script to process and save, otherwise save manually
        if (client) {
            client.write(data.length + " " + data);
        } else {
            fs.writeFile('../config.json', JSON.stringify(config), (err) => {
                if (err) {
                    console.error(err);
                    return;
                }
                console.log('File saved successfully!');
            });
        }
    });

    const server = net.createServer((socket) => {
        console.log('Client connected');
        let buffer = '';
        client = socket

        socket.on('data', (data) => {
            buffer += data.toString();
            responses = buffer.split('\x00');

            for (let i = 0; i < responses.length - 1; i++) {
                var response = responses[i].trim();

                if (response.length > 0) {
                    var body = response.slice(response.indexOf(' ') + 1);

                    try {
                        var message = JSON.parse(body);
                        mainWindow.webContents.send(message.type, message.data);
                    } catch (error) {
                        console.error('Failed to parse JSON:', body);
                    }
                }
            }

            buffer = responses[responses.length - 1];
        });

        socket.on('error', (error) => {
            // No error here :^]
            // console.error('Client error:', error);
        });

        socket.on('end', () => {
            console.log('Client disconnected');
        });
    });

    const port = 51055;
    server.listen(port, () => {
        console.log(`Server listening on port ${port}`);
    });
})

app.on('activate', function () {
    if (BrowserWindow.getAllWindows().length === 0) {
        createWindow()
    }
})

app.on('window-all-closed', function () {
    if (process.platform !== 'darwin') app.quit()
})