const { ipcRenderer } = require('electron')

let elapsedInterval;
var gameTab = 0;

let recentEncounters;
let recentTargets;

function updateBnp() {
    var binomialDistribution = function (b, a) {
        c = Math.pow(1 - a, b);
        return 100 * (c * Math.pow(- (1 / (a - 1)), b) - c);
    }

    var rate = $('#shiny-rate').val();
    var seen = document.getElementById('phase-seen').innerHTML;
    var chance = binomialDistribution(seen, 1 / rate);
    var cumulativeOdds = Math.floor(chance * 100) / 100;

    if (cumulativeOdds == 100 || isNaN(cumulativeOdds)) cumulativeOdds = '99.99'
    document.getElementById('bnp').innerHTML = cumulativeOdds.toString() + '%';
}

function displayClientParty(index, party) {
    var ele = 'party-template-' + index.toString();
    $('#' + ele).remove()

    if (!party) return

    var party_mon_template = $('#party-mon-template');
    var party_template = $('#party-template').tmpl();
    $('#game-party').append(party_template)

    for (var i = 0; i < 6; i++) {
        var mon = party[i]

        if (!mon) break

        if (mon.isEgg) {
            party_mon_template = $('#party-egg-template')
        } else {
            mon.folder = mon.shiny ? 'shiny/' : '';
            mon.shiny = mon.shiny ? '✨' : '';

            if (mon.altForm > 0) mon.species = mon.species + '-' + mon.altForm.toString()
            mon.fainted = mon.currentHP == 0 ? 'opacity: 0.5' : '';
        }

        mon.gender = mon.gender == 'Genderless' ? 'none' : mon.gender.toLowerCase()
        mon.name = '(' + mon.name + ')'
        mon.pid = mon.pid.toString(16).toUpperCase().padEnd(8, '0');
        // mon.rating = rating_stars(mon.rating)

        // Get Pokerus strain
        var x = mon.pokerus << 8;
        var y = mon.pokerus & 0xF;

        if (x > 0) {
            if (y == 0) {
                mon.pokerus = 'cured'
            } else {
                mon.pokerus = 'infected'
            }
        } else {
            mon.pokerus = 'none'
        }

        party_template.append(party_mon_template.tmpl(mon))
    }

    if (gameTab != index) party_template.hide()
    party_template.attr('id', ele)
}

function displayClientTabs(clients) {
    $('#game-buttons').empty();

    if (clients.length == 0) {
        $('#top-row').append($('#game-template').tmpl())

        var button = $('#button-template').tmpl({ 'game': 'No game detected!' })
        button.attr('class', 'btn btn-primary col text-truncate')
        $('#game-buttons').append(button)

        displayClientParty(0, {});
        displayClientGameInfo(0, {});
        return
    }

    for (var j = 0; j < clients.length; j++) {
        var client = clients[j]

        if (!client.game) continue;

        var button = $('#button-template').tmpl({ 'game': client.game.replace('Pokemon', '') })
        $('#game-buttons').append(button)

        button.attr('id', 'button-template-' + j.toString())
    }

    gameTab = Math.min(gameTab, clients.length - 1)
    updateTabVisibility()
    $('#button-template-' + gameTab.toString()).attr('class', 'btn btn-primary col text-truncate')
}

function displayClientGameInfo(index, client) {
    var ele = 'game-template-' + index.toString();
    $('#' + ele).remove()

    var game_template = $('#game-template').tmpl(client)
    $('#game-info').append(game_template)

    for (const key in client.other) {
        $('#field-table').append(`<tr><th>${key}</th><td>${client.other[key]}</td></tr>`);
    }

    if (gameTab != index) {
        game_template.hide();
    }

    game_template.attr('id', ele);
    $('#field-table').attr('id', '')
}

