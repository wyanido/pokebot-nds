const { ipcRenderer } = require('electron')

var game_tab = 0

function displayClientInfo(clients) {
    $('#party div').empty();

    for (var j = 0; j < clients.length; j++) {
        var client = clients[j]
        var game = $('#game-template').tmpl(client)
        var button = $('#button-template').tmpl({ 'game': client.game })

        $('#top-row').append(game)
        $('#game-buttons').append(button)

        var template = $('#party-template');
        
        var party = client.party
        if (party) {
            for (var i = 0; i < 6; i++) {
                var partyID = '#party-' + (i + 1).toString()
                var mon = party[i]

                if (mon) {
                    if (mon.isEgg) {
                        template = $('#party-egg-template')
                    } else {
                        mon.folder = mon.shiny ? 'shiny/' : '';
                        mon.shiny = mon.shiny ? '✨' : '';
                    }

                    mon.fainted = mon.currentHP == 0 ? 'opacity: 0.5' : '';
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

                    var newTableRow = template.tmpl(mon);
                    $(partyID).append(newTableRow)
                }

                /* 
                    Remove the id attribute from this template to ensure Pokemon
                    from other parties are not appended to it
                */
                $(partyID).removeAttr('id')
            }
        }

        button.attr('id', 'button-template-' + j.toString())
        game.hide()
        game.attr('id', 'game-template-' + j.toString())
    }

    game_tab = Math.min(game_tab, clients.length - 1)

    $('#button-template-' + game_tab.toString()).attr('class', 'btn btn-primary col text-truncate')
    $('#game-template-' + game_tab.toString()).show()
}

function selectTab(ele) {
    game_tab = ele.id.replace('button-template-','');

    for (var i = 0; i <= $('#top-row').children.length + 1; i++) {
        var idx = i.toString()

        if (i == game_tab) {
            $('#game-template-' + idx).show()
            $('#button-template-' + idx).attr('class', 'btn btn-primary col text-truncate')
        } else {
            $('#game-template-' + idx).hide()
            $('#button-template-' + idx).attr('class', 'btn col text-truncate')
        }
    }
}

ipcRenderer.on('set_recents', (_event, encounters) => {
    // Refresh log display
    var template = $('#row-template');
    var log = $('#recents')

    $('#recents').empty();

    for (var i = encounters.length; i >= encounters.length - 7; i--) {
        if (encounters[i]) {
            var row = template.tmpl(encounters[i]);
            log.append(row)
        }
    }
});

ipcRenderer.on('set_targets', (_event, encounters) => {
    // Refresh log display
    var template = $('#row-template');
    var log = $('#targets')

    $('#targets').empty();

    for (var i = encounters.length; i >= encounters.length - 7; i--) {
        if (encounters[i]) {
            var row = template.tmpl(encounters[i]);
            log.append(row)
        }
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
    $('#top-row').empty()
    $('#game-buttons').empty()

    if (clients.length == 0) {
        $('#top-row').append($('#game-template').tmpl())

        var button = $('#button-template').tmpl({ 'game': 'No game detected!'})
        button.attr('class', 'btn btn-primary col text-truncate')
        $('#game-buttons').append(button)
        return
    }

    displayClientInfo(clients)
});

ipcRenderer.on('set_page_icon', (_event, gen) => {
    // Set the page icon to match the current loaded game generation
    page_icon_set = true
    var minValue, maxValue

    switch (gen) {
        case 4:
            minValue = 387
            maxValue = 493
            break;
        case 5:
            minValue = 494
            maxValue = 649
            break;
    }

    var num = Math.floor(Math.random() * (maxValue - minValue)) + minValue
    document.getElementById('icon').src = 'images/pokemon-icon/' + num.toString().padStart(3, '0') + '.png';
});