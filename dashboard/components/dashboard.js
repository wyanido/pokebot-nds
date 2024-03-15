
let elapsedStart;
let elapsedInterval;
let gameTab = 0;

let recentEncounters;
let recentTargets;

/* 
    Hashes are used to determine whether value changes
    should be reflected to minimise page updates
*/
let partyHashes = [];
let shownValuesHashes = [];

function hashObject(obj) {
    const jsonString = JSON.stringify(obj);
    
    if (!jsonString) return null
    
    var hash = 0;
    for (var i = 0; i < jsonString.length; i++) {
        var code = jsonString.charCodeAt(i);
        hash = ((hash << 5) - hash) + code;
        hash = hash & hash;
    }
    
    return hash;
}

function updateBnp() {
    var binomialDistribution = function (b, a) {
        c = Math.pow(1 - a, b);
        return 100 * (c * Math.pow(- (1 / (a - 1)), b) - c);
    }

    const rate = $('#shiny-rate').val();
    const seen = document.getElementById('phase-seen').innerHTML;
    const chance = binomialDistribution(seen, 1 / rate);
    const cumulativeOdds = Math.floor(chance * 100) / 100;

    if (cumulativeOdds == 100 || isNaN(cumulativeOdds)) cumulativeOdds = '99.99'
    document.getElementById('bnp').innerHTML = cumulativeOdds.toString() + '%';
}

const partyContainer = $('#game-party')
const partyMonTemplate = $('#party-mon-template');
const partyEggTemplate = $('#party-egg-template');
const partyTemplate = $('#party-template');

function displayClientParty(tabIndex, party) {
    const getPokerusStrain = function (value) {
        const x = value << 8;
        const y = value & 0xF;

        if (x > 0) {
            if (y == 0) {
                return 'cured';
            } else {
                return 'infected';
            }
        } else {
            return 'none';
        }
    }

    // Update existing party element, otherwise create a new template
    const eleName = 'party-template-' + tabIndex.toString();
    const existing = $('#' + eleName);
    const ele = existing.length ? existing.detach() : partyTemplate.tmpl();

    if (existing.length) {
        ele.empty()
    } else {
        ele.attr('id', eleName);
    }

    if (!party) return

    for (var i = 0; i < 6; i++) {
        const mon = party[i]

        if (!mon) break

        // Format Pokemon data for readability
        mon.folder = mon.shiny ? 'shiny/' : '';
        mon.shiny = mon.shiny ? '✨' : '';
        mon.fainted = mon.currentHP == 0 ? 'opacity: 0.5' : '';
        mon.gender = mon.gender == 'Genderless' ? 'none' : mon.gender.toLowerCase();
        mon.name = '(' + mon.name + ')';
        mon.pid = mon.pid.toString(16).toUpperCase().padEnd(8, '0');
        mon.pokerus = getPokerusStrain(mon.pokerus);

        if (mon.altForm > 0) {
            mon.species = mon.species + '-' + mon.altForm.toString();
        }

        const template = mon.isEgg ? partyEggTemplate : partyMonTemplate;
        ele.append(template.tmpl(mon))
    }

    partyContainer.append(ele);
}

const gameContainer = $('#game-info');
const gameTemplate = $('#game-template');

function valueHasUpdated(hash, hashArray, i) {
    return (i > hashArray.length || hash != hashArray[i])
}

function displayClientGameInfo(tabIndex, clientData) {
    // Update existing game element, otherwise create a new template
    const eleName = 'game-template-' + tabIndex.toString();
    const existing = $('#' + eleName);
    const ele = existing.length ? existing : gameTemplate.tmpl();

    if (!existing.length) {
        ele.attr('id', eleName);
        gameContainer.append(ele);
    }

    // OT, TID, SID
    const trainerFieldTable = $('#trainer-field-table', ele).detach();
    trainerFieldTable.empty();
    
    for (const key in clientData.trainer) {
        trainerFieldTable.append(`
            <tr>
                <th>
                    ${key}
                </th>
                <td>
                    ${clientData.trainer[key]}
                </td>
            </tr>`
        );
    }

    ele.append(trainerFieldTable)

    // Game-specific values the bot decides to send
    const fieldTable = $('#field-table', ele).detach();
    fieldTable.empty();

    for (const key in clientData.shownValues) {
        fieldTable.append(`
            <tr>
                <th>
                    ${key}
                </th>
                <td>
                    ${clientData.shownValues[key]}
                </td>
            </tr>`
        );
    }

    ele.append(fieldTable)
}

const tabContainer = $('#game-buttons');
const buttonTemplate = $('#button-template');

