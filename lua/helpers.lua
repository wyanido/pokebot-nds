-----------------------------------------------------------------------------
-- General helper methods for bot functionality
-- Author: wyanido, storyzealot
-- Homepage: https://github.com/wyanido/pokebot-nds
-----------------------------------------------------------------------------

--- Attempts to re-read the party data from memory and update the global reference 
function update_party()
    -- Don't attempt to read the party before a save is loaded.
    -- Notably it can still be read at this point in gen 4, but
    -- this is ignored to keep it consistent across all games.
    if not game_state.in_game then
        local party_was_emptied = #party ~= 0

        party = {}
        
        return party_was_emptied
    end

    local party_size = mbyte(pointers.party_count)
    local party_was_updated = false

    for i = 1, 6 do
        local checksum = mword(pointers.party_data + 6 + _MON_BYTE_LENGTH * (i - 1))
        
        if i <= party_size then
            if party[i] == nil or checksum ~= party[i].checksum then -- If the Pokemon has changed, re-read its data
                local mon_data = pokemon.read_data(pointers.party_data + (i - 1) * _MON_BYTE_LENGTH)

                if mon_data then
                    local mon = pokemon.parse_data(mon_data, true)
                    
                    party[i] = mon
                    party_was_updated = true
                else
                    print_debug("Party checksum failed at slot " .. i)
                end
            end
        else
            if party[i] ~= nil then
                party_was_updated = true
                party[i] = nil
            end
        end
    end
    
    return party_was_updated
end

--- Attempts to read the foe(s) data from memory
function update_foes()
    -- Make sure a battle is actually underway before reading
    local battle_value = mbyte(pointers.battle_indicator)

    if not game_state.in_game or (battle_value ~= 0x41 and battle_value ~= 0x97 and battle_value ~= 0xC0) then
        foe = nil
        return
    end

    -- If the foe is already known, then don't re-read it within the same battle
    if foe then
        return
    end

    local function attempt_fetch()
        local foe_count = mbyte(pointers.foe_count)
        
        if foe_count == 0 then
            print_debug("Foe data doesn't exist yet, retrying next frame...")
            return
        end

        local foe_table = {}

        for i = 1, foe_count do
            local mon_data = pokemon.read_data(pointers.current_foe + (i - 1) * _MON_BYTE_LENGTH)
            
            if mon_data then
                local mon = pokemon.parse_data(mon_data, true)
                
                table.insert(foe_table, mon)
            else
                print_debug("Foe checksum failed at slot " .. i .. ", retrying next frame...")
                return
            end
        end

        foe = foe_table
    end

    -- Attempt to identify the foe once per frame until it succeeds
    while foe == nil do
        -- Exit in case the bot SR'ed during this stage
        if not game_state.in_game then
            return
        end

        attempt_fetch()
        emu.frameadvance()
    end
end

--- Converts an unsigned 32-bit int to a signed 16-bit int
local function to_s16(u32)
    return ((u32 / 65536) + 32768) % 65536 - 32768
end

--- Updates the global reference of the current game state for bot modes to use
function update_game_state()
    if pointers.map_header < 0 then
        game_state = {}
        return
    end
    
    local map = mword(pointers.map_header)
    local save_is_loaded = _MAP[map] ~= nil

    -- Don't consider the save file as 'loaded' if the Journal page is open
    if _ROM.version == "D" or _ROM.version == "P" or _ROM.version == "PL" then
        save_is_loaded = save_is_loaded and mdword(pointers.start_value) ~= 0
    end

    if not save_is_loaded then
        game_state = {}
        return
    end

    game_state = {
        in_game = true,
        in_battle = type(foe) == "table" and #foe > 0,
        map_header = map,
        map_name = _MAP[map + 1],
        trainer_name = read_string(pointers.trainer_name),
        trainer_id = string.format("%05d", mword(pointers.trainer_id)) .. " (" .. string.format("%05d", mword(pointers.trainer_id + 2)) .. ")",
        trainer_x = to_s16(mdword(pointers.trainer_x)),
        trainer_y = to_s16(mdword(pointers.trainer_y)),
        trainer_z = to_s16(mdword(pointers.trainer_z)),
    }

    if _ROM.gen == 5 then
        game_state["phenomenon_x"] = mword(pointers.phenomenon_x + 2)
        game_state["phenomenon_z"] = mword(pointers.phenomenon_z + 2)
    end
