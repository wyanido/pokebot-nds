<template>
  <nav class="navbar sticky-top navbar-dark navbar-expand bg-dark">
    <div class="navbar-brand">
      <img src="./assets/pokemon-icon/201-27.png" width="26" height="26" class="d-inline m-2" id="icon">
      <span class="align-middle h5">Pokébot NDS</span>
      <span class="navbar-text m-3" style="font-size: 14px">v0.5.0-alpha</span>
    </div>
    <div class="collapse navbar-collapse" id="navbarNavAltMarkup">
      <div class="navbar-nav">
        <a class="nav-item nav-link" href="/">
          <button class="btn active" type="button">
            <font-awesome-icon icon="fa-solid fa-user-circle" style="margin-right: 5px;" />
            Dashboard
          </button>
        </a>
        <a class="nav-item nav-link" href="/config">
          <button class="btn active selected" type="button">
            <font-awesome-icon icon="fa-solid fa-gear" style="margin-right: 5px;" />
            Config
          </button>
        </a>
        <a class="nav-item nav-link disabled" href="#">
          <button class="btn active" type="button">
            <font-awesome-icon icon="fa-solid fa-wrench" style="margin-right: 5px;" />
            Tools
          </button>
        </a>
      </div>
    </div>
  </nav>
  <fieldset class="row mt-4 px-5" id="config-control" disabled>
    <div class="col-6">
      <div class="input-group" style="width: 400px; margin-right:0px !important">
        <label class="input-group-text">Editing config for</label>
        <select class="form-control" id="editing">
          <option value="all">All Games</option>
        </select>
      </div>
    </div>
    <div class="col-6">
      <button class="btn btn-primary" style="float: right;" id="post-config" onclick="sendConfig()">
        <font-awesome-icon icon="fa-solid fa-save" style="margin-left: 5px;" />
        Save Changes (CTRL+S)
      </button>
    </div>
  </fieldset>
  <div class="container-fluid mt-4 px-5">
    <div class="col">
      <fieldset class="row" id="config-form" disabled>
        <div class="col-6">
          <div class="card p-4">
            <h4 class="content-title">Primary</h4>
            <div class="form-check">
              <input class="form-check-input" type="checkbox" id="save_game_on_start">
              <label class="form-check-label" for="save_game_on_start">Save game on start</label>
            </div>
            <br>
            <label class="form-label" for="mode">Bot Behaviour</label>
            <select class="form-control" id="mode">
              <option value="manual">Manual</option>
              <option disabled>-- Soft Resets</option>
              <option value="starters">Starters</option>
              <option value="gift">Gift Pokémon</option>
              <option value="static_encounters">Static Encounters</option>
              <option disabled>-- Standard</option>
              <option value="random_encounters">Random Encounters</option>
              <option value="phenomenon_encounters">Phenomenon Encounters</option>
              <option value="fishing">Fishing</option>
              <option value="daycare_eggs">Collect & Hatch Eggs</option>
              <option disabled>-- Misc</option>
              <option value="voltorb_flip">Voltorb Flip</option>
            </select>
            <div id="option_moving_encounters">
              <br>
              <label class="form-label" for="move_direction">Move Direction</label>
              <select class="form-control" id="move_direction">
                <option value="Horizontal">Horizontal</option>
                <option value="Vertical">Vertical</option>
              </select>
            </div>
            <div id="option_starters">
              <br>
              <label class="form-label" for="starters">Target Starters
                <font-awesome-icon icon="fa-solid fa-info-circle" style="margin: 0 5px;" data-bs-toggle="tooltip"
                  data-bs-placement="top" data-bs-title="The bot will choose all selected starters an equal number of times, cycling through them in order." />
              </label>
              <div id="starters">
                <div class="form-check">
                  <input class="form-check-input" type="checkbox" id="starter0">
                  <label class="form-check-label" for="starter0">Turtwig/Snivy</label>
                </div>
                <br>
                <div class="form-check">
                  <input class="form-check-input" type="checkbox" id="starter1">
                  <label class="form-check-label" for="starter1">Chimchar/Tepig</label>
                </div>
                <br>
                <div class="form-check">
                  <input class="form-check-input" type="checkbox" id="starter2">
                  <label class="form-check-label" for="starter2">Piplup/Oshawott</label>
                </div>
              </div>
            </div>
          </div>
          <div class="card p-4 mt-3">
            <h4 class="content-title">Target Pokémon</h4>
            <label class="form-label" for="catch">Target traits
              <font-awesome-icon icon="fa-solid fa-info-circle" style="margin: 0 5px;" data-bs-toggle="tooltip"
                data-bs-placement="top" data-bs-title="YAML format. Specifies all traits a Pokémon must meet in order to be a target. If 'shiny: true' is specified, the bot will catch all shinies. Otherwise, the Pokémon must match all specified traits. For multiple items in a list, only one needs to be matched." />
            </label>
            <textarea class="form-control" spellcheck="false" style="min-width:120px; max-width:100%; height: 120px;"
              id="target_traits" placeholder=""></textarea>
            <br>
            <div class="form-check">
              <input class="form-check-input" type="checkbox" id="save_game_after_catch">
              <label class="form-check-label" for="save_game_after_catch">Save game after obtaining a target</label>
            </div>
          </div>
          <div class="card p-4 mt-3">
            <h4 class="content-title">Logging</h4>
            <label class="form-label" for="encounter_log_limit">Encounter Log Limit</label>
            <input id="encounter_log_limit" min="1" type="number" class="form-control" placeholder="30">
            <br>
            <label class="form-label" for="target_log_limit">Target Log Limit</label>
            <input id="target_log_limit" min="1" type="number" class="form-control" placeholder="30">
          </div>
          <div class="card p-4 mt-3">
            <h4 class="content-title">Other</h4>
            <div class="form-check">
              <input class="form-check-input" type="checkbox" id="hax">
              <label class="form-check-label" for="hax">Use hax for faster resets
                <font-awesome-icon icon="fa-solid fa-info-circle" style="margin: 0 5px;" data-bs-toggle="tooltip"
                data-bs-placement="top" data-bs-title="Soft reset earlier than humanly possible by reading Pokémon data from RAM as soon as it is accessible." />
              </label>
            </div>
            <br>
            <div class="form-check">
              <input class="form-check-input" type="checkbox" id="debug">
              <label class="form-check-label" for="debug">Debug mode
                <font-awesome-icon icon="fa-solid fa-info-circle" style="margin: 0 5px;" data-bs-toggle="tooltip"
                data-bs-placement="top" data-bs-title="Outputs extra info to the Lua Console. Useful if you need to troubleshoot an issue." />
              </label>
            </div>
            <br>
            <label class="form-label" for="inactive_client_timeout">Inactive game timeout (ms)</label>
            <input id="inactive_client_timeout" min="1000" type="number" class="form-control" placeholder="2500">
            <br>
            <label class="form-label" for="game_refresh_cooldown">Game info refresh cooldown (ms)</label>
            <input id="game_refresh_cooldown" min="1" type="number" class="form-control" placeholder="200">
          </div>
        </div>
        <div class="col-6">
          <div class="card p-4">
            <h4 class="content-title">Wild Battles</h4>
            <div class="form-check">
              <input class="form-check-input" type="checkbox" id="battle_non_targets">
              <label class="form-check-label" for="battle_non_targets">Defeat non-targets</label>
            </div>
            <br>
            <div class="form-check">
              <input class="form-check-input" type="checkbox" id="cycle_lead_pokemon">
              <label class="form-check-label" for="cycle_lead_pokemon">Replace lead Pokémon when exhausted</label>
            </div>
            <br>
            <div class="form-check">
              <input class="form-check-input" type="checkbox" id="thief_wild_items">
              <label class="form-check-label" for="thief_wild_items">Use Thief to steal held items</label>
            </div>
            <br>
            <h4 class="content-title">Auto-Catch</h4>
            <div class="form-check">
              <input class="form-check-input" type="checkbox" id="auto_catch">
              <label class="form-check-label" for="auto_catch">Auto-catch wild targets</label>
            </div>
            <div id="option_auto_catch">
              <br>
              <div class="form-check">
                <input class="form-check-input" type="checkbox" id="false_swipe">
                <label class="form-check-label" for="false_swipe">Use False Swipe</label>
              </div>
              <br>
              <div class="form-check">
                <input class="form-check-input" type="checkbox" id="inflict_status">
                <label class="form-check-label" for="inflict_status">Inflict sleep/paralysis</label>
              </div>
              <br>
              <label class="form-label" for="pokeball_priority">Poké Ball priority
                <font-awesome-icon icon="fa-solid fa-info-circle" style="margin: 0 5px;" data-bs-toggle="tooltip"
                data-bs-placement="top" data-bs-title="YAML format list. Specifies the preferred Poké Ball type for the bot to use when catching a target from highest to lowest priority." />
              </label>
              <textarea class="form-control" spellcheck="false" style="min-width:120px; max-width:100%; height: 140px;"
                id="pokeball_priority" placeholder=""></textarea>
              <br>
              <label class="form-label" for="pokeball_override">Poké Ball override
                <font-awesome-icon icon="fa-solid fa-info-circle" style="margin: 0 5px;" data-bs-toggle="tooltip"
                data-bs-placement="top" data-bs-title="YAML format. Specifies the target traits per Poké Ball type the bot will check for in order to use. Traits must always be in a list. Takes priority over Poké Ball priority" />
              </label>
              <textarea class="form-control" spellcheck="false" style="min-width:120px; max-width:100%; height: 260px;"
                id="pokeball_override" placeholder=""></textarea>
            </div>
          </div>
          <div class="card p-4 mt-3">
            <h4 class="content-title">Pickup</h4>
            <div class="form-check">
              <input class="form-check-input" type="checkbox" id="pickup">
              <label class="form-check-label" for="pickup">Collect Pickup items from party</label>
            </div>
            <br>
            <label class="form-label" for="pickup_threshold">Pickup threshold
              <font-awesome-icon icon="fa-solid fa-info-circle" style="margin: 0 5px;" data-bs-toggle="tooltip"
                data-bs-placement="top" data-bs-title="Number of party Pickup Pokémon that must hold an item before collection." />
            </label>
            <input id="pickup_threshold" style="width:100px" min="1" max="6" type="number" class="form-control">
          </div>
        </div>
      </fieldset>
    </div>
  </div>
  <br>