function updateClientTabs(clients) {
    const clientCount = clients.length;

    if (clientCount == 0) {
        tabContainer.empty();
        const button = buttonTemplate.tmpl({ 'game': 'Load pokebot-nds.lua in an emulator to begin!' })
        button.attr('class', 'btn btn-primary col text-truncate')

        tabContainer.append(button)

        displayClientParty(0, {});
        displayClientGameInfo(0, {});
        return
    }

    // Refresh display
    if (tabContainer.children().length != clientCount) {
        tabContainer.empty()
    }

    for (var i = 0; i < clientCount; i++) {
        const client = clients[i]

        if (!client.version) continue; // Client still hasn't loaded a game

        const buttonName = 'button-template-' + i.toString(); 
        const existing = $('#' + buttonName);

        if (!existing.length) {
            const button = existing.length ? existing.detach() : buttonTemplate.tmpl({ 'game': `${client.trainer.Name} (${client.version})` });
            button.attr('id', buttonName);
            tabContainer.append(button)
        }
    }

    gameTab = Math.min(gameTab, clientCount - 1)
}

function updateTabVisibility() {
    const tabCount = tabContainer.children().length

    for (var i = 0; i <= tabCount; i++) {
        const idx = i.toString()

        if (i == gameTab) {
            $('#game-template-' + idx).show()
            $('#party-template-' + idx).show()
            $('#button-template-' + idx).attr('class', 'btn btn-primary col text-truncate')
        } else {
            $('#game-template-' + idx).hide()
            $('#party-template-' + idx).hide()
            $('#button-template-' + idx).attr('class', 'btn col text-truncate')
        }
    }
}

function selectTab(ele) {
    gameTab = ele.id.replace('button-template-', '');

    updateTabVisibility()
}

const rowTemplate = $('#row-template');

function refreshPokemonList(log, doReformat, targetEle, targetsLength, hard_limit) {
    const entries = log.length;

    targetEle.empty();

    for (var i = entries; i >= entries - hard_limit; i --) {
        const mon = log[i]
        if (!mon) continue;

        if (i < entries - targetsLength) continue;

        if (doReformat && mon.altForm > 0) {
            mon.species = mon.species + '-' + mon.altForm.toString()
        }

        // Display raised/lowered stat modifiers in colour
        mon.attackMod    = ['Lonely', 'Adamant', 'Naughty', 'Brave'].includes(mon.nature) ? 'up' : ['Bold', 'Modest', 'Calm', 'Timid'].includes(mon.nature) ? ' down' : '';
        mon.defenseMod   = ['Bold', 'Impish', 'Lax', 'Relaxed'].includes(mon.nature) ? 'up'      : ['Lonely', 'Mild', 'Gentle', 'Hasty'].includes(mon.nature) ? ' down' : '';
        mon.spAttackMod  = ['Modest', 'Mild', 'Rash', 'Quiet'].includes(mon.nature) ? 'up'       : ['Adamant', 'Impish', 'Careful', 'Jolly'].includes(mon.nature) ? ' down' : '';
        mon.spDefenseMod = ['Calm', 'Gentle', 'Careful', 'Sassy',].includes(mon.nature) ? 'up'   : ['Naughty', 'Lax', 'Rash', 'Naive'].includes(mon.nature) ? ' down' : '';
        mon.speedMod     = ['Timid', 'Hasty', 'Jolly', 'Naive',].includes(mon.nature) ? 'up'     : ['Brave', 'Relaxed', 'Quiet', 'Sassy'].includes(mon.nature) ? ' down' : '';


        const row = rowTemplate.tmpl(mon);

        if (mon.shiny == true || mon.shinyValue < 8) {
            row.attr('id', 'shiny');
        }

        targetEle.append(row)
    }
}

const recentsEle = $('#recents');
const recentsLimit = $('#recents-limit');

function updateRecentlySeen(reformat = true, force = false) {
    socketServerGet('recents', function (error, encounters) {
        if (error) {
            console.error(error);
            return;
        }

        const updated = !recentEncounters || recentEncounters.slice(-1)[0].pid != encounters.slice(-1)[0].pid
        recentEncounters = encounters;

        if (updated || force) {
            refreshPokemonList(
                encounters,
                reformat,
                recentsEle,
                recentsLimit.val() || 7,
                recentsHardLimit
            )
        }

        let uniquePIDS = [];
        recentEncounters.forEach(mon => {
            if (!uniquePIDS.includes(mon.pid)) {
                uniquePIDS.push(mon.pid);
            }
        });
        
        if (uniquePIDS.length < recentEncounters.length) {
            $('#warn-duplicate').show()
        } else {
            $('#warn-duplicate').hide()
        }
    });
}

