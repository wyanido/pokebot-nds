function update_pointers()
    offset.party_count = mdword(0x021C489C) + 14
    offset.party_data = offset.party_count + 4

    offset.foe_count = mdword(0x21C5A08) + 0x729C
    offset.current_foe = offset.foe_count + 4

    offset.map_header = mdword(0x21C489C) + 0x11B2
    offset.trainer_x = offset.map_header + 4 + 2
    offset.trainer_y = offset.map_header + 12 + 2
    offset.trainer_z = offset.map_header + 8 + 2
    local mem_shift = mdword(0x21C0794)
    offset.battle_state_value = mem_shift + 0x44878

    --console.log(string.format("%08X", offset.battle_state_value))
end

local save_counter = 0
-----------------------
-- MISC. BOT ACTIONS
-----------------------

function save_game()
    wait_frames(100)
    console.log("Saving game...")
    hold_button("X")
    wait_frames(20)
    release_button("X")
    console.log("Starting Map Check...")
    -- SAVE button is at a different position before choosing starter
    if mword(offset.map_header) == 0156 then -- No dex (not a perfect fix)
        while mbyte(0x021C4C86) ~= 04 do
            press_sequence("Up", 10)
        end
    else
        console.log("Not on first route...")
        while mbyte(0x021C4C86) ~= 07 do
            press_sequence("Up", 10)
        end
    end
    press_sequence("A", 10)
    console.log("Pressing A")
    hold_button("B")
    console.log("Holding B")
    wait_frames(100)
    release_button("B")
    press_button("A")
    console.log("Pressing A")
    wait_frames(30)
    hold_button("B")
    console.log("Holding B")
    wait_frames(100)
    release_button("B")
    console.log("Starting to save")
    press_sequence("A", 800)

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
        hold_button("B")
        hold_button(button)
        if dz < 2 then
            release_button("B")
        end
    end
    clear_all_inputs()
end

function move_horizontally(target)
    while target ~= game_state.trainer_x do
        local dx = target - game_state.trainer_x
        local button = dx > 0 and "Right" or "Left"

        hold_button("B")
        hold_button(button)
        if dx < 2 then
            release_button("B")
        end
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
    if (offset.trainer_z == 825) then
        move_vertically(826)
    end
    move_horizontally(184)
    move_vertically(843)
    move_horizontally(177)
    move_vertically(842)
    wait_frames(200)
    move_vertically(6)
    wait_frames(5)
    press_button("A")
    wait_frames(5)
    hold_button("B")
    for i = 1, 60, 1 do
        press_button("A")
        wait_frames(1)
    end
    release_button("B")
    for i = 1, 200, 1 do
        press_button("B")
        wait_frames(1)
    end
    move_vertically(12)
    hold_button("Down")
    wait_frames(10)
    release_button("Down")
    move_horizontally(184)
    move_vertically(829)
    move_horizontally(179)
    save_game()
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
            press_sequence(60, "X", 30)
            while mbyte(0x021C4C86) ~= 02 do
                press_sequence("Up", 10)
            end
            press_button("A")
            wait_frames(120)
            console.log("Item count: " .. item_count)
            for i = 1, #items, 1 do
                if items[i] ~= "none" then
                    console.log("getting item from mon at slot: " .. i)
                    if i % 2 == 0 then
                        press_button("Right")
                        wait_frames(5)
                    end
                    if i == 3 or i == 4 then
                        press_button("Down")
                        wait_frames(5)
                    end
                    if i == 5 or i == 6 then
                        press_button("Down")
                        wait_frames(5)
                        press_button("Down")
                        wait_frames(5)
                    end
                    press_sequence("A", 5, "Down", 5, "Down", 5, "A", 5, "Down", 5, "A")
                    wait_frames(200)
                    press_button("B")
                end
            end
            press_sequence(30, "B", 150, "B", 100)
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
    while offset.battle_state_value == 14 do
        skip_dialogue()
    end
    console.log("Using Subdue Move")
    wait_frames(60)
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
    wait_frames(100)
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
    -- Press B until battle state has advanced
    while ((game_state.in_battle and (offset.battle_state_value == 0 or offset.battle_state_value == 14))) do
        if (offset.current_hp == 0 or offset.foe_current_hp == 0) then
            break
        else
            press_sequence("B", 5)
        end
    end

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

        if not game_state.in_battle then   -- Battle over
            return
        elseif offset.current_hp == 0 then -- Fainted or learning new move
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
                --console.log("Gained Level skipping learn new move")
                if offset.level ~= level then
                    for i = 1, 50, 1 do
                        --console.log("touching screen at 125, 135")
                        touch_screen_at(125, 135)
                        wait_frames(2)
                    end
                    for i = 1, 20, 1 do
                        touch_screen_at(125, 70)
                        wait_frames(2)
                    end
                    if offset.battle_state_value == 0x6C or offset.battle_state_value == 0x14 then
                        --console.log(offset.battle_state_value)
                        console.log("EVOLVING POGGGGGGGG")
                        for i = 0, 300, 1 do
                            press_button("A")
                            wait_frames(2)
                        end
                        for i = 0, 90, 1 do
                            press_button("B")
                            wait_frames(2)
                        end
                        for i = 0, 20, 1 do
                            press_button("A")
                            wait_frames(2)
                        end
                        return
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
    while (game_state.in_battle and (offset.battle_state_value == 0)) do
        press_sequence("B", 5)
    end
    if config.auto_catch then
        console.log("Attempting to catch pokemon now...")
        if config.inflict_status or config.false_swipe then
            subdue_pokemon()
        end
        while offset.battle_state_value == 14 do
            press_sequence("B", 5)
        end
        wait_frames(60)
        ::retry::
        while offset.battle_state_value ~= 01 do
            press_sequence("B", 5)
        end
        wait_frames(10)
        touch_screen_at(40, 170)
        wait_frames(50)
        touch_screen_at(190, 45)
        wait_frames(20)
        touch_screen_at(60, 30)
        wait_frames(20)
        touch_screen_at(100, 170)
        wait_frames(750)
        if mbyte(0x02101DF0) == 0x01 then
            console.log("Pokemon caught!!!")
            skip_nickname()
            wait_frames(200)
            if config.sandgemloop then
                to_and_from_pokecenter()
            end
        else
            console.log("Failed catch trying again...")
            if config.foe_status == 0 then
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

    --[[if foe[1].PID == old_mon_id then
        console.log("Same Pokemon encountered... returning to main loop")
        return]]

    wait_frames(30)

    if foe_is_target then
        console.log("Wild " .. foe[1].name .. " is a target!!! Catching Now")
        catch_pokemon()
    else
        while game_state.in_battle do
            if config.battle_non_targets then
                console.log("Wild " .. foe[1].name .. " is not a target, and battle non tartgets is on. Battling!")
                do_battle()
                return
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
function mode_static_encounters()
    if not game_state.in_game then
        console.log("Waiting to reach overworld...")

        while not game_state.in_game do
            skip_dialogue()
        end
        while not game_state.in_battle do
            press_button("A")
        end
        while game_state.in_battle and offset.battle_state_value == 0 do
            press_sequence("B", 5)
        end
        mon = foe[1]
        local was_target = pokemon.log(mon)
        if was_target then
            if config.auto_catch then
                console.log("Pokemon meets target specs!")
                catch_pokemon()
            else
                pause_bot("Pokemon meets target specs!")
            end
        else
            press_button("Power")
        end
    end
