import os
import json
import logging
from threading import Thread, Event
# HTTP server/interface modules         
from flask import Flask, abort, jsonify, request
from flask_cors import CORS
import webview

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
        else: abort(503)
    @server.route('/encounters', methods=['GET'])
    def req_encounters():
        if encounters:
            response = jsonify(encounters)
            return response
        else: abort(503)
    server.run(debug=False, threaded=True, host="127.0.0.1", port=6969)

os.makedirs("stats", exist_ok=True) # Sets up stats files if they don't exist

file = read_file("stats/totals.json")
totals = json.loads(file) if file else {
    "totals": {
        "highest_iv_sum": 0, 
        "lowest_sv": 65535, 
        "encounters": 0, 
    }
}

file = read_file("stats/encounters.json")
encounters = json.loads(file) if file else { "encounters": [] }

# Dashboard
def on_window_close():
    print("Dashboard closed on user input")
    os._exit(1)
    
http_server = Thread(target=httpServer)
http_server.start()

window = webview.create_window("PokeBot Gen V", url="ui/dashboard.html", width=1280, height=720, resizable=True, hidden=False, frameless=False, easy_drag=True, fullscreen=False, text_select=True, zoomable=True)
window.events.closed += on_window_close

webview.start()