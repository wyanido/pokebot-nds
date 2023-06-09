
// function stats_info() {
//     $.ajax({
//             method: "GET",
//             url: "http://127.0.0.1:6969/totals",
//             crossDomain: true,
//             dataType: "json",
//             format: "json",
//             timeout: 50
//         })
//         .done(function(totals) {
//             var iv_sum = totals["highest_iv_sum"]

//             $("#total_encounters").text(totals["encounters"].toLocaleString());
//             $("#highest_iv_sum").text(iv_sum.toLocaleString() + "(" + Math.round((iv_sum / 186) * 100).toString() + "% Perfect)");
//             $("#lowest_sv").text(totals["lowest_sv"].toLocaleString() + " (<8 is shiny)");
//         })
// }

function hev_reverse(hex) {
    return hex.match(/[a-fA-F0-9]{2}/g).reverse().join('').padEnd(8, '0');
}

function party() {
    $.ajax({
            method: "GET",
            url: "http://127.0.0.1:55056/party",
            crossDomain: true,
            dataType: "json",
            format: "json",
            timeout: 50
        })
        .done(function(party) {
            var template = $("#party-template");
            
            for (var i = 0; i < 6; i++) {
                if (party[i]) {
                    var partyID = "#party-" + (i + 1).toString()

                    mon = party[i]

                    var partyMonData = {
                        species: mon.species,
                        gender: mon.gender.toLowerCase(),
                        name: mon.name,
                        level: mon.level,
                        ability: mon.ability,
                        item: mon.heldItem,
                        nature: mon.nature,
                        hpIV: mon.hpIV,
                        attackIV: mon.attackIV,
                        defenseIV: mon.defenseIV,
                        spAttackIV: mon.spAttackIV,
                        spDefenseIV: mon.spDefenseIV,
                        speedIV: mon.speedIV,
                        pid: hev_reverse(mon.pid.toString(16).toUpperCase()),
                    };

                    var newTableRow = template.tmpl(partyMonData);
                    $(partyID).empty();
                    $(partyID).append(newTableRow)
                }
            }
        })
}

function recent_encounters() {
    $.ajax({
            method: "GET",
            url: "http://127.0.0.1:55056/encounters",
            crossDomain: true,
            dataType: "json",
            format: "json",
            timeout: 50
        })
        .done(function(encounter_log) {
            // Don't update list if data is the same
            if (encounter_log["hash"] == previous_hash) {
                return
            }
            
            previous_hash = encounter_log["hash"]

            var template = $("#row-template");
            var recents = $("#recents")
            $("#recents tr").empty();

            reverse_encounter_log = encounter_log["encounters"].reverse()

            for (var i = 0; i < 7; i++) {
                if (reverse_encounter_log[i]) {
                    mon = reverse_encounter_log[i]
                    
                    var newRowData = {
                        species: mon.species,
                        gender: mon.gender.toLowerCase(),
                        level: mon.level,
                        ability: mon.ability,
                        item: mon.heldItem,
                        nature: mon.nature,
                        hpIV: mon.hpIV,
                        attackIV: mon.attackIV,
                        defenseIV: mon.defenseIV,
                        spAttackIV: mon.spAttackIV,
                        spDefenseIV: mon.spDefenseIV,
                        speedIV: mon.speedIV,
                        pid: hev_reverse(mon.pid.toString(16).toUpperCase()),
                        shinyValue: mon.shinyValue,
                        shiny: mon.shiny ? "✅" : "❌"
                    };

                    var newTableRow = template.tmpl(newRowData);

                    recents.append(newTableRow)
                }
            }
        })
}

var previous_hash = ""

window.setInterval(function() {
    recent_encounters();
    party();
}, 250);

// window.setInterval(function() {
//     stats_info();
// }, 250);