</template>

<script setup lang="ts">
import { Tooltip } from 'bootstrap';
import 'bootstrap/scss/bootstrap.scss';
import './components/style.css';

</script>

<script lang="ts">
import YAML from 'yaml';

function populateConfigFields(config) {
  const configForm = document.getElementById('config-form');
  const textAreas = [...configForm.getElementsByTagName('textarea')].map(ele => ele.id);
  const fields = [...configForm.querySelectorAll('input[type="number"], select')].map(ele => ele.id);
  const checkboxes = [...configForm.querySelectorAll('input[type="checkbox"]')].map(ele => ele.id);

  for (var i = 0; i < textAreas.length; i++) {
    const key = textAreas[i]
    $('#' + key).val(YAML.stringify(config[key]))
  }

  for (var i = 0; i < fields.length; i++) {
    const field = fields[i]
    $('#' + field).val(config[field])
  }

  for (var i = 0; i < checkboxes.length; i++) {
    const field = checkboxes[i]
    $('#' + field).prop('checked', config[field]);
  }

  $('#config-control').removeAttr('disabled')
  $('#config-form').removeAttr('disabled')
}

export default {
  name: 'Config',
  mounted() {
    this.fetchConfig();

    const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]')
    const tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl => new Tooltip(tooltipTriggerEl))
  },
  methods: {
    async fetchConfig() {
      try {
        const response = await window.__TAURI__.invoke('return_config');
        const config = JSON.parse(response);

        console.log(config);

        populateConfigFields(config);
      } catch (error) {
        console.error(error);
      }
    },
  },
};

</script>