end

function mode_starters_DP(starter)
    if not game_state.in_game then
        console.log("Waiting to reach overworld...")

        while not game_state.in_battle do
            skip_dialogue()
        end
    end

    hold_button("Up") -- Enter Lake Verity
    console.log("Waiting to reach briefcase...")

    -- Skip through dialogue until starter select
    while not (mdword(offset.starters_ready) > 0) do
        skip_dialogue()
    end

    release_button("Up")

    -- Highlight and select target
    console.log("Selecting starter...")

    while mdword(offset.selected_starter) < starter do
        press_sequence("Right", 5)
    end

    while #party == 0 do
        press_sequence("A", 6)
    end

    if not config.hax then
        console.log("Waiting to see starter...")

        for i = 0, 86, 1 do
            press_button("A")
            clear_unheld_inputs()
            wait_frames(6)
        end
    end

    mon = party[1]
    local was_target = pokemon.log(mon)

    if was_target then
        pause_bot("Starter meets target specs!")
    else
        console.log("Starter was not a target, resetting...")
        press_button("Power")
        wait_frames(180)
    end
end

function mode_starters(starter) --starters for platinum
    if not game_state.in_game then
        console.log("Waiting to reach overworld...")

        while mbyte(offset.battle_indicator) == 0x1D do
            local rand1 = math.random(3, 60)
            console.log(rand1)
            press_button("A")
            wait_frames(rand1)
        end
    end --]]

    while mbyte(offset.battle_indicator) ~= 0xFF do
        local rand2 = math.random(3, 60)
        wait_frames(rand2)
        press_button("A")
        wait_frames(rand2)
    end
    --we can save right in front of the bag in platinum so all we have to do is open and select are starter

    -- Open briefcase and skip through dialogue until starter select
    console.log("Skipping dialogue to briefcase")
    local selected_starter = mdword(0x2101DEC) + 0x203E8 -- 0: Turtwig, 1: Chimchar, 2: Piplup
    local starters_ready = selected_starter + 0x84       -- 0 before hand appears, A94D afterwards

    while not (mdword(starters_ready) > 0) do
        press_button("B")
        wait_frames(2)
    end

    -- Need to wait for hand to be visible to find offset
    console.log("Selecting starter...")

    -- Highlight and select target
    while mdword(selected_starter) < starter do
        press_sequence("Right", 10)
    end

    while #party == 0 do
        press_sequence("A", 6)
    end

    console.log("Waiting to see starter...")
    if config.hax then
        mon = party[1]
        local was_target = pokemon.log(mon)
        if was_target then
            pause_bot("Starter meets target specs!")
        else
            press_button("Power")
        end
    else
        while not offset.in_starter_battle ~= 0x41 do
            skip_dialogue()
        end
        local battle_state_value = 0
        while offset.in_starter_battle == 0x41 and battle_state_value == 0 do
            press_sequence("B", 5)
            --console.log("Battle State: " .. mbyte(offset.battle_state_value))
            battle_state_value = mbyte(offset.battle_state_value) --should set to 01
        end
        wait_frames(50)
        mon = party[1]
        local was_target = pokemon.log(mon)
        if was_target then
            pause_bot("Starter meets target specs!")
        else
            console.log("Starter was not a target, resetting...")
            selected_starter = 0
            starters_ready = 0
            press_button("Power")
        end
    end
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
    wait_frames(200)
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
    wait_frames(100)
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

function mode_sandgem_loop()
    --use either movement mode then check status after every battle, if status bad return player to pokecenter to heal
    if config.move_direction == "Horizontal" or config.move_direction == "Vertical" then
        mode_random_encounters_running()
    elseif config.move_direction == "Spin" then
        mode_spin_to_win()
    end
    check_status()
end
