-----------------------
-- BASE GEN IV FUNCTIONS
-----------------------
function update_pointers()
    local offset = 0
    
    if _ROM.language == language.GERMAN then
        offset = 0x140
    end
    
    local mem_shift = mdword(0x21C489C + offset)
    local foe_offset = mdword(mem_shift + 0x226FE)

    pointers = {
        party_count = mem_shift + 0xE,
        party_data  = mem_shift + 0x12,

        foe_count   = foe_offset - 0x2B74,
        current_foe = foe_offset - 0x2B70,

        map_header  = mem_shift + 0x11B2,
        trainer_x   = mem_shift + 0x11B8,
        trainer_z   = mem_shift + 0x11BC,
        trainer_y   = mem_shift + 0x11C0,
        facing      = mem_shift + 0x247C6,

        battle_state_value  = mem_shift + 0x44878,        
        battle_indicator    = 0x021A1B2A + offset, -- mostly static
        fishing_bite_indicator = 0x21D5E16,

        trainer_name = mem_shift - 0x22,
        trainer_id = mem_shift - 0x12
    }
end

-----------------------
-- MISC. BOT ACTIONS
-----------------------

function save_game()
    console.log("Saving game...")
    hold_button("X")
    wait_frames(20)
    release_button("X")
    
    -- SAVE button is at a different position before choosing starter
    if mword(pointers.map_header) == 0156 then -- No dex (not a perfect fix)
        while mbyte(0x021C4C86) ~= 04 do
            press_sequence("Up", 10)
        end
    else
        while mbyte(0x021C4C86) ~= 07 do
            press_sequence("Up", 10)
        end
    end

    press_sequence("A", 10)
    hold_button("B")
    wait_frames(100)
    release_button("B")
    press_button("A")
    wait_frames(30)
    hold_button("B")
    wait_frames(100)
    release_button("B")
    press_sequence("A", 5)

    while pointers.saveFlag == 00 do
        press_sequence("B", 5)
    end

    client.saveram() -- Flush save ram to the disk	
    wait_frames(50)
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
            abort("auto cycle off waiting for manual intervention")
        end
    end
    console.log("Lead Pokemon is OK, continuing search...")
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

