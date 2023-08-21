const { ipcRenderer } = require('electron')

var game_tab = 0

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

    if (game_tab != index) party_template.hide()
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

        var button = $('#button-template').tmpl({ 'game': client.game })
        $('#game-buttons').append(button)

        button.attr('id', 'button-template-' + j.toString())
    }

    game_tab = Math.min(game_tab, clients.length - 1)
    updateTabVisibility()
    $('#button-template-' + game_tab.toString()).attr('class', 'btn btn-primary col text-truncate')
}

function displayClientGameInfo(index, client) {
    var ele = 'game-template-' + index.toString();
    $('#' + ele).remove()

    var game_template = $('#game-template').tmpl(client)
    $('#game-info').append(game_template)

    for (const key in client.other) {
        $('#field-table').append(`<tr><th>${key}</th><td>${client.other[key]}</td></tr>`);
    }

    // console.log(client.other)
    if (game_tab != index) {
        game_template.hide();
    }

    game_template.attr('id', ele);
    $('#field-table').attr('id', '')
}

function updateTabVisibility() {
    for (var i = 0; i <= $('#client-container').children.length + 1; i++) {
        var idx = i.toString()

        if (i == game_tab) {
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
    game_tab = ele.id.replace('button-template-', '');

    updateTabVisibility()
}

ipcRenderer.on('set_recents', (_event, encounters) => {
    // Refresh log display
    var template = $('#row-template');
    var log = $('#recents')

    $('#recents').empty();

    for (var i = encounters.length; i >= encounters.length - 7; i--) {
        var mon = encounters[i]
        if (!mon) continue;
        
        if (mon.altForm > 0) mon.species = mon.species + '-' + mon.altForm.toString()
        var row = template.tmpl(mon);
        log.append(row)
    }
});

ipcRenderer.on('set_targets', (_event, encounters) => {
    // Refresh log display
    var template = $('#row-template');
    var log = $('#targets')

    $('#targets').empty();

    for (var i = encounters.length; i >= encounters.length - 7; i--) {
        var mon = encounters[i]
        if (!mon) continue;

        if (mon.altForm > 0) mon.species = mon.species + '-' + mon.altForm.toString()
        var row = template.tmpl(mon);
        log.append(row)
    }
});

ipcRenderer.on('set_stats', (_event, stats) => {
    document.getElementById('total-seen').innerHTML = stats.total.seen
    document.getElementById('total-shiny').innerHTML = stats.total.shiny
    document.getElementById('total-max-iv').innerHTML = stats.total.max_iv_sum
    document.getElementById('total-min-iv').innerHTML = stats.total.min_iv_sum

    document.getElementById('phase-seen').innerHTML = stats.phase.seen
    document.getElementById('phase-lowest-sv').innerHTML = stats.phase.lowest_sv
});

ipcRenderer.on('set_clients', (_event, clients) => {
    displayClientTabs(clients);

    for (var i = 0; i < clients.length; i++) {
        var client = clients[i];

        displayClientParty(i, client.party);
        displayClientGameInfo(i, client);
    }
    
    last_client_count = clients.length
});

ipcRenderer.on('set_client_party', (_event, index, party) => {
    displayClientParty(index, party);
});

ipcRenderer.on('set_client_tabs', (_event, clients) => {
    displayClientTabs(clients);
});

ipcRenderer.on('set_client_game_info', (_event, index, client) => {
    displayClientGameInfo(index, client);
});

ipcRenderer.on('set_page_icon', (_event, icon_src) => {
    document.getElementById('icon').src = icon_src
});