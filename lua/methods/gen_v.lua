function update_pointers()
    local anchor = mdword(0x2146A88 + _ROM.offset)

    pointers = {
        -- Bag pouches, 4 byte pairs | 0001 0004 = 4x Master Ball
        items_pouch     = 0x02233FAC + _ROM.offset, -- 1240 bytes long
        key_items_pouch = 0x02234484 + _ROM.offset, -- 332 bytes long
        tms_hms_case    = 0x022345D0 + _ROM.offset, -- 436 bytes long
        medicine_pouch  = 0x02234784 + _ROM.offset, -- 192 bytes long
        berries_pouch   = 0x02234844 + _ROM.offset, -- 234 bytes long

        running_shoes   = 0x0223C054 + _ROM.offset, -- 0 before receiving

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
        battle_menu_state         = anchor + 0x1367C, -- 1 on FIGHT menu, 2 on move select, 4 on switch/run after faint, 0 otherwise
        battle_bag_page           = 0x022962C8 + _ROM.offset,
        selected_starter          = 0x02269994 + _ROM.offset, -- Unconfirmed selection in gift box; 0 Snivy, 1 Tepig, 2 Oshawott, 4 Nothing
        text_interrupt            = 0x2172BA0 + _ROM.offset,

        fishing_bite_indicator    = 0x20A8362 + _ROM.offset,
        fishing_no_bite           = 0x21509DB + _ROM.offset,

        trainer_name = 0x2234FB0 + _ROM.offset,
        trainer_id   = 0x2234FC0 + _ROM.offset,

        thundurus_tornadus = 0x225960C + _ROM.offset
    }
end

--- Press random key combo after SRing to increase seed randomness
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

--- Moves the bot toward a position on the map.
-- @param target Target position (x, z)
-- @param on_move Function called each frame while moving
-- If an axis in the target is not specified, it will be substituted with the bot's current position
function move_to(target, on_move)
    if not target.x then
        target.x = game_state.trainer_x - 0.5
    elseif not target.z then
        target.z = game_state.trainer_z - 0.5
    end

    while game_state.trainer_x <= target.x - 0.5 do
        hold_button("Right")
        if on_move then on_move() end
    end
    
    while game_state.trainer_x >= target.x + 1.5 do
        hold_button("Left")
        if on_move then on_move() end
    end
    
    while game_state.trainer_z < target.z - 0.5 do
        hold_button("Down")
        if on_move then on_move() end
    end
    
    while game_state.trainer_z > target.z + 1.5 do
        hold_button("Up")
        if on_move then on_move() end
    end
end

--- Opens the menu and selects the specified option.
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
        if game_state.map_name == "Nuvema Town" then
            touch_screen_at(200, 95) -- Button position is different before receiving Pokedex
        else
            touch_screen_at(65, 145)
        end
    elseif menu == "Options" then
        touch_screen_at(200, 145)
    end

    wait_frames(90)
end

--- Presses the RUN button until the battle is over.
function flee_battle()
    while game_state.in_battle do
        local battle_state = mbyte(pointers.battle_menu_state)

        if battle_state == 4 then -- Fainted
            wait_frames(30)
            touch_screen_at(128, 100) -- RUN
            wait_frames(140)

            while game_state.in_battle do
                press_sequence("B", 5)
            end
            return
        elseif battle_state ~= 1 then
            press_sequence("B", 1)
        else
            touch_screen_at(125, 175) -- Run
            wait_frames(5)
        end
    end
end

--- Returns true if the rod state has changed from being cast.
function fishing_status_changed()
    return not (mword(pointers.fishing_bite_indicator) ~= 0xFFF1 and mbyte(pointers.fishing_no_bite) == 0)
end

--- Returns true if a Pokemon is on the hook.
function fishing_has_bite()
    return mword(pointers.fishing_bite_indicator) == 0xFFF1
end

--- Converts bytes into readable text using the game's respective encoding method.
-- @param input Table of bytes or memory address to read from
-- @param pointer Offset into the byte table if provided
function read_string(input, pointer)
    local text = ""

    if type(input) == "table" then
        for i = pointer + 1, #input, 2 do
            local value = input[i] + (bit.lshift(input[i + 1], 8))

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

