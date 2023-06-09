import io
import time
import mmap
import json
import traceback
from pokemon import enrich_mon_data

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
            time.sleep(16.66)
        except Exception as e:
            traceback.print_exc()
            pass

trainer_info, game_info, opponent_info, party_info = None, None, None, None