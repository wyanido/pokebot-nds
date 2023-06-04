import io
import time
import mmap
import json
from threading import Thread, Event
# Helper functions
from maps import MapID
from input import press_button, press_combo, press_screen_at

def load_json_mmap(size, file): 
    # BizHawk writes game information to memory mapped files every few frames (see pokebot.lua)
    # See https://tasvideos.org/Bizhawk/LuaFunctions (comm.mmfWrite)
    try:
        shmem = mmap.mmap(0, size, file)
        if shmem:
            bytes_io = io.BytesIO(shmem)
            byte_str = bytes_io.read()
            json_obj = json.loads(byte_str.decode("utf-8").split("\x00")[0]) # Only grab the data before \x00 null chars
            return json_obj
        else: return False
    except Exception as e:
        print(str(e))
        return False

# Loop repeatedly to read trainer info from memory
def mem_getGameInfo():
    global trainer_info

    while True:
        try:
            game_info_mmap = load_json_mmap(4096, "bizhawk_game_info")

            if game_info_mmap:
                trainer_info = game_info_mmap["trainer"]
            
            wait_frames(1)
        except Exception as e:
            print(str(e))

@staticmethod
def wait_frames(frames):
    time.sleep(frames_to_ms(frames))

def frames_to_ms(frames: float):
    return max((frames/60.0), 0.02)

def mainLoop():
    while True:
        press_screen_at(176, 107)
        wait_frames(1)

trainer_info = None
get_trainer_info = Thread(target=mem_getGameInfo)
get_trainer_info.start()

# Wait to start main loop until key information is gathered
while trainer_info == None:
    wait_frames(15)

mainLoop()