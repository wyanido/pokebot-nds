const { ipcRenderer } = require('electron')
const YAML = require('yaml');

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
});

ipcRenderer.on('set_config', (_event, config) => {
    original_config = config

    // Text areas
    text_areas = ["target_traits", "pokeball_priority", "pokeball_override"]

    for (var i = 0; i < text_areas.length; i++) {
        var key = text_areas[i]
        $("#" + key).val(YAML.stringify(config[key]))
    }

    // Fields
    fields = ["mode", "move_direction", "pickup_threshold", "encounter_log_limit"]

    for (var i = 0; i < fields.length; i++) {
        field = fields[i]
        $("#" + field).val(config[field])
    }

    // Checkboxes
    checkboxes = ["starter0", "starter1", "starter2", "battle_non_targets", "cycle_lead_pokemon", "auto_catch", "save_game_after_catch", "save_game_on_start", "thief_wild_items", "pickup"]

    for (var i = 0; i < checkboxes.length; i++) {
        field = checkboxes[i]
        $("#" + field).prop('checked', config[field]);
    }

    $("#config-form").removeAttr('disabled')
});

function sendConfig() {
    config = original_config

    // Edit the original config file with new values
    text_areas = ["target_traits", "pokeball_priority", "pokeball_override"]
    var current_ta = 0

    try {
        for (var i = 0; i < text_areas.length; i++) {
            var key = text_areas[i]
            config[key] = YAML.parse($("#" + key).val())
        }
    }
    catch (e) {
        halfmoon.initStickyAlert({
            content: e,
            title: "Changes not saved",
            alertType: "alert-danger",
        })
        return
    }

    fields = ["mode", "move_direction", "pickup_threshold", "encounter_log_limit"]

    for (var i = 0; i < fields.length; i++) {
        field = fields[i]
        config[field] = $("#" + field).val()
    }

    checkboxes = ["starter0", "starter1", "starter2", "battle_non_targets", "cycle_lead_pokemon", "save_game_after_catch", "save_game_on_start", "auto_catch", "thief_wild_items", "pickup"]

    for (var i = 0; i < checkboxes.length; i++) {
        field = checkboxes[i]
        config[field] = $("#" + field).prop('checked')
    }

    ipcRenderer.send('apply_config', config);
    
    halfmoon.initStickyAlert({
        content: "You may need to restart pokebot-nds.lua for the bot mode to update immediately. Other changes will take effect now.",
        title: "Changes saved!",
        alertType: "alert-success",
    })

}

original_config = ""

// Allow tab indentation in textareas
var textareas = document.getElementsByTagName('textarea');
var count = textareas.length;
for (var i = 0; i < count; i++) {
    textareas[i].onkeydown = function (e) {
        if (e.key == "Tab") {
            e.preventDefault();
            var s = this.selectionStart;
            this.value = this.value.substring(0, this.selectionStart) + "  " + this.value.substring(this.selectionEnd);
            this.selectionEnd = s + 2;
        }
    }
}

// Ctrl + S shortcut
document.addEventListener('keydown', function(event) {
    if (event.ctrlKey && event.key === 's') {
      event.preventDefault();
      sendConfig();
    }
  });
  