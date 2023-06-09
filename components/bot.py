import os
import io
import time
import mmap
import json
import math
import traceback
from threading import Thread, Event

from maps import MapID
from gamestate import GameState
from pokemon import *
from dashboard import *
from input import press_button, press_combo, press_screen_at

def load_json_mmap(size, file): 
    # BizHawk writes game information to memory mapped files every few frames (see pokebot.lua)
    # See https://tasvideos.org/Bizhawk/LuaFunctions (comm.mmfWrite)
    shmem = mmap.mmap(0, size, file)
    
    try:
        bytes_io = io.BytesIO(shmem)
        byte_str = bytes_io.read().decode('utf-8').split("\x00")[0]

        if byte_str != "":
            return json.loads(byte_str)
    except Exception as e:
        traceback.print_exc()
        return False

def mem_getGameInfo():
    global trainer_info, game_info, party_info, opponent_info

    while True:
        try:
            game_info_mmap = load_json_mmap(4096, "bizhawk_game_info")
            
            if game_info_mmap:
                trainer_info =  game_info_mmap["trainer"]
                game_info =     game_info_mmap["game_state"]
                party_info =    game_info_mmap["party"]

                if "opponent" in game_info_mmap:
                    opponent_info = enrich_mon_data(game_info_mmap["opponent"])
                else:
                    opponent_info = None

                if len(party_info) > 0:
                    for pokemon in party_info:
                        pokemon = enrich_mon_data(pokemon)
            wait_frames(1)
        except Exception as e:
            traceback.print_exc()
            pass

@staticmethod
def wait_frames(frames):
    time.sleep(frames_to_ms(frames))

def frames_to_ms(frames: float):
    return max((frames/60.0), 0.02)

def mode_starters(ball_position):
    print("Waiting to reach overworld...")

    while not game_info["state"] == GameState.OVERWORLD:
        press_combo(["A", 10])

    wait_frames(60)

    print("Opening Gift Box...")

    while not game_info["starter_box_open"]:
        press_combo(["Down", "A", 10])

    print("Choosing Starter...")

    while game_info["starter_box_open"] != 0:
        if game_info["selected_starter"] != 4:
            press_screen_at((120, 180)) # Pick this one!
            wait_frames(5)
            press_screen_at((240, 100)) # Yes
            wait_frames(5)
        else:
            press_screen_at(ball_position) # Starter
            wait_frames(5)
    
    print("Waiting to start battle...")

    while not game_info["in_battle"]:
        press_combo(["A", 10])
    
    i = 0
    while i < 23:
        press_button("A")
        wait_frames(30)
        i += 1

    mon = party_info[0]
    
    log_encounter(mon)

    if not mon["shiny"]:
        press_button("Power")
        wait_frames(60)
    else:
        print("Found a shiny Oshawott! Ending the script.")
        os._exit(1)

def mode_randomEncounters():
    print("Waiting for battle")

    while not game_info["in_battle"]:
        wait_frames(30)

    print("Starting battle")

    # i = 0
    # while i < 23:
    #     press_button("A")
    #     wait_frames(30)
    #     i += 1

    log_encounter(opponent_info)

    print("Waiting for battle to end")

    while game_info["in_battle"]:
        wait_frames(60)


def main_loop():
    # starter = "oshawott"

    # match starter:
    #     case "snivy":    ball_position = (60, 100)
    #     case "tepig":    ball_position = (128, 75)
    #     case "oshawott": ball_position = (185, 100)

    # starter = 0

    # while True:
    #     match starter % 3:
    #         case 0: ball_position = (60, 100)
    #         case 1: ball_position = (128, 75)
    #         case 2: ball_position = (185, 100)

    #     mode_starters(ball_position)

    #     starter += 1

    while True:
        mode_randomEncounters()

record_shinyValue = None
record_ivSum = None
record_encounters = 0

trainer_info, game_info, opponent_info, party_info = None, None, None, None
get_game_info = Thread(target=mem_getGameInfo)
get_game_info.start()

# Wait to start bot until key information is gathered
while trainer_info == None:
    wait_frames(10)

main_loop = Thread(target=main_loop)
main_loop.start()

dashboard_init()
