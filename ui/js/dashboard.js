
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

function rating_stars(rating) {
    switch (Math.floor(rating * 1.5)) {
        case 3: return "★★★☆"; break;
        case 2: return "★★☆☆"; break;
        case 1: return "★☆☆☆"; break;
        case 0: return "☆☆☆☆"; break;
        default: return "★★★★"; break;
    }
}

function longPoll_party() {
    $.ajax({
        method: "GET",
        url: "http://127.0.0.1:55056/party",
        crossDomain: true,
        dataType: "json",
        format: "json",
        timeout: 0,
        success: function(party) {
            var template = $("#party-template");
            
            $("#party div").empty();

            for (var i = 0; i < 6; i++) {
                if (party[i]) {
                    var partyID = "#party-" + (i + 1).toString()

                    mon = party[i]
                    mon.folder = mon.shiny ? "shiny/" : ""
                    mon.gender = mon.gender.toLowerCase()
                    mon.name = "(" + mon.name + ")"
                    mon.pid = hev_reverse(mon.pid.toString(16).toUpperCase())
                    mon.rating = rating_stars(mon.rating)

                    var newTableRow = template.tmpl(mon);
                    $(partyID).append(newTableRow)
                }
            }

            longPoll_party()
        },
        error: function(xhr, status, error) {
            longPoll_party();
        }
    });
}

function longPoll_encounters() {
    $.ajax({
        method: "GET",
        url: "http://127.0.0.1:55056/encounters",
        crossDomain: true,
        dataType: "json",
        format: "json",
        timeout: 0,
        success: function(encounter_log) {
            var template = $("#row-template");
            var recents = $("#recents")
            $("#recents tr").empty();

            reverse_encounter_log = encounter_log["encounters"].reverse()

            for (var i = 0; i < 7; i++) {
                if (reverse_encounter_log[i]) {
                    mon = reverse_encounter_log[i]

                    mon.gender = mon.gender.toLowerCase()
                    mon.pid = hev_reverse(mon.pid.toString(16).toUpperCase())
                    mon.shiny = mon.shiny ? "✅" : "❌"
                    mon.rating = rating_stars(mon.rating)

                    var newTableRow = template.tmpl(mon);
                    recents.append(newTableRow)
                }
            }

            longPoll_encounters()
        },
        error: function(xhr, status, error) {
            longPoll_encounters();
        }
    });
}

longPoll_encounters();
longPoll_party();