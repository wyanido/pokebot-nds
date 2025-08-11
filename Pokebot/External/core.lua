config = {}
foe = nil

function hint_config_default(key, value)
    if table_contains(config, key) then
        return
    end

    config[key] = value
end

--- Returns whether a table contains a given string key
function table_contains(table_, item)
    if type(table_) ~= "table" then table_ = {table_} end

    for _, table_item in ipairs(table_) do
        if string.lower(table_item) == string.lower(item) then
            return true
        end
    end

    return false
end

function abort(reason)
    client.invisibleemulation(false)
    clear_all_inputs()
    print("##### BOT TASK ENDED #####")
    error(reason)
end

mbyte = memory.read_u8
mword = memory.read_u16_le
mdword = memory.read_u32_le

-- Suppress deprecation warnings for bitwise operations replaced in newer versions of BizHawk.
-- The bot uses the old methods to maintain compatibility with DeSmuME which still uses them
bit = {
    band = function(val, amt) return val & amt; end,
    bnot = function(val) return ~val; end,
    bor = function(val, amt) return val | amt; end,
    bxor = function(val, amt) return val ~ amt; end, -- not a typo
    lshift = function(val, amt) return val << amt; end,
    rol = bit.rol,
    ror = bit.ror,
    rshift = function(val, amt) return val >> amt; end,
    arshift = bit.arshift,
    check = bit.check,
    set = bit.set,
    clear = bit.clear,
    byteswap_16 = bit.byteswap_16,
    byteswap_32 = bit.byteswap_32,
    byteswap_64 = bit.byteswap_64
};

hint_config_default("focus_mode", false)

--- Advances the game by one frame and calls all update methods
-- All frame advances go through this method, meaning it can
-- update the current game state without needing asynchronosity
function process_frame()
    joypad.set(input)
    
    --client.invisibleemulation(config.focus_mode)
    -- TEMPORARY, USE ORIGINAL LINE
    client.invisibleemulation(false)
    emu.frameadvance()

    decrement_input_buffers()
    clear_unheld_inputs()
    
    update_pointers()
    update_foes()
end

--- Debug function for printing the memory address of a pointer
function print_pointer(pointer)
    local local_pointer = pointer - 0x2000000
    print(string.format("%06X", local_pointer))
end

-- When stopped, attempt to restore display and reset the touch screen position override
event.onexit(function()
    joypad.setanalog({['Touch X'] = nil, ['Touch Y'] = nil})
    client.clearautohold()
    client.invisibleemulation(false)
end)

local input_buffer = {}

function touch_screen_at(x, y)
    joypad.setanalog({['Touch X'] = x, ['Touch Y'] = y})
    hold_button("Touch")
    wait_frames(4)
    release_button("Touch")
    joypad.setanalog({['Touch X'] = nil, ['Touch Y'] = nil}) -- Remove touch position override
end

--- Releases D-pad inputs besides the one specified to match what's possible on a real D-pad
local function release_conflicting_directions(direction)
    local directions = {"Up", "Down", "Left", "Right"}

    if not table_contains(directions, direction) then
        return
    end

    for _, v in ipairs(directions) do
        if v ~= direction then
            release_button(v)
        end
    end
end

function press_button(button)
    release_conflicting_directions(button)
    input[button] = true
    joypad.set(input)
    wait_frames(4)
    release_button(button)
end

function hold_button(button)
    release_conflicting_directions(button)
    held_input[button] = true
    input[button] = true
    joypad.set(input)
    wait_frames(1)
end

function release_button(button)
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

hint_config_default("target_rulesets", 
    {
        MyRuleset1 = {
            IsShiny = True,
            IVs = {
                Sum = 180
            }
        }
    }
)

input = joypad.get()
held_input = input

clear_all_inputs()
client.clearautohold()