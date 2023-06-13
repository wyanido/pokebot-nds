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

            // console.log('Added new party member ', mon.name)
        }
    }
});

ipcRenderer.on('encounters', (event, encounters) => {
    var template = $("#row-template");
    var recents = $("#recents")
    
    $("#recents tr").empty();

    var reverse_log = encounters.reverse()
    
    for (var i = 0; i < 7; i++) {
        if (reverse_log[i]) {
            mon = reverse_log[i]
            
            mon.gender = mon.gender.toLowerCase()
            mon.pid = hex_reverse(mon.pid.toString(16).toUpperCase())
            mon.shiny = mon.shiny ? "✅" : "❌"
            // mon.rating = rating_stars(mon.rating)
            
            var newTableRow = template.tmpl(mon);
            recents.append(newTableRow)
        }
    }
});

ipcRenderer.on('stats', (event, stats) => {
    document.getElementById("encounters").innerHTML = stats.encounters
    document.getElementById("lowest-sv").innerHTML = stats.lowest_sv
    document.getElementById("highest-iv-sum").innerHTML = stats.highest_iv_sum
});

ipcRenderer.on('game', (event, game) => {
    document.getElementById("map-header").innerHTML = game.map_string
    document.getElementById("position").innerHTML = game.posX.toString() + ", " + game.posY.toString() + ", " + game.posZ.toString()
});