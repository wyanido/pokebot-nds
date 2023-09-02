
<script setup lang="ts">
import './scss/styles.scss'

import { Tooltip, Toast, Popover } from 'bootstrap';
</script>

<template>
  <nav class="navbar sticky-top navbar-dark bg-dark navbar-expand">
    <div class="navbar-brand">
      <img src="./assets/pokemon-icon/201-27.png" width="30" height="30" class="d-inline-block align-top" id="icon">
      Pokébot NDS
      <span class="navbar-text fs-6">v0.4.0-alpha</span>
    </div>
    <div class="collapse navbar-collapse" id="navbarNavAltMarkup">
      <div class="navbar-nav">
        <a class="nav-item nav-link" href="#">
          <button class="btn active" type="button">
            <font-awesome-icon icon="fa-solid fa-user-circle" />
            Dashboard
          </button>
        </a>
        <a class="nav-item nav-link" href="#">
          <button class="btn active" type="button">
            <font-awesome-icon icon="fa-solid fa-gear" />
            Config
          </button>
        </a>
        <a class="nav-item nav-link disabled" href="#">
          <button class="btn active" type="button">
            <font-awesome-icon icon="fa-solid fa-wrench" />
            Tools
          </button>
        </a>
      </div>
    </div>
  </nav>
  <div class="container mt-4">
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
            <div class="col-6 text-center">
              Encounter Rate: <span id="encounter-rate" class="badge text-bg-secondary">0/h</span>
            </div>
            <br><br>
            <div class="col-6">
              <h2 class="card-title text-center h4">Total</h2>
              <table class="table">
                <tr>
                  <th>Seen</th>
                  <td id="total-seen"></td>
                </tr>
                <tr>
                  <th>Shiny</th>
                  <td id="total-shiny"></td>
                </tr>
                <tr>
                  <th>IVs</th>
                  <td class="text-nowrap">
                    <i class="fa fa-arrow-circle-up"></i>
                    <span id="total-max-iv" style="margin-right: 10px"></span>
                    <i class="fa fa-arrow-circle-down"></i>
                    <span id="total-min-iv"></span>
                  </td>
                </tr>
              </table>
            </div>
            <div class="col-6">
              <h2 class="card-title text-center h4">Target Phase</h2>
              <table class="table">
                <tr>
                  <th>Seen</th>
                  <td id="phase-seen"></td>
                </tr>
                <tr>
                  <th>Lowest SV</th>
                  <td id="phase-lowest-sv"></td>
                </tr>
                <tr>
                  <th>B(n,p)
                    <div class="input-group">
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
      <div class="position-absolute w-100 text-center h4">Recently Seen</div>
      <div class="input-group" style="width: 160px">
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
      <div class="position-absolute w-100 text-center h4">Recent Targets</div>
      <div class="input-group" style="width: 160px">
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
</template>
