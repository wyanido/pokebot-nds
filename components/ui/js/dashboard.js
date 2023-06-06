
function stats_info() {
    $.ajax({
            method: "GET",
            url: "http://127.0.0.1:6969/totals",
            crossDomain: true,
            dataType: "json",
            format: "json",
            timeout: 50
        })
        .done(function(totals) {
            var iv_sum = totals["totals"]["highest_iv_sum"]
            
            $("#total_encounters").text(totals["totals"]["encounters"].toLocaleString());
            $("#highest_iv_sum").text(iv_sum.toLocaleString() + "(" + Math.round((iv_sum / 186) * 100).toString() + "% Perfect)");
            $("#lowest_sv").text(totals["totals"]["lowest_sv"].toLocaleString() + " (<8 is shiny)");
        })
}

template = '<tr><td><img class="sprite" src="icons/mon/Ani000MS.png"></td><td><img src="icons/{gender}.png"></td><td style="font-size:30px">Lv.{level}   </td><td>{hp}</td><td>{atk}</td><td>{def}</td><td>{spatk}</td><td>{spdef}</td><td>{speed}</td><td>{sv}</td><td style="font-size:30px">{shiny}</td></tr>'

function encounter_log() {
    $.ajax({
            method: "GET",
            url: "http://127.0.0.1:6969/encounters",
            crossDomain: true,
            dataType: "json",
            format: "json",
            timeout: 50
        })
        .done(function(encounter_log) {
            var tr = '<tr><th></th><th></th><th></th><th>HP</th><th>ATK</th><th>DEF</th><th>SP.A</th><th>SP.D</th><th>SPD</th><th>Shiny Value</th><th>Shiny?</th></tr>'
            var wrapper = document.getElementById("encounters");
            
            reverse_encounter_log = encounter_log["encounters"].reverse()

            for (var i = 0; i < 7; i++) {
                if (reverse_encounter_log[i]) {
                    mon = reverse_encounter_log[i]

                    row = template.replace("000", mon.species);
                    row = row.replace("{gender}", mon.gender.toLowerCase());
                    row = row.replace("{level}", mon.level);
                    // row = row.replace("{ability}", mon.ability);
                    row = row.replace("{hp}", mon.hpIV);
                    row = row.replace("{atk}", mon.attackIV);
                    row = row.replace("{def}", mon.defenseIV);
                    row = row.replace("{spatk}", mon.spAttackIV);
                    row = row.replace("{spdef}", mon.spDefenseIV);
                    row = row.replace("{speed}", mon.speedIV);
                    row = row.replace("{sv}", mon.shinyValue);

                    if (mon.shiny) {
                        row = row.replace("{shiny}", "✅");
                    } else {
                         row = row.replace("{shiny}", "❌");
                    }
                    
                    tr += row;
                }
            }

            wrapper.innerHTML = tr
        })
}

window.setInterval(function() {
    encounter_log();
}, 1000);

window.setInterval(function() {
    stats_info();
}, 250);

stats_info();
encounter_log();