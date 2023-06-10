import os
import json
import time
import logging
from threading import Thread, Event
# HTTP server/interface modules         
from flask import Flask, abort, jsonify, request
from flask_cors import CORS
import common
import webview

ENCOUNTER_LOG_LIMIT = 20

# Values not relevant to the encounter log
# Gets trimmed before the dict is appended
excess_keys = [
    "nickname",
    "hpEV"
    "attackEV", 
    "defenseEV", 
    "spAttackEV",
    "spDefenseEV",
    "speedEV",
    "dreamWorldAbility", 
    "friendship",
    "isEgg",
    "isNicknamed",
    "otLanguage",
    "otName",
    "pokeball",
    "pokerus",
    "ppUps",
    "status"
]

def log_encounter(pokemon: dict):
    # Statistics
    global record_ivSum, record_shinyValue, record_encounters, encounters

    if pokemon is None:
        print("Tried to log null Pokemon!")
        return

    iv_sum = pokemon["hpIV"] + pokemon["attackIV"] + pokemon["defenseIV"] + pokemon["spAttackIV"] + pokemon["spDefenseIV"] + pokemon["speedIV"]

    totals["highest_iv_sum"]        = iv_sum if totals["highest_iv_sum"] == None else max(totals["highest_iv_sum"], iv_sum)
    totals["lowest_sv"]   = pokemon["shinyValue"] if totals["lowest_sv"] == None else min(totals["lowest_sv"], pokemon["shinyValue"])
    totals["encounters"]   += 1

    print("--------------")
    print(f"Seen Pokemon #{totals['encounters']}: a {pokemon['nature']} {pokemon['name']}!")
    print(f"HP: {pokemon['hpIV']}, ATK: {pokemon['attackIV']}, DEF: {pokemon['defenseIV']}, SP.ATK: {pokemon['spAttackIV']}, SP.DEF: {pokemon['spDefenseIV']}, SPD: {pokemon['speedIV']}")
    print(f"Shiny Value: {pokemon['shinyValue']}, Shiny?: {str(pokemon['shiny'])}")
    print("")
    print(f"Highest IV sum: {totals['highest_iv_sum']}")
    print(f"Lowest shiny value: {totals['lowest_sv']}")
    print("--------------")
    
    for key in excess_keys:
        pokemon.pop(key, None)

    encounters["encounters"].append(pokemon)
    encounters["encounters"] = encounters["encounters"][-ENCOUNTER_LOG_LIMIT:]

    write_file("stats/totals.json", json.dumps(totals, indent=4, sort_keys=True)) # Save stats file
    write_file("stats/encounters.json", json.dumps(encounters, indent=4, sort_keys=True)) # Save encounter log file

@staticmethod
def read_file(file: str):
    if os.path.exists(file):
        with open(file, mode="r", encoding="utf-8") as open_file:
            return open_file.read()
    else:
        return False

@staticmethod
def write_file(file: str, value: str):
    dirname = os.path.dirname(file)
    if not os.path.exists(dirname):
        os.makedirs(dirname)

    with open(file, mode="w", encoding="utf-8") as save_file:
        save_file.write(value)
        return True

# Run HTTP server to make data available via HTTP GET
def httpServer():
    log = logging.getLogger('werkzeug')
    log.setLevel(logging.ERROR)

    server = Flask(__name__)
    CORS(server)

    @server.route('/totals', methods=['GET'])
    def req_stats():
        if totals:
            response = jsonify(totals)
            return response
        
        abort(204)
    @server.route('/encounters', methods=['GET'])
    def req_encounters():
        global encounters_hash
        if encounters:
            # Compare with the last encounter list; don't send repeat data
            while True:
                new_hash = hash(json.dumps(encounters, sort_keys=True).encode())

                if encounters_hash != new_hash:
                    break

                time.sleep(0.16)

            encounters_hash = new_hash
            
            # print("enc: " + str(encounters_hash))

            response = jsonify(encounters)
            return response
        else:
            abort(503)
    @server.route('/party', methods=['GET'])
    def req_party():
        global party_hash
        if common.party_info:
            # Compare with the last encounter list; don't send repeat data
            while True:
                new_hash = hash(json.dumps(common.party_info, sort_keys=True))

                if party_hash != new_hash:
                    break

                time.sleep(1)

            party_hash = new_hash
            
            # print("party: " + str(party_hash))

            response = jsonify(common.party_info)
            return response
        else:
            abort(503)
    server.run(debug=False, threaded=True, host="127.0.0.1", port=55056)

def dashboard_init():
    def on_window_close():
        print("Dashboard closed on user input")
        os._exit(1)

    window = webview.create_window("PokeBot Gen V", url="../ui/dashboard.html", width=1280, height=720, resizable=True, hidden=False, frameless=False, easy_drag=True, fullscreen=False, text_select=True, zoomable=True)
    window.events.closed += on_window_close

    webview.start()

os.makedirs("stats", exist_ok=True) # Sets up stats files if they don't exist

encounters_hash = ""
party_hash = ""

file = read_file("stats/totals.json")
totals = json.loads(file) if file else {
    "highest_iv_sum": 0, 
    "lowest_sv": 65535, 
    "encounters": 0, 
}

file = read_file("stats/encounters.json")
encounters = json.loads(file) if file else { "encounters": [] }

record_shinyValue = None
record_ivSum = None
record_encounters = 0

http_server = Thread(target=httpServer)
http_server.start()
