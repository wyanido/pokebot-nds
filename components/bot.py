import os
import io
import math
import time
from threading import Thread, Event

import common
from maps import MapID
from gamestate import GameState
from dashboard import dashboard_init, log_encounter
from input import press_button, press_combo, press_screen_at

@staticmethod
def wait_frames(frames):
    time.sleep(frames_to_ms(frames))

def frames_to_ms(frames: float):
    return max((frames/60.0) / common.emu_speed, 0.02)

def mode_starters(ball_position):
    print("Waiting to reach overworld...")

    while common.game_info["state"] != GameState.OVERWORLD:
        press_combo(["A", 10])

    wait_frames(60)

    print("Opening Gift Box...")

    while common.game_info["starter_box_open"] != 1:
        press_combo(["Down", "A", 10])

    print("Choosing Starter...")

    while common.game_info["starter_box_open"] != 0:
        if common.game_info["selected_starter"] != 4:
            press_screen_at((120, 180)) # Pick this one!
            wait_frames(6)
            press_screen_at((240, 100)) # Yes
            wait_frames(6)
        else:
            press_screen_at(ball_position) # Starter
            wait_frames(6)
    
    print("Waiting to start battle...")

    while not common.game_info["in_battle"]:
        press_combo(["A", 10])
    
    print("Waiting to see starter...")

    i = 0
    while i < 66:
        press_button("B")
        wait_frames(10)
        i += 1

    mon = common.party_info[0]
    
    log_encounter(mon)

    if not mon["shiny"]:
        press_button("Power")
        wait_frames(60)
    else:
        print("Found a shiny Oshawott! Ending the script.")
        os._exit(1)

def mode_randomEncounters():
    print("Waiting for battle")

    while common.opponent_info is None and not common.game_info["in_battle"]:
        wait_frames(10)

    for foe in common.opponent_info:
        log_encounter(foe)
    
    print("Waiting for battle to end")

    while common.game_info["in_battle"]:
        wait_frames(10)

def main_loop():
    starter = 0

    while True:
        match starter % 3:
            case 0: ball_position = (60, 100)
            case 1: ball_position = (128, 75)
            case 2: ball_position = (185, 100)

        mode_starters(ball_position)

    #     starter += 1

    # while True:
    #     mode_randomEncounters()

get_game_info = Thread(target=common.mem_get_game_info)
get_game_info.start()
get_party_info = Thread(target=common.mem_get_party_info)
get_party_info.start()

# Wait to start bot until key information is gathered
while common.trainer_info == None:
    wait_frames(10)

main_loop = Thread(target=main_loop)
main_loop.start()

dashboard_init()
