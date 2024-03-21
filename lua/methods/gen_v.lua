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
        pokeparam        = 0x0226D676 + _ROM.offset,

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
    }
end

-----------------------
-- MISC. BOT ACTIONS
-----------------------
-- Press random key combo after SRing to increase seed randomness
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

function pathfind_to(target)
    -- Use local position if one axis isn't specified
    if not target.x then
        target.x = game_state.trainer_x
    elseif not target.z then
        target.z = game_state.trainer_z
    end

    local dx = target.x - game_state.trainer_x
    local dz = target.z - game_state.trainer_z
    local direction_priority = "x"
    local turn_cooldown = 2

    local function move_vertically()
        local button = dz > 0 and "Down" or "Up"
        hold_button(button)
        wait_frames(frames_per_move() - 1)
        release_button(button)
    end

    local function move_horizontally()
        local button = dx > 0 and "Right" or "Left"
        hold_button(button)
        wait_frames(frames_per_move() - 1)
        release_button(button)
    end

    hold_button("B")
    while game_state.trainer_x ~= target.x or game_state.trainer_z ~= target.z do
        dx = target.x - game_state.trainer_x
        dz = target.z - game_state.trainer_z

        if direction_priority == "z" then
            if dz ~= 0 then
                move_vertically()
            elseif dx ~= 0 then
                move_horizontally()
            end
        else
            if dx ~= 0 then
                move_horizontally()
            elseif dz ~= 0 then
                move_vertically()
            end
        end
        
        -- Swap movement axis often to zigzag to the target,
        -- decreasing the chance of the bot getting stuck
        if turn_cooldown == 0 then
            direction_priority = (direction_priority == "x") and "z" or "x"
            turn_cooldown = 2
        else
            turn_cooldown = turn_cooldown - 1
        end

        wait_frames(1) -- Makes movement more precise by reducing timing inconsistencies between directions

        dismiss_repel()
    end
    release_button("B")
end

function save_game()
    print("Saving game...")
    open_menu("Save")

    touch_screen_at(218, 60)
    wait_frames(120)

    while mbyte(pointers.save_indicator) ~= 0 do
        press_sequence("B", 12)
    end

    client.saveram() -- Flush save ram to the disk	

    press_sequence("B", 10)
end

function find_usable_ball()
    -- Check bag for Pokeballs
    local balls = {}
    local ball_count = 0

    local slot = 1
    for i = pointers.items_pouch, pointers.items_pouch + 1240, 4 do
        local id = mword(i)
        
        -- IDs from Master Ball to Cherish Ball
        if id >= 0x1 and id <= 0x10 then
            local count = mword(i + 2)
            
            if count > 0 then
                local item_name = _ITEM[id]

                balls[string.lower(item_name)] = slot
                ball_count = ball_count + count
            end

            slot = slot + 1
        elseif id == 0x0 then -- No more items beyond this byte
            break
        end
    end

    if ball_count == 0 then
        return -1
    end

    -- Compare with pokeball override
    if config.pokeball_override then
        for ball, _ in pairs(config.pokeball_override) do
            if pokemon.matches_ruleset(foe[1], config.pokeball_override[ball]) then
                local index = balls[string.lower(ball)]

                if index then
                    return index
                end
            end
        end
    end

    -- If no override rules were matched, default to priority
    if config.pokeball_priority then
        for _, ball in ipairs(config.pokeball_priority) do
            local index = balls[string.lower(ball)]

            if index then
                return index
            end
        end
    end

    return -1
end

function bike_back_and_forth()
    local horizontal = config.move_direction == "horizontal"
    local axis = horizontal and pointers.trainer_x or pointers.trainer_z
    local dir1 = horizontal and "Right" or "Down"
    local dir2 = horizontal and "Left" or "Up"

    local move_in_direction = function(dir)
        hold_button(dir)
        wait_frames(2)

        local z = mword(axis)
        while mword(axis) == z do
            hold_button(dir)
            dismiss_repel()

            if game_state.battle then
                return
            end
        end
    end

    -- Use registered bike if not already riding
    if mbyte(pointers.on_bike) ~= 1 then
        press_sequence("Y", 30, "A")
    end

    move_in_direction(dir1)
    move_in_direction(dir2)

    release_button(dir2)