--- Returns whether a Pokemon is registered in the dex under a certain form.
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
        print_warn(field .. " is not a valid dex flag")
        return nil
    end

    for i, v in ipairs(_DEX) do
        if string.lower(v[1]) == string.lower(name) then
            local idx = i - 2
            local byte = addr + math.floor(idx / 8)
            local value = mbyte(byte)
            local registered = bit.band(value, bit.lshift(1, idx % 8)) > 0
            
            if registered then
                print_debug(name .. " " .. field)
            end

            return registered
        end    
    end

    print_warn("Pokemon " .. name .. " not found")

    return nil
end

function mode_starters()
    cycle_starter_choice()
    
    local balls = {
        [0] = { x = 60, y = 100 }, -- Snivy
        [1] = { x = 128, y = 75 }, -- tepig
        [2] = { x = 185, y = 100 }, -- Oshawott
    }

    if not game_state.in_game then
        print("Waiting to reach overworld...")

        while not game_state.in_game do
            press_sequence("A", 20)
        end
    end

    -- Ensure value has reset before trying to pick starter, otherwise the box will be assumed open too early
    while mbyte(pointers.starter_selection_is_open) ~= 0 do
        process_frame()
    end
    
    print("Opening Starter Selection...")

    while mbyte(pointers.starter_selection_is_open) == 0 do
        press_sequence("A", 5)
    end

    print("Choosing Starter...")

    while mbyte(pointers.starter_selection_is_open) ~= 0 do
        if mbyte(pointers.selected_starter) ~= 4 then
            touch_screen_at(120, 180) -- Pick this one!
            wait_frames(5)
            touch_screen_at(240, 100) -- Yes
            wait_frames(5)
        else
            touch_screen_at(balls[starter].x, balls[starter].y) -- Starter
            wait_frames(5)
        end
    end

    while #party == 0 do
        press_sequence("A", 5)
    end

    local is_target = pokemon.log_encounter(party[1])

    if is_target then
        abort("Starter meets target specs")
    else
        print("Starter was not a target, resetting...")
        soft_reset()
    end
end

function mode_random_encounters()
    local home = {
        x = game_state.trainer_x,
        z = game_state.trainer_z
    }

    local function move_in_direction(dir)
        dismiss_repel()

        hold_button("B")
        hold_button(dir)
        wait_frames(frames_per_move() - 2)
        release_button(dir)
        release_button("B")
    end

    while true do
        check_party_status()

        print("Attempting to start a battle...")

        local dir1 = config.move_direction == "horizontal" and "Left" or "Up"
        local dir2 = config.move_direction == "horizontal" and "Right" or "Down"
        
        wait_frames(60) -- Wait to regain control post-battle

        while not game_state.in_battle do
            move_in_direction(dir1)
            move_in_direction(dir2)
        end

        release_button(dir2)

        process_wild_encounter()
    end
end

