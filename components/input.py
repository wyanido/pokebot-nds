import mmap
from enum import IntEnum

#### INPUTS
# A, B, X, Y
# Left, Right, Up, Down
# Start, Select
# L, R
# LidClose, LidOpen
# Power, Screenshot
# Touch X, Touch Y, Touch
# GBA Light Sensor # useless
# Mic Volume

# button_list = ["A", "B", "X", "Y", "Left", "Right", "Up", "Down", "Start", "Select", "L", "R", "Power", "Touch"]

@staticmethod
def wait_frames(frames):
    time.sleep(frames_to_ms(frames))

def frames_to_ms(frames: float):
    return max((frames/60.0), 0.02)

@staticmethod
def emu_combo(sequence: list):
    for k in sequence:
        if type(k) is int:
            wait_frames(k)
        else:
            press_button(k)
            wait_frames(1)

def press_button(button: str):
    global g_current_index

    match button:
        case 'A':       byte = 1 << 0
        case 'B':       byte = 1 << 1
        case 'X':       byte = 1 << 2
        case 'Y':       byte = 1 << 3
        case 'Up':      byte = 1 << 4
        case 'Down':    byte = 1 << 5
        case 'Left':    byte = 1 << 6
        case 'Right':   byte = 1 << 7
        case 'Start':   byte = 1 << 8
        case 'Select':  byte = 1 << 9
        case 'L':       byte = 1 << 10
        case 'R':       byte = 1 << 11
        case 'Power':   byte = 1 << 12
        case _:         byte = 0
    
    input_list_mmap.seek(g_current_index)
    input_list_mmap.write(bytes(str(byte), encoding="utf-8"))
    input_list_mmap.seek(100) # Position 100 stores the current index
    input_list_mmap.write(bytes([g_current_index+1]))

    # Increment index
    g_current_index += 1
    
    if g_current_index > 99:
        g_current_index = 0

# def hold_button(button: str):
#     global hold_input
    
#     hold_input[button] = True
#     hold_input_mmap.seek(0)
#     hold_input_mmap.write(bytes(json.dumps(hold_input), encoding="utf-8"))

# def release_button(button: str):
#     global hold_input
    
#     hold_input[button] = False
#     hold_input_mmap.seek(0)
#     hold_input_mmap.write(bytes(json.dumps(hold_input), encoding="utf-8"))

# def release_all_inputs()
#     global press_input, hold_input
    
#     for button in button_list:
#         hold_input[button] = False
#         hold_input_mmap.seek(0)
#         hold_input_mmap.write(bytes(json.dumps(hold_input), encoding="utf-8"))

# def touch_screen_at(x: int, y: int)
    

# Create input map
g_current_index, hold_input, press_input = 0, False, False
input_list_mmap = mmap.mmap(-1, 512, tagname="bizhawk_input_list", access=mmap.ACCESS_WRITE)
input_list_mmap.flush()
input_list_mmap.seek(0)

# Clear inputs from last instance in case it wasn't refreshed in the Lua Console
for i in range(100):
    input_list_mmap.write(bytes(str(0), encoding="utf-8"))