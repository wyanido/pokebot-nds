const { app, BrowserWindow, ipcMain } = require('electron')
const path = require('path')
const net = require('net');

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
        }
    });

    ipcMain.on('apply_config', (_event, config) => {
        var data = JSON.stringify({
            "type": "apply_config",
            "data": {
                "config": config
            }
        })

        client.write(data.length + " " + data);
    });

    const server = net.createServer((socket) => {
        console.log('Client connected');
        let buffer = '';
        client = socket

        socket.on('data', (data) => {
            buffer += data.toString();
            const responses = buffer.split('\x00');

            for (let i = 0; i < responses.length - 1; i++) {
                const response = responses[i].trim();

                if (response.length > 0) {
                    const spaceIndex = response.indexOf(' ');

                    if (spaceIndex !== -1) {
                        const responseContent = response.slice(spaceIndex + 1);

                        try {
                            const parsedResponse = JSON.parse(responseContent);

                            mainWindow.webContents.send(parsedResponse.type, parsedResponse.data);
                        } catch (error) {
                            console.error('Failed to parse JSON:', responseContent);
                        }
                    } else {
                        console.warn('Invalid response format:', response);
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