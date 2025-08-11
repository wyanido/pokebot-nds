-----------------------------------------------------------------------------
-- General bot methods for gen 5 games (BW, B2W2)
-- Author: wyanido
-- Homepage: https://github.com/wyanido/pokebot-nds
-----------------------------------------------------------------------------

function update_pointers()
    local anchor = mdword(0x2146A88 + _ROM.offset)

    pointers = {
        -- Bag pouches, 4 byte pairs | 0001 0004 = 4x Master Ball
        items_pouch     = 0x02233FAC + _ROM.offset, -- 1240 bytes long
        key_items_pouch = 0x02234484 + _ROM.offset, -- 332 bytes long
        tms_hms_case    = 0x022345D0 + _ROM.offset, -- 436 bytes long
        medicine_pouch  = 0x02234784 + _ROM.offset, -- 192 bytes long
        berries_pouch   = 0x02234844 + _ROM.offset, -- 234 bytes long

        running_shoes = 0x0223C054 + _ROM.offset, -- 0 before receiving

        -- Party
        party_count = 0x022349B0 + _ROM.offset, -- 4 bytes before first index
        party_data  = 0x022349B4 + _ROM.offset, -- PID of first party member

        step_counter = 0x02235125 + _ROM.offset,
        step_cycle   = 0x02235126 + _ROM.offset,

        -- Location
        map_header        = 0x0224F90C + _ROM.offset,
        trainer_x         = 0x0224F910 + _ROM.offset,
        trainer_y         = 0x0224F914 + _ROM.offset,
        trainer_z         = 0x0224F918 + _ROM.offset,
        trainer_direction = 0x0224F924 + _ROM.offset, -- 0, 4, 8, 12 -> Up, Left, Down, Right
        on_bike           = 0x0224F94C + _ROM.offset,
        encounter_table   = 0x0224FFE0 + _ROM.offset,
        map_matrix        = 0x02250C1C + _ROM.offset,

        phenomenon_x = 0x02257018 + _ROM.offset,
        phenomenon_z = 0x0225701C + _ROM.offset,

        egg_hatching = 0x0226DF68 + _ROM.offset,

        -- Battle
        battle_indicator = 0x0226ACE6 + _ROM.offset, -- 0x41 if during a battle
        foe_count        = 0x0226ACF0 + _ROM.offset, -- 4 bytes before the first index
        current_foe      = 0x0226ACF4 + _ROM.offset, -- PID of foe, set immediately after the battle transition ends

        -- Misc
        save_indicator            = 0x021F0100 + _ROM.offset, -- 1 while save menu is open
        starter_selection_is_open = 0x022B0C40 + _ROM.offset, -- 0 when opening gift, 1 at starter select
        battle_bag_page           = 0x022962C8 + _ROM.offset,
        selected_starter          = 0x02269994 + _ROM.offset, -- Unconfirmed selection in gift box; 0 Snivy, 1 Tepig, 2 Oshawott, 4 Nothing
        text_interrupt            = 0x2172BA0 + _ROM.offset,
        battle_menu_state         = anchor + 0x1367C, -- 1 on FIGHT menu, 2 on move select, 4 on switch/run after faint, 0 otherwise

        fishing_bite_indicator    = 0x20A8362 + _ROM.offset,
        fishing_no_bite           = 0x21509DB + _ROM.offset,

        trainer_name = 0x2234FB0 + _ROM.offset,
        trainer_id   = 0x2234FC0 + _ROM.offset,

        roamer = 0x225960C + _ROM.offset,
        daycare_egg = 0x223CB74 + _ROM.offset,
    }
end