end

-----------------------
-- BOT MODES
-----------------------

function choose_starter(ball_positions)
    print("Choosing Starter...")

    while mbyte(pointers.starter_selection_is_open) ~= 0 do
        if mbyte(pointers.selected_starter) ~= 4 then
            touch_screen_at(120, 180) -- Pick this one!
            wait_frames(5)
            touch_screen_at(240, 100) -- Yes
            wait_frames(5)
        else
            touch_screen_at(ball_positions[starter].x, ball_positions[starter].y) -- Starter
            wait_frames(5)
        end
    end

    while #party == 0 do
        press_sequence("A", 5)
    end
end

function mode_starters()
    cycle_starter_choice()
    
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

    choose_starter({
        [0] = { x = 60, y = 100 }, -- Snivy
        [1] = { x = 128, y = 75 }, -- tepig
        [2] = { x = 185, y = 100 }, -- Oshawott
    })

    if not config.hax then
        print("Waiting to see starter...")

        while not game_state.battle do
            press_sequence("A", 5)
        end

        for i = 0, 80, 1 do
            press_sequence("A", 5)
        end
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
        -- pathfind_to(home)
        -- wait_frames(8)

        while not game_state.battle do
            move_in_direction(dir1)
            move_in_direction(dir2)
        end

        release_button(dir2)

        process_wild_encounter()

        if config.pickup then
            do_pickup()
        end
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
            pathfind_to(home)
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
        
        local do_encounter = function()
            print("Running until a phenomenon spawns...")

            local dir1 = config.move_direction == "horizontal" and "Left" or "Up"
            local dir2 = config.move_direction == "horizontal" and "Right" or "Down"

            while game_state.phenomenon_x == 0 and game_state.phenomenon_z == 0 do
                move_in_direction(dir1)
                move_in_direction(dir2)
            end

            release_button(dir2)

            print("Phenomenon spawned! Attempting to reach it...")

            while not game_state.battle do
                if game_state.phenomenon_x == 0 then -- Phenomenon was an item
                    return
                end

                pathfind_to({
                    x = game_state.phenomenon_x,
                    z = game_state.phenomenon_z
                })
            end

            if game_state.battle then
                process_wild_encounter()
            else
                accept_interrupt_text() -- Accept repel dialogue or dust cloud item
            end

            pathfind_to(home)
        end

        do_encounter()
    end
end

function mode_daycare_eggs()
    local function collect_daycare_egg()
        print_debug("That's an egg!")

        clear_all_inputs()
        press_sequence(30, "B")
        
        pathfind_to({z=557})

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
            
            pathfind_to({x=748}) -- Move to staircase
            pathfind_to({z=557}) -- Move to the door
            pathfind_to({x=749,z=556})
            
            -- Walk to daycare lady at desk
            while game_state.map_header ~= 323 do
                hold_button("Up")
                wait_frames(1)
            end

            release_button("Up")

            -- Walk to PC
            pathfind_to({x=9,z=9})
            press_sequence("Up", 16, "A", 140, "A", 120, "A", 110, "A", 100)

            -- Temporary, add this to config once I figure out PC storage limitations
            local release_hatched_duds = true

            if release_hatched_duds then
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
            else
                -- Unfinished
                press_sequence("A", 120)

                abort("This code shouldn't be running right now")
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

function read_string(input, pointer)
    local bytes_to_string = function(start, finish, get_value)
        local text = ""

        for i = start, finish, 2 do
            local value = get_value(i)

            if value == 0xFFFF or value == 0x0000 then -- Null terminator
                break
            end

            text = text .. utf8.char(value)
        end

        return text
    end

    if type(input) == "table" then
        -- Read data from a table of bytes
        return bytes_to_string(pointer + 1, #input, function(i) 
            return input[i] + bit.lshift(input[i + 1], 8) 
        end)
    else
        -- Read data from an address
        return bytes_to_string(input, input + 32, function(i) 
            return mword(i) 
        end)
    end

    return text
end