end

--- Returns whether a table contains a given string key
function table_contains(table_, item)
    if type(table_) ~= "table" then
        table_ = {table_}
    end

    for _, table_item in ipairs(table_) do
        if string.lower(table_item) == string.lower(item) then
            return true
        end
    end

    return false
end

function abort(reason)
    if _EMU == "BizHawk" then
        client.invisibleemulation(false)
    end
    
    clear_all_inputs()
    print("##### BOT TASK ENDED #####")
    error(reason)
end

function cycle_starter_choice()
    if starter == nil then starter = -1 end
    
    -- Alternate between starters specified in config and reset until one is a target
    if not config.starter0 and not config.starter1 and not config.starter2 then
        abort("At least one starter selection must be enabled in config for this bot mode")
    end

    -- Cycle to next enabled starter
    starter = (starter + 1) % 3

    while not config["starter" .. tostring(starter)] do
        starter = (starter + 1) % 3
    end

    return starter
end

--- Advances the game by one frame and calls all update methods
-- All frame advances go through this method, meaning it can
-- update the current game state without needing asynchronosity
function process_frame()
    if config.focus_mode and _EMU == "DeSmuME" then
        emu.emulateframeinvisible()
        sound.clear()
    else
        if _EMU == "BizHawk" then
            client.invisibleemulation(config.focus_mode)
        end

        emu.frameadvance()
    end
    
    decrement_input_buffers()
    update_pointers()
    update_game_state()
    update_foes()
    
    -- Only send data on change to minimize expensive DOM updates on dashboard
    local party_was_updated = update_party()
    
    if party_was_updated then
        print_debug("Party updated")
        dashboard_send({
            type = "party",
            data = party
        })
    end

    -- Interact with the dashboard once per in-game second
    if emu.framecount() % 60 == 0 then
        dashboard_send({
            type = "game_state",
            data = game_state
        })
        
        dashboard_poll()
    end
end

--- Returns an array of booleans to indicate the egg state for each party member
function get_party_egg_states()
    local eggs = {}

    for i = 1, 6 do
        if party[i] then
            eggs[i] = party[i].isEgg
        else
            eggs[i] = true
        end
    end

    return eggs
end

--- Presses A to allow the egg hatch animation to finish if it's currently happening
function check_hatching_eggs()
    if emu.framecount() % 10 == 0 then
        if _ROM.version == "HG" or _ROM.version == "SS" then -- HGSS needs to deny phone calls a lot of the time, so we use B instead
            press_button_async("B")
        else
            press_button_async("A")
        end
    end

    local current_egg_states = get_party_egg_states()

    -- Check for egg hatching
    for i, is_egg in ipairs(current_egg_states) do
        -- Eggs are already considered "hatched" as soon as the animation starts,
        -- so we can tell if an egg is hatching when 'is_egg' has changed since last reference
        if party[i] then
            if party_egg_states[i] ~= is_egg then
                clear_all_inputs()
                hatch_egg(i)

                local is_target = pokemon.log_encounter(party[i])
                if is_target then
                    abort("Hatched a target Pokémon: " .. party[i].name .. "!")
                end
                
                wait_frames(90)
                break
            end
        end
    end

    party_egg_states = current_egg_states

    -- Check if all eggs are hatched only if the party is full
    if party and #party == 6 then
        local has_egg = false
        
        -- This should check the current egg states to see if any are still not hatched
        for i, is_egg in ipairs(current_egg_states) do
            if is_egg then
                has_egg = true
                break
            end
        end

        -- Only release hatched duds if all eggs are hatched
        if not has_egg then
            print("Party has no room for eggs! Releasing last 5 Pokemon...")
            release_hatched_duds()
        end
    elseif not party then
        print("Error: Party is nil.")
    end
end

--- Debug function for printing the memory address of a pointer
function print_pointer(pointer)
    local local_pointer = pointer - 0x2000000
    print(string.format("%06X", local_pointer))
end
