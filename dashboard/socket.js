const net = require('net');
const fs = require('fs');
const { AttachmentBuilder, EmbedBuilder, WebhookClient } = require('discord.js');
const port = 51055;

var clients = [];
var clientData = [];

var elapsedStart;

var lastEncounter;
var sinceLastEncounter;

const rateHistorySample = 20;
var rateHistory = [];
var encounterRate = 0;

// === FILE SETUP ===
// Default config
const configTemplate = {
    save_game_on_start: false,
    mode: "random_encounters",
    starter0: true,
    starter1: true,
    starter2: true,
    move_direction: "Horizontal",
    target_traits: {
        iv_sum: 180
    },
    pokeball_override: {
        'Repeat Ball': {
            species: [
                "Lillipup",
                "Patrat"
            ]
        },
        'Net Ball': {
            "type": [
                "Bug",
                "Water"
            ]
        }
    },
    thief_wild_items: false,
    pickup: false,
    pokeball_priority: [
        "Premier Ball",
        "Ultra Ball",
        "Great Ball",
        "Poke Ball"
    ],
    save_game_after_catch: false,
    pickup_threshold: "2",
    hax: false,
    cycle_lead_pokemon: true,
    encounter_log_limit: "30",
    battle_non_targets: false,
    auto_catch: false,
    target_log_limit: "30",
    inactive_client_timeout: "5000",
    dashboard_poll_interval: "330",
    inflict_status: false,
    false_swipe: false,
    debug: false,
    webhook_url: "",
    webhook_enabled: false,
    ping_user: false,
    user_id: "",
    show_status: true,
    save_pkx: true,
    state_backup: true,
    backup_interval: "30",
    always_catch_shinies: true
}
const statsTemplate = {
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

// Create /user and subfolders if it doesn't exist
const userDir = '../user';

if (!fs.existsSync(userDir)) {
    fs.mkdirSync(userDir);
}

if (!fs.existsSync(userDir + "/targets")) {
    fs.mkdirSync(userDir + "/targets");
}

var recents = readJSONFromFile('../user/encounters.json', []);
var targets = readJSONFromFile('../user/target_log.json', []);
var config = readJSONFromFile('../user/config.json', configTemplate);
var stats = readJSONFromFile('../user/stats.json', statsTemplate);

// Update stats and config with values not included in previous versions
objectSubstitute(stats, statsTemplate, true)
writeJSONToFile('../user/stats.json', stats)

objectSubstitute(config, configTemplate)
writeJSONToFile('../user/config.json', config)

// Discord 'playing' status
const Version = {
    DIAMOND: 0,
    PEARL: 1,
    PLATINUM: 2,
    HEARTGOLD: 3,
    SOULSILVER: 4,
    BLACK: 5,
    WHITE: 6,
    BLACK2: 7,
    WHITE2: 8
}

process.on('uncaughtException', function (err) {
    console.log(err);
});

if (config.show_status) {
    DiscordRPC = require('discord-rich-presence')('1140996615784636446');

    DiscordRPC.on('error', (reason, _promise) => {
        console.error(`Discord RPC ${reason}`);
    });

    DiscordRPC.on('connected', (_status) => {
        setInterval(() => {
            // Default status
            let status = {
                state: 'Idling',
                largeImageKey: 'none',
                startTimestamp: null,
                instance: false,
            }

            if (clientData.length > 0) {
                const game = clientData[0].game;
                if (!game) return;

                // Get game-specific icon
                let icon;

                switch (clientData[0].version) {
                    case Version.DIAMOND: icon = "diamond"; break;
                    case Version.PEARL: icon = "pearl"; break;
                    case Version.PLATINUM: icon = "platinum"; break;
                    case Version.HEARTGOLD: icon = "heartgold"; break;
                    case Version.SOULSILVER: icon = "soulsilver"; break;
                    case Version.BLACK: icon = "black"; break;
                    case Version.WHITE: icon = "white"; break;
                    case Version.BLACK2: icon = "black2"; break;
                    case Version.WHITE2: icon = "white2"; break;
                }

                const location = clientData[0].map_name;
                if (location == undefined) return;
                const moreGames = (clients.length > 1) ? `+ ${clientData.length - 1} game(s)` : ''

                status.largeImageKey = icon;
                status.details = `📍${location} ${moreGames}`;
                status.state = `${stats.total.seen} seen (${stats.total.shiny}✨) at ${encounterRate}/h`;
                status.startTimestamp = elapsedStart;
            }

            DiscordRPC.updatePresence(status);
        }, 2500)
    }
    );
}

function getTimestamp() {
    return new Date().toLocaleTimeString()
}

const server = net.createServer((socket) => {
    console.log('[%s] Client %d connected', getTimestamp(), clients.length);
    clients.push(socket);
    socketSetTimeout(socket);

    socket.write(formatClientMessage(
        'apply_config',
        { 'config': config }
    ));

    let buffer = ''
    socket.on('data', (data) => {
        buffer += data.toString();
        let responses = buffer.split('\x00');

        for (let i = 0; i < responses.length - 1; i++) {
            var response = responses[i].trim();

            if (response.length > 0) {
                clearTimeout(socket.inactivityTimeout);
                socketSetTimeout(socket);

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
        // console.log('Client disconnected');
    });

    socket.on('error', (_err) => {
        // console.error('Socket error:', err);
    });
});

server.listen(port, () => {
    console.log(`=======================================`);
    console.log(`Socket server listening for clients on port ${port}`);
});

function objectSubstitute(src, sub, recursive = false) {
    for (var key in sub) {
        if (sub.hasOwnProperty(key)) {
            if (src[key] === undefined) {
                src[key] = sub[key];
            } else if (recursive && (typeof src[key] === 'object' && typeof sub[key] === 'object')) {
                objectSubstitute(src[key], sub[key]);
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
    }

    lastEncounter = now
}

function updateEncounterLog(mon) {
    recents.push(formatMonData(mon));
    recents.splice(0, recents.length - config.encounter_log_limit);

    updateEncounterRate()

    stats.total.seen += 1;
    stats.phase.seen += 1;

    stats.phase.lowest_sv = typeof (stats.phase.lowest_sv) != 'number' ? mon.shinyValue : Math.min(mon.shinyValue, stats.phase.lowest_sv);

    var iv_sum = mon.hpIV + mon.attackIV + mon.defenseIV + mon.spAttackIV + mon.spDefenseIV + mon.speedIV;
    stats.total.max_iv_sum = typeof (stats.total.max_iv_sum) != 'number' ? iv_sum : Math.max(iv_sum, stats.total.max_iv_sum);
    stats.total.min_iv_sum = typeof (stats.total.min_iv_sum) != 'number' ? iv_sum : Math.min(iv_sum, stats.total.min_iv_sum);

    if (mon.shiny == true || mon.shinyValue < 8) {
        stats.total.shiny = stats.total.shiny + 1;
    }

    writeJSONToFile('../user/encounters.json', recents);

    return recents;
}

function updateTargetLog(mon) {
    targets.push(formatMonData(mon))
    targets = targets.slice(-config.target_log_limit)

    // Reset target phase stats
    stats.phase.seen = 0
    stats.phase.lowest_sv = '--'

    writeJSONToFile('../user/target_log.json', targets)

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
        console.log('[%s] Client %d removed for inactivity', getTimestamp(), index)
    }, config.inactive_client_timeout)
}

function formatClientMessage(type, data) {
    var msg = JSON.stringify({
        'type': type,
        'data': data
    });

    return msg.length + ' ' + msg;
}

function webhookLogPokemon(mon, client) {
    let gender;
    switch (mon.gender.toLowerCase()) {
        case 'male': gender = '♂️'; break;
        case 'female': gender = '♀️'; break;
        default: gender = ''; break;
    }

    const iv_sum = mon.hpIV + mon.attackIV + mon.defenseIV + mon.spAttackIV + mon.spDefenseIV + mon.speedIV;
    const sparkle = (mon.shinyValue < 8 || mon.shiny) ? '✨' : '';
    const folder = (mon.shinyValue < 8 || mon.shiny) ? 'shiny/' : '';
    const file = new AttachmentBuilder(`./assets/pokemon/${folder}${mon.species}.png`);
    const embed = new EmbedBuilder()
        .setTitle(`Encountered Lv.${mon.level} ${mon.name} ${gender}`)
        .setThumbnail(`attachment://${mon.species}.png`)
        .setDescription(`Found at ${client.map_name} on ${client.game}`)
        .addFields(
            { name: 'Shiny Value', value: `${sparkle}${mon.shinyValue.toString()}`, inline: true },
            { name: 'Nature', value: mon.nature, inline: true },
            { name: 'Item', value: mon.heldItem, inline: true },
        )
        .addFields(
            { name: '\u200B', value: `IVs (${iv_sum} Total)` })
        .addFields(
            { name: 'HP', value: mon.hpIV.toString(), inline: true },
            { name: 'ATK', value: mon.attackIV.toString(), inline: true },
            { name: 'DEF', value: mon.defenseIV.toString(), inline: true },
            { name: 'SP.ATK', value: mon.spAttackIV.toString(), inline: true },
            { name: 'SP.DEF', value: mon.spDefenseIV.toString(), inline: true },
            { name: 'SPEED', value: mon.speedIV.toString(), inline: true },
        )
        .setColor('Aqua')

    const webhookClient = new WebhookClient({ url: config.webhook_url });
    let messageContents = {
        username: 'Pokébot NDS',
        avatarURL: 'https://i.imgur.com/7tJPLRX.png',
        embeds: [embed],
        files: [file]
    }

    if (config.ping_user) {
        messageContents.content = `📢 <@${config.user_id}>`
    }

    webhookClient.send(messageContents);
}

function webhookTest() {
    const webhookClient = new WebhookClient({ url: config.webhook_url });
    webhookClient.send({
        username: 'Pokébot NDS',
        avatarURL: 'https://i.imgur.com/7tJPLRX.png',
        content: 'Testing...'
    });
}

function interpretClientMessage(socket, message) {
    const index = clients.indexOf(socket);
    let client = clientData[index];
    let data = message.data;

    switch (message.type) {
        case 'seen':
            updateEncounterLog(data);

            writeJSONToFile('../user/stats.json', stats);
            break;
        case 'seen_target':
            if (config.webhook_enabled) {
                webhookLogPokemon(data, client);
            }

            updateEncounterLog(data);
            updateTargetLog(data);

            writeJSONToFile('../user/stats.json', stats);
            break;
        case 'party':
            client.party_hash = data.hash
            client.party = data.party;
            break;
        case 'load_game':
            clientData[index] = {
                gen: data.gen,
                game: data.game,
                version: data.version
            }

            if (clients.length == 1) {
                elapsedStart = Date.now();
            }
            break;
        case 'game_state':
            client.map = data.map_name + " (" + data.map_header.toString() + ")";
            client.map_name = data.map_name;
            client.position = data.trainer_x.toString() + ", " + data.trainer_y.toString() + ", " + data.trainer_z.toString();
            
            // Values displayed on the game instance's tab on the dashboard
            var shownValues = {
                Map: client.map,
                Position: client.position
            }
            
            if ('phenomenon_x' in data) {
                shownValues.Phenomenon = data.phenomenon_x.toString() + ", --, " + data.phenomenon_z.toString();
            }
            
            client.shownValues = shownValues
            break;
    }
}

function sendConfigToClients(new_config, target) {
    // Send updated config to all clients
    if (clients.length > 0) {
        var msg = formatClientMessage(
            'apply_config',
            { 'config': new_config }
        )

        if (target == "all") {
            clients.forEach((client) => {
                client.write(msg);
            });
        } else {
            clients[target].write(msg);
        }
    }

    writeJSONToFile('../user/config.json', new_config);
}

module.exports = {
    clientData,
    stats,
    config,
    recents,
    targets,
    getElapsedStart: () => {
        return elapsedStart;
    },
    getEncounterRate: () => {
        return encounterRate;
    },
    sendConfigToClients,
    setSocketConfig: (new_config) => {
        config = new_config;
    },
    webhookTest
};