const targetsEle = $('#targets');
const targetsLimit = $('#targets-limit');

function updateRecentTargets(reformat = true, force = false) {
    socketServerGet('targets', function (error, encounters) {
        if (error) {
            console.error(error);
            return;
        }

        const updated = !recentTargets || recentTargets.slice(-1)[0].pid != encounters.slice(-1)[0].pid
        recentTargets = encounters;
        
        if (updated || force) {
            refreshPokemonList(
                encounters,
                reformat,
                targetsEle,
                targetsLimit.val() || 7,
                targetsHardLimit
            )
        }
    });
}

const elapsedTime = $('#elapsed-time');

function updateElapsedTime() {
    const elapsed = Math.floor((Date.now() - elapsedStart) / 1000);
    const s = elapsed;
    const m = Math.floor(s / 60);
    const h = Math.floor(m / 60);
    const time = `${h}h ${m % 60}m ${s % 60}s`;

    elapsedTime.text(time)
}

let statsHash;

function updateStats() {
    socketServerGet('stats', function (error, stats) {
        if (error) {
            console.error(error);
            return;
        }

        const hash = hashObject(stats);
        if (statsHash == hash) return;

        statsHash = hash;

        document.getElementById('total-seen').innerHTML      = stats.total.seen;
        document.getElementById('total-shiny').innerHTML     = stats.total.shiny;
        document.getElementById('total-max-iv').innerHTML    = stats.total.max_iv_sum;
        document.getElementById('total-min-iv').innerHTML    = stats.total.min_iv_sum;

        document.getElementById('phase-seen').innerHTML      = stats.phase.seen;
        document.getElementById('phase-lowest-sv').innerHTML = stats.phase.lowest_sv;

        updateBnp();
    });
};

function setClients() {
    socketServerGet('clients', function (error, clients) {
        if (error) {
            console.error(error);
            return;
        }

        const clientCount = clients.length;

        setBadgeClientCount(clientCount);
        updateClientTabs(clients);

        // Refresh displays
        if (clientCount < gameContainer.children().length) gameContainer.empty();
        if (clientCount < partyContainer.children().length) partyContainer.empty();

        if (clientCount == 0) {
            clearInterval(elapsedInterval);
            elapsedStart = null;

            $('#elapsed-time').text('0s');
            $('#encounter-rate').text('0/h');
            return;
        }

        for (var i = 0; i < clientCount; i++) {
            const client = clients[i];

            // Update client party display if data changed
            if (partyContainer.children().length != clientCount || valueHasUpdated(client.party_hash, partyHashes, i)) {
                displayClientParty(i, client.party);
                partyHashes[i] = client.party_hash;
            }
            
            if (gameContainer.children().length != clientCount || valueHasUpdated(hashObject(client.shownValues), shownValuesHashes, i)) {
                displayClientGameInfo(i, client);
                shownValuesHashes[i] = hashObject(client.shownValues);
            }
        }

        updateTabVisibility()

        if (!elapsedStart) {
            // Start elapsed timer if a game is connected
            socketServerGet('elapsed_start', function (error, start) {
                if (error) {
                    console.error(error);
                    return;
                }

                elapsedStart = start;
                elapsedInterval = setInterval(updateStatBadges, 1000);
            });
        }
    })
};

const encounterRate = $('#encounter-rate');

function updateEncounterRate() {
    socketServerGet('encounter_rate', function (error, rate) {
        if (error) {
            console.error(error);
            return;
        }

        encounterRate.text(`${rate}/h`)
    })
}

function updateStatBadges() {
    updateEncounterRate()
    updateElapsedTime()
}

function updatePage() {
    updateStats()
    setClients()
    updateRecentTargets()
    updateRecentlySeen()
}

const recentEncountersEle = document.getElementById('recents-limit');
recentEncountersEle.addEventListener('change', () => {
    updateRecentlySeen(false, true)
})

const recentTargetsEle = document.getElementById('targets-limit');
recentTargetsEle.addEventListener('change', () => {
    updateRecentTargets(false, true)
})

const rateEle = document.getElementById('shiny-rate');
rateEle.addEventListener('change', () => {
    updateBnp()
})

let recentsHardLimit;
let targetsHardLimit;

socketServerGet('config', function (error, config) {
    if (error) {
        console.error(error);
        return;
    }

    recentsHardLimit = config.encounter_log_limit;
    targetsHardLimit = config.target_log_limit;
    
    updatePage();
    
    const interval = config.dashboard_poll_interval;
    
    setInterval(() => {
        updatePage();
    }, interval);
})