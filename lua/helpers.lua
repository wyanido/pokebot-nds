function update_party()
    -- Prevent reading out of bounds when loading gen 4 games
    if pointers.party_count < 0x02000000 then
        party = {}
        return true
    end

    local party_size = mbyte(pointers.party_count)
    local party_updated = false

    for i = 1, 6, 1 do
        local checksum = mword(pointers.party_data + 6 + MON_DATA_SIZE * (i - 1))
        
        if i <= party_size then
            -- If the Pokemon has changed, re-read its data
            if party[i] == nil or checksum ~= party[i].checksum then
                local mon_data = pokemon.decrypt_data(pointers.party_data + (i - 1) * MON_DATA_SIZE)
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

    return true
end

function update_foes()
    -- Make sure it's not reading garbage non-battle data
    local battle_value = mbyte(pointers.battle_indicator)

    if battle_value ~= 0x41 and battle_value ~= 0x97 then
        foe = nil
    elseif not foe then -- Only update foe on battle start
        local attempt_fetch = function()
            local foe_table = {}
            local foe_count = mbyte(pointers.foe_count)
            
            if foe_count == 0 then
                print_debug("Foe data doesn't exist yet, retrying next frame...")
                return
            end 

            for i = 1, foe_count do
                local mon_data = pokemon.decrypt_data(pointers.current_foe + (i - 1) * MON_DATA_SIZE)
                
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

function get_game_state()
    if pointers.map_header < 0 then
        return {}
    end
    
    local map = mword(pointers.map_header)
    local in_game = (map ~= 0x0 and map <= #map_names)

    if not in_game then
        return {}
    end

    local state = {
        in_game = true,
        in_battle = type(foe) == "table" and #foe > 0,
        map_header = map,
        map_name = map_names[map + 1],
        trainer_name = read_string(pointers.trainer_name),
        trainer_id = string.format("%05d", mword(pointers.trainer_id)) .. " (" .. string.format("%05d", mword(pointers.trainer_id + 2)) .. ")",
        trainer_x = mdword(pointers.trainer_x) / 65536.0,
        trainer_y = to_signed(mdword(pointers.trainer_y) / 65536.0),
        trainer_z = mdword(pointers.trainer_z) / 65536.0,
    }

    if _ROM.gen == 5 then
        state["phenomenon_x"] = mword(pointers.phenomenon_x + 2)
        state["phenomenon_z"] = mword(pointers.phenomenon_z + 2)
    end
    
    return state
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

function frames_per_move()
    if _ROM.gen == 4 then -- Temporary
        return 16
    end

    if mbyte(pointers.on_bike) == 1 then
        return 4
    elseif mbyte(pointers.running_shoes) > 0 then
        return 8
    end

    return 16
end

function update_game_info()
    game_state = get_game_state()
    
    if emu.framecount() % 60 == 0 then    
        dashboard_send({
            type = "game_state",
            data = game_state
        })
    end
    
    if not foes then
        update_foes()
    end

    update_party()
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
    
    update_pointers()
    poll_dashboard_response()
    update_game_info()
end

function to_signed(u16)
    return (u16 + 32768) % 65536 - 32768
end