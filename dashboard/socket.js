const net = require('net');
const fs = require('fs');
const { AttachmentBuilder, EmbedBuilder, WebhookClient } = require('discord.js');
const port = 51055;

var clients = [];
var clientData = [];

var clientCooldown = false;
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
        shiny: true,
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
    webhook_enabled: false
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

// Create user folder if it doesn't exist
const userDir = '../user';

try {
    if (!fs.existsSync(userDir)) {
        fs.mkdirSync(userDir);
    }
} catch (err) {
    console.error(err);
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

const server = net.createServer((socket) => {
    console.log('Client %d connected', clients.length);
    clients.push(socket);
    clientData.push({})
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
        console.log('Client disconnected');
    });

    socket.on('error', (err) => {
        // console.error('Socket error:', err);
    });
});

server.listen(port, () => {
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
        console.log('Removed inactive client %d', index)
    }, config.inactive_client_timeout)
}

function formatClientMessage(type, data) {
    var msg = JSON.stringify({
        'type': type,
        'data': data
    });

    return msg.length + ' ' + msg;
}

function webhookLogPokemon(mon) {
    const file = new AttachmentBuilder('./assets/pokemon/' + mon.species + '.png');
    const embed = new EmbedBuilder()
        .setTitle('Encountered ' + mon.name)
        .setThumbnail('attachment://' + mon.species + '.png')
        .setDescription('A target Pokémon was found!')
        .addFields(
            { name: '\u200B', value: 'IVs' })
        .addFields(
            { name: 'HP', value: mon.hpIV.toString(), inline: true },
            { name: 'ATK', value: mon.attackIV.toString(), inline: true },
            { name: 'DEF', value: mon.defenseIV.toString(), inline: true },
            { name: 'SP.ATK', value: mon.spAttackIV.toString(), inline: true },
            { name: 'SP.DEF', value: mon.spDefenseIV.toString(), inline: true },
            { name: 'SPEED', value: mon.speedIV.toString(), inline: true },
        )

    const webhookClient = new WebhookClient({ url: config.webhook_url });
    webhookClient.send({
        username: 'Pokébot NDS',
        embeds: [embed],
        files: [file]
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
            return;
        case 'seen_target':
            webhookLogPokemon()
            updateEncounterLog(data);
            updateTargetLog(data);

            writeJSONToFile('../user/stats.json', stats);
        case 'party':
            client.party = data;
            break;
        case 'load_game':
            client.gen = data.gen;
            client.game = data.game;

            if (clients.length == 1) {
                elapsedStart = Date.now();
            }
            break;
        case 'game_state':
            client.map = data.map_name + " (" + data.map_header.toString() + ")";
            client.position = data.trainer_x.toString() + ", " + data.trainer_y.toString() + ", " + data.trainer_z.toString();

            // Parse additional data as a special category
            delete data['map_name'];
            delete data['map_header'];
            delete data['trainer_x'];
            delete data['trainer_y'];
            delete data['trainer_z'];
            delete data['in_game'];
            delete data['in_battle'];

            // Reformat phenomenon if present
            if ('phenomenon_x' in data) {
                data.Phenomenon = data.phenomenon_x.toString() + ", --, " + data.phenomenon_z.toString();
                delete data['phenomenon_x'];
                delete data['phenomenon_z'];
            }

            client.other = data;

            // Add a minimum update interval
            if (!clientCooldown) {
                clientCooldown = true;

                refreshTimeout = setTimeout(() => {
                    clientCooldown = false;
                }, config.game_refresh_cooldown);
            }
            break;
    }
}

function setConfig(new_config, target) {
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
    setConfig,
    setSocketConfig: (new_config) => {
        config = new_config;
    }
};