--- Presses a random key combination after SRing to increase seed randomness
-- https://www.smogon.com/ingame/rng/bw_rng_part2
function randomise_reset()
    local inputs = { "Up", "Down", "Left", "Right", "A", "B", "X", "Y", "L", "R", "Start", "Select" }
    local press = {}

    for i = 1, math.random(3, 7), 1 do
        table.insert(press, #press + 1, inputs[math.random(1, #inputs)])
    end

    for _, v in ipairs(press) do
        hold_button(v)
    end

    wait_frames(200)

    for _, v in ipairs(press) do
        release_button(v)
    end
end

--- Opens the menu and selects the specified option
-- @param menu Name of the menu to open
function open_menu(menu)
    press_sequence(60, "X", 30)
    
    if menu == "Pokemon" then
        touch_screen_at(65, 45)
        press_sequence(90, "A", 5) -- When opening party with touch screen, a Pokemon isn't highlighted on open
        return
    elseif menu == "Pokedex" then
        touch_screen_at(200, 45)
    elseif menu == "Bag" then
        touch_screen_at(65, 95)
    elseif menu == "Trainer" then
        touch_screen_at(200, 95)
    elseif menu == "Save" then
        if game.map_name() == "Nuvema Town" then
            touch_screen_at(200, 95) -- Button position is different before receiving Pokedex
        else
            touch_screen_at(65, 145)
        end
    elseif menu == "Options" then
        touch_screen_at(200, 145)
    end

    wait_frames(90)
end

--- Returns true if the rod state has changed from being cast
function fishing_status_changed()
    return not (mword(pointers.fishing_bite_indicator) ~= 0xFFF1 and mbyte(pointers.fishing_no_bite) == 0)
end

--- Returns true if a Pokemon is on the hook
function fishing_has_bite()
    return mword(pointers.fishing_bite_indicator) == 0xFFF1
end

--- Converts bytes into readable text using the game's respective encoding method
-- @param input Table of bytes or memory address to read from
-- @param pointer Offset into the byte table if provided
function read_string(input, pointer)
    local text = ""

    if type(input) == "table" then
        for i = pointer + 1, #input, 2 do
            local value = input[i] + bit.lshift(input[i + 1], 8)

            if value == 0xFFFF or value == 0x0000 then -- Null terminator
                break
            end

            text = text .. utf8.char(value)
        end
    else
        for i = input, input + 32, 2 do
            local value = mword(i)

            if value == 0xFFFF or value == 0x0000 then -- Null terminator
                break
            end

            text = text .. utf8.char(value)
        end
    end
    
    return text
end

-- Get list of Poke Ball types from bag
function get_usable_balls()
    local balls = {}
    local slot = 1

    for i = pointers.items_pouch, pointers.items_pouch + 1240, 4 do
        local id = mword(i)
        
        -- IDs from Master Ball to Cherish Ball
        if id >= 0x1 and id <= 0x10 then
            local count = mword(i + 2)
            
            if count > 0 then
                local item_name = _ITEM[id + 1]

                balls[string.lower(item_name)] = slot + 1
            end

            slot = slot + 1
        elseif id == 0x0 then -- No more items beyond this byte
            return balls
        end
    end
end

--- Returns whether a Pokemon is registered in the dex under a certain form
-- @param name Name of the Pokemon
-- @param field Form to check if registered
function dex_registered(name, field)
    local dex = {
        ["caught"]       = 0x223D1B4 + _ROM.offset,
        ["male"]         = 0x223D208 + _ROM.offset,
        ["female"]       = 0x223D25C + _ROM.offset,
        ["shiny_female"] = 0x223D304 + _ROM.offset,
        ["seen"]         = 0x223D358 + _ROM.offset,
        ["shiny_male"]   = 0x223D2B0 + _ROM.offset,
    }

    local addr = dex[field]
    if not addr then
        console.warn(field .. " is not a valid dex flag")
        return nil
    end

    for i, v in ipairs(_DEX) do
        if string.lower(v[1]) == string.lower(name) then
            local idx = i - 2
            local byte = addr + math.floor(idx / 8)
            local value = mbyte(byte)
            local registered = bit.band(value, bit.lshift(1, idx % 8)) > 0
            
            if registered then
                console.debug(name .. " " .. field)
            end

            return registered
        end    
    end

    console.warn("Pokemon " .. name .. " not found")

    return nil
end

--- Proceeds until the egg hatch animation finishes.
function hatch_egg(slot)
    while mdword(pointers.egg_hatching) == 1 do
        press_sequence(15, "B")
    end
end

--- Navigates to the Route 3 daycare and releases all hatched Pokemon in the party
function release_hatched_duds()
    local function release(i)
        local x = 40 * ((i - 1) % 2 + 1)
        local y = 72 + 30 * math.floor((i - 1) / 2)
        
        touch_screen_at(x, y) -- Select Pokemon
        wait_frames(30)
        touch_screen_at(211, 121) -- RELEASE
        wait_frames(30)
        touch_screen_at(220, 110) -- YES
        press_sequence(60, "B", 20, "B", 20) -- Bye-bye!
    end

    move_to({x=748}) -- Move to staircase
    move_to({z=557}) -- Move to the door
    move_to({x=749,z=556})
    
    -- Walk to daycare lady at desk
    while game.map_header() ~= 323 do
        hold_button("Up")
    end

    release_button("Up")

    -- Walk to PC
    hold_button("B")
    move_to({z=9})
    move_to({x=9})
    hold_button("Up")
    wait_frames(10)
    release_button("Up")
    wait_frames(10)
    release_button("B")
    
    -- PC Menu
    press_sequence("A", 140, "A", 120, "A", 110, "A", 60, "A", 60, "Down", 5, "Down", 5, "A", 110)

    touch_screen_at(45, 175)
    wait_frames(60)

    -- Release party in reverse order so the positions don't shuffle to fit empty spaces
    for i = #party, 1, -1 do
        if pokemon.is_hatched_dud(party[i]) then
            release(i)
        end
    end

    press_sequence("B", 25, "B", 30, "B", 30, "B", 150, "B", 90) -- Exit PC
    
    -- Exit daycare
    hold_button("B")
    move_to({x=6})
    move_to({z=13})
    press_sequence("Down")

    --Restart the loop
    release_button("B")
    release_button("Down")
    press_sequence(180, "Y", 30, "Y")
    move_to({z=557})
    move_to({x=748})
    move_to({z=563})
end

--- Returns the current stage of the battle as a simple string
function get_battle_state()
    if not game.in_battle() then
        return nil
    end

    local state = mbyte(pointers.battle_menu_state)
    
    if state == 0x1 then
        return "Menu"
    elseif state == 0x2 then
        return "Fight"
    elseif state == 0x4 then
        return "New Move"
    end

    return nil
end