function open_menu(menu)
    press_sequence(60, "X", 30)

    if menu == "Pokemon" then
        touch_screen_at(65, 45)
    elseif menu == "Save" then
        -- Button is at a different position before choosing starter
        if #party == 0 then
            -- No starter, no dex
            touch_screen_at(60, 93)
        elseif mword(pointers.map_header) == 391 then
            -- No dex (not a perfect fix)
            touch_screen_at(188, 88)
        else
            touch_screen_at(60, 143)
        end
    end
    
    wait_frames(90)
end

function manage_party(...)
    local select_pokemon = function(slot)
        local x = 80 * ((slot - 1) % 2 + 1)
        local y = 30 + 50 * math.floor((slot - 1) / 2)

        touch_screen_at(x, y)
    end

    for _, v in ipairs({...}) do
        if type(v) == "number" then
            select_pokemon(v)
        elseif v == "Switch" then
            touch_screen_at(200, 130)
        elseif v == "Item" then
            touch_screen_at(200, 155)
        elseif v == "Take" then
            touch_screen_at(200, 155) 
            press_sequence(120, "B", 30)
        elseif v == "Summary" then
            touch_screen_at(200, 105)
            wait_frames(60)
        end

        wait_frames(60)
    end

    wait_frames(30)
end

function close_menu()
    press_sequence(30, "B", 120, "B", 60)
end

function get_battle_state()
    local read_mon = function(addr)
        -- Multipliers for base stats
        local mult = { 0.33, 3/8, 3/7, 0.5, 0.6, 0.75, 1.0, 4/3, 5/3, 2.0, 7/3, 8/3, 3.0}

        -- Stat modifiers (-6 to +6)
        local mod = {
            attack    = mbyte(addr + 0x12A),
            defense   = mbyte(addr + 0x12B),
            speed     = mbyte(addr + 0x12E),
            spAttack  = mbyte(addr + 0x12C),
            spDefense = mbyte(addr + 0x12D),
        }

        local id = mword(addr)
        
        if id == 0 then
            return nil
        end
        
        return {
            species   = id,
            name      = _DEX[id + 1][1],
            type      = _DEX[id + 1][2],
            attack    = mword(addr + 0x11C) * mult[mod.attack + 1],
            defense   = mword(addr + 0x11E) * mult[mod.defense + 1],
            speed     = mword(addr + 0x124) * mult[mod.speed + 1],
            spAttack  = mword(addr + 0x120) * mult[mod.spAttack + 1],
            spDefense = mword(addr + 0x122) * mult[mod.spDefense + 1],
            moves = {
                _MOVE[mword(addr + 0x132) + 1],
                _MOVE[mword(addr + 0x140) + 1],
                _MOVE[mword(addr + 0x14E) + 1],
                _MOVE[mword(addr + 0x15C) + 1]
            },
            ability = _ABILITY[mbyte(addr + 0x44) + 1],
            pp = {
                mbyte(addr + 0x134),
                mbyte(addr + 0x142),
                mbyte(addr + 0x150),
                mbyte(addr + 0x15E)
            },
            level = mbyte(addr + 0x46),
            currentHP = mword(addr + 0x3E),
            maxHP = mword(addr + 0x3C),
            hasStatusCondition = mbyte(addr + 0x52) ~= 0 or mbyte(addr + 0x4E) ~= 0 -- Only checking for sleep/paralysis, other statuses have different pointers
        }
    end

    local pokeparam_length = 0x224
    local lead = mbyte(pointers.lead_index)

    local state = {
        ally = read_mon(pointers.pokeparam + pokeparam_length * lead),
        foe = read_mon(pointers.pokeparam + pokeparam_length * #party),
    }

    if not state.ally or not state.foe then
        return nil
    end

    return state
end

function mode_thundurus_tornadus()
    local dex_entry_added = function()
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

    if dex_registered("tornadus", "shiny_male") or dex_registered("thundurus", "shiny_male") then
        abort("Dex entry is shiny!")
    else
        print("Dex entry was not shiny, resetting...")
        soft_reset()
    end
end

function dex_registered(name, field)
    local dex = {
        ["caught"] = 0x223D1B4,
        ["male"] = 0x223D208,
        ["female"] = 0x223D25C,
        ["shiny_female"] = 0x223D304,
        ["seen"] = 0x223D358,
        ["shiny_male"] = 0x223D2B0,
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