const { ipcRenderer } = require('electron')

function hex_reverse(hex) {
    return hex.match(/[a-fA-F0-9]{2}/g).reverse().join('').padEnd(8, '0');
}

ipcRenderer.on('party', (event, party) => {
    var template = $("#party-template");

    $("#party div").empty();

    for (var i = 0; i < party.length; i++) {
        if (party[i]) {
            var partyID = "#party-" + (i + 1).toString()

            mon = party[i]

            if (mon.isEgg) {
                template = $("#party-egg-template")
            } else {
                mon.folder = mon.shiny ? "shiny/" : "";
                mon.shiny = mon.shiny ? "✨" : "";
            }
            
            mon.gender = mon.gender.toLowerCase()
            mon.name = "(" + mon.name + ")"
            mon.pid = hex_reverse(mon.pid.toString(16).toUpperCase())
            // mon.rating = rating_stars(mon.rating)

            // Get Pokerus strain
            var x = mon.pokerus << 8;
            var y = mon.pokerus & 0xF;

            if (x > 0) {
                if (y == 0) {
                    mon.pokerus = "cured"
                } else {
                    mon.pokerus = "infected"
                }
            } else {
                mon.pokerus = "none"
            }

            var newTableRow = template.tmpl(mon);
            $(partyID).append(newTableRow)
        }
    }
});

ipcRenderer.on('set_recents', (_event, encounters) => {
    // Refresh log display
    var template = $("#row-template");
    var log = $("#recents")
    
    $("#recents").empty();
    
    for (var i = encounters.length; i >= encounters.length - 7; i--) {
        if (encounters[i]) {
            var row = template.tmpl(encounters[i]);
            log.append(row)
        }
    }
});

ipcRenderer.on('set_targets', (_event, encounters) => {
    // Refresh log display
    var template = $("#row-template");
    var log = $("#targets")
    
    $("#targets").empty();
    
    for (var i = encounters.length; i >= encounters.length - 7; i--) {
        if (encounters[i]) {
            var row = template.tmpl(encounters[i]);
            log.append(row)
        }
    }
});

ipcRenderer.on('set_stats', (_event, stats) => {
    document.getElementById("total-seen").innerHTML = stats.total.seen
    document.getElementById("total-shiny").innerHTML = stats.total.shiny
    document.getElementById("total-max-iv").innerHTML = stats.total.max_iv_sum

    document.getElementById("phase-seen").innerHTML = stats.phase.seen
    document.getElementById("phase-lowest-sv").innerHTML = stats.phase.lowest_sv
});

ipcRenderer.on('game', (_event, game) => {
    document.getElementById("map-header").innerHTML = game.map_name + " (" + game.map_header.toString() + ")"
    document.getElementById("position").innerHTML = game.trainer_x.toString() + ", " + game.trainer_y.toString() + ", " + game.trainer_z.toString()
    document.getElementById("phenomenon").innerHTML = game.phenomenon_x.toString() + ", --, " + game.phenomenon_z.toString()
});

ipcRenderer.on('init', (_event, info) => {
    // Set the page icon to match the current loaded game generation
    var minValue, maxValue

    switch (info.gen) {
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
    document.getElementById("icon").src = "images/pokemon-icon/" + num.toString().padStart(3, '0') + ".png";
    document.getElementById("nav-game").innerHTML = info.game;
});
