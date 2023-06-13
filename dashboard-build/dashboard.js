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
            mon.folder = mon.shiny ? "shiny/" : ""
            mon.gender = mon.gender.toLowerCase()
            mon.name = "(" + mon.name + ")"
            mon.pid = hex_reverse(mon.pid.toString(16).toUpperCase())
            // mon.rating = rating_stars(mon.rating)

            var newTableRow = template.tmpl(mon);
            $(partyID).append(newTableRow)
        }
    }
});

encounter_log = []

ipcRenderer.on('encounters', (event, encounters) => {
    // Modify data and add new encounters to the log
    for (var i = 0; i < encounters.length; i ++ ) {
        mon = encounters[i]
        mon.gender = mon.gender.toLowerCase()
        mon.pid = hex_reverse(mon.pid.toString(16).toUpperCase())
        mon.shiny = (mon.shiny ? "✨ " : "➖ ") + mon.shinyValue
        
        encounter_log.push(mon)
    }

    // Only keep the latest 7 entries
    encounter_log = encounter_log.slice(-7)
    
    // Refresh log display
    var template = $("#row-template");
    var recents = $("#recents")
    
    $("#recents tr").empty();

    for (var i = encounter_log.length; i >= 0; i--) {
        if (encounter_log[i]) {
            var row = template.tmpl(encounter_log[i]);
            recents.append(row)
        }
    }
});

ipcRenderer.on('stats', (event, stats) => {
    document.getElementById("encounters").innerHTML = stats.encounters
    document.getElementById("lowest-sv").innerHTML = stats.lowest_sv
    document.getElementById("highest-iv-sum").innerHTML = stats.highest_iv_sum
});

ipcRenderer.on('game', (event, game) => {
    document.getElementById("map-header").innerHTML = game.map_name + " (" + game.map_header.toString() + ")"
    document.getElementById("position").innerHTML = game.trainer_x.toString() + ", " + game.trainer_y.toString() + ", " + game.trainer_z.toString()
    document.getElementById("phenomenon").innerHTML = game.phenomenon_x.toString() + ", --, " + game.phenomenon_z.toString()
});