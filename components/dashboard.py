import json
# HTTP server/interface modules         
from flask import Flask, abort, jsonify, request # https://pypi.org/project/Flask/
from flask_cors import CORS                      # https://pypi.org/project/Flask-Cors/
import webview                                   # https://pypi.org/project/pywebview/

# Run HTTP server to make data available via HTTP GET
def httpServer():
    try:
        server = Flask(__name__)
        CORS(server)

        @server.route('/stats', methods=['GET'])
        def req_opponent_info():
            if opponent_info:
                if stats:
                    try: 
                        opponent_info["stats"] = stats["pokemon"][opponent_info["name"]]
                        response = jsonify(opponent_info)
                        return response
                    except: abort(503)
                else: response = jsonify(opponent_info)
                return response
            else: abort(503)
        server.run(debug=False, threaded=True, host="127.0.0.1", port=6969)
    except Exception as e:
        print(str(e))

default_stats = {
    "pokemon": {}, 
    "totals": {
        "longest_phase_encounters": 0, 
        "shortest_phase_encounters": "-", 
        "phase_lowest_sv": 99999, 
        "phase_lowest_sv_pokemon": "", 
        "encounters": 0, 
        "phase_encounters": 0, 
        "shiny_average": "-", 
        "shiny_encounters": 0
    }
}

# Dashboard
http_server = Thread(target=httpServer)
http_server.start()

totals = read_file("stats.json")
stats = json.loads(totals) if totals else default_stats

window = webview.create_window("PokeBot Gen V", url="ui/dashboard.html", width=1280, height=720, resizable=True, hidden=False, frameless=False, easy_drag=True, fullscreen=False, text_select=True, zoomable=True)
window.events.closed += on_window_close

webview.start()