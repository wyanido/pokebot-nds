const http = require('http');
const fs = require('fs');
const path = require('path');
const socket = require('./socket');
const mime = require('mime');
const port = 3000;
const baseDir = path.resolve(__dirname, '.');

console.clear(); // Clear node package upgrade text 

const server = http.createServer(function (req, res) {
    const filePath = path.join(baseDir, decodeURI(req.url));

    if (req.url.startsWith('/api')) {
        const urlObject = new URL(req.url, 'http://localhost');
        urlObject.searchParams.delete("data");
        const endpoint = urlObject.pathname.substring(1).slice(4);

        // console.log(endpoint)
        // const endpoint = req.url.split(/); / / Second half of the / api /...request
        const jsonData = handleAPIRequest(endpoint, req.url, req.method);

        if (jsonData !== null) {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify(jsonData));
        } else {
            // Handle unknown API routes with a 404 response
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end('Not Found');
        }
        return;
    }

    // Handle file requests
    const extname = path.extname(filePath);
    const contentType = mime.getType(extname) || 'text/html'; // Default to 'text/html'

    fs.readFile(filePath, function (error, data) {
        if (error) {
            if (error.code === 'ENOENT') {
                res.writeHead(404);
                res.end('Error: File not found');
            } else {
                res.writeHead(500);
                res.write('Error: Internal Server Error');
                res.end('\n\nPlease open the dashboard at http://localhost:3000/dashboard.html instead!');
            }
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(data);
        }
    });
});

server.listen(port, function (error) {
    if (error) {
        console.log('An error occurred while starting the dashboard server: ', error);
    } else {
        var url = 'http://localhost:' + port + '/dashboard.html';
        var config = require('../user/config.json');
        
        if (config.auto_open_page) {
            var start = (process.platform == 'darwin' ? 'open' : process.platform == 'win32' ? 'start' : 'xdg-open');
            require('child_process').exec(start + ' ' + url);
        }

        console.log('\nDashboard started successfully. Access it at ' + url + "\n");
    }
});

function handleAPIRequest(endpoint, url, method) {
    let data;

    if (method == "POST") {
        const searchParams = new URLSearchParams(url.split("?")[1]);
        const dataParam = searchParams.get("data");
        
        data = JSON.parse(decodeURIComponent(dataParam));
    }

    switch (endpoint) {
        case 'test_webhook':
            socket.webhookTest(data.webhook_url);
            break;
        case 'clients':
            return socket.clientData;
        case 'stats':
            return socket.stats;
        case 'recents':
            return socket.recents;
        case 'targets':
            return socket.targets;
        case 'elapsed_start':
            return socket.getElapsedStart();
        case 'config':
            if (method == "GET") {
                return socket.config;
            } else if (method == "POST") {
                socket.sendConfigToClients(data.config, data.game);

                /*  
                    Try both methods of overwriting the socket's config
                    because they don't work consistently
                */
                socket.config = data.config;
                socket.setSocketConfig(data.config);
            }
        case 'encounter_rate':
            return socket.getEncounterRate();
        default:
            return null;
    }
}