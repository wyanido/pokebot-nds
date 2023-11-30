-----------------------
-- DP FUNCTION OVERRIDES
-----------------------
function update_pointers()
    local mem_shift = mdword(0x21D4158) -- Value differs per reset

    pointers.party_count = mem_shift - 0x23F44
    pointers.party_data = pointers.party_count + 4
    
    pointers.map_header = mem_shift - 0x22DA4
    pointers.trainer_x = pointers.map_header + 4 + 2
    pointers.trainer_y = pointers.map_header + 12 + 2
    pointers.trainer_z = pointers.map_header + 8 + 2
    
    if mword(pointers.map_header) == 340 then -- Bell Tower
        -- Wild Ho-oh's data is located at a different address to standard encounters
        -- May apply to other statics too -- research?
        pointers.foe_count = mem_shift + 0x977C
    else
        pointers.foe_count = mem_shift + 0x7574
    end

    pointers.current_foe = pointers.foe_count + 4

    local mem_shift = mdword(0x21D2228) -- 27C1E0  --value @ 2C32B4

    pointers.battle_indicator = 0x021E76D2 -- Static
    pointers.battle_state = mem_shift + 0x470D4
    pointers.battle_state_value = mbyte(pointers.battle_state) -- 01 is FIGHT menu, 04 is Move Select, 08 is Bag,
    pointers.current_pokemon = mem_shift + 0x49E14 -- 0A is POkemon menu 0E is animation
    pointers.foe_in_battle = pointers.current_pokemon + 0xC0 -- 2C5ff4
    pointers.foe_status = pointers.foe_in_battle + 0x6C
    pointers.current_hp = mword(pointers.current_pokemon + 0x4C)
    pointers.level = mbyte(pointers.current_pokemon + 0x34)
    pointers.foe_current_hp = mword(pointers.foe_in_battle + 0x4C)
    pointers.facing_direction = mbyte(mem_shift + 0x25E88)

    -- console.log(string.format("%08X", pointers.map_header))
end

local save_counter = 0

function save_game()
    console.log("Saving game...")
    touch_screen_at(125, 75)
    wait_frames(30)
    hold_button("B")
    wait_frames(100)
    release_button("B")
    wait_frames(10)
    touch_screen_at(230, 95)
    wait_frames(30)
    hold_button("B")
    wait_frames(100)
    release_button("B")
    wait_frames(10)
    touch_screen_at(230, 95)
    wait_frames(800)

    console.log("Saving ram")
    client.saveram() -- Flush save ram to the disk	

    press_sequence("B", 10)
end

function get_lead_mon_index()
    -- Returns the first non-fainted Pokémon in the party
    local i = 1
    while i < 6 do if party[i].currentHP ~= 0 then return i end end
end

-----------------------
-- BATTLE BOT ACTIONS
-----------------------

function do_battle()
    -- local battle_state_value = 0

    -- Press B until battle state has advanced
    while ((game_state.in_battle and
        (pointers.battle_state_value == 0 or pointers.battle_state_value == 14))) do
        if (pointers.current_hp == 0 or pointers.foe_current_hp == 0) then
            break
        else
            press_sequence("B", 5)
        end
        -- console.log(pointers.battle_state_value)
    end
    -- console.log("State before stats: " .. pointers.battle_state_value)
    -- console.log("Updating stats")
    if (config.swap_lead_battle) then
        console.log("Config set to swap lead.. swapping now")
        swap_lead_battle()
    end
    wait_frames(100)
    local best_move = pokemon.find_best_move(party[1], foe[1])

    if best_move then
        local move1_pp = mbyte(pointers.current_pokemon + 0x2C)
        local move2_pp = mbyte(pointers.current_pokemon + 0x2D)
        local move3_pp = mbyte(pointers.current_pokemon + 0x2E)
        local move4_pp = mbyte(pointers.current_pokemon + 0x2F)
        local level = pointers.level
        -- console.log(level)

        if not game_state.in_battle then -- Battle over
            return
        elseif pointers.current_hp == 0 then -- Fainted
            console.log("My Pokemon fainted...")
            while game_state.in_battle do
                wait_frames(400)
                touch_screen_at(125, 135) -- FLEE
                wait_frames(500)
                if game_state.in_battle then -- if hit with can't flee message
                    console.log("Could not flee battle reseting...")
                    press_button("Power")
                end
                press_sequence("B", 5)
            end
            return
        elseif pointers.foe_current_hp == 0 then
            console.log("Enemy Pokemon fainted skipping text...")
            save_counter = save_counter + 1
            console.log("Save counter: " .. save_counter)
            while game_state.in_battle do
                touch_screen_at(125, 70)
                if pointers.level ~= level then
                    for i = 1, 30, 1 do
                        touch_screen_at(125, 135)
                        wait_frames(2)
                    end
                    if pointers.battle_state_value == 0x6C then
                        console.log(pointers.battle_state_value)
                        console.log("EVOLVING POGGGGGGGG")
                        for i = 0, 300 do
                            press_button("A")
                            wait_frames(2)
                        end
                        for i = 0, 50, 1 do
                            press_button("B")
                            wait_frames(2)
                        end
                        for i = 0, 20, 1 do
                            press_button("A")
                            wait_frames(2)
                        end
                        return
                    end
                    console.log("Gained Level skipping learn new move")
                    for i = 0, 50, 1 do
                        press_button("B")
                        wait_frames(2)
                    end
                    while game_state.in_battle do
                        touch_screen_at(125, 70)
                        wait_frames(2)
                    end
                end
                wait_frames(2)
            end
            if save_counter == 50 then
                save_game()
                save_counter = 0
                return
            else
                return
            end
        end

        wait_frames(60)

        -- checks if move has pp and is a damaging move
        if (best_move.power > 0) then
            console.debug("Best move against foe is " .. best_move.name ..
                              " (Effective base power is " .. best_move.power ..
                              ")")
            touch_screen_at(128, 96) -- FIGHT
            wait_frames(60)
            local xpos = 80 * (((best_move.index - 1) % 2) + 1)
            local ypos = 50 * (((best_move.index - 1) // 2) + 1)
            touch_screen_at(xpos, ypos) -- Select move slot
            console.log("Attacking now...")
            wait_frames(30)

            party[1].pp[1] = move1_pp -- update moves pp for find_best_move function
            party[1].pp[2] = move2_pp
            party[1].pp[3] = move3_pp
            party[1].pp[4] = move4_pp
            do_battle()
        else
            console.log(
                "Lead Pokemon has no valid moves left to battle! Fleeing...")

            while game_state.in_battle do
                touch_screen_at(125, 175) -- Run
                wait_frames(5)
            end
        end
    else
        -- Wait another frame for valid battle data
        wait_frames(1)
    end
end

function swap_lead_battle()
    -- find strongest_mon
    local strongest_mon_index = 1
    local strongest_mon_first = pointers.level
    local strongest_mon = 0
    for i = 2, #party, 1 do
        strongest_mon = party[i].level
        if strongest_mon_first < strongest_mon then
            strongest_mon_first = strongest_mon
            strongest_mon_index = strongest_mon_index + 1
        end
    end
    -- select strongest_mon
    if strongest_mon_index == 1 then
        return
    else
        while pointers.battle_state_value ~= 0x0A do
            touch_screen_at(215, 165)
            wait_frames(5)
            console.log(pointers.battle_state_value)
        end
        while pointers.battle_state_value == 0x0A do
            local xpos = 80 * (((strongest_mon_index - 1) % 2) + 1)
            local ypos = (40 * (((strongest_mon_index - 1) // 3) + 1) +
                             strongest_mon_index - 1)
            touch_screen_at(xpos, ypos)
            wait_frames(5)
            touch_screen_at(xpos, ypos)
        end
        while (pointers.battle_state_value ~= 0x01) do skip_dialogue() end
    end
end

function catch_pokemon()
    if config.auto_catch then
        console.log("Attempting to catch pokemon now...")
        console.log(config.inflict_status)
        if config.inflict_status or config.false_swipe then
            subdue_pokemon()
        end
        wait_frames(60)
        ::retry::
        wait_frames(100)
        touch_screen_at(40, 170)
        wait_frames(50)
        touch_screen_at(190, 45)
        wait_frames(20)
        touch_screen_at(60, 30)
        wait_frames(20)
        touch_screen_at(100, 170)
        wait_frames(750)
        if mbyte(0x0211194C) == 0x01 then
            console.log("Pokemon caught!!!")
            skip_nickname()
            wait_frames(200)
        else
            console.log("Failed catch trying again...")
            if pointers.foe_status == 0 then
                console.log("Foe not asleep reapplying")
                subdue_pokemon()
            else
                goto retry
            end
        end
    else
        pause_bot("Wild Pokemon meets target specs!")
    end
end

function mode_random_encounters()
    if config.move_direction == "horizontal" or config.move_direction == "vertical" then
        console.log("Attempting to start a battle...")

        local tile_frames = frames_per_move() * 2
        local dir1 = config.move_direction == "horizontal" and "Left" or "Up"
        local dir2 = config.move_direction == "horizontal" and "Right" or "Down"

        hold_button("B")
        while not foe and not game_state.in_battle do
            hold_button(dir1)
            wait_frames(tile_frames)
            release_button(dir1)
            -- release_button("B")
            press_button("A")
            -- hold_button("B")
            hold_button(dir2)
            wait_frames(tile_frames)
            release_button(dir2)
        end
        release_button("B")
        release_button(dir2)
    elseif config.move_direction == "spin" then
        console.log("Attempting to start a battle... and Spinning!")
        wait_frames(200)

        if pointers.facing_direction == 00 then
            while not foe and not game_state.in_battle do
                press_sequence("Left", "Down", "Right", "Up")
            end
        else
            while not foe and not game_state.in_battle do
                press_sequence("Up", "Left", "Down", "Right")
            end
        end

    end

    process_wild_encounter()
    if config.pickup then do_pickup() end
end

function mode_starters()
    -- Get starter data offset for this reset
    local starter_pointer = mdword(0x2111938) + 0x1BF78

    -- Proceed until starters are loaded into RAM
    while mdword(starter_pointer - 0x8) ~= 0 or mdword(starter_pointer - 0x4) ==
        0 do
        starter_pointer = mdword(0x2111938) + 0x1BF78
        local delay = math.random(6, 21) -- Mimic imperfect human inputs
        press_sequence("A", delay)
    end

    if not config.hax then
        press_sequence(130, "A", 15)
    else
        wait_frames(5)
    end

    -- Check all Pokémon
    local is_target = false
    for i = 0, 2, 1 do
        local mon_data = pokemon.decrypt_data(
                             starter_pointer + i * MON_DATA_SIZE)
        local starter = pokemon.parse_data(mon_data, true)

        is_target = pokemon.log_encounter(starter)

        if is_target then
            pause_bot("Starter " .. (i + 1) .. " meets target specs!")
        end

        -- Scroll through each starter and log as they become visible
        if not config.hax and i < 2 then press_sequence("Left", 30) end
    end

    -- Soft reset otherwise
    press_button("Power")
    wait_frames(30)

    -- Wait a random number of frames before mashing A next reset
    -- to decrease the odds of hitting similar seeds
    local delay = math.random(1, 90)
    console.debug("Delaying " .. delay .. " frames...")
    wait_frames(delay)
end

function mode_voltorb_flip()
    local board_pointer = mdword(0x2111938) + 0x45FCC

    local function proceed_text()
        while mdword(board_pointer - 0x4) ~= 0xA0 or
            mdword(board_pointer - 0x14) ~= 0 do press_sequence("A", 6) end
    end

    local function flip_tile(x, y) touch_screen_at(x * 30 - 10, y * 30 - 10) end

    -- The game corner doesn't let you play while holding the maximum of 50k coins
    local coin_count = mword(board_pointer - 0x69BA8)
    if coin_count == 50000 then pause_bot("Can't earn any more coins") end

    proceed_text()

    local tile_index = 0

    -- Iterate through board and flip safe tiles
    for y = 1, 5, 1 do
        for x = 1, 5, 1 do
            local tile_offset = board_pointer + tile_index * 12
            local tile_type = mdword(tile_offset)
            local is_flipped = mdword(tile_offset + 8)

            if (tile_type == 2 or tile_type == 3) and is_flipped == 0 then -- a tile_type of 4 is Voltorb
                -- Tap tile until game registers the flip
                while is_flipped == 0 do
                    is_flipped = mdword(tile_offset + 8)

                    proceed_text()

                    flip_tile(x, y)
                    wait_frames(4)
                end

                press_button("A")
                wait_frames(8)
            end

            tile_index = tile_index + 1
        end
    end

    press_sequence("A", 9)
end

function mode_static_encounters()
    console.log("Waiting for battle to start...")
    
    while not foe and not game_state.in_battle do
        local delay = math.random(6, 21) -- Mimic imperfect human inputs
        press_sequence("A", delay)
    end

    foe_is_target = pokemon.log_encounter(foe[1])

    if not config.hax then
        -- Wait for Pokémon to fully appear on screen
        for i = 0, 22, 1 do press_sequence("A", 6) end
    end

    if foe_is_target then
        pause_bot("Wild Pokémon meets target specs!")
    else
        console.log("Wild " .. foe[1].name .. " was not a target, resetting...")
        press_button("Power")
        wait_frames(30)
    end

    -- Wait a random number of frames before mashing A next reset
    -- to decrease the odds of hitting similar seeds
    local delay = math.random(1, 90)
    console.debug("Delaying " .. delay .. " frames...")
    wait_frames(delay)
end
