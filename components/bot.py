import os
import io
import time
import mmap
import json
from threading import Thread, Event
# Helper functions
from maps import MapID
from gamestate import GameState
from pokemon import *
from input import press_button, press_combo, press_screen_at

def load_json_mmap(size, file): 
    # BizHawk writes game information to memory mapped files every few frames (see pokebot.lua)
    # See https://tasvideos.org/Bizhawk/LuaFunctions (comm.mmfWrite)
    try:
        shmem = mmap.mmap(0, size, file)
        if shmem:
            bytes_io = io.BytesIO(shmem)
            byte_str = bytes_io.read()
            json_obj = json.loads(byte_str.decode("utf-8").split("\x00")[0])
            return json_obj
        else: return False
    except Exception as e:
        print(str(e))
        return False

def mem_getGameInfo():
    global trainer_info, game_info, party_info

    while True:
        try:
            game_info_mmap = load_json_mmap(4096, "bizhawk_game_info")

            if game_info_mmap:
                trainer_info = game_info_mmap["trainer"]
                game_info = game_info_mmap["game_state"]
                party_info = game_info_mmap["party"]
                
                if len(party_info) > 0:
                    for pokemon in party_info:
                        pokemon = enrich_mon_data(pokemon)
            wait_frames(1)
        except Exception as e:
            # print(party_info)
            pass

def enrich_mon_data(pokemon: dict):
    pokemon["otLanguage"] = monLanguage[pokemon["otLanguage"]]
    pokemon["shiny"] = pokemon["shinyValue"] < 8
    pokemon["ability"] = monAbility[pokemon["ability"]]
    pokemon["nature"] = monNature[pokemon["nature"]]
    pokemon["name"] = monName[pokemon["species"]]
    pokemon["heldItem"] = monItem[pokemon["heldItem"]]
    pokemon["gender"] = monGender[pokemon["gender"]] 
    pokemon["moves"] = [monMove[move] for move in pokemon["moves"]]

    return pokemon

@staticmethod
def wait_frames(frames):
    time.sleep(frames_to_ms(frames))

def frames_to_ms(frames: float):
    return max((frames/60.0), 0.02)

# --------------- v MAIN BOT STUFF BELOW v ---------------

def mode_starters():
    print("Waiting to reach overworld...")
    while not game_info["state"] == GameState.OVERWORLD:
        press_combo(["A", 10])

    print("Opening Gift Box...")

    while not game_info["starter_box_open"]:
        press_combo(["Down", "A", 10])

    print("Choosing Oshawott...")

    while game_info["starter_box_open"]:
        press_screen_at(185, 100) # Oshawott
        wait_frames(5)
        press_screen_at(120, 180) # Pick this one!
        wait_frames(5)
        press_screen_at(216, 100) # Yes
        wait_frames(5)
    
    print("Waiting for party info to update...")

    while len(party_info) < 1:
        press_combo(["A", 10])
    
    mon = party_info[0]
    print("--------------")
    print(f"Received Pokemon: {mon['name']}!")
    print(f"HP: {mon['hpIV']}, ATK: {mon['attackIV']}, DEF: {mon['defenseIV']}, SP.ATK: {mon['spAttackIV']}, SP.DEF: {mon['spDefenseIV']}, SPD: {mon['speedIV']}")
    print(f"Shiny Value: {mon['shinyValue']}, Shiny?: {str(mon['shiny'])}")
    print("--------------")

    if not mon["shiny"]:
        press_button("Power")
        wait_frames(60)
    else:
        print("Found a shiny Oshawott! Ending the script.")
        os._exit(1)

def mainLoop():
    while True:
        mode_starters()

trainer_info, game_info, party_info = None, None, None
get_game_info = Thread(target=mem_getGameInfo)
get_game_info.start()

# Wait to start bot until key information is gathered
while trainer_info == None:
    wait_frames(15)

mainLoop()