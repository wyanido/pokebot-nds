-----------------------
-- INITIALIZATION
-----------------------
local BOT_VERSION = "v0.7.0-alpha"

console.clear()
-- console.log("Running " .. _VERSION)
console.log("Pokébot NDS " .. BOT_VERSION .. " by NIDO (wyanido)")
console.log("https://github.com/wyanido/pokebot-nds\n")

if gameinfo.getromhash() == "" then
    console.log("Please load a ROM before enabling the script!")
    return
end

-- Override memory functions to prevent reading out of bounds
mbyte = function(addr) return memory.read_u8(math.max(addr, 0)) end
mword = function(addr) return memory.read_u16_le(math.max(addr, 0)) end
mdword = function(addr) return memory.read_u32_le(math.max(addr, 0)) end
console.debug = function(message)
    if config.debug then
        console.log("- " .. message)
    end
end
console.warning = function(message)
    console.log("# " .. message .. " #")
end

-- Requirements
json = require("lua\\modules\\json")
dofile("lua\\input.lua")
dofile("lua\\game_setup.lua")

pokemon = require("lua\\pokemon")

dofile("lua\\dashboard.lua")

-----------------------
-- GAME INFO POLLING
-----------------------

-- Send game info to the dashboard
dashboard:send(json.encode({
    type = "load_game",
    data = _ROM
}) .. "\x00")

party_hash = ""
party = {}

function update_party(is_reattempt)
    -- Prevent reading out of bounds when loading gen 4 games
    if pointers.party_count < 0x02000000 then
        party_changed = true
        party = {}
        return true
    end

    -- Check if party data has updated
    local party_size = mbyte(pointers.party_count)

    if not is_reattempt then
        local new_hash = memory.hash_region(pointers.party_data, MON_DATA_SIZE * party_size)
        
        if party_hash == new_hash then
            return false
        end

        party_hash = new_hash
        console.debug("Party updated")
    end
    
    -- Read new party data
    local new_party = {}

    for i = 0, party_size - 1 do
        local mon_data = pokemon.decrypt_data(pointers.party_data + i * MON_DATA_SIZE)
        if mon_data then
            local mon = pokemon.parse_data(mon_data, true)
            
            -- Friendship value is used to store egg cycles before hatching
            if mon.isEgg == 1 then
                mon.friendship = mon.friendship << 8
            end
            
            table.insert(new_party, mon)
        else
            -- If any party checksums fail, do not process this frame
            console.debug("Party checksum failed at slot " .. i)
            return false
        end
    end

    party = new_party

    -- Update party on the node server
    dashboard:send(json.encode({
        type = "party",
        data = {
            party = party,
            hash = party_hash
        }
    }) .. "\x00")

    return true
end

function update_foes()
    -- Make sure it's not reading garbage non-battle data
    if mbyte(pointers.battle_indicator) ~= 0x41 then
        foe = nil
    elseif not foe then -- Only update foe on battle start
        ::retry::
        local foe_table = {}
        local foe_count = mbyte(pointers.foe_count)
        
        if foe_count == 0 then
            console.debug("Foe data doesn't exist yet, retrying next frame...")
            emu.frameadvance()
            goto retry
        end 

        for i = 1, foe_count do
            local mon_data = pokemon.decrypt_data(pointers.current_foe + (i - 1) * MON_DATA_SIZE)
            
            if mon_data then
                local mon = pokemon.parse_data(mon_data, true)
                
                table.insert(foe_table, mon)
            else
                console.debug("Foe checksum failed at slot " .. i .. ", retrying next frame...")
                emu.frameadvance()
                goto retry
            end
        end

        foe = foe_table
    end
end

