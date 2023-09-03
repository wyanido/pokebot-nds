<template>
  <nav class="navbar sticky-top navbar-dark navbar-expand bg-dark">
    <div class="navbar-brand">
      <img src="./assets/pokemon-icon/201-27.png" width="26" height="26" class="d-inline m-2" id="icon">
      <span class="align-middle h5">Pokébot NDS</span>
      <span class="navbar-text m-3" style="font-size: 14px">v0.5.0-alpha</span>
    </div>
    <div class="collapse navbar-collapse" id="navbarNavAltMarkup">
      <div class="navbar-nav">
        <a class="nav-item nav-link" href="#">
          <button class="btn active selected" type="button">
            <font-awesome-icon icon="fa-solid fa-user-circle" style="margin-right: 5px;" />
            Dashboard
          </button>
        </a>
        <a class="nav-item nav-link" href="/config">
          <button class="btn active" type="button">
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
  <div class="container-fluid mt-4 px-5">
    <div class="row">
      <div class="col-6">
        <div class="card p-3">
          <div id="game-buttons" class="btn-group w-full" role="group"></div>
          <div id="game-party"></div>
          <div id="game-info"></div>
        </div>
      </div>
      <div class="col-6">
        <div class="card p-3">
          <div class="row">
            <div class="col-6 text-center">
              Elapsed: <span id="elapsed-time" class="badge text-bg-secondary">0s</span>
            </div>
            <div class="col-6 text-center text-nowrap">
              Encounter Rate: <span id="encounter-rate" class="badge text-bg-secondary">0/h</span>
            </div>
            <br><br>
            <div class="col-6" style="padding-right: 0">
              <h4 class="text-center">Total</h4>
              <table class="table">
                <tr>
                  <th>Seen</th>
                  <td id="total-seen"></td>
                </tr>
                <tr>
                  <th>Shiny</th>
                  <td id="total-shiny"></td>
                </tr>
                <tr style="border: none;">
                  <th>IVs</th>
                  <td class="text-nowrap">
                    <font-awesome-icon icon="fa-solid fa-arrow-circle-up" class="white-icon align-middle p-0" />
                    <span class="iv" id="total-max-iv"></span>
                    <font-awesome-icon icon="fa-solid fa-arrow-circle-down" class="white-icon align-middle p-0" />
                    <span class="iv" id="total-min-iv"></span>
                  </td>
                </tr>
              </table>
            </div>
            <div class="col-6" style="padding-left: 0">
              <h4 class="text-center">Target Phase</h4>
              <table class="table">
                <tr>
                  <th>Seen</th>
                  <td id="phase-seen"></td>
                </tr>
                <tr>
                  <th>Lowest SV</th>
                  <td id="phase-lowest-sv"></td>
                </tr>
                <tr style="border: none;">
                  <th>B(n,p)
                    <div class="input-group mt-2" style="width: 90px">
                      <label class="input-group-text">1/</label>
                      <input class="form-control" id="shiny-rate" min="1" value="8192">
                    </div>
                  </th>
                  <td id="bnp"></td>
                </tr>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="card p-3 mt-4">
      <h4 class="w-100 text-center mt-1 mb-3">Recently Seen</h4>
      <div class="input-group position-absolute" style="width: 140px">
        <label class="input-group-text">Show latest</label>
        <input class="form-control" id="recents-limit" min="1" type="number" value="5">
      </div>
      <table class="table">
        <thead>
          <tr>
            <th></th>
            <th></th>
            <th></th>
            <th class="text-center">Ability</th>
            <th class="text-center">Nature</th>
            <th class="text-center">PID</th>
            <th class="text-center">IVs</th>
            <th class="text-center">Shiny Value (SV)</th>
          </tr>
        </thead>
        <tbody id="recents">
        </tbody>
      </table>
    </div>
    <div class="card p-3 mt-4">
      <h4 class="w-100 text-center mt-1 mb-3">Recent Targets</h4>
      <div class="input-group position-absolute " style="width: 140px">
        <label class="input-group-text">Show latest</label>
        <input class="form-control" id="targets-limit" min="1" type="number" value="5">
      </div>
      <table class="table">
        <thead>
          <tr>
            <th></th>
            <th></th>
            <th></th>
            <th class="text-center">Ability</th>
            <th class="text-center">Nature</th>
            <th class="text-center">PID</th>
            <th class="text-center">IVs</th>
            <th class="text-center">Shiny Value (SV)</th>
          </tr>
        </thead>
        <tbody id="targets">
        </tbody>
      </table>
    </div>
  </div>
  <br>
</template>

<script setup lang="ts">
import 'bootstrap/scss/bootstrap.scss';
// import { Tooltip, Toast, Popover } from 'bootstrap';

import './components/style.css';
</script>