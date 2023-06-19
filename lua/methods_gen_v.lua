-----------------------
-- MISC. BOT ACTIONS
-----------------------
function do_thief()
    local checked_mons = 0
    local thief_slot = {0, 0}

    -- Check leading Pokemon for Thief move
    local i, j = 1, 1
    while i < 6 and checked_mons < #foe and thief_slot[1] == 0 do
        -- Iterate through first 1 (or 2 in a double battle) healthy party members
        if party[i].currentHP ~= 0 then
            -- Check moveset for Thief with more than 0 PP
            for j = 1, #party[i].moves, 1 do
                if party[i].moves[j].name == "Thief" and party[i].pp[j] > 0 then
                    thief_slot = {i, j}
                    break
                end
            end
            checked_mons = checked_mons + 1
        end
        i = i + 1
    end

    if thief_slot[1] == 0 then
        console.log("### Thief was enabled in config, but no lead Pokemon can use the move ### ")
        return false
    end

    if #foe == 1 then -- Single battle
        while game_state.in_battle do
            -- Skip text to FIGHT menu
            while game_state.in_battle and mbyte(offset.battle_menu_state) == 0 do
                press_sequence("B", 5)
            end

            wait_frames(30)
            touch_screen_at(128, 90) -- FIGHT
            wait_frames(30)
            touch_screen_at(80 * ((thief_slot[2] - 1) % 2 + 1), 50 * (((thief_slot[2] - 1) // 2) + 1)) -- Select move slot
            wait_frames(60)

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
            console.log("Pickup items in party: " .. item_count .. ". Collecting at threshold: " ..
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
                    touch_screen_at(200, 155) -- Take
                    press_sequence(120, "B", 30)
                end
            end

            -- Exit out of menu
            press_sequence(30, "B", 120, "B", 60)
        end
    else
        console.log(
            "### Pickup is enabled in config, but no party Pokemon have the Pickup ability. Was this a mistake? ###")
    end
end

function do_battle()
    local best_move = pokemon.find_best_move(party[1], foe[1])

    if best_move then
        -- Press B until battle state has advanced
        local battle_state = 0

        while game_state.in_battle and battle_state == 0 do
            press_sequence("B", 5)
            battle_state = mbyte(offset.battle_menu_state)
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

            console.log(
                "Best move against foe is " .. best_move.name .. " (Effective base power is " .. best_move.power .. ")")
            wait_frames(30)
            touch_screen_at(128, 90) -- FIGHT
            wait_frames(30)

            touch_screen_at(80 * ((best_move.index - 1) % 2 + 1), 50 * (((best_move.index - 1) // 2) + 1)) -- Select move slot
            wait_frames(30)
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

function check_party_status()
    if #party == 0 then
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
                pause_bot("No suitable Pokemon left to battle")
            else
                console.log("Best replacement was " .. party[best_index].name .. " (Slot " .. best_index .. ")")
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
            pause_bot("Lead Pokemon can no longer battle, and current config disallows cycling lead")
        end
    end

    if config.thief_wild_items then
        -- Check leading Pokemon for held items
        local item_leads = {}
        local i, checked_mons = 1, 0

        while i < 6 and checked_mons < 2 do
            if party[i].currentHP > 0 and party[i].heldItem ~= "none" then
                for j = 1, #party[i].moves, 1 do
                    if party[i].moves[j].name == "Thief" and party[i].pp[j] > 0 then
                        table.insert(item_leads, i)
                        break
                    end
                end
                checked_mons = checked_mons + 1
            end
            i = i + 1
        end

        if #item_leads > 0 then
            console.log(#item_leads .. " lead Thief Pokemon already holds an item. Removing...")
            clear_all_inputs()

            -- Open party menu
            press_sequence(60, "X", 30)
            touch_screen_at(65, 45)
            wait_frames(90)

            -- Collect items from each lead
            for i = 1, #item_leads, 1 do
                touch_screen_at(80 * ((item_leads[i] - 1) % 2 + 1), 30 + 50 * ((item_leads[i] - 1) // 2)) -- Select Pokemon

                wait_frames(30)
                touch_screen_at(200, 155) -- Item
                wait_frames(30)
                touch_screen_at(200, 155) -- Take
                press_sequence(120, "B", 30)
            end

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
    elseif mword(offset.map_header) == 391 then -- No dex (not a perfect fix)
        touch_screen_at(188, 88)
    else -- Standard
        touch_screen_at(60, 143)
    end

    wait_frames(60)

    while mbyte(0x21F0100) ~= 0 do -- 1 while save menu is open
        press_sequence("A", 12)
    end

    client.saveram() -- Flush save ram to the disk	
end

function flee_battle()
    while game_state.in_battle do
        local battle_state = mbyte(offset.battle_menu_state)

        if battle_state == 4 then -- Fainted
            wait_frames(30)
            touch_screen_at(128, 100) -- RUN
            wait_frames(140)

            while game_state.in_battle do
                press_sequence("B", 5)
            end
            return
        else
            touch_screen_at(125, 175) -- Run
            wait_frames(5)
        end
    end
end

function catch_pokemon()
    local function find_ball(balls, ball)
        for k2, v2 in pairs(balls) do
            if string.lower(k2) == string.lower(ball) then
                console.log("Bot will use ball " .. k2 .. " from slot " .. ((v2 - 1) % 6) .. ", page " .. math.floor(v2 / 6))
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

    clear_all_inputs()

    -- Check bag for Pokeballs
    local balls = {}
    local ball_count = 0

    local slot = 1
    for i = offset.items_pouch, offset.items_pouch + 1240, 4 do
        local item = mword(i)
        local count = mword(i + 2)

        -- IDs from Poke Ball to Cherish Ball
        if item >= 0x1 and item <= 0x10 then
            if count > 0 then
                balls[mon_ball[item]] = slot
                ball_count = ball_count + count
            end

            slot = slot + 1
        elseif item == 0x0 then -- No items beyond this offset
            break
        end
    end

    if ball_count == 0 then
        pause_bot("Nothing to catch the target with")
    end

    console.log("Finding usable Ball...")
    local ball_index = -1

    -- Compare with pokeball override
    if config.pokeball_override then
        for k, v in pairs(config.pokeball_override) do
            console.log("Checking rule " .. k .. "...")
            -- If config states this ball should be used
            if pokemon.matches_ruleset(foe[1], config.pokeball_override[k]) then
                console.log(k .. " is a valid match!")
                
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

    if ball_index == -1 then
        pause_bot("Nothing to catch the target with allowed by config")
    end

    while mbyte(offset.battle_menu_state) ~= 1 do
        press_sequence("B", 5)
    end

    wait_frames(20)

    touch_screen_at(38, 174)
    wait_frames(90)

    touch_screen_at(192, 36)
    wait_frames(90)

    -- TODO scroll page
    local button = (ball_index - 1) % 6 + 1
    local page = math.floor((ball_index - 1) / 6)
    local current_page = mbyte(0x22962C8)

    while current_page ~= page do -- Scroll to page with ball
        if current_page < page then
            touch_screen_at(58, 180)
            current_page = current_page + 1
        else
            touch_screen_at(17, 180)
            current_page = current_page - 1
        end

        wait_frames(30)
        console.log("Page is " .. current_page .. ", scrolling to " .. page)
    end

    touch_screen_at(80 * ((button - 1) % 2 + 1), 30 + 50 * ((button - 1) // 2)) -- Select Ball
    wait_frames(30)
    touch_screen_at(108, 176) -- USE

    while mbyte(offset.battle_menu_state) ~= 1 and game_state.in_battle do -- Wait until catch failed or battle ended
        press_sequence("B", 5)

        if mbyte(offset.battle_menu_state) == 4 then
            pause_bot("Lead fainted while trying to catch target")
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

-----------------------
-- BOT MODES
-----------------------

function mode_starters(starter)
    local ball_x
    local ball_y

    if starter == 0 then
        ball_x = 60
        ball_y = 100
    elseif starter == 1 then
        ball_x = 128
        ball_y = 75
    elseif starter == 2 then
        ball_x = 185
        ball_y = 100
    end

    if not game_state.in_game then
        console.log("Waiting to reach overworld...")

        while not game_state.in_game do
            press_sequence("A", 20)
        end
    end

    console.log("Opening Gift Box...")

    while game_state.starter_box_open ~= 1 do
        press_sequence("A", 5, "Down", 1)
    end

    console.log("Choosing Starter...")

    while game_state.starter_box_open ~= 0 do
        if game_state.selected_starter ~= 4 then
            touch_screen_at(120, 180) -- Pick this one!
            wait_frames(5)
            touch_screen_at(240, 100) -- Yes
            wait_frames(5)
        else
            touch_screen_at(ball_x, ball_y) -- Starter
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

        -- For whatever reason, press_button("A", 5)
        -- does not work on its own within this specific loop
        for i = 0, 118, 1 do
            press_button("A")
            clear_unheld_inputs()
            wait_frames(5)
        end
    end

    mon = party[1]
    local was_target = pokemon.log(mon)
    update_dashboard_recents()

    -- Check both cases because I can't trust it on just one
    if was_target then
        if not config.save_game_after_catch then
            pause_bot("Starter meets target specs")
        else
            console.log("Starter meets target specs! Skipping battles until next save opportunity...")

            -- Button mash through two battles until bot can save
            if config.hax then
                while not game_state.in_battle do
                    press_sequence("A", 5)
                end
            end

            while game_state.in_battle do
                press_sequence("A", 5)
            end

            while not game_state.in_battle do
                skip_dialogue()
            end

            while game_state.in_battle do
                press_sequence("A", 5)
            end

            for i = 0, 40, 1 do
                skip_dialogue()
            end

            save_game()
            client.pause()
        end
    else
        console.log("Starter was not a target, resetting...")
        press_button("Power")
        wait_frames(60)
    end
end

function mode_random_encounters()
    check_party_status()

    console.log("Attempting to start a battle...")

    hold_button("B")

    local tile_frames = frames_per_move() - 1
    local dir1 = config.move_direction == "Horizontal" and "Left" or "Up"
    local dir2 = config.move_direction == "Horizontal" and "Right" or "Down"

    while not foe and not game_state.in_battle do
        hold_button(dir1)
        wait_frames(tile_frames)
        hold_button(dir2)
        wait_frames(tile_frames)
    end

    release_button("B")
    release_button("Right")

    -- Check all foes in case of a double battle
    local foe_is_target = false
    local foe_item = false

    for i = 1, #foe, 1 do
        foe_is_target = pokemon.log(foe[i]) or foe_is_target
        update_dashboard_recents() -- Only sends the latest encounter to the dashboard, so it needs to be called for every log

        if foe[i].heldItem ~= "none" then
            foe_item = true
        end
    end

    local double = #foe == 2

    if foe_is_target then
        if double then
            wait_frames(120)
            pause_bot("Wild Pokemon meets target specs! There are multiple opponents, so pausing for manual catch")
        else
            if config.auto_catch then
                while game_state.in_battle do
                    catch_pokemon()
                end
            else
                pause_bot("Wild Pokemon meets target specs, but auto_catch is disabled")
            end
        end
    else
        console.log("Wild Pokemon was not a target, attempting next action...")

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

function mode_gift()
    if not game_state.in_game then
        console.log("Waiting to reach overworld...")

        while not game_state.in_game do
            press_sequence("A", 20)
        end
    end

    wait_frames(60)

    local in_dreamyard = game_state.map_header == 152

    local og_party_count = #party
    while #party == og_party_count do
        if in_dreamyard then
            press_sequence("A", 5)
        else
            press_sequence("A", 5)
        end
    end

    -- Dialogue varies per gift type
    if in_dreamyard then
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
    local was_target = pokemon.log(mon)
    update_dashboard_recents()

    -- Check both cases because I can't trust it on just one
    if was_target then
        if not config.save_game_after_catch then
            pause_bot("Gift Pokemon meets target specs, pausing")
        else
            console.log("Gift Pokemon meets target specs!")

            if not config.hax then
                press_sequence("B", 120, "B", 120, "B", 60) -- Exit out of menu
            end

            save_game()
            client.pause()
        end
    else
        console.log("Gift Pokemon was not a target, resetting...")
        press_button("Power")
        wait_frames(60)
    end
end

function mode_phenomenon_encounters()
    pause_bot("This mode is unfinished")

    check_party_status()

    console.log("Running until a phenomenon spawns...")

    hold_button("B")

    local tile_frames = frames_per_move()

    while game_state.phenomenon_x == 0 and game_state.phenomenon_z == 0 do
        hold_button("Left")
        wait_frames(tile_frames)
        hold_button("Right")
        wait_frames(tile_frames)
    end

    console.log("Phenomena spawned! Attempting to start encounter...")
end

function mode_daycare_eggs()
    local function collect_daycare_egg()
        console.log("That's an egg!")

        release_button("Right")
        press_sequence(60, "B")
        hold_button("Up")

        while game_state.trainer_z ~= 557 do -- Bike up to daycare man
            wait_frames(8)
        end

        release_button("Up")

        local og_party_count = #party -- Press A until egg in party
        while #party == og_party_count do
            press_sequence("A", 5)
        end

        press_sequence(200, "B", 90, "B") -- End dialogue
    end

    -- Daycare routine below
    if game_state.map_header ~= 321 then
        pause_bot("Please place the bot on Route 3")
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
            hold_button("B")

            -- Reach staircase
            while game_state.trainer_x < 742 do
                hold_button("Right")
                wait_frames(1)
            end

            while game_state.trainer_x > 748 do
                hold_button("Left")
                wait_frames(1)
            end

            release_button("Right")
            release_button("Left")

            -- Ascend staircase
            while game_state.trainer_z > 558 do
                hold_button("Up")
                wait_frames(1)
            end

            release_button("Up")

            -- Align with door
            while game_state.trainer_x < 749 do
                hold_button("Right")
                wait_frames(1)
            end

            release_button("Right")

            -- Walk to daycare lady at desk
            while game_state.map_header ~= 323 or game_state.trainer_z ~= 9 do
                hold_button("Up")
                wait_frames(1)
            end

            release_button("Up")

            -- Walk to PC
            while game_state.trainer_x < 9 do
                hold_button("Right")
                wait_frames(1)
            end

            release_button("B")
            release_button("Right")

            wait_frames(frames_per_move())
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

                pause_bot("This code shouldn't be running right now")
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

        if mdword(offset.egg_hatching) == 1 then -- Interrupted by egg hatching
            console.log("Oh?")

            release_button("Right")
            release_button("Left")

            press_sequence("B", 60)

            -- Remember which Pokemon are currently eggs
            local party_eggs = {}
            for i = 1, #party, 1 do
                party_eggs[i] = party[i].isEgg
            end

            while mdword(offset.egg_hatching) == 1 do
                press_sequence(15, "B")
            end

            -- Find newly hatched party member and add to the log
            for i = 1, #party, 1 do
                if party_eggs[i] == 1 and party[i].isEgg == 0 then
                    local was_target = pokemon.log(party[i])
                    update_dashboard_recents()
                    break
                end
            end

            if was_target then
                if config.save_game_after_catch then
                    save_game()
                end
                
                pause_bot("Hatched a target Pokemon")
            end

            console.log("Egg finished hatching.")
        elseif game_state.trainer_x == 748 then -- Interrupted by daycare man
            collect_daycare_egg()
        end
    end
end