function get_game_state()
    local map = mword(pointers.map_header)
    local in_game = (map ~= 0x0 and map <= MAP_HEADER_COUNT)

    -- Update in-game values
    if _ROM.gen == 4 then -- gen 4 is always considered "in game" even before the title screen, so it always returns real data
        if in_game then
            return {
                map_header = map,
                map_name = map_names[map + 1],
                trainer_x = mword(pointers.trainer_x + 2),
                trainer_y = to_signed(mword(pointers.trainer_y + 2)),
                trainer_z = mword(pointers.trainer_z + 2),
                in_battle = type(foe) == "table" and #foe > 0,
                in_game = true,
                trainer_name = read_string(pointers.trainer_name),
                trainer_id = string.format("%05d", mword(pointers.trainer_id)),
                trainer_sid = string.format("%05d", mword(pointers.trainer_id + 2)),
            }
        else
            return {
                map_header = 0,
                in_game = false,
            }
        end
    else
        if in_game then
            return {
                map_header = map,
                map_name = map_names[map + 1],
                trainer_x = mword(pointers.trainer_x + 2),
                trainer_y = to_signed(mword(pointers.trainer_y + 2)),
                trainer_z = mword(pointers.trainer_z + 2),
                phenomenon_x = mword(pointers.phenomenon_x + 2),
                phenomenon_z = mword(pointers.phenomenon_z + 2),
                in_battle = mbyte(pointers.battle_indicator) == 0x41 and foe,
                in_game = true,
                trainer_name = read_string(pointers.trainer_name),
                trainer_id = string.format("%05d", mword(pointers.trainer_id)),
                trainer_sid = string.format("%05d", mword(pointers.trainer_id + 2)),
            }
        else
            -- Set minimum required values for the dashboard
            return {
                map_header = 0,
                in_game = false,
            }
        end
    end
end

function update_game_info(force)
    if emu.framecount() % 4 == 0 or force then
        game_state = get_game_state()
        dashboard:send(json.encode({
            type = "game_state",
            data = game_state
        }) .. "\x00")

        update_foes()
    end

    update_party()
end

function abort(reason)
    clear_all_inputs()
    client.clearautohold()

    console.log("##### BOT TASK ENDED #####")
    error(reason)
end

function cycle_starter_choice(starter)
    -- Alternate between starters specified in config and reset until one is a target
    if not config.starter0 and not config.starter1 and not config.starter2 then
        console.warning("At least one starter selection must be enabled in config for this bot mode")
        return
    end

    -- Cycle to next enabled starter
    starter = (starter + 1) % 3

    while not config["starter" .. tostring(starter)] do
        starter = (starter + 1) % 3
    end

    return starter
end

function process_frame()
    emu.frameadvance()
    update_pointers()
    poll_dashboard_response()
    update_game_info()
end

function to_signed(u16)
    return (u16 + 32768) % 65536 - 32768
end

-----------------------
-- PREPARATION
-----------------------
console.write("Waiting for dashboard to relay bot configuration... ")
::poll_config::

emu.frameadvance()
poll_dashboard_response()

if config == nil then
    goto poll_config
end

-----------------------
-- MAIN BOT LOGIC
-----------------------

input = input_init()
foe = nil -- Prevents logging old Pokemon when re-enabling the script in a different battle than the one it was disabled in
update_pointers()
update_game_info(true)

::begin::
clear_all_inputs()
client.clearautohold()

console.log("Bot mode set to " .. config.mode)
mode_real = config.mode

if config.save_game_on_start then
    save_game()
end

local mode = string.lower(config.mode)
local mode_function = _G["mode_" .. mode] -- Get the respective global scope function for the current bot mode
local starter = -1

while true do
    if mode_function then
        if mode == "starters" then
            starter = cycle_starter_choice(starter)
            mode_starters(starter)
        else
            mode_function()
        end
    else
        if mode == "manual" then -- No bot logic, just manual gameplay with a dashboard
            while true do
                while not game_state.in_battle do
                    process_frame()
                    
                    if mode_real ~= config.mode then
                        goto begin -- Restart if config changed
                    end
                end

                for i = 1, #foe, 1 do
                    pokemon.log_encounter(foe[i])
                end

                while game_state.in_battle do
                    process_frame()
                    
                    if mode_real ~= config.mode then
                        goto begin -- Restart if config changed
                    end
                end
            end
        else
            abort("Function for mode '" .. config.mode .. "' does not exist. It may not be compatible with this game.")
        end
    end

    -- Restart if config changed
    if mode_real ~= config.mode then
        goto begin
    end

    joypad.set(input)
    process_frame()
    clear_unheld_inputs()
end
