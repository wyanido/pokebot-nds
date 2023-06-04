import time
# Helper functions
from maps import MapID
from input import press_button

@staticmethod
def wait_frames(frames):
    time.sleep(frames_to_ms(frames))

def frames_to_ms(frames: float):
    return max((frames/60.0), 0.02)

def mainLoop():
    while True:
        press_button("A")
        wait_frames(60)

mainLoop()