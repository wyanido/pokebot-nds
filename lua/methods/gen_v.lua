function update_pointers()
    local offset = (_ROM.version == version.WHITE) and 0x20 or 0x0 -- White version is offset slightly

    pointers = {
        -- Bag pouches, 4 byte pairs | 0001 0004 = 4x Master Ball
        items_pouch = 0x02233FAC + offset, -- 1240 bytes long
        key_items_pouch = 0x02234484 + offset, -- 332 bytes long
        tms_hms_case = 0x022345D0 + offset, -- 436 bytes long
        medicine_pouch = 0x02234784 + offset, -- 192 bytes long
        berries_pouch = 0x02234844 + offset, -- 234 bytes long

        running_shoes = 0x0223C054 + offset, -- 0 before receiving

        -- Party
        party_count = 0x022349B0 + offset, -- 4 bytes before first index
        party_data = 0x022349B4 + offset, -- PID of first party member

        step_counter = 0x02235125 + offset,
        step_cycle = 0x02235126 + offset,

        -- Location
        map_header = 0x0224F90C + offset,
        trainer_x = 0x0224F910 + offset,
        trainer_y = 0x0224F914 + offset,
        trainer_z = 0x0224F918 + offset,
        trainer_direction = 0x0224F924 + offset, -- 0, 4, 8, 12 -> Up, Left, Down, Right
        on_bike = 0x0224F94C + offset,
        encounter_table = 0x0224FFE0 + offset,
        map_matrix = 0x02250C1C + offset,

        phenomenon_x = 0x02257018 + offset,
        phenomenon_z = 0x0225701C + offset,

        egg_hatching = 0x0226DF68 + offset,

        -- Battle
        battle_indicator = 0x0226ACE6 + offset, -- 0x41 if during a battle
        foe_count = 0x0226ACF0 + offset, -- 4 bytes before the first index
        current_foe = 0x0226ACF4 + offset, -- PID of foe, set immediately after the battle transition ends

        -- Misc
        save_indicator = 0x021F0100 + offset, -- 1 while save menu is open
        starter_selection_is_open = 0x022B0C40 + offset, -- 0 when opening gift, 1 at starter select
        battle_menu_state = mdword(0x2146A88 + offset) + 0x1367C, -- 1 on FIGHT menu, 2 on move select, 4 on switch/run after faint, 0 otherwise
        battle_bag_page = 0x022962C8 + offset,
        selected_starter = 0x02269994 + offset, -- Unconfirmed selection in gift box; 0 Snivy, 1 Tepig, 2 Oshawott, 4 Nothing
        text_interrupt = 0x2172BA0 + offset,

        fishing_bite_indicator = 0x20A8362 + offset,
        fishing_no_bite = 0x21509DB + offset
    }
end

-----------------------
-- MODE VARIABLES
-----------------------

snivy_ball = { x = 60, y = 100 }
tepig_ball = { x = 128, y = 75 }
oshawott_ball = { x = 185, y = 100 }

take_button = { x = 200, y = 155 }

-----------------------
-- MISC. BOT ACTIONS
-----------------------

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

        -- Re-apply repel if necessary
        while mdword(pointers.text_interrupt) == 2 do
            press_sequence("Up", 1, "A", 1)
        end
    end
    release_button("B")
end

function get_mon_move_slot(mon, move_name)
    for i, v in ipairs(mon.moves) do
        if v.name == move_name and mon.pp[i] > 0 then
            return i
        end
    end
    return 0
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

