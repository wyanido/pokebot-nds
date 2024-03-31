function update_party()
    -- Prevent reading out of bounds when loading gen 4 games
    if pointers.party_count < 0x02000000 then
        local emptied = #party ~= 0
        party = {}
        return emptied
    end

    local party_size = mbyte(pointers.party_count)
    local party_updated = false

    for i = 1, 6, 1 do
        local checksum = mword(pointers.party_data + 6 + _MON_BYTE_LENGTH * (i - 1))
        
        if i <= party_size then
            -- If the Pokemon has changed, re-read its data
            if party[i] == nil or checksum ~= party[i].checksum then
                local mon_data = pokemon.decrypt_data(pointers.party_data + (i - 1) * _MON_BYTE_LENGTH)
                if mon_data then
                    local mon = pokemon.parse_data(mon_data, true)
                    
                    party[i] = mon
                    party_updated = true
                else
                    print_debug("Party checksum failed at slot " .. i)
                end
            end
        else
            if party[i] ~= nil then
                party_updated = true
                party[i] = nil
            end
        end
    end
    
    return party_updated
end

function update_foes()
    -- Make sure it's not reading garbage non-battle data
    local battle_value = mbyte(pointers.battle_indicator)

    if battle_value ~= 0x41 and battle_value ~= 0x97 then
        foe = nil
    elseif not foe then -- Only update foe on battle start
        local function attempt_fetch()
            local foe_table = {}
            local foe_count = mbyte(pointers.foe_count)
            
            if foe_count == 0 then
                print_debug("Foe data doesn't exist yet, retrying next frame...")
                return
            end 

            for i = 1, foe_count do
                local mon_data = pokemon.decrypt_data(pointers.current_foe + (i - 1) * _MON_BYTE_LENGTH)
                
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

        while foe == nil do
            attempt_fetch()
            emu.frameadvance()
        end
    end
end

local function to_s16(u32)
    return ((u32 / 65536) + 32768) % 65536 - 32768
end

function update_game_state()
    if pointers.map_header < 0 then
        game_state = {}
        return
    end
    
    local map = mword(pointers.map_header)
    
    -- Save not loaded yet
    if not _MAP[map] then
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

function table_contains(table_, item)
    if type(table_) ~= "table" then
        table_ = {table_}
        -- print_debug("Ruleset entry was not a table. Fixing.")
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
    update_foes()
    update_game_state()
    local party_updated = update_party()

    -- Only send data on change to minimize expensive DOM updates on dashboard
    if party_updated then
        print_debug("Party updated")
        dashboard_send({
            type = "party",
            data = {
                party = party
            }
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

--- Returns an array of the isEgg value for each party member.
function get_party_eggs()
    local eggs = {}

    for i = 1, 6, 1 do
        if party[i] then
            eggs[i] = party[i].isEgg == 1
        else
            eggs[i] = true
        end
    end

    return eggs
end

--- Presses A to allow the egg hatch animation to finish where necessary.
function check_hatching_eggs()
    if emu.framecount() % 10 == 0 then
        press_button_async("A")
    end
    
    local new_eggs = get_party_eggs()
    
    for i, is_egg in ipairs(new_eggs) do
        -- Eggs are already considered "hatched" as soon as the animation starts
        if party[i] and party_eggs[i] ~= is_egg then
            clear_all_inputs()
            
            print("Egg is hatching!")
            hatch_egg(i)
            
            local is_target = pokemon.log_encounter(party[i])
            if is_target then
                abort("Hatched a target Pokemon!")
            else
                print("Hatched " .. party[i].name .. " was not a target...")
            end
            
            wait_frames(90)
            break
        end
    end

    party_eggs = new_eggs
    
    -- Check party to see if it's clear of eggs
    if #party == 6 then
        local has_egg = false
        
        for _, is_egg in ipairs(new_eggs) do
            if is_egg then
                has_egg = true
                break
            end
        end

        -- If no eggs are left and no target was found,
        -- we can release all Level 1 Pokemon from party
        if not has_egg then
            print("Party has no room for eggs! Releasing last 5 Pokemon...")
            release_hatched_duds()
        end
    end
end