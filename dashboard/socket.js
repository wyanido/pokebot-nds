const net = require('net');
const { AttachmentBuilder, EmbedBuilder, WebhookClient } = require('discord.js');
// const { webhookId, webhookToken } = require('../config.json');
const port = 51055;

// const file = new AttachmentBuilder('./assets/pokemon/1.png');
// const embed = new EmbedBuilder()
//     .setTitle('Some title')
//     .setImage('attachment://1.png');

// const webhookClient = new WebhookClient({ url: 'https://discord.com/api/webhooks/1144275363577483306/fKmwz4f37gT2-dR1aCu0yrz0WY2h9D2o-4ahfwMf2huPoFSvHeZTkmO1T_jQDtmho5x-' });
// webhookClient.send({
//     content: 'Webhook test',
//     username: 'some-username',
//     embeds: [embed],
//     files: [file]
// });

const server = net.createServer((socket) => {
    console.log('Client connected.');

    let buffer = ''
    socket.on('data', (data) => {
        buffer += data.toString();
        let responses = buffer.split('\x00');

        for (let i = 0; i < responses.length - 1; i++) {
            var response = responses[i].trim();

            if (response.length > 0) {
                // clearTimeout(socket.inactivityTimeout);
                // socketSetTimeout(socket);

                // Separate JSON from length prefix
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

    socket.on('end', () => {
        console.log('Client disconnected.');
    });

    socket.on('error', (err) => {
        // console.error('Socket error:', err);
    });
});

server.listen(port, () => {
    console.log(`Socket server listening for clients on port ${port}`);
});

function interpretClientMessage(socket, message) {
    // var index = clients.indexOf(socket);
    // var client = clientData[index];
    var data = message.data;

    switch (message.type) {
        case 'seen':

            break;
        case 'seen_target':

            break;
        case 'party':

            break;
        case 'load_game':
            console.log("Game was loaded.")
            break;
        case 'game_state':

            break;
    }
}