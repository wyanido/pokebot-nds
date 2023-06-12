import io
import os
import json
import mmap
import time
import logging
import traceback
from threading import Thread, Event
# HTTP server/interface modules         
from pokemon import enrich_mon_data
from flask import Flask, abort, jsonify, request
from flask_cors import CORS
import webview

port = 51055
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

@staticmethod
def load_json_mmap(size, file): 
    # BizHawk writes game information to memory mapped files every few frames (see pokebot.lua)
    # See https://tasvideos.org/Bizhawk/LuaFunctions (comm.mmfWrite)
    shmem = mmap.mmap(0, size, file)
    bytes_io = io.BytesIO(shmem)
    byte_str = bytes_io.read().decode('utf-8').split("\x00")[0]

    try:
        if byte_str != "":
            return json.loads(byte_str)
    except Exception as e:
        traceback.print_exc()
        print(byte_str)
        return False

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

def mem_get_encounter_info():
    global latest_encounter, seen_hash

    while True:
        try:
            while True:
                encounter_mmap = load_json_mmap(1024, "bizhawk_encounter")
                new_hash = hash(json.dumps(encounter_mmap, sort_keys=True).encode())

                if seen_hash != new_hash:
                    break

                time.sleep(1)

            if encounter_mmap:
                log_encounter(enrich_mon_data(encounter_mmap))
            
            seen_hash = new_hash
        except Exception as e:
            traceback.print_exc()
            pass

def mem_get_party_info():
    global party_info

    while True:
        try:
            party_info_mmap = load_json_mmap(8192, "bizhawk_party_info")

            if party_info_mmap:
                new_party = [None] * party_info_mmap["party_count"]

                for i, mon in enumerate(party_info_mmap["party"]):
                    new_party[i] = enrich_mon_data(mon)
                
                party_info = new_party

            time.sleep(0.12)
        except Exception as e:
            traceback.print_exc()
            pass

# def mem_get_general_info():
#     global general_info

#     while True:
#         try:
#             general_info_mmap = load_json_mmap(1024, "bizhawk_general_info")

#             if general_info_mmap:
#                 general_info = general_info_mmap
            
#             time.sleep(0.12)
#         except Exception as e:
#             traceback.print_exc()
#             pass

def log_encounter(pokemon: dict):
    # Statistics
    global record_ivSum, record_shinyValue, record_encounters, encounters

    # iv_sum = pokemon["hpIV"] + pokemon["attackIV"] + pokemon["defenseIV"] + pokemon["spAttackIV"] + pokemon["spDefenseIV"] + pokemon["speedIV"]

    # totals["highest_iv_sum"]    = iv_sum if totals["highest_iv_sum"] == None else max(totals["highest_iv_sum"], iv_sum)
    # totals["lowest_sv"]         = pokemon["shinyValue"] if totals["lowest_sv"] == None else min(totals["lowest_sv"], pokemon["shinyValue"])
    # totals["encounters"]        += 1

    for key in excess_keys:
        pokemon.pop(key, None)

    encounters.append(pokemon)
    encounters = encounters[-ENCOUNTER_LOG_LIMIT:]

    # write_file("stats/totals.json", json.dumps(totals, indent=4, sort_keys=True)) # Save stats file
    write_file("stats/encounters.json", json.dumps(encounters, indent=4, sort_keys=True)) # Save encounter log file

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
            # Compare with the last encounter list
            while True:
                new_hash = hash(json.dumps(encounters, sort_keys=True).encode())

                if encounters_hash != new_hash:
                    break

                time.sleep(0.5)

            encounters_hash = new_hash
            
            response = jsonify(encounters)
            return response
        else:
            abort(503)
    @server.route('/party', methods=['GET'])
    def req_party():
        global party_hash

        if party_info != None:
            # Compare with the last party info
            while True:
                new_hash = hash(json.dumps(party_info, sort_keys=True))

                if party_hash != new_hash:
                    break

                time.sleep(0.25)

            party_hash = new_hash

            response = jsonify(party_info)
            return response
        else:
            abort(503)
    server.run(debug=False, threaded=True, host="127.0.0.1", port=port)

os.makedirs("stats", exist_ok=True) # Sets up stats files if they don't exist

general_info, opponent_info, emu_speed, party_info = None, None, 1, []

seen_hash = ""
encounters_hash = ""
party_hash = ""

# file = read_file("../stats/totals.json")
# totals = json.loads(file) if file else {
#     "highest_iv_sum": 0, 
#     "lowest_sv": 65535, 
#     "encounters": 0, 
# }

file = read_file("stats/encounters.json")
encounters = json.loads(file) if file else []

# record_shinyValue = None
# record_ivSum = None
# record_encounters = 0

http_server = Thread(target=httpServer)
http_server.start()

get_party_info = Thread(target=mem_get_party_info)
get_party_info.start()

get_encounter_info = Thread(target=mem_get_encounter_info)
get_encounter_info.start()

# get_general_info = Thread(target=mem_get_general_info)
# get_general_info.start()

def on_window_close():
    os._exit(1)

window = webview.create_window("PokeBot Gen V", url="../dashboard/dashboard.html", width=1280, height=720, resizable=True, hidden=False, frameless=False, easy_drag=True, fullscreen=False, text_select=True, zoomable=True)
window.events.closed += on_window_close

webview.start()
