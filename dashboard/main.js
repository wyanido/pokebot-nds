const { app, BrowserWindow } = require('electron')
const path = require('path')
const net = require('net');

var mainWindow = null

function createWindow() {
    mainWindow = new BrowserWindow({
        width: 1280,
        height: 720,
        webPreferences: {
            contextIsolation: false,
            nodeIntegration: true
        }
    })

    // mainWindow.setMenuBarVisibility(false)
    mainWindow.loadFile('index.html')
}

app.whenReady().then(() => {
    createWindow()
    
    app.on('activate', function() {
        if (BrowserWindow.getAllWindows().length === 0) createWindow()
    })
})

app.on('window-all-closed', function() {
    if (process.platform !== 'darwin') app.quit()
})

const server = net.createServer((socket) => {
    console.log('Client connected');
    let buffer = '';

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
        if (buffer.length > 0) {
            console.warn('Incomplete response received:', buffer);
        }
        console.log('Client disconnected');
    });
});

const port = 51055;
server.listen(port, () => {
    console.log(`Server listening on port ${port}`);
});