function mode_gift()
    if not game_state.in_game then
        print("Waiting to reach overworld...")

        while not game_state.in_game do
            press_sequence("A", 20)
        end
    end

    wait_frames(60)
    
    local og_party_count = #party
    while #party == og_party_count do
        press_sequence("A", 5)
    end

    -- Dialogue varies per gift type
    if game_state.map_name == "Dreamyard" then
        press_sequence(300, "B", 120, "B", 150, "B", 110, "B", 30) -- Decline nickname and progress text afterwards
    else
        press_sequence(180, "B", 60) -- Decline nickname
    end

    local mon = party[#party]
    local is_target = pokemon.log_encounter(mon)

    if is_target then
        if config.save_game_after_catch then
            print("Gift Pokemon meets target specs! Saving...")

            save_game()
        end

        abort("Gift Pokemon meets target specs")
    else
        print("Gift Pokemon was not a target, resetting...")
        soft_reset()
    end
end

function mode_phenomenon_encounters()
    -- Remember initial position to return to after every battle
    local home = {
        x = game_state.trainer_x,
        z = game_state.trainer_z
    }

    local function accept_interrupt_text()
        local interrupted = false

        while mdword(pointers.text_interrupt) == 2 do
            press_sequence("Up", 1, "A", 1)
            interrupted = true
        end

        if interrupted then
            move_to(home)
        end
    end

    local function move_in_direction(dir)
        accept_interrupt_text()

        hold_button("B")
        hold_button(dir)
        wait_frames(frames_per_move() - 2)
        release_button(dir)
        release_button("B")
    end

    while true do
        check_party_status()
        
        local function do_encounter()
            print("Running until a phenomenon spawns...")

            local dir1 = config.move_direction == "horizontal" and "Left" or "Up"
            local dir2 = config.move_direction == "horizontal" and "Right" or "Down"

            while game_state.phenomenon_x == 0 and game_state.phenomenon_z == 0 do
                move_in_direction(dir1)
                move_in_direction(dir2)
            end

            release_button(dir2)

            print("Phenomenon spawned! Attempting to reach it...")

            while not game_state.in_battle do
                if game_state.phenomenon_x == 0 then -- Phenomenon was an item
                    return
                end

                move_to({
                    x = game_state.phenomenon_x,
                    z = game_state.phenomenon_z
                })
            end

            if game_state.in_battle then
                process_wild_encounter()
            else
                accept_interrupt_text() -- Accept repel dialogue or dust cloud item
            end

            move_to(home)
        end

        do_encounter()
    end
end

function mode_daycare_eggs()
    local function collect_daycare_egg()
        print_debug("That's an egg!")

        clear_all_inputs()
        press_sequence(30, "B")
        
        move_to({z=557})

        local og_party_count = #party -- Press A until egg in party
        while #party == og_party_count do
            press_sequence("A", 5)
        end

        press_sequence(200, "B", 70, "B") -- End dialogue
    end

    if game_state.map_header ~= 321 then
        abort("Please place the bot on Route 3")
    end

    -- If the party is full, assert that at least one is still unhatched
    if #party == 6 then
        local has_egg = false
        for i = 1, #party, 1 do
            if party[i].isEgg == 1 then
                has_egg = true
                break
            end
        end

        -- Otherwise free up party slots at PC
        if not has_egg then
            print("Party is clear of eggs. Depositing hatched Pokemon...")
            
            move_to({x=748}) -- Move to staircase
            move_to({z=557}) -- Move to the door
            move_to({x=749,z=556})
            
            -- Walk to daycare lady at desk
            while game_state.map_header ~= 323 do
                hold_button("Up")
                wait_frames(1)
            end

            release_button("Up")

            -- Walk to PC
            move_to({x=9,z=9})
            press_sequence("Up", 16, "A", 140, "A", 120, "A", 110, "A", 100)
            press_sequence("Down", 5, "Down", 5, "A", 110)

            touch_screen_at(45, 175)
            wait_frames(60)

            -- Release party in reverse order so the positions don't shuffle to fit empty spaces
            for i = #party, 1, -1 do
                if party[i].level == 1 and not pokemon.matches_ruleset(party[i], config.target_traits) then
                    touch_screen_at(40 * ((i - 1) % 2 + 1), 72 + 30 * math.floor((i - 1) / 2)) -- Select Pokemon
                    wait_frames(30)
                    touch_screen_at(211, 121) -- RELEASE
                    wait_frames(30)
                    touch_screen_at(220, 110) -- YES
                    press_sequence(60, "B", 20, "B", 20) -- Bye-bye!
                end
            end

            press_sequence("B", 30, "B", 30, "B", 30, "B", 150, "B", 90) -- Exit PC
            
            hold_button("B")
            
            while game_state.trainer_x > 6 do -- Align with door
                hold_button("Left")
                wait_frames(1)
            end

            release_button("Left")

            while game_state.map_header ~= 321 do -- Exit daycare
                hold_button("Down")
                wait_frames(1)
            end

            while game_state.trainer_z ~= 558 do
                hold_button("Down")
                wait_frames(1)
            end

            release_button("Down")

            press_sequence(20, "Left", 20, "Y") -- Mount Bicycle and with staircase
        end
    end

    -- Move down until on the two rows used for egg hatching
    if game_state.trainer_x >= 742 and game_state.trainer_x <= 748 and game_state.trainer_z < 563 then
        hold_button("Down")

        local stuck_frames = 0
        local last_z = game_state.trainer_z
        while game_state.trainer_z ~= 563 and game_state.trainer_z ~= 564 do
            wait_frames(1)

            if game_state.trainer_z == last_z then
                stuck_frames = stuck_frames + 1

                if stuck_frames > 60 then -- Interrupted by daycare man as you were JUST leaving
                    collect_daycare_egg()
                end
            end

            last_z = game_state.trainer_z
        end

        release_button("Down")
    else
        local tile_frames = frames_per_move() * 4

        -- Hold left until interrupted
        hold_button("Left")

        local last_x = 0
        while last_x ~= game_state.trainer_x do
            last_x = game_state.trainer_x
            wait_frames(tile_frames)

            -- Reached left route boundary
            press_button("B")
            if game_state.trainer_x <= 681 then
                break
            end
        end

        -- Hold right until interrupted
        hold_button("Right")

        local last_x = 0
        while last_x ~= game_state.trainer_x do
            last_x = game_state.trainer_x
            wait_frames(tile_frames)

            -- Right route boundary
            press_button("B")
            if game_state.trainer_x >= 758 then
                break
            end
        end

        if mdword(pointers.egg_hatching) == 1 then -- Interrupted by egg hatching
            print("Oh?")

            press_sequence("B", 60)

            -- Remember which Pokemon are currently eggs
            local party_eggs = {}
            for i = 1, #party, 1 do
                party_eggs[i] = party[i].isEgg
            end

            while mdword(pointers.egg_hatching) == 1 do
                press_sequence(15, "B")
            end

            -- Find newly hatched party member and add to the log
            for i = 1, #party, 1 do
                if party_eggs[i] == 1 and party[i].isEgg == 0 then
                    local is_target = pokemon.log_encounter(party[i])
                    break
                end
            end

            if is_target then
                if config.save_game_after_catch then
                    save_game()
                end

                abort("Hatched a target Pokemon")
            end

            print_debug("Egg finished hatching.")
        elseif game_state.trainer_x == 748 then -- Interrupted by daycare man
            collect_daycare_egg()
        end
    end
end

function mode_static_encounters()
    while not game_state.in_battle do
        if game_state.map_name == "Dreamyard" then
            press_button("Right")
        end

        press_sequence("A", 5)
    end

    local is_target = pokemon.log_encounter(foe[1])

    if is_target then
        if config.auto_catch then
            while game_state.in_battle do
                catch_pokemon()
            end

            if config.save_game_after_catch then
                print("Target Pokémon was caught! Saving...")
                save_game()
            end

            abort("Target Pokémon was caught!")
        else
            abort("Pokemon meets target specs, but Auto-catch is disabled")
        end
    else
        print("Wild " .. foe[1].name .. " was not a target, resetting...")
        soft_reset()
    end
end

function mode_thundurus_tornadus()
    local function dex_entry_added()
        local tornadus_seen = dex_registered("tornadus", "male") or dex_registered("tornadus", "shiny_male")
        local thundurus_seen = dex_registered("thundurus", "male") or dex_registered("thundurus", "shiny_male")

        return tornadus_seen or thundurus_seen
    end

    while not game_state.in_game do
        press_sequence("A", 5)
    end

    -- Exit house
    while game_state.map_header == 344 do
        hold_button("Down")
    end

    release_button("Down")

    -- Skip through cutscene until dex entry is registered
    while not dex_entry_added() do
        press_sequence("A", 5)
    end

    -- Read pre-generated Pokemon from memory
    local data = pokemon.decrypt_data(pointers.thundurus_tornadus)
    local mon = pokemon.parse_data(data, true)
    local is_target = pokemon.log_encounter(mon)

    if is_target then
        abort(mon.name .. " is a target!")
    else
        print(mon.name .. " was not a target, resetting...")
        soft_reset()
    end
end