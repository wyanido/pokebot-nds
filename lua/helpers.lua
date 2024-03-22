function update_party(is_reattempt)
    -- Prevent reading out of bounds when loading gen 4 games
    if pointers.party_count < 0x02000000 then
        party_changed = true
        party = {}
        return true
    end

    -- Check if party data has updated
    local party_size = mbyte(pointers.party_count)
    local new_hash = ""

    if not is_reattempt then
        -- Generate a "hash" by stringing together every checksum in the party
        for i = 1, party_size, 1 do
            new_hash = new_hash .. mdword(pointers.party_data + 4 + MON_DATA_SIZE * i)
        end
        
        if party_hash == new_hash then
            return false
        end
    end
    
    -- Read new party data
    local new_party = {}

    for i = 0, party_size - 1 do
        local mon_data = pokemon.decrypt_data(pointers.party_data + i * MON_DATA_SIZE)
        if mon_data then
            local mon = pokemon.parse_data(mon_data, true)
            
            -- Friendship value is used to store egg cycles before hatching
            if mon.isEgg == 1 then
                mon.friendship = bit.lshift(mon.friendship, 8)
            end
            
            table.insert(new_party, mon)
        else
            -- If any party checksums fail, do not process this frame
            print_debug("Party checksum failed at slot " .. i)
            return false
        end
    end

    party = new_party
    party_hash = new_hash
    print_debug("Party updated")
    
    -- Update party on the node server
    dashboard_send({
        type = "party",
        data = {
            party = party,
            hash = party_hash
        }
    })

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
        trainer_x = mword(pointers.trainer_x + 2),
        trainer_y = to_signed(mword(pointers.trainer_y + 2)),
        trainer_z = mword(pointers.trainer_z + 2),
    }

    if _ROM.gen == 5 then
        state["phenomenon_x"] = mword(pointers.phenomenon_x + 2)
        state["phenomenon_z"] = mword(pointers.phenomenon_z + 2)
    end
    
    return state
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