function use_move_at_slot(slot)
    -- Skip text to FIGHT menu
    while game_state.in_battle and mbyte(pointers.battle_menu_state) == 0 do
        press_sequence("B", 5)
    end

    wait_frames(30)
    touch_screen_at(128, 90) -- FIGHT
    wait_frames(30)
    touch_screen_at(80 * ((slot - 1) % 2 + 1), 50 * (((slot - 1) // 2) + 1)) -- Select move slot
    wait_frames(60)
end

function do_thief()
    local thief_slot = get_mon_move_slot(party[get_lead_mon_index()], "Thief")

    if thief_slot == 0 then
        console.warning("Thief was enabled in config, but the lead Pokemon can't use the move")
        return false
    end

    if #foe == 1 then -- Single battle
        while game_state.in_battle do
            use_move_at_slot(thief_slot)

            -- Assume the item was stolen and flee
            flee_battle()
        end
    end
end

function do_pickup()
    local pickup_count = 0
    local item_count = 0
    local items = {}

    for i = 1, #party, 1 do
        -- Insert all item names, even none, to preserve party order
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
            console.debug("Pickup items in party: " .. item_count .. ". Collecting at threshold: " ..
                              config.pickup_threshold)
        else
            press_sequence(60, "X", 30)
            touch_screen_at(65, 45)
            wait_frames(90)

            -- Collect items from each Pickup member
            for i = 1, #items, 1 do
                if items[i] ~= "none" then
                    touch_screen_at(80 * ((i - 1) % 2 + 1), 30 + 50 * ((i - 1) // 2)) -- Select Pokemon

                    wait_frames(30)
                    touch_screen_at(200, 155) -- Item
                    wait_frames(30)
                    touch_screen_at(take_button.x, take_button.y) -- Take
                    press_sequence(120, "B", 30)
                end
            end

            -- Exit out of menu
            press_sequence(30, "B", 120, "B", 60)
        end
    else
        console.warning("Pickup is enabled in config, but no party Pokemon have the Pickup ability.")
    end
end

function do_battle()
    local best_move = pokemon.find_best_move(party[1], foe[1])

    if best_move then
        -- Press B until battle state has advanced
        local battle_state = 0

        while game_state.in_battle and battle_state == 0 do
            press_sequence("B", 5)
            battle_state = mbyte(pointers.battle_menu_state)
        end

        if not game_state.in_battle then -- Battle over
            return
        elseif battle_state == 4 then -- Fainted or learning new move
            wait_frames(30)
            touch_screen_at(128, 100) -- RUN or KEEP OLD MOVES
            wait_frames(140)
            touch_screen_at(128, 50) -- FORGET or nothing if fainted

            while game_state.in_battle do
                press_sequence("B", 5)
            end
            return
        end

        if best_move.power > 0 then
            -- Manually decrement PP count
            -- The game only updates this itself at the end of the battle
            local pp_dec = 1
            if foe[1].ability == "Pressure" then
                pp_dec = 2
            end

            party[1].pp[best_move.index] = party[1].pp[best_move.index] - pp_dec

            console.debug("Best move against foe is " .. best_move.name .. " (Effective base power is " .. best_move.power .. ")")
            wait_frames(30)
            touch_screen_at(128, 90) -- FIGHT
            wait_frames(30)

            touch_screen_at(80 * ((best_move.index - 1) % 2 + 1), 50 * (((best_move.index - 1) // 2) + 1)) -- Select move slot
            wait_frames(30)
        else
            console.log("Lead Pokemon has no valid moves left to battle! Fleeing...")

            flee_battle()
        end
    else
        -- Wait another frame for valid battle data
        wait_frames(1)
    end
end

function check_party_status()
    if #party == 0 or game_state.in_battle then -- Don't check party status if bot was started during a battle
        return nil
    end

    -- Check how many valid move uses the lead has remaining
    local lead_pp_sum = 0

    for i = 1, #party[1].moves, 1 do
        if party[1].moves[i].power ~= nil then
            lead_pp_sum = lead_pp_sum + party[1].pp[i]
        end
    end

    if party[1].currentHP == 0 or (lead_pp_sum == 0 and config.battle_non_targets) then
        if config.cycle_lead_pokemon then
            console.log("Lead Pokemon can no longer battle. Replacing...")

            -- Find suitable replacement
            local most_usable_pp = 0
            local best_index = 1

            for i = 2, #party, 1 do
                local ally = party[i]

                if ally.currentHP > 0 then
                    local pp_sum = 0

                    for j = 1, #ally.moves, 1 do
                        if ally.moves[j].power ~= nil then
                            -- Multiply PP by level to weight selections toward
                            -- higher level party members
                            pp_sum = pp_sum + ally.pp[j] * ally.level
                        end
                    end

                    if pp_sum > most_usable_pp then
                        most_usable_pp = pp_sum
                        best_index = i
                    end
                end
            end

            if most_usable_pp == 0 then
                abort("No suitable Pokemon left to battle")
            else
                console.debug("Best replacement was " .. party[best_index].name .. " (Slot " .. best_index .. ")")
                -- Party menu
                press_sequence(60, "X", 30)
                touch_screen_at(65, 45)
                wait_frames(90)

                touch_screen_at(80, 30) -- Select fainted lead

                wait_frames(30)
                touch_screen_at(200, 130) -- SWITCH
                wait_frames(30)

                touch_screen_at(80 * ((best_index - 1) % 2 + 1), 30 + 50 * ((best_index - 1) // 2)) -- Select Pokemon
                wait_frames(30)

                press_sequence(30, "B", 120, "B", 60) -- Exit out of menu
            end
        else
            abort("Lead Pokemon can no longer battle, and current config disallows cycling lead")
        end
    end

    if config.thief_wild_items then
        -- Check leading Pokemon for held items
        local item_leads = {}
        local lead_mon = get_lead_mon_index()

        if party[lead_mon].heldItem ~= "none" then
            console.log("Thief Pokemon already holds an item. Removing...")
            clear_all_inputs()

            -- Open party menu
            press_sequence(60, "X", 30)
            touch_screen_at(65, 45)
            wait_frames(90)

            -- Collect item from lead
            touch_screen_at(80, 30) -- Select Pokemon

            wait_frames(30)
            touch_screen_at(200, 155) -- Item
            wait_frames(30)
            touch_screen_at(take_button.x, take_button.y) -- Take
            press_sequence(120, "B", 30)

            press_sequence(30, "B", 120, "B", 60) -- Exit out of menu
        end
    end
end

function save_game()
    console.log("Saving game...")
    press_sequence("X", 30)

    -- SAVE button is at a different position before choosing starter
    if #party == 0 then -- No starter, no dex
        touch_screen_at(60, 93)
    elseif mword(pointers.map_header) == 391 then -- No dex (not a perfect fix)
        touch_screen_at(188, 88)
    else -- Standard
        touch_screen_at(60, 143)
    end

    wait_frames(90)

    touch_screen_at(218, 60)
    wait_frames(120)

    while mbyte(pointers.save_indicator) ~= 0 do
        press_sequence("A", 12)
    end

    client.saveram() -- Flush save ram to the disk	

    press_sequence("B", 10)
end

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

function find_usable_ball()
    local function find_ball(balls, ball)
        for k2, v2 in pairs(balls) do
            if string.lower(k2) == string.lower(ball) then
                console.debug("Bot will use ball " .. k2 .. " from slot " .. ((v2 - 1) % 6) .. ", page " .. math.floor(v2 / 6))
                return v2
            end
        end
        return -1
    end

    local mon_ball = {
        [0] = "none",
        [1] = "Master Ball",
        [2] = "Ultra Ball",
        [3] = "Great Ball",
        [4] = "Poke Ball",
        [5] = "Safari Ball",
        [6] = "Net Ball",
        [7] = "Dive Ball",
        [8] = "Nest Ball",
        [9] = "Repeat Ball",
        [10] = "Timer Ball",
        [11] = "Luxury Ball",
        [12] = "Premier Ball",
        [13] = "Dusk Ball",
        [14] = "Heal Ball",
        [15] = "Quick Ball",
        [16] = "Cherish Ball"
    }

    -- Check bag for Pokeballs
    local balls = {}
    local ball_count = 0

    local slot = 1
    for i = pointers.items_pouch, pointers.items_pouch + 1240, 4 do
        local item = mword(i)
        local count = mword(i + 2)

        -- IDs from Poke Ball to Cherish Ball
        if item >= 0x1 and item <= 0x10 then
            if count > 0 then
                balls[mon_ball[item]] = slot
                ball_count = ball_count + count
            end

            slot = slot + 1
        elseif item == 0x0 then -- No more items beyond this byte
            break
        end
    end

    if ball_count == 0 then
        return -1
    end

    local ball_index = -1

    -- Compare with pokeball override
    if config.pokeball_override then
        for k, v in pairs(config.pokeball_override) do
            console.debug("Checking rule " .. k .. "...")
            -- If config states this ball should be used
            if pokemon.matches_ruleset(foe[1], config.pokeball_override[k]) then
                console.debug(k .. " is a valid match!")

                ball_index = find_ball(balls, k)

                if ball_index ~= -1 then
                    break
                end
            end
        end
    end

    -- If no override rules were matched, default to priority
    if ball_index == -1 and config.pokeball_priority then
        for _, key in ipairs(config.pokeball_priority) do
            ball_index = find_ball(balls, key)

            if ball_index ~= -1 then
                break
            end
        end
    end

    return ball_index
end

function subdue_pokemon()
    if config.false_swipe then
        -- Ensure target has no recoil moves before attempting to weaken it
        local recoil_moves = {"Brave Bird", "Double-Edge", "Flare Blitz", "Head Charge", "Head Smash", "Self-Destruct",
                              "Take Down", "Volt Tackle", "Wild Charge", "Wood Hammer"}
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
        local status_moves = {"Spore", "Sleep Powder", "Lovely Kiss", "Dark Void", "Hypnosis", "Sing", "Grass Whistle",
                              "Thunder Wave", "Glare", "Stun Spore"}
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
            local grass_moves = {"Spore", "Sleep Powder", "Grass Whistle", "Stun Spore"}

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
            -- Bot will blindly use the status move once and hope it lands
            use_move_at_slot(status_slot)
        else
            console.warning("The lead Pokemon has no usable status moves.")
        end
    end
end

function catch_pokemon()
    clear_all_inputs()
    update_pointers()

    if config.false_swipe or config.inflict_status then
        subdue_pokemon()
    end

    local ball_index = find_usable_ball()
    if ball_index == -1 then
        abort("No valid Poké Balls to catch the target with")
    end

    while mbyte(pointers.battle_menu_state) ~= 1 do
        press_sequence("B", 5)
    end

    wait_frames(20)

    touch_screen_at(38, 174)
    wait_frames(90)

    touch_screen_at(192, 36)
    wait_frames(90)

    local button = (ball_index - 1) % 6 + 1
    local page = math.floor((ball_index - 1) / 6)
    local current_page = mbyte(pointers.battle_bag_page)

    while current_page ~= page do -- Scroll to page with ball
        if current_page < page then
            touch_screen_at(58, 180)
            current_page = current_page + 1
        else
            touch_screen_at(17, 180)
            current_page = current_page - 1
        end

        wait_frames(30)
        console.debug("Page is " .. current_page .. ", scrolling to " .. page)
    end

    touch_screen_at(80 * ((button - 1) % 2 + 1), 30 + 50 * ((button - 1) // 2)) -- Select Ball
    wait_frames(30)
    touch_screen_at(108, 176) -- USE

    while mbyte(pointers.battle_menu_state) ~= 1 and game_state.in_battle do -- Wait until catch failed or battle ended
        press_sequence("B", 5)

        if mbyte(pointers.battle_menu_state) == 4 then
            abort("Lead fainted while trying to catch target")
        end
    end

    if not game_state.in_battle then
        console.log("Skipping through all post-battle dialogue... (This may take a few seconds)")
        for i = 0, 118, 1 do
            press_button("B")
            clear_unheld_inputs()
            wait_frames(5)
        end

        if config.save_game_after_catch then
            save_game()
        end
    end
end

function process_wild_encounter()
    -- Check all foes in case of a double battle
    local foe_is_target = false
    local foe_item = false

    for i = 1, #foe, 1 do
        foe_is_target = pokemon.log_encounter(foe[i]) or foe_is_target

        if foe[i].heldItem ~= "none" then
            foe_item = true
        end
    end

    local double = #foe == 2

    wait_frames(30)

    if foe_is_target then
        if double then
            wait_frames(120)
            abort("Wild Pokemon meets target specs! There are multiple foes, so pausing for manual catch")
        else
            if config.auto_catch then
                while game_state.in_battle do
                    catch_pokemon()
                end
            else
                abort("Wild Pokemon meets target specs, but Auto-catch is disabled")
            end
        end
    else
        console.log("Wild " .. foe[1].name .. " was not a target, attempting next action...")

        update_pointers()

        while game_state.in_battle do
            if config.thief_wild_items and foe_item and not double then
                console.log("Wild Pokemon has a held item, trying to use Thief...")
                local success = do_thief()

                if not success then
                    flee_battle()
                end
            elseif config.battle_non_targets and not double then
                do_battle()
            else
                if not double and config.thief_wild_items and not foe_item then
                    console.log("Wild Pokemon had no held item. Fleeing!")
                elseif double then
                    console.log("Won't battle two targets at once. Fleeing!")
                end

                flee_battle()
            end
        end

        if config.pickup then
            do_pickup()
        end
    end
end

-----------------------
-- BOT MODES
-----------------------

function mode_starters(starter)
    local ball

    if starter == 0 then
        ball = snivy_ball
    elseif starter == 1 then
        ball = tepig_ball
    elseif starter == 2 then
        ball = oshawott_ball
    end

    if not game_state.in_game then
        console.log("Waiting to reach overworld...")

        while not game_state.in_game do
            press_sequence("A", 20)
        end
    end

    console.log("Opening Starter Selection...")

    while mbyte(pointers.starter_selection_is_open) ~= 1 do
        press_sequence("A", 5, "Down", 1)
    end

    console.log("Choosing Starter...")

    while mbyte(pointers.starter_selection_is_open) ~= 0 do
        if mbyte(pointers.selected_starter) ~= 4 then
            touch_screen_at(120, 180) -- Pick this one!
            wait_frames(5)
            touch_screen_at(240, 100) -- Yes
            wait_frames(5)
        else
            touch_screen_at(ball.x, ball.y) -- Starter
            wait_frames(5)
        end
    end

    while #party == 0 do
        press_sequence("A", 5)
    end

    if not config.hax then
        console.log("Waiting to start battle...")

        while not game_state.in_battle do
            press_sequence("A", 5)
        end

        console.log("Waiting to see starter...")

        for i = 0, 118, 1 do
            press_sequence("A", 5)
        end
    end

    mon = party[1]
    local was_target = pokemon.log_encounter(mon)

    if was_target then
        abort("Starter meets target specs")
    else
        console.log("Starter was not a target, resetting...")
        press_button("Power")
        wait_frames(60)
    end
end

function mode_random_encounters()
    local home = {
        x = game_state.trainer_x,
        z = game_state.trainer_z
    }

    local function accept_interrupt_text()
        while mdword(pointers.text_interrupt) == 2 do
            press_sequence("Up", 1, "A", 1)
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

        console.log("Attempting to start a battle...")

        local dir1 = config.move_direction == "horizontal" and "Left" or "Up"
        local dir2 = config.move_direction == "horizontal" and "Right" or "Down"
        
        wait_frames(60) -- Wait to regain control post-battle
        -- pathfind_to(home)
        -- wait_frames(8)

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
        console.log("Waiting to reach overworld...")

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
    if game_state.map_header == 152 then -- Dreamyard
        press_sequence(300, "B", 120, "B", 150, "B", 110, "B", 30) -- Decline nickname and progress text afterwards
    else
        press_sequence(180, "B", 60) -- Decline nickname
    end

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
        ::begin::
        console.log("Running until a phenomenon spawns...")

        local dir1 = config.move_direction == "horizontal" and "Left" or "Up"
        local dir2 = config.move_direction == "horizontal" and "Right" or "Down"

        while game_state.phenomenon_x == 0 and game_state.phenomenon_z == 0 do
            move_in_direction(dir1)
            move_in_direction(dir2)
        end

        release_button(dir2)

        console.log("Phenomenon spawned! Attempting to reach it...")

        while not game_state.in_battle do
            if game_state.phenomenon_x == 0 then -- Phenomenon was an item
                goto begin
            end

            pathfind_to({
                x = game_state.phenomenon_x,
                z = game_state.phenomenon_z
            })
        end

        if game_state.in_battle then
            process_wild_encounter()
        else
            accept_interrupt_text() -- Accept repel dialogue or dust cloud item
        end

        pathfind_to(home)
    end
end

function mode_daycare_eggs()
    local function collect_daycare_egg()
        console.debug("That's an egg!")

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
            console.log("Party is clear of eggs. Depositing hatched Pokemon...")
            
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
                        touch_screen_at(40 * ((i - 1) % 2 + 1), 72 + 30 * ((i - 1) // 2)) -- Select Pokemon
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
            console.log("Oh?")

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
                    local was_target = pokemon.log_encounter(party[i])
                    break
                end
            end

            if was_target then
                if config.save_game_after_catch then
                    save_game()
                end

                abort("Hatched a target Pokemon")
            end

            console.debug("Egg finished hatching.")
        elseif game_state.trainer_x == 748 then -- Interrupted by daycare man
            collect_daycare_egg()
        end
    end
end

function mode_static_encounters()
    while not game_state.in_battle do
        if mword(pointers.map_header) == 152 then -- Dreamyard, Eon duo encounter
            press_button("Right")
        end

        press_sequence("A", 5)
    end

    foe_is_target = pokemon.log_encounter(foe[1])

    if not config.hax then
        for i = 0, 22, 1 do
            press_sequence("A", 5)
        end
    end

    if foe_is_target then
        if config.auto_catch then
            while game_state.in_battle do
                catch_pokemon()
            end

            if config.save_game_after_catch then
                console.log("Target Pokémon was caught! Saving...")
                save_game()
            end

            abort("Target Pokémon was caught!")
        else
            abort("Pokemon meets target specs, but Auto-catch is disabled")
        end
    else
        console.log("Wild " .. foe[1].name .. " was not a target, resetting...")
        press_button("Power")
        wait_frames(60)
    end
end

function mode_fishing()
    while not game_state.in_battle do
        press_button("Y")
        wait_frames(60)

        while mword(pointers.fishing_bite_indicator) ~= 0xFFF1 and
            mbyte(pointers.fishing_no_bite) == 0 do wait_frames(1) end

        if mword(pointers.fishing_bite_indicator) == 0xFFF1 then
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
