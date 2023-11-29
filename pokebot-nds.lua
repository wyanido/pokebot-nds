-----------------------
-- INITIALIZATION
-----------------------
local BOT_VERSION = "v0.6.0-alpha"

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
json = require("lua\\json")
dofile("lua\\input.lua")
dofile("lua\\game_setup.lua")

pokemon = require("lua\\pokemon")

dofile("lua\\dashboard.lua")

-----------------------
-- GAME INFO POLLING
-----------------------

-- Send game info to the dashboard
comm.socketServerSend(json.encode({
    type = "load_game",
    data = {
        gen = gen,
        game = game_name,
        version = game_version
    }
}) .. "\x00")

party_hash = ""
party = {}

function update_party(is_reattempt)
    -- Prevent reading out of bounds when loading gen 4 games
    if offset.party_count < 0x02000000 then
        party_changed = true
        party = {}
        return true
    end

    -- Check if party data has updated
    local party_size = mbyte(offset.party_count)

    if not is_reattempt then
        local new_hash = memory.hash_region(offset.party_data, MON_DATA_SIZE * party_size)
        
        if party_hash == new_hash then
            return false
        end

        party_hash = new_hash
        console.debug("Party updated")
    end
    
    -- Read new party data
    local new_party = {}

    for i = 0, party_size - 1 do
        local mon_data = pokemon.decrypt_data(offset.party_data + i * MON_DATA_SIZE)
        
        if mon_data then
            local mon = pokemon.parse_data(mon_data, true)
            
            -- Friendship value is used to store egg cycles before hatching
            if mon.isEgg == 1 then
                mon.friendship = mon.friendship << 8
            end

            table.insert(new_party, mon)
        else
            -- If any party checksums fail, wait a frame and try again
            console.debug("Party checksum failed at slot " .. i .. ", retrying")
            emu.frameadvance()
            return update_party(true)
        end
    end

    party = new_party

    -- Update party on the node server
    comm.socketServerSend(json.encode({
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
    if mbyte(offset.battle_indicator) ~= 0x41 or mbyte(offset.foe_count) == 0 then
        foe = nil
    elseif not foe then -- Only update foe on battle start
        ::retry::
        local foe_table = {}
        local foe_count = mbyte(offset.foe_count)

        for i = 1, foe_count do
            local mon_data = pokemon.decrypt_data(offset.current_foe + (i - 1) * MON_DATA_SIZE)
            
            if mon_data then
                local mon = pokemon.parse_data(mon_data, true)
                
                if config.save_pkx and pokemon.matches_ruleset(mon, config.target_traits) then
                    pokemon.export_pkx(mon_data)
                end
                
                table.insert(foe_table, mon)
            else
                console.debug("Foe checksum failed at slot " .. i .. ", retrying")
                emu.frameadvance()
                goto retry
            end
        end

        foe = foe_table
    end
end

function get_game_state()
    local map = mword(offset.map_header)
    local in_game = (map ~= 0x0 and map <= MAP_HEADER_COUNT)

    -- Update in-game values
    if gen == 4 then -- gen 4 is always considered "in game" even before the title screen, so it always returns real data
        if in_game then
            return {
                map_header = map,
                map_name = map_names[map + 1],
                trainer_x = mword(offset.trainer_x + 2),
                trainer_y = to_signed(mword(offset.trainer_y + 2)),
                trainer_z = mword(offset.trainer_z + 2),
                in_battle = mbyte(offset.battle_indicator) == 0x41 and mbyte(offset.foe_count) > 0,
                in_starter_battle = mbyte(offset.battle_indicator) == 0x41,
                in_game = true
            }
        else
            return {
                map_header = 0,
                map_name = "--",
                trainer_x = 0,
                trainer_y = 0,
                trainer_z = 0,
                in_game = false
            }
        end
    else
        if in_game then
            return {
                -- map_matrix = mdword(offset.map_matrix),
                map_header = map,
                map_name = map_names[map + 1],
                trainer_x = mword(offset.trainer_x + 2),
                trainer_y = to_signed(mword(offset.trainer_y + 2)),
                trainer_z = mword(offset.trainer_z + 2),
                phenomenon_x = mword(offset.phenomenon_x + 2),
                phenomenon_z = mword(offset.phenomenon_z + 2),
                -- trainer_dir = mdword(offset.trainer_direction),
                in_battle = mbyte(offset.battle_indicator) == 0x41 and mbyte(offset.foe_count) > 0,
                in_game = true
            }
        else
            -- Set minimum required values for the dashboard
            return {
                map_header = 0,
                map_name = "--",
                trainer_x = 0,
                trainer_y = 0,
                trainer_z = 0,
                phenomenon_x = 0,
                phenomenon_z = 0,
                in_game = false
            }
        end
    end
end

function frames_per_move()
    if gen == 4 then -- Temporary
        return 16
    end

    if mbyte(offset.on_bike) == 1 then
        return 4
    elseif mbyte(offset.running_shoes) > 0 then
        return 8
    end

    return 16
end

function update_game_info(force)
    -- Refresh data at the rate it takes to move 1 tile
    local refresh_frames = frames_per_move()

    if emu.framecount() % refresh_frames == 0 or force then
        game_state = get_game_state()
        comm.socketServerSend(json.encode({
            type = "game_state",
            data = game_state
        }) .. "\x00")

        update_foes()
    end

    update_party()
end

function pause_bot(reason)
    clear_all_inputs()
    client.clearautohold()

    console.log("###################################")
    console.log(reason .. ". Pausing bot! (Make sure to disable the lua script before intervening)")

    -- Do nothing ever again
    while true do
        emu.frameadvance()
    end
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
console.log("Waiting for dashboard to relay bot configuration...")
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
            console.log("No function found for mode '" .. config.mode .. "'")
            return
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
