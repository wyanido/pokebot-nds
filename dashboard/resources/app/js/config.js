const { ipcRenderer } = require('electron')
const YAML = require('yaml');

const text_areas = [...document.getElementsByTagName('textarea')].map(ele => ele.id);
const fields = [...document.querySelectorAll('input[type="number"], select')].map(ele => ele.id);
const checkboxes = [...document.querySelectorAll('input[type="checkbox"]')].map(ele => ele.id);

var original_config = ''

function sendConfig() {
    config = original_config

    try {
        for (var i = 0; i < text_areas.length; i++) {
            var key = text_areas[i]
            config[key] = YAML.parse($('#' + key).val())
        }
    }
    catch (e) {
        halfmoon.initStickyAlert({
            content: e,
            title: 'Changes not saved',
            alertType: 'alert-danger',
        })
        return
    }

    for (var i = 0; i < fields.length; i++) {
        field = fields[i]
        config[field] = $('#' + field).val()
    }

    for (var i = 0; i < checkboxes.length; i++) {
        field = checkboxes[i]
        config[field] = $('#' + field).prop('checked')
    }

    ipcRenderer.send('apply_config', config);

    halfmoon.initStickyAlert({
        content: 'You may need to restart pokebot-nds.lua for the bot mode to update immediately. Other changes will take effect now.',
        title: 'Changes saved!',
        alertType: 'alert-success',
    })

}

function updateOptionVisibility() {
    $('#option_starters').hide()
    $('#option_move_direction').hide()
    $('#option_auto_catch').hide()

    var mode = $('#mode').val()
    switch (mode) {
        case 'starters':
            $('#option_starters').show()
            break;
        case 'random encounters':
            $('#option_move_direction').show()
            break;
    }

    if ($('#auto_catch').prop('checked')) {
        $('#option_auto_catch').show()
    }
}

// Hide values not relevant to the current bot mode
const form = document.querySelector('fieldset');
form.addEventListener('change', function () {
    updateOptionVisibility()
});

// Allow tab indentation in textareas
const textareas = document.getElementsByTagName('textarea');
const count = textareas.length;
for (var i = 0; i < count; i++) {
    textareas[i].onkeydown = function (e) {
        if (e.key == 'Tab') {
            e.preventDefault();
            var s = this.selectionStart;
            this.value = this.value.substring(0, this.selectionStart) + '  ' + this.value.substring(this.selectionEnd);
            this.selectionEnd = s + 2;
        }
    }
}

// Ctrl + S shortcut
document.addEventListener('keydown', function (event) {
    if (event.ctrlKey && event.key === 's') {
        event.preventDefault();
        sendConfig();
    }
});

ipcRenderer.on('set_config', (_event, config) => {
    original_config = config

    for (var i = 0; i < text_areas.length; i++) {
        var key = text_areas[i]
        $('#' + key).val(YAML.stringify(config[key]))
    }

    for (var i = 0; i < fields.length; i++) {
        field = fields[i]
        $('#' + field).val(config[field])
    }

    for (var i = 0; i < checkboxes.length; i++) {
        field = checkboxes[i]
        $('#' + field).prop('checked', config[field]);
    }

    $('#config-form').removeAttr('disabled')
    updateOptionVisibility()
});

ipcRenderer.on('set_page_icon', (_event, icon_src) => {
    document.getElementById('icon').src = icon_src
});