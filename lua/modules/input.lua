-----------------------------------------------------------------------------
-- Cross-emulator button and touch screen methods
-- Author: wyanido
-- Homepage: https://github.com/wyanido/pokebot-nds
-----------------------------------------------------------------------------
local input_buffer = {}

-- Define touch screen methods specific to each emulator
if _EMU == "BizHawk" then
    function touch_screen_at(x, y)
        joypad.setanalog({['Touch X'] = x, ['Touch Y'] = y})
        hold_button("Touch")
        wait_frames(4)
        release_button("Touch")
        joypad.setanalog({['Touch X'] = nil, ['Touch Y'] = nil}) -- Remove touch position override
    end
else
    function touch_screen_at(x, y)
        for i = 1, 4 do
            stylus.set({x = x, y = y, touch = true})
            process_frame()
        end

        stylus.set({touch = false})
    end
end 

--- Releases D-pad inputs besides the one specified to match what's possible on a real D-pad
local function release_conflicting_directions(direction)
    local directions = {"up", "down", "left", "right"}

    if not table_contains(directions, direction) then
        return
    end

    for _, v in ipairs(directions) do
        if v ~= direction then
            release_button(v)
        end
    end
end

--- Adjusts for differences in input names between emulators by formatting them all consistently
local function adjust_case(button)
    if _EMU == "DeSmuME" then
        if button == "Up" or button == "Down" or button == "Left" or button == "Right" or button == "Start" or button == "Select" then 
            return string.lower(button)
        end
    end

    return button
end

function press_button(button)
    button = adjust_case(button)
    release_conflicting_directions(button)
    input[button] = true
    joypad.set(input)
    wait_frames(4)
    release_button(button)
end

function hold_button(button)
    button = adjust_case(button)
    release_conflicting_directions(button)
    held_input[button] = true
    input[button] = true
    joypad.set(input)
    wait_frames(1)
end

function release_button(button)
    button = adjust_case(button)
    held_input[button] = false
    input[button] = false
    joypad.set(input)
end

function press_sequence(...)
    for _, k in ipairs({...}) do
        if type(k) == "number" then
            wait_frames(k)
        else
            press_button(k)
        end
    end
end

--- Prevents other actions from processing for a set number of frames
function wait_frames(frames)
    for _ = 1, frames do
        joypad.set(input)
        process_frame()
    end

    clear_unheld_inputs()
end

--- Presses a button without delaying other actions in the script
-- Useful when additional inputs are needed during precise movement
function press_button_async(button)
    button = adjust_case(button)
    release_conflicting_directions(button)
    input_buffer[button] = 4
    input[button] = true
    joypad.set(input)
end

--- Decreases the timer on asynchronous button inputs
function decrement_input_buffers()
    for button, frames in pairs(input_buffer) do
        if frames > -1 then
            input_buffer[button] = frames - 1
        end

        if frames == 0 then
            input[button] = false
        end 
    end
end

--- Releases any button inputs still buffered that aren't explicitly set to 'held'
function clear_unheld_inputs()
    for k, _ in pairs(input) do
        if k ~= "Touch X" and k ~= "Touch Y" and not held_input[k] then
            input[k] = false
        end
    end

    joypad.set(input)
end

--- Releases all button inputs
function clear_all_inputs()
    for k, _ in pairs(input) do
        if k ~= "Touch X" and k ~= "Touch Y" then
            input[k] = false
            held_input[k] = false
        end
    end

    joypad.set(input)
end

input = joypad.get()
held_input = input

clear_all_inputs()
