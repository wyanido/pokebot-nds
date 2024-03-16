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
        let mon = party[i]

        if (!mon) break

        // Format Pokemon data for readability
        mon = enrichFurther(mon);
        
        mon.fainted = mon.currentHP == 0 ? 'opacity: 0.5' : '';
        mon.gender = mon.gender == 'Genderless' ? 'none' : mon.gender.toLowerCase();
        mon.name = '(' + mon.name + ')';
        mon.pokerus = getPokerusStrain(mon.pokerus);
        
        // Don't spoil info on unhatched eggs
        if (mon.isEgg) {
            mon.shiny = '';
            mon.species = 'egg';
            mon.folder = '';
            mon.name = `<${mon.friendship} Steps Remaining`;
        } else {
            const shiny = mon.shinyValue < 8;

            mon.folder = shiny ? 'shiny/' : '';
            mon.shiny = shiny ? '✨' : '';
        }

        ele.append(partyMonTemplate.tmpl(mon))
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

    // Game-specific display values the bot decides to send
    const fieldTable = $('#shown-values', ele).detach();
    fieldTable.empty();

    for (const key in clientData.shownValues) {
        fieldTable.append(`
            <div class="d-flex w-full p-10">
                <div class="w-half"><b>${key}</b></div>
                <div class="w-half">
                ${clientData.shownValues[key]}
                </div>
            </div>`
        );
    }

    ele.append(fieldTable)
}

const tabContainer = $('#game-buttons');
const buttonTemplate = $('#button-template');

function updateClientTabs(clients) {
    const clientCount = clients.length;

    // Refresh display
    if (tabContainer.children().length != clientCount) {
        tabContainer.empty()
        partyContainer.empty()
        gameContainer.empty()
    }

    for (var i = 0; i < clientCount; i++) {
        const client = clients[i]

        if (!client.version || !client.trainer_name) continue; // Client still hasn't sent important values

        const buttonName = 'button-template-' + i.toString(); 
        const existing = $('#' + buttonName);

        if (!existing.length) {
            const button = existing.length ? existing.detach() : buttonTemplate.tmpl({ 'game': `${client.trainer_name} (${client.version})` });
            button.attr('id', buttonName);
            tabContainer.append(button)
        }
    }

    const tabCount = tabContainer.children().length;

    if (tabCount == 0) {
        tabContainer.empty();
        const button = buttonTemplate.tmpl({ 'game': 'Load pokebot-nds.lua in an emulator to begin!' })
        button.attr('class', 'btn btn-primary col text-truncate')

        tabContainer.append(button)

        displayClientParty(0, {});
        displayClientGameInfo(0, {});
    }

    // Set selected tab to first valid client
    if (!clients[gameTab] || !clients[gameTab].version || !clients[gameTab].trainer_name) {
        for (let i = 0; i < clientCount; i++) {
            const client = clients[i];
            
            if (client.version && client.trainer_name) {
                gameTab = i;
                break;
            } 
        }
    }
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

function refreshPokemonList(log, targetEle, targetsLength) {
    const entries = log.length;

    targetEle.empty();

    for (var i = entries; i >= entries - targetsLength; i --) {
        let mon = log[i]
        
        if (!mon) continue;

        mon = enrichFurther(mon);

        const row = rowTemplate.tmpl(mon);

        if (mon.shiny == true || mon.shinyValue < 8) {
            row.attr('id', 'shiny');
        }

        targetEle.append(row)
    }
}

function enrichFurther(mon) {
    // Fix filenames for display
    const gender = mon.gender.toLowerCase();
    mon.gender = gender == 'genderless' ? 'none' : gender;
    mon.shiny = (mon.shinyValue < 8 ? '✨ ' : '➖ ');
    mon.species = mon.species.toString().padStart(3, '0');

    if (mon.altForm > 0) {
        mon.species = mon.species + '-' + mon.altForm.toString()
    }

    // Display raised/lowered stat modifiers in colour
    mon.attackMod    = ['Lonely', 'Adamant', 'Naughty', 'Brave'].includes(mon.nature) ? 'up' : ['Bold', 'Modest', 'Calm', 'Timid'].includes(mon.nature) ? ' down' : '';
    mon.defenseMod   = ['Bold', 'Impish', 'Lax', 'Relaxed'].includes(mon.nature) ? 'up'      : ['Lonely', 'Mild', 'Gentle', 'Hasty'].includes(mon.nature) ? ' down' : '';
    mon.spAttackMod  = ['Modest', 'Mild', 'Rash', 'Quiet'].includes(mon.nature) ? 'up'       : ['Adamant', 'Impish', 'Careful', 'Jolly'].includes(mon.nature) ? ' down' : '';
    mon.spDefenseMod = ['Calm', 'Gentle', 'Careful', 'Sassy',].includes(mon.nature) ? 'up'   : ['Naughty', 'Lax', 'Rash', 'Naive'].includes(mon.nature) ? ' down' : '';
    mon.speedMod     = ['Timid', 'Hasty', 'Jolly', 'Naive',].includes(mon.nature) ? 'up'     : ['Brave', 'Relaxed', 'Quiet', 'Sassy'].includes(mon.nature) ? ' down' : '';

    return mon;
}

const recentsEle = $('#recents');
const recentsLimit = $('#recents-limit');

function updateRecentlySeen(force = false) {
    socketServerGet('recents', function (error, encounters) {
        if (error) {
            console.error(error);
            return;
        }

        if (encounters.length == 0) return;

        const updated = !recentEncounters || recentEncounters.slice(-1)[0].pid != encounters.slice(-1)[0].pid
        recentEncounters = encounters;

        if (updated || force) {
            refreshPokemonList(
                encounters,
                recentsEle,
                recentsLimit.val() || 7
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

function updateRecentTargets(force = false) {
    socketServerGet('targets', function (error, encounters) {
        if (error) {
            console.error(error);
            return;
        }

        if (encounters.length == 0) return;

        const updated = !recentTargets || recentTargets.slice(-1)[0].pid != encounters.slice(-1)[0].pid
        recentTargets = encounters;
        
        if (updated || force) {
            refreshPokemonList(
                encounters,
                targetsEle,
                targetsLimit.val() || 7
            )
        }
    });
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

            if (!client.version || !client.trainer_name) continue; // Client still hasn't sent important values

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

        // Start elapsed timer if a game is connected
        if (!elapsedStart) {
            socketServerGet('elapsed_start', function (error, start) {
                if (error) {
                    console.error(error);
                    return;
                }

                elapsedStart = start;
                elapsedInterval = setInterval(updateStatBadges, 1000);

                updateStatBadges();
            });
        }
    })
};

function updatePage() {
    updateStats()
    setClients()
    updateRecentTargets()
    updateRecentlySeen()
}

const recentEncountersEle = document.getElementById('recents-limit');
recentEncountersEle.addEventListener('change', () => {
    updateRecentlySeen(true)
})

const recentTargetsEle = document.getElementById('targets-limit');
recentTargetsEle.addEventListener('change', () => {
    updateRecentTargets(true)
})

const rateEle = document.getElementById('shiny-rate');
rateEle.addEventListener('change', () => {
    updateBnp()
})

socketServerGet('config', function (error, config) {
    if (error) {
        console.error(error);
        return;
    }
    
    updatePage();
    
    const interval = config.dashboard_poll_interval;
    
    setInterval(() => {
        updatePage();
    }, interval);
})