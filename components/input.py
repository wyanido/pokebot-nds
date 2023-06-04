import time
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
def press_combo(sequence: list):
    for k in sequence:
        if type(k) is int:
            wait_frames(k)
        else:
            press_button(k)
            wait_frames(1)

def press_screen_at(x: int, y: int):
    touchscreen_mmap.seek(0)
    touchscreen_mmap.write(bytes(f"{x},{y}", encoding="utf-8"))
    # touchscreen_mmap[0] = x
    # touchscreen_mmap[1] = y

def press_button(button: str):
    global g_current_index

    match button:
        case 'Up':      button = "U"
        case 'Down':    button = "D"
        case 'Left':    button = "L"
        case 'Right':   button = "R"
        case 'Start':   button = "S"
        case 'Select':  button = "s"
        case 'L':       button = "l"
        case 'R':       button = "r"
        case 'Power':   button = "P"
        case 'Touch':   button = "T"

    input_list_mmap.seek(g_current_index)
    input_list_mmap.write(bytes(button, encoding="utf-8"))
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

g_current_index, hold_input, press_input = 0, False, False
input_list_mmap = mmap.mmap(-1, 4096, tagname="bizhawk_input_list", access=mmap.ACCESS_WRITE)
input_list_mmap.seek(0)

# Clear inputs from last instance in case it wasn't refreshed in the Lua Console
for i in range(100):
    input_list_mmap.write(bytes(str(0), encoding="utf-8"))

touchscreen_mmap = mmap.mmap(-1, 1024, tagname="bizhawk_touchscreen", access=mmap.ACCESS_WRITE)
touchscreen_mmap.seek(0)