function updateTabVisibility() {
    for (var i = 0; i <= $('#game-buttons').children().length; i++) {
        var idx = i.toString()

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

function setRecentlySeen(encounters, reformat = true) {
    var template = $('#row-template');
    var log = $('#recents')

    var recentsLength = $('#recents-limit').val()
    if (isNaN(recentsLength)) recentsLength = 7

    $('#recents').empty();

    for (var i = encounters.length; i >= encounters.length - recentsLength; i--) {
        var mon = encounters[i]
        if (!mon) continue;

        if (reformat && mon.altForm > 0) mon.species = mon.species + '-' + mon.altForm.toString()
        var row = template.tmpl(mon);
        log.append(row)
    }
}

function setRecentTargets(encounters, reformat = true) {
    var template = $('#row-template');
    var log = $('#targets')

    var targetsLength = $('#targets-limit').val()
    if (isNaN(targetsLength)) targetsLength = 7

    $('#targets').empty();

    for (var i = encounters.length; i >= encounters.length - targetsLength; i--) {
        var mon = encounters[i]
        if (!mon) continue;

        if (reformat && mon.altForm > 0) mon.species = mon.species + '-' + mon.altForm.toString()
        var row = template.tmpl(mon);
        log.append(row)
    }
}

function setElapsedTime() {
    var elapsed = Math.floor((Date.now() - elapsedStart) / 1000);
    s = elapsed;
    m = Math.floor(s / 60);
    h = Math.floor(m / 60);

    var time = `${h}h ${m % 60}m ${s % 60}s`;

    $('#elapsed-time').empty()
    $('#elapsed-time').append(time);
}

function setBadgeClientCount(clients) {
    $('#home-button').empty()

    if (clients > 0) {
        $('#home-button').append('<span style="bottom:16px; right:-10px; font-size:10px" class="badge badge-primary position-absolute translate-middle text-bg-primary px-5">' + clients.toString() + '</span>')
    }
}

var recentEncountersEle = document.getElementById('recents-limit');
recentEncountersEle.addEventListener('change', () => {
    setRecentlySeen(recentEncounters, false)
})

var recentTargetsEle = document.getElementById('targets-limit');
recentTargetsEle.addEventListener('change', () => {
    setRecentTargets(recentTargets, false)
})

ipcRenderer.on('set_recents', (_event, encounters) => {
    recentEncounters = encounters;
    setRecentlySeen(encounters);
});

ipcRenderer.on('set_targets', (_event, encounters) => {
    recentTargets = encounters;
    setRecentTargets(encounters);
});

var rateEle = document.getElementById('shiny-rate');
rateEle.addEventListener('change', () => {
    updateBnp()
})

ipcRenderer.on('set_stats', (_event, stats) => {
    document.getElementById('total-seen').innerHTML = stats.total.seen
    document.getElementById('total-shiny').innerHTML = stats.total.shiny
    document.getElementById('total-max-iv').innerHTML = stats.total.max_iv_sum
    document.getElementById('total-min-iv').innerHTML = stats.total.min_iv_sum

    document.getElementById('phase-seen').innerHTML = stats.phase.seen
    document.getElementById('phase-lowest-sv').innerHTML = stats.phase.lowest_sv

    updateBnp();
});

ipcRenderer.on('set_clients', (_event, clients) => {
    setBadgeClientCount(clients.length)
    displayClientTabs(clients);

    for (var i = 0; i < clients.length; i++) {
        var client = clients[i];

        displayClientParty(i, client.party);
        displayClientGameInfo(i, client);
    }

    if (clients.length == 0) {
        clearInterval(elapsedInterval)
        $('#elapsed-time').empty()
        $('#elapsed-time').append('0s')

        $('#encounter-rate').empty()
        $('#encounter-rate').append('0/h')
    }
});

ipcRenderer.on('set_client_party', (_event, index, party) => {
    displayClientParty(index, party);
});

ipcRenderer.on('clients_updated', (_event, clients) => {
    setBadgeClientCount(clients.length)
    displayClientTabs(clients);
});

ipcRenderer.on('set_client_game_info', (_event, index, client) => {
    displayClientGameInfo(index, client);
});

ipcRenderer.on('set_page_icon', (_event, icon_src) => {
    document.getElementById('icon').src = icon_src
});

ipcRenderer.on('set_elapsed_start', (_event, time) => {
    elapsedStart = time;

    setElapsedTime()
    elapsedInterval = setInterval(setElapsedTime, 1000);
});

ipcRenderer.on('set_encounter_rate', (_event, rate) => {
    $('#encounter-rate').empty()
    $('#encounter-rate').append(rate + '/h');
});
