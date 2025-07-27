_CONFIG = {}
game_state = {}
party = {}
foe = nil

function hint_config_default(key, value)
    if table_contains(_CONFIG, key) then
        return
    end

    _CONFIG[key] = value
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
    if _EMU == "BizHawk" then client.invisibleemulation(false) end

    clear_all_inputs()
    print("##### BOT TASK ENDED #####")
    error(reason)
end

mbyte = memory.read_u8
mword = memory.read_u16_le
mdword = memory.read_u32_le

function print_debug(message) if _CONFIG.debug then print("- " .. message) end end

function print_warn(message) print("# " .. message .. " #") end

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

--- Converts an unsigned 32-bit int to a signed 16-bit int
function to_s16(u32) return ((u32 / 65536) + 32768) % 65536 - 32768 end

hint_config_default("focus_mode", false)

--- Advances the game by one frame and calls all update methods
-- All frame advances go through this method, meaning it can
-- update the current game state without needing asynchronosity
function process_frame()
    joypad.set(input)
    
    client.invisibleemulation(_CONFIG.focus_mode)
    emu.frameadvance()

    decrement_input_buffers()
    clear_unheld_inputs()
    
    update_pointers()
    update_game_state()
    update_foes()
    update_party()
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

client.clearautohold()
