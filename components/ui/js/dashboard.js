
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

var template_header = `
    <tr>
        <th></th>
        <th></th>
        <th></th>
        <th>HP</th>
        <th>ATK</th>
        <th>DEF</th>
        <th>SP.A</th>
        <th>SP.D</th>
        <th>SPD</th>
        <th></th>
        <th>Shiny Value</th>
        <th>Shiny?</th>
    </tr>
`
var template = `
    <tr>
        <td>
            <img class="sprite" src="icons/mon/Ani000MS.png">
        </td>
        <td>
            <img src="icons/{gender}.png">
        </td>
        <td style="font-size:30px">
            Lv.{level}   
        </td>
        <td class="{hpn}">{hp}</td>
        <td class="{akn}">{atk}</td>
        <td class="{dfn}">{def}</td>
        <td class="{san}">{spatk}</td>
        <td class="{sdn}">{spdef}</td>
        <td class="{spn}">{speed}</td>
        <td>={sum}</td>
        <td>{sv}</td>
        <td style="font-size:30px">
            {shiny}
        </td>
    </tr>`

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
            var tr = template_header
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
                    row = row.replace("{sum}", mon.hpIV + mon.attackIV + mon.defenseIV + mon.spAttackIV + mon.spDefenseIV + mon.speedIV);
                    
                    if (mon.loweredStat == mon.raisedStat) {
                        row = row.replace("{hpn}", "neutralStat");
                        row = row.replace("{akn}", "neutralStat");
                        row = row.replace("{dfn}", "neutralStat");
                        row = row.replace("{san}", "neutralStat");
                        row = row.replace("{sdn}", "neutralStat");
                        row = row.replace("{spn}", "neutralStat");
                    } else {
                        row = row.replace("{hpn}", (mon.raisedStat == "HP") ? "raisedStat" : "{hpn}");
                        row = row.replace("{akn}", (mon.raisedStat == "Attack") ? "raisedStat" : "{akn}");
                        row = row.replace("{dfn}", (mon.raisedStat == "Defense") ? "raisedStat" : "{dfn}");
                        row = row.replace("{san}", (mon.raisedStat == "Sp. Attack") ? "raisedStat" : "{san}");
                        row = row.replace("{sdn}", (mon.raisedStat == "Sp. Defense") ? "raisedStat" : "{sdn}");
                        row = row.replace("{spn}", (mon.raisedStat == "Speed") ? "raisedStat" : "{spn}");

                        row = row.replace("{hpn}", (mon.loweredStat == "HP") ? "loweredStat" : "neutralStat");
                        row = row.replace("{akn}", (mon.loweredStat == "Attack") ? "loweredStat" : "neutralStat");
                        row = row.replace("{dfn}", (mon.loweredStat == "Defense") ? "loweredStat" : "neutralStat");
                        row = row.replace("{san}", (mon.loweredStat == "Sp. Attack") ? "loweredStat" : "neutralStat");
                        row = row.replace("{sdn}", (mon.loweredStat == "Sp. Defense") ? "loweredStat" : "neutralStat");
                        row = row.replace("{spn}", (mon.loweredStat == "Speed") ? "loweredStat" : "neutralStat");
                    }

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