import io
import time
import mmap
import json
from threading import Thread, Event
# Helper functions
from maps import MapID
from gamestate import GameState
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
    global trainer_info, game_info

    while True:
        try:
            game_info_mmap = load_json_mmap(4096, "bizhawk_game_info")

            if game_info_mmap:
                trainer_info = game_info_mmap["trainer"]
                game_info = game_info_mmap["game_state"]
            
            wait_frames(1)
        except Exception as e:
            print(str(e))

@staticmethod
def wait_frames(frames):
    time.sleep(frames_to_ms(frames))

def frames_to_ms(frames: float):
    return max((frames/60.0), 0.02)

# --------------- v MAIN BOT STUFF BELOW v ---------------

def mode_starters():
    print("Opening Gift Box...")

    while not game_info["starter_box_open"]:
        press_combo(["A", 10])

    print("Choosing Oshawott...")

    while game_info["starter_box_open"]:
        press_screen_at(185, 100) # Oshawott
        wait_frames(60)
        press_screen_at(120, 180) # Pick this one!
        wait_frames(60)
        press_screen_at(216, 100) # Yes
        wait_frames(60)
    
    print("Waiting to start battle...")

    while game_info["state"] != GameState.BATTLE:
        press_combo(["A", 10])

def mainLoop():
    while True:
        mode_starters()

trainer_info, game_info = None, None
get_game_info = Thread(target=mem_getGameInfo)
get_game_info.start()

# Wait to start bot until key information is gathered
while trainer_info == None or game_info == None:
    wait_frames(15)

mainLoop()