function do_pickup()
    local pickup_count = 0
    local item_count = 0
    local items = {}

    while not game_state.in_game do
        press_sequence(12, "A")
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
    while pointers.battle_state_value == 14 do
        press_sequence(12, "A")
    end

    wait_frames(60)
    touch_screen_at(128, 90) -- FIGHT
    wait_frames(30)

    local xpos = 80 * (((slot - 1) % 2) + 1)
    local ypos = 50 * (((slot - 1) // 2) + 1)
    touch_screen_at(xpos, ypos) -- Select move slot

    wait_frames(60)
end

function flee_battle()
    while game_state.in_battle do
        touch_screen_at(125, 175) -- Run
        wait_frames(5)
    end

    console.log("Got away safely!")
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
    while ((game_state.in_battle and (pointers.battle_state_value == 0 or pointers.battle_state_value == 14))) do
        if (pointers.current_hp == 0 or pointers.foe_current_hp == 0) then
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
        local move1_pp = mbyte(pointers.current_pokemon + 0x2C)
        local move2_pp = mbyte(pointers.current_pokemon + 0x2D)
        local move3_pp = mbyte(pointers.current_pokemon + 0x2E)
        local move4_pp = mbyte(pointers.current_pokemon + 0x2F)
        local level = pointers.level

        if not game_state.in_battle then   -- Battle over
            return
        elseif pointers.current_hp == 0 then -- Fainted or learning new move
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
        elseif pointers.foe_current_hp == 0 then
            console.log("Enemy Pokemon fainted skipping text...")
            while game_state.in_battle do
                touch_screen_at(125, 70)
                
                if pointers.level ~= level then
                    for i = 1, 50, 1 do
                        touch_screen_at(125, 135)
                        wait_frames(2)
                    end
                    for i = 1, 20, 1 do
                        touch_screen_at(125, 70)
                        wait_frames(2)
                    end
                    if pointers.battle_state_value == 0x6C or pointers.battle_state_value == 0x14 then
                        -- Evolving
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
    local strongest_mon_first = pointers.level
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
        while pointers.battle_state_value ~= 0x0A do
            touch_screen_at(215, 165)
            wait_frames(5)
        end
        while pointers.battle_state_value == 0x0A do
            local xpos = 80 * (((strongest_mon_index - 1) % 2) + 1)
            local ypos = (40 * (((strongest_mon_index - 1) // 3) + 1) + strongest_mon_index - 1)
            touch_screen_at(xpos, ypos)
            wait_frames(5)
            touch_screen_at(xpos, ypos)
        end
        while (pointers.battle_state_value ~= 0x01) do
            press_sequence(12, "A")
        end
    end
end

function catch_pokemon()
    while game_state.in_battle and pointers.battle_state_value == 0 do
        press_sequence("B", 5)
    end
    if config.auto_catch then
        if config.inflict_status or config.false_swipe then
            subdue_pokemon()
        end
        while pointers.battle_state_value == 14 do
            press_sequence("B", 5)
        end
        wait_frames(60)
        
        ::retry::
        while pointers.battle_state_value ~= 01 do
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
            skip_nickname()
            wait_frames(200)
        else
            if pointers.foe_status == 0 then
                subdue_pokemon()
            else
                goto retry
            end
        end
    else
        abort("Wild Pokemon meets target specs!")
    end
end

function process_wild_encounter()
    -- Check all foes in case of a double battle in Eterna Forest
    local foe_is_target = false
    for i = 1, #foe, 1 do
        foe_is_target = pokemon.log_encounter(foe[i]) or foe_is_target
    end
	
    wait_frames(30)
    
    if foe_is_target then
        catch_pokemon()
    else
        while game_state.in_battle do
            if config.battle_non_targets then
                console.log("Wild " .. foe[1].name .. " is not a target, and battle non tartgets is on. Battling!")
                do_battle()
                return
            else
                if config.mode_static_encounters then
                    press_button("Power")
                else
                    console.log("Wild " .. foe[1].name .. " is not a target, fleeing!")
                    flee_battle()
                end
            end
        end
    end
end

-----------------------
-- BOT ENCOUNTER MODES
-----------------------
function mode_static_encounters()
    console.log("Waiting for battle to start...")
    
    while not game_state.in_battle do
        local delay = math.random(6, 21) -- Mimic imperfect human inputs
        press_sequence("A", delay)
    end

    foe_is_target = pokemon.log_encounter(foe[1])

    if not config.hax then
        -- Wait for Pokémon to fully appear on screen
        for i = 0, 22, 1 do press_sequence("A", 6) end
    end

    if foe_is_target then
        abort("Wild Pokémon meets target specs!")
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

function mode_starters(starter)
    if not game_state.in_game then
        console.log("Waiting to reach overworld...")

        while not game_state.in_battle do
            press_sequence(12, "A")
        end
    end

    hold_button("Up") -- Enter Lake Verity
    console.log("Waiting to reach briefcase...")

    -- Skip through dialogue until starter select
    while not (mdword(pointers.starters_ready) > 0) do
        press_sequence(12, "A")
    end

    release_button("Up")

    -- Highlight and select target
    console.log("Selecting starter...")

    while mdword(pointers.selected_starter) < starter do
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
    local was_target = pokemon.log_encounter(mon)

    if was_target then
        abort("Starter meets target specs!")
    else
        console.log("Starter was not a target, resetting...")
        press_button("Power")
        wait_frames(180)
    end
end

function mode_random_encounters()
    console.log("Attempting to start a battle...")
    wait_frames(30)

    if config.move_direction == "spin" then
        -- Prevent accidentally taking a step by
        -- preventing a down input while facing down
        if mbyte(pointers.facing) == 1 then
            press_sequence("Right", 3)
        end
        
        while not game_state.in_battle do
            press_sequence(
                "Down", 3,
                "Left", 3,
                "Up", 3,
                "Right", 3
            )
        end
    else
        local dir1, dir2, start_face
        
        if config.move_direction == "horizontal" then
            dir1 = "Left"
            dir2 = "Right"
            start_face = 2
        else
            dir1 = "Up"
            dir2 = "Down"
            start_face = 0
        end

        if mbyte(pointers.facing) ~= start_face then
            press_sequence(dir2, 8)
        end

        hold_button("B")
        
        while not game_state.in_battle do
            hold_button(dir1)
            wait_frames(7)
            hold_button(dir2)
            wait_frames(7)
        end

        release_button("B")
    end

    process_wild_encounter()
    
    if config.pickup then
        do_pickup()
    end
end

function mode_fishing()
    while true do
        press_button("Y")
        wait_frames(60)

        while mbyte(pointers.fishing_bite_indicator) == 0x00 do
            wait_frames(1)
        end

        if mbyte(pointers.fishing_bite_indicator) == 0x01 then
            console.log("Landed a Pokémon!")
            break
        else
            console.log("Not even a nibble...")
            press_sequence(30, "A", 20)
        end
    end

    while not game_state.in_battle do
        press_sequence("A", 5)
    end

    process_wild_encounter()

    wait_frames(90)
end

function mode_gift()
    if not game_state.in_game then
        console.log("Waiting to reach overworld...")

        while not game_state.in_game do
            local delay = math.random(5, 30) -- Mimic imperfect human inputs
            press_sequence("A", delay)
        end
    end

    wait_frames(60)
    
    local og_party_count = #party
    while #party == og_party_count do
        press_sequence("A", 5)
    end

    press_sequence(180, "B", 60) -- Decline nickname
    
    if not config.hax then
        -- Party menu
        press_sequence("X", 30)
        touch_screen_at(65, 45)
        wait_frames(90)

        touch_screen_at(80 * ((#party - 1) % 2 + 1), 30 + 50 * ((#party - 1) // 2)) -- Select gift mon
        wait_frames(30)

        touch_screen_at(200, 105) -- SUMMARY
        wait_frames(120)
    end

    local mon = party[#party]
    local was_target = pokemon.log_encounter(mon)

    if was_target then
        if config.save_game_after_catch then
            console.log("Gift Pokemon meets target specs! Saving...")

            if not config.hax then
                press_sequence("B", 120, "B", 120, "B", 60) -- Exit out of menu
            end

            save_game()
        end

        abort("Gift Pokemon meets target specs")
    else
        console.log("Gift Pokemon was not a target, resetting...")
        press_button("Power")
        wait_frames(60)
    end
end

function read_string(input, offset)
    local char_table = {"💰", "🗝️", "💿", "✉️", "💊", "🍓", "◓", "💥", "←", "↑", "↓", "→",
                    "►", "＆", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F",
                    "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y",
                    "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r",
                    "s", "t", "u", "v", "w", "x", "y", "z", "À", "Á", "Â", "Ã", "Ä", "Å", "Æ", "Ç", "È",
                    "É", "Ê", "Ë", "Ì", "Í", "Î", "Ï", "Ð", "Ñ", "Ò", "Ó", "Ô", "Õ", "Ö", "×", "Ø",
                    "Ù", "Ú", "Û", "Ü", "Ý", "Þ", "ß", "à", "á", "â", "ã", "ä", "å", "æ", "ç", "è",
                    "é", "ê", "ë", "ì", "í", "î", "ï", "ð", "ñ", "ò", "ó", "ô", "õ", "ö", "÷", "ø",
                    "ù", "ú", "û", "ü", "ý", "þ", "ÿ", "Œ", "œ", "Ş", "ş", "ª", "º", "er", "re", "r",
                    "₽", "¡", "¿", "!", "?", ", ", ".", "…", "･", "/", "‘", "’", "“", "”", "„",
                    "«", "»", "(", ")", "♂", "♀", "+", "-", "*", "#", "=", "&", "~", ":", ";", "♠", "♣",
                    "♥", "♦", "★", "◎", "○", "□", "△", "◇", "@", "♪", "%", "☀", "☁", "☂",
                    "☃", "😑", "☺", "☹", "😠", "⤴︎", "⤵︎", "💤", " ", "PK", "MN", " ", " ",
                    " ", " ", " ", "°", "_", "＿", "․", "‥"}
    local text = ""

    if type(input) == "table" then
        -- Read data from an inputted table of bytes
        for i = offset + 1, #input, 2 do
            local value = input[i] + (input[i] << 8)

            if value == 0xFFFF or value == 0x0000 then -- Null terminator
                break
            end

            text = text .. char_table[(value - 0x112) & 0xFF]
        end
    else
        -- Read data from an inputted address
        for i = input, input + 32, 2 do
            local value = mword(i)

            if value == 0xFFFF or value == 0x0000 then -- Null terminator
                break
            end

            text = text .. (char_table[(value - 0x112) & 0xFF] or "?")
        end
    end

    return text
end