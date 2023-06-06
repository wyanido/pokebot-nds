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
# from dashboard import *
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
    global trainer_info, game_info, party_info, opponent_info

    while True:
        try:
            game_info_mmap = load_json_mmap(4096, "bizhawk_game_info")
            
            if game_info_mmap:
                trainer_info =  game_info_mmap["trainer"]
                game_info =     game_info_mmap["game_state"]
                party_info =    game_info_mmap["party"]
                
                if opponent_info:
                    opponent_info = enrich_mon_data(game_info_mmap["opponent"])

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

def log_mon_encounter(mon):
    # Statistics
    global record_ivSum, record_shinyValue, record_encounters
    iv_sum = mon["hpIV"] + mon["attackIV"] + mon["defenseIV"] + mon["spAttackIV"] + mon["spDefenseIV"] + mon["speedIV"]

    record_ivSum        = iv_sum if record_ivSum == None else max(record_ivSum, iv_sum)
    record_shinyValue   = mon["shinyValue"] if record_shinyValue == None else min(record_shinyValue, mon["shinyValue"])
    record_encounters   += 1

    print("--------------")
    print(f"Received Pokemon #{record_encounters}: a {mon['nature']} {mon['name']}!")
    print(f"HP: {mon['hpIV']}, ATK: {mon['attackIV']}, DEF: {mon['defenseIV']}, SP.ATK: {mon['spAttackIV']}, SP.DEF: {mon['spDefenseIV']}, SPD: {mon['speedIV']}")
    print(f"Shiny Value: {mon['shinyValue']}, Shiny?: {str(mon['shiny'])}")
    print("")
    print(f"Highest IV sum: {record_ivSum}")
    print(f"Lowest shiny value: {record_shinyValue}")
    print("--------------")

    # # Write current encounter
    # open('output.txt', 'w').close()

    # with open('output.txt', 'a') as f:
    #     f.write(f"IVs\nHP: {mon['hpIV']} | ATK: {mon['attackIV']} | DEF: {mon['defenseIV']} | SP.ATK: {mon['spAttackIV']} | SP.DEF: {mon['spDefenseIV']} | SPD: {mon['speedIV']}")
    #     f.write(f"\nTotal: {iv_sum} ({math.floor((iv_sum / (31 * 6)) * 100)}% Perfect)")
    #     f.write(f"\n\nNature: {mon['nature']}")
    #     f.write(f"\nGender: {mon['gender']}")
    #     f.write(f"\nShiny Value: {mon['shinyValue']} (Shiny?: {str(mon['shiny'])})")

    # # Write total stats
    # open('totals.txt', 'w').close()

    # with open('totals.txt', 'a') as f:
    #     f.write(f"# Oshawott Seen: {record_encounters}")
    #     f.write(f"\nLowest ever Shiny Value: {record_shinyValue}")
    #     f.write(f"\nHighest IV total: {record_ivSum} ({math.floor((record_ivSum / (31 * 6)) * 100)}% Perfect)")

# --------------- v MAIN BOT STUFF BELOW v ---------------

def mode_starters(ball_position):
    print("Waiting to reach overworld...")
    while not game_info["state"] == GameState.OVERWORLD:
        press_combo(["A", 10])

    print("Opening Gift Box...")

    while not game_info["starter_box_open"]:
        press_combo(["Down", "A", 10])

    print("Choosing Starter...")

    while game_info["starter_box_open"]:
        if game_info["selected_starter"] != 4:
            press_screen_at((120, 180)) # Pick this one!
            wait_frames(5)
            press_screen_at((240, 100)) # Yes
            wait_frames(5)
        else:
            press_screen_at(ball_position) # Starter
            wait_frames(5)
    
    print("Waiting to start battle...")

    # while len(party_info) < 1:
    #     press_combo(["A", 10])
    
    while not game_info["in_battle"]:
        press_combo(["A", 10])
    
    i = 0
    while i < 23:
        press_button("A")
        wait_frames(30)
        i += 1

    mon = party_info[0]
    
    log_mon_encounter(mon)

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

    print(f"Battling {opponent_info['name']}")
    print("Waiting for battle to end")

    while game_info["in_battle"]:
        wait_frames(60)


def mainLoop():
    starter = "snivy"

    match starter:
        case "snivy":    ball_position = (60, 100)
        case "tepig":    ball_position = (128, 75)
        case "oshawott": ball_position = (185, 100)

    while True:
        # mode_starters(ball_position)
        mode_randomEncounters()

record_shinyValue = None
record_ivSum = None
record_encounters = 0

trainer_info, game_info, opponent_info, party_info = None, None, None, None
get_game_info = Thread(target=mem_getGameInfo)
get_game_info.start()

# Wait to start bot until key information is gathered
while trainer_info == None:
    wait_frames(15)

mainLoop()