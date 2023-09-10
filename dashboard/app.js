const http = require('http');
const fs = require('fs');
const path = require('path');
const socket = require('./socket');
const port = 3000;

function dashboardSetup() {
    // Open dashboard page in default browser
    var url = 'http://localhost:' + port + '/dashboard.html';
    var start = (process.platform == 'darwin' ? 'open' : process.platform == 'win32' ? 'start' : 'xdg-open');
    require('child_process').exec(start + ' ' + url);

    // Create user folder if it doesn't exist
    const userDir = '../user';

    try {
        if (!fs.existsSync(userDir)) {
            fs.mkdirSync(userDir);
        }
    } catch (err) {
        console.error(err);
    }
}

// Serve local files to the webpage
const server = http.createServer(function (req, res) {
    const filePath = '.' + req.url;

    const extname = path.extname(filePath);
    let contentType = 'text/html';

    switch (extname) {
        case '.js':
            contentType = 'text/javascript';
            break;
        case '.css':
            contentType = 'text/css';
            break;
        case '.png':
            contentType = 'image/png';
            break;
    }

    fs.readFile(filePath, function (error, data) {
        if (error) {
            if (error.code === 'ENOENT') {
                res.writeHead(404);
                res.end('Error: File not found');
            } else {
                res.writeHead(500);
                res.write('Error: Internal Server Error');
                res.end('\n\nPlease open the dashboard at http://localhost:3000/dashboard.html instead!')
            }
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(data);
        }
    });
});

server.listen(port, function (error) {
    if (error) {
        console.log('An error has occurred', error);
    } else {
        console.log('Web server running on port ' + port);

        dashboardSetup();
    }
});
