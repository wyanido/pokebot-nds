const net = require('net');
const fs = require('fs');
const { AttachmentBuilder, EmbedBuilder, WebhookClient, ButtonBuilder, ButtonStyle } = require('discord.js');
const port = 51055;

var clients = [];
var clientData = [];

var elapsedStart;

var lastEncounter;
var sinceLastEncounter;

const clientInactivityTimeout = 180000; // Prevent excessive pile-up of ended sessions, remove them after 3 minutes
const rateHistorySample = 20;
var rateHistory = [];
var encounterRate = 0;

// === FILE SETUP ===
// Default config
const configTemplate = {
    mode: "random_encounters",
    starter0: true,
    starter1: true,
    starter2: true,
    move_direction: "horizontal",
    target_traits: {
        ivSum: 180
    },
    pokeball_override: {
        'Repeat Ball': {
            name: [
                "Lillipup",
                "Bidoof",
                "Sentret"
            ]
        },
        'Net Ball': {
            type: [
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
    cycle_lead_pokemon: true,
    encounter_log_limit: "30",
    battle_non_targets: false,
    auto_catch: false,
    target_log_limit: "30",
    dashboard_poll_interval: "1000",
    subdue_target: false,
    debug: false,
    webhook_url: "",
    webhook_enabled: false,
    ping_user: false,
    user_id: "",
    show_status: true,
    save_pkx: true,
    always_catch_shinies: true,
    auto_open_page: true,
    primo1: 1,
    primo2: 1,
    primo3: 1,
    primo4: 1,
    grotto: 0
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
                state: 'Idle',
                details: 'No games connected',
                largeImageKey: 'none',
                startTimestamp: null,
                instance: false,
                buttons: [new ButtonBuilder()
                    .setLabel('View on GitHub')
                    .setURL('https://github.com/wyanido/pokebot-nds')
                    .setStyle(ButtonStyle.Link)
                ]
            }

            if (clientData.length > 0 && clientData[0] != undefined) {
                const version = clientData[0].version;
                if (!version) return;

                let icon;

                switch (version) {
                    case 'D': icon = "diamond"; break;
                    case 'P': icon = "pearl"; break;
                    case 'PL': icon = "platinum"; break;
                    case 'HG': icon = "heartgold"; break;
                    case 'SS': icon = "soulsilver"; break;
                    case 'B': icon = "black"; break;
                    case 'W': icon = "white"; break;
                    case 'B2': icon = "black2"; break;
                    case 'W2': icon = "white2"; break;
                }

                const location = clientData[0].map_name;
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
    console.log('[%s] Session %d connected', getTimestamp(), clients.length + 1)
    clients.push(socket);
    socketSetTimeout(socket);

    socket.write(formatClientMessage(
        'apply_config',
        { 'config': config }
    ));

    let buffer = ''
    socket.on('data', (data) => {
        buffer += data.toString();
        let responses = buffer.split('\0');

        for (let i = 0; i < responses.length - 1; i++) {
            var response = responses[i].trim();

            if (response.length > 0) {
                clearTimeout(socket.inactivityTimeout);
                socketSetTimeout(socket);

                try {
                    var message = JSON.parse(response);

                    interpretClientMessage(socket, message);
                } catch (error) {
                    console.error(error);
                }
            }
        }

        buffer = responses[responses.length - 1];
    });

    socket.on('end', () => {
        const index = killSocket(socket);
        console.log('[%s] Session %d disconnected', getTimestamp(), index + 1);
    });

    socket.on('error', (_err) => {
        // console.error('Socket error:', err);
    });
});

server.listen(port, () => {
    console.log(`Socket server listening for emulators on port ${port}`);
});

function killSocket(socket) {
    const index = clients.indexOf(socket);

    if (index > -1) {
        clients.splice(index, 1);
        clientData.splice(index, 1);
    }

    socket.destroy()
    return index;
}

function socketSetTimeout(socket) {
    socket.inactivityTimeout = setTimeout(() => {
        const index = killSocket(socket);
        console.log('[%s] Session %d removed for inactivity', getTimestamp(), index + 1);
    }, clientInactivityTimeout)
}

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
    recents.push(mon);
    recents.splice(0, recents.length - config.encounter_log_limit);

    updateEncounterRate()

    stats.total.seen += 1;
    stats.phase.seen += 1;

    stats.phase.lowest_sv = typeof (stats.phase.lowest_sv) != 'number' ? mon.shinyValue : Math.min(mon.shinyValue, stats.phase.lowest_sv);

    stats.total.max_iv_sum = typeof (stats.total.max_iv_sum) != 'number' ? mon.ivSum : Math.max(mon.ivSum, stats.total.max_iv_sum);
    stats.total.min_iv_sum = typeof (stats.total.min_iv_sum) != 'number' ? mon.ivSum : Math.min(mon.ivSum, stats.total.min_iv_sum);

    if (mon.shiny == true || mon.shinyValue < 8) {
        stats.total.shiny = stats.total.shiny + 1;
    }

    writeJSONToFile('../user/encounters.json', recents);
}

function updateTargetLog(mon) {
    targets.push(mon)
    targets.splice(0, targets.length - config.target_log_limit)

    // Reset target phase stats
    stats.phase.seen = 0
    stats.phase.lowest_sv = '--'

    writeJSONToFile('../user/target_log.json', targets)
}

function formatClientMessage(type, data) {
    return JSON.stringify({
        'type': type,
        'data': data
    });
}

function webhookLogPokemon(mon, client) {
    let gender;
    switch (mon.gender.toLowerCase()) {
        case 'male': gender = '♂️'; break;
        case 'female': gender = '♀️'; break;
        default: gender = ''; break;
    }

    const species = mon.species.toString().padStart(3, '0');
    const iv_sum = mon.hpIV + mon.attackIV + mon.defenseIV + mon.spAttackIV + mon.spDefenseIV + mon.speedIV;
    const sparkle = (mon.shinyValue < 8 || mon.shiny) ? '✨' : '';
    const folder = (mon.shinyValue < 8 || mon.shiny) ? 'shiny/' : '';
    const file = new AttachmentBuilder(`./assets/pokemon/${folder}${species}.png`);
    const embed = new EmbedBuilder()
        .setTitle(`Encountered Lv.${mon.level} ${mon.name} ${gender}`)
        .setThumbnail(`attachment://${species}.png`)
        .setDescription(`Found at ${client.map_name} (${client.version})`)
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

function webhookTest(url) {
    const webhookClient = new WebhookClient({ url: url });
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
            client.party = data.party;
            break;
        case 'load_game':
            console.log('[%s] Session %d loaded %s', getTimestamp(), clientData.length + 1, data.version);

            clientData[index] = {
                gen: data.gen,
                version: data.version
            }

            if (clients.length == 1) {
                elapsedStart = Date.now();
            }
            break;
        case 'game_state':
            const map = data.map_name || '--';

            client.map_name = map;
            client.position = `${Math.floor(data.trainer_x || 0)}, ${Math.floor(data.trainer_y || 0)}, ${Math.floor(data.trainer_z || 0)}`;
            client.trainer_name = data.trainer_name || '--'
            client.trainer_id = data.trainer_id || '--';

            // Values displayed on the game instance's tab on the dashboard
            var shownValues = {
                Name: client.trainer_name,
                "Trainer ID": client.trainer_id,
                Map: `${map} (${(data.map_header || 0).toString()})`,
                Position: client.position
            }
            
            if ('phenomenon_x' in data) {
                shownValues.Phenomenon = `${(data.phenomenon_x || '--').toString()}, --, ${(data.phenomenon_z || '--').toString()}`;
            }
            
            client.shownValues = shownValues
            break;
        case 'save_pkx':
            const buffer = Int8Array.from(data);

            fs.writeFileSync(`../user/targets/${message.filename}`, buffer);
            break;
    }
}

function sendConfigToClients(new_config, target) {
    writeJSONToFile('../user/config.json', new_config);
    
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
    webhookTest,
};