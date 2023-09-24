-----------------------
-- DP FUNCTION OVERRIDES
-----------------------
function update_pointers()
    offset.party_count = mdword(0x021D10EC) + 14
    offset.party_data = offset.party_count + 4

    offset.foe_count = mdword(0x21D4158) + 0x7574
    offset.current_foe = offset.foe_count + 4

    offset.map_header = mdword(0x21D2228) + 0x1244
    offset.trainer_x = offset.map_header + 4 + 2
    offset.trainer_y = offset.map_header + 12 + 2
    offset.trainer_z = offset.map_header + 8 + 2

    local mem_shift = mdword(0x21D2228)                    --27C1E0  --value @ 2C32B4
    offset.battle_state = mem_shift + 0x470D4
    offset.battle_state_value = mbyte(offset.battle_state) --01 is FIGHT menu, 04 is Move Select, 08 is Bag,
    offset.current_pokemon = mem_shift + 0x49E14           -- 0A is POkemon menu 0E is animation
    offset.foe_in_battle = offset.current_pokemon + 0xC0   --2C5ff4
    offset.foe_status = offset.foe_in_battle + 0x6C
    offset.current_hp = mword(offset.current_pokemon + 0x4C)
    offset.level = mbyte(offset.current_pokemon + 0x34)
    offset.foe_current_hp = mword(offset.foe_in_battle + 0x4C)
    offset.facing_direction = mbyte(mem_shift + 0x25E88)

    -- console.log(string.format("%08X", offset.map_header))
end

local save_counter = 0
-----------------------
-- MISC. BOT ACTIONS
-----------------------

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

function skip_nickname()
    while game_state.in_battle do
        touch_screen_at(125, 140)
        wait_frames(20)
    end
    wait_frames(150)
    save_game()
end

function check_status()
    if #party == 0 or game_state.in_battle then -- Don't check party status if bot was started during a battle
        return nil
    end

    -- Check how many valid move uses the lead has remaining
    local lead_pp_sum = 0
    for i = 1, #party[1].moves, 1 do
        local pp = party[1].pp[i]
        local power = party[1].moves[i].power
        if pp ~= 0 and power ~= nil then
            lead_pp_sum = lead_pp_sum + pp
        end
    end

    if party[1].currentHP == 0 or party[1].currentHP < (party[1].maxHP / 5) or (lead_pp_sum == 0 and config.battle_non_targets) then
        console.log("Lead Pokemon can no longer battle...")
        if config.cycle_lead_pokemon then
            console.log("Finding a suitable replacement")
        else
            if config.mode == "sandgem_loop" then
                console.log("Headed to pokecenter to heal")
                to_and_from_pokecenter()
            else
                pause_bot("auto cycle off waiting for manual intervention")
            end
        end
    end
    console.log("Lead Pokemon is OK, continuing search...")
end

function move_vertically(target)
    while target ~= game_state.trainer_z do
        local dz = target - game_state.trainer_z
        local button = dz > 0 and "Down" or "Up"
        hold_button(button)
    end
    clear_all_inputs()
end

function move_horizontally(target)
    while target ~= game_state.trainer_x do
        local dx = target - game_state.trainer_x
        local button = dx > 0 and "Right" or "Left"
        hold_button(button)
    end
    clear_all_inputs()
end

function get_lead_mon_index()
    -- Returns the first non-fainted Pokémon in the party
    local i = 1
    while i < 6 do
        if party[i].currentHP ~= 0 then
            return i
        end
    end
end

function to_and_from_pokecenter() --starts at grass patch and moves to pokecenter and heals and goes back
    --TODO Change to new route loop
end

function do_pickup()
    local pickup_count = 0
    local item_count = 0
    local items = {}

    while not game_state.in_game do
        skip_dialogue()
    end

    for i = 1, #party, 1 do
        table.insert(items, party[i].heldItem)

        if party[i].ability == "Pickup" then
            pickup_count = pickup_count + 1

            if party[i].heldItem ~= "none" then
                item_count = item_count + 1
            end
        end
    end

    if pickup_count > 0 then
        if item_count < tonumber(config.pickup_threshold) then
            console.log("Pickup items in party: " ..
                item_count .. ". Collecting at threshold: " .. config.pickup_threshold)
        else
            wait_frames(60)
            touch_screen_at(45, 75)
            wait_frames(120)

            console.log("Item count: " .. item_count)
            for i = 1, #items, 1 do
                if items[i] ~= "none" then
                    console.log("getting item from mon at slot: " .. i)
                    touch_screen_at(80 * ((i - 1) % 2 + 1), 30 + 50 * ((i - 1) // 2))
                    wait_frames(50)
                    touch_screen_at(190, 100)
                    wait_frames(50)
                    touch_screen_at(175, 65)
                    wait_frames(200)
                    press_button("B")
                end
            end
            press_sequence(30, "B", 120, "B", 60)
        end
    else
        console.log("Pickup is enabled in config, but no Pokemon have the pickup ability.")
    end
end

-----------------------
-- BATTLE BOT ACTIONS
-----------------------

function get_mon_move_slot(mon, move_name)
    for i, v in ipairs(mon.moves) do
        if v.name == move_name and mon.pp[i] > 0 then
            return i
        end
    end
    return 0
end

function use_move_at_slot(slot)
    -- Skip text to FIGHT menu
    while game_state.in_battle and (offset.battle_state_value == 0 or offset.battle_state_value == 14) do
        skip_dialogue()
    end
    console.log("Using Subdue Move")
    wait_frames(30)
    touch_screen_at(128, 90) -- FIGHT
    wait_frames(30)
    local xpos = 80 * (((slot - 1) % 2) + 1)
    local ypos = 50 * (((slot - 1) // 2) + 1)
    touch_screen_at(xpos, ypos) -- Select move slot
    wait_frames(60)
end

function flee_battle()
    while (game_state.in_battle and offset.battle_state_value == 0) do
        press_sequence("B", 5)
    end
    while game_state.in_battle do
        touch_screen_at(125, 175) -- Run
        wait_frames(5)
    end
end

function subdue_pokemon()
    console.log("Attempting to subdue pokemon...")
    if config.false_swipe then
        -- Ensure target has no recoil moves before attempting to weaken it
        local recoil_moves = { "Brave Bird", "Double-Edge", "Flare Blitz", "Head Charge", "Head Smash", "Self-Destruct",
            "Take Down", "Volt Tackle", "Wild Charge", "Wood Hammer" }
        local recoil_slot = 0

        for _, v in ipairs(recoil_moves) do
            recoil_slot = get_mon_move_slot(foe[1], v)

            if recoil_slot ~= 0 then
                console.warning("The target has a recoil move. False Swipe won't be used.")
                break
            end
        end

        if recoil_slot == 0 then
            -- Check whether the lead actually has False Swipe
            local false_swipe_slot = get_mon_move_slot(party[get_lead_mon_index()], "False Swipe")

            if false_swipe_slot == 0 then
                console.warning("The lead Pokemon can't use False Swipe.")
            else
                use_move_at_slot(false_swipe_slot)
            end
        end
    end

    if config.inflict_status then
        -- Status moves in order of usefulness
        local status_moves = { "Spore", "Sleep Powder", "Lovely Kiss", "Dark Void", "Hypnosis", "Sing", "Grass Whistle",
            "Thunder Wave", "Glare", "Stun Spore", "Yawn" }
        local status_slot = 0

        for i = 1, #foe[1].type, 1 do
            if foe[1].type[i] == "Ground" then
                console.debug("Foe is Ground-type. Thunder Wave can't be used.")
                table.remove(status_moves, 8) -- Remove Thunder Wave from viable options if target is Ground type
                break
            end
        end

        -- Remove Grass type status moves if target has Sap Sipper
        if foe[1].ability == "Sap Sipper" then
            local grass_moves = { "Spore", "Sleep Powder", "Grass Whistle", "Stun Spore" }

            for i, k in ipairs(grass_moves) do
                for i2, k2 in pairs(status_moves) do
                    if k == k2 then
                        table.remove(status_moves, i2)
                        break
                    end
                end
            end
        end

        for _, v in ipairs(status_moves) do
            status_slot = get_mon_move_slot(party[get_lead_mon_index()], v)

            if status_slot ~= 0 then
                break
            end
        end

        if status_slot > 0 then
            if party[1].moves[status_slot].name == "Yawn" then
                console.log("Using First Yawn")
                use_move_at_slot(status_slot)
            end
            -- Bot will blindly use the status move once and hope it lands
            console.log("Using Second Yawn")
            use_move_at_slot(status_slot)
        else
            console.warning("The lead Pokemon has no usable status moves.")
        end
    end
end

function do_battle()
    --local battle_state_value = 0

    -- Press B until battle state has advanced
    while ((game_state.in_battle and (offset.battle_state_value == 0 or offset.battle_state_value == 14))) do
        if (offset.current_hp == 0 or offset.foe_current_hp == 0) then
            break
        else
            press_sequence("B", 5)
        end
        --console.log(offset.battle_state_value)
    end
    --console.log("State before stats: " .. offset.battle_state_value)
    --console.log("Updating stats")
    if (config.swap_lead_battle) then
        console.log("Config set to swap lead.. swapping now")
        swap_lead_battle()
    end
    wait_frames(100)
    local best_move = pokemon.find_best_move(party[1], foe[1])

    if best_move then
        local move1_pp = mbyte(offset.current_pokemon + 0x2C)
        local move2_pp = mbyte(offset.current_pokemon + 0x2D)
        local move3_pp = mbyte(offset.current_pokemon + 0x2E)
        local move4_pp = mbyte(offset.current_pokemon + 0x2F)
        local level = offset.level
        --console.log(level)

        if not game_state.in_battle then   -- Battle over
            return
        elseif offset.current_hp == 0 then -- Fainted
            console.log("My Pokemon fainted...")
            while game_state.in_battle do
                wait_frames(400)
                touch_screen_at(125, 135)    -- FLEE
                wait_frames(500)
                if game_state.in_battle then --if hit with can't flee message
                    console.log("Could not flee battle reseting...")
                    press_button("Power")
                end
                press_sequence("B", 5)
            end
            return
        elseif offset.foe_current_hp == 0 then
            console.log("Enemy Pokemon fainted skipping text...")
            save_counter = save_counter + 1
            console.log("Save counter: " .. save_counter)
            while game_state.in_battle do
                touch_screen_at(125, 70)
                if offset.level ~= level then
                    for i = 1, 30, 1 do
                        touch_screen_at(125, 135)
                        wait_frames(2)
                    end
                    if offset.battle_state_value == 0x6C then
                        console.log(offset.battle_state_value)
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

        --checks if move has pp and is a damaging move
        if (best_move.power > 0) then
            console.debug("Best move against foe is " ..
                best_move.name .. " (Effective base power is " .. best_move.power .. ")")
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
            console.log("Lead Pokemon has no valid moves left to battle! Fleeing...")

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
    --find strongest_mon
    local strongest_mon_index = 1
    local strongest_mon_first = offset.level
    local strongest_mon = 0
    for i = 2, #party, 1 do
        strongest_mon = party[i].level
        if strongest_mon_first < strongest_mon then
            strongest_mon_first = strongest_mon
            strongest_mon_index = strongest_mon_index + 1
        end
    end
    --select strongest_mon
    if strongest_mon_index == 1 then
        return
    else
        while offset.battle_state_value ~= 0x0A do
            touch_screen_at(215, 165)
            wait_frames(5)
            console.log(offset.battle_state_value)
        end
        while offset.battle_state_value == 0x0A do
            local xpos = 80 * (((strongest_mon_index - 1) % 2) + 1)
            local ypos = (40 * (((strongest_mon_index - 1) // 3) + 1) + strongest_mon_index - 1)
            touch_screen_at(xpos, ypos)
            wait_frames(5)
            touch_screen_at(xpos, ypos)
        end
        while (offset.battle_state_value ~= 0x01) do
            skip_dialogue()
        end
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
            if offset.foe_status == 0 then
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

function process_wild_encounter()
    -- Check all foes in case of a double battle in Eterna Forest
    local foe_is_target = false
    for i = 1, #foe, 1 do
        foe_is_target = pokemon.log(foe[i]) or foe_is_target
    end

    wait_frames(30)

    if foe_is_target then
        console.log("Wild " .. foe[1].name .. " is a target!!! Catching Now")
        catch_pokemon()
    else
        while game_state.in_battle do
            if config.battle_non_targets then
                console.log("Wild " .. foe[1].name .. " is not a target, and battle non tartgets is on. Battling!")
                do_battle()
            else
                console.log("Wild " .. foe[1].name .. " is not a target, fleeing!")
                flee_battle()
            end
        end
    end
end

-----------------------
-- BOT ENCOUNTER MODES
-----------------------
function mode_starters()
    wait_frames(30)

    -- Get starter data offset for this reset
    local starter_pointer = mdword(0x2111938) + 0x1BF78

    -- Proceed until starters are loaded into RAM
    while mdword(starter_pointer - 0x8) ~= 0 or mdword(starter_pointer - 0x4) == 0 do
        rand = math.random(8, 50)
        wait_frames(rand)
        press_sequence("A", 10)
    end

    if not config.hax then
        press_sequence(130, "A", 15)
    else
        wait_frames(5)
    end

    -- Check all Pokémon
    local is_target = false
    for i = 0, 2, 1 do
        local starter = pokemon.read_data(starter_pointer + i * MON_DATA_SIZE)
        is_target = pokemon.log(pokemon.enrich_data(starter))

        if is_target then
            pause_bot("Starter " .. (i + 1) .. " meets target specs!")
        end

        -- Scroll through each starter and log as they become visible
        if not config.hax and i < 2 then
            press_sequence("Left", 30)
        end
    end

    -- Soft reset otherwise
    press_button("Power")
    wait_frames(30)
end

function mode_random_encounters()
    if config.move_direction == "Horizontal" or config.move_direction == "Vertical" then
        mode_random_encounters_running()
    elseif config.move_direction == "Spin" then
        mode_spin_to_win()
    end
end

function mode_random_encounters_running()
    console.log("Attempting to start a battle...")

    local tile_frames = frames_per_move() * 2
    local dir1 = config.move_direction == "Horizontal" and "Left" or "Up"
    local dir2 = config.move_direction == "Horizontal" and "Right" or "Down"

    hold_button("B")
    while not foe and not game_state.in_battle do
        hold_button(dir1)
        wait_frames(tile_frames)
        release_button(dir1)
        --release_button("B")
        press_button("A")
        --hold_button("B")
        hold_button(dir2)
        wait_frames(tile_frames)
        release_button(dir2)
    end
    release_button("B")
    release_button(dir2)

    process_wild_encounter()
    if config.pickup then
        do_pickup()
    end
end

function mode_spin_to_win()
    console.log("Attempting to start a battle... and Spinning!")
    wait_frames(200)
    if offset.facing_direction == 00 then
        while not foe and not game_state.in_battle do
            press_sequence("Left", "Down", "Right", "Up")
        end
    else
        while not foe and not game_state.in_battle do
            press_sequence("Up", "Left", "Down", "Right")
        end
    end

    process_wild_encounter()
    if config.pickup then
        do_pickup()
    end
end

function mode_voltorb_flip()
    local board_pointer = mdword(0x2111938) + 0x45FCC

    local function proceed_text()
        while mdword(board_pointer - 0x4) ~= 0xA0 or mdword(board_pointer - 0x14) ~= 0 do
            press_sequence("A", 6)
        end
    end

    local function flip_tile(x, y)
        touch_screen_at(x * 30 - 10, y * 30 - 10)
    end

    -- The game corner doesn't let you play while holding the maximum of 50k coins
    local coin_count = mword(board_pointer - 0x69BA8)
    if coin_count == 50000 then
        pause_bot("Can't earn any more coins")
    end

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
