
const { app, BrowserWindow } = require('electron')
const path = require('path')
const net = require('net');

var mainWindow = null

function createWindow () {
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 720,
    webPreferences: {
      contextIsolation: false,
      nodeIntegration: true
    }
  })

  mainWindow.setMenuBarVisibility(false)
  mainWindow.loadFile('index.html')
}

app.whenReady().then(() => {
  createWindow()

  app.on('activate', function () {
    if (BrowserWindow.getAllWindows().length === 0) createWindow()
  })
})

app.on('window-all-closed', function () {
  if (process.platform !== 'darwin') app.quit()
})

const server = net.createServer((socket) => {
  console.log('Client connected');

  socket.on('data', (data) => {
    var length = data.slice(0, data.indexOf(' '));
    var response = data.slice(data.indexOf(' ') + 1);

    response = JSON.parse(response)
    
    // console.log('Received data:', data.toString());
    // console.log(response.type)

    switch (response.type) {
      case "party":
        mainWindow.webContents.send('party', response.data);
      break;
    }
  });

  socket.on('error', () => {
    console.log('Client refreshed, probably!');
  });

  socket.on('end', () => {
    console.log('Client disconnected');
  });
});

const port = 51055;
server.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
