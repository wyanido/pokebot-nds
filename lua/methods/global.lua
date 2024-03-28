-- No bot logic, just log encounters as the user plays
function mode_manual()
    while true do
        while not game_state.in_battle do
            process_frame()
        end

        for i = 1, #foe, 1 do
            pokemon.log_encounter(foe[i])
        end

        while game_state.in_battle do
            process_frame()
        end
    end
end

function mode_fishing()
    while not game_state.in_battle do
        press_button("Y")
        wait_frames(60)

        while not fishing_status_changed() do 
            wait_frames(1)
        end

        if fishing_has_bite() then
            print("Landed a Pokémon!")
            break
        else
            print("Not even a nibble...")
            press_sequence(30, "A", 20)
        end
    end

    while not game_state.in_battle do
        press_sequence("A", 5)
    end

    process_wild_encounter()

    wait_frames(90)
end

-- Returns the index of the first non-fainted Pokémon in the party
function get_lead_mon_index()
    for i = 1, 6, 1 do
        if party[i].currentHP ~= 0 then
            return i
        end 
    end
end

function do_thief()
    local lead = get_lead_mon_index()
    local thief_slot = pokemon.get_move_slot(party[lead], "Thief")

    if #foe == 2 or thief_slot == 0 then
        return false
    end

    while game_state.in_battle do
        use_move_at_slot(thief_slot)
    end
end

function subdue_pokemon()
    if config.false_swipe then
        -- Ensure target has no recoil moves before attempting to weaken it
        local recoil_moves = {"Brave Bird", "Double-Edge", "Flare Blitz", "Head Charge", "Head Smash", "Self-Destruct",
                              "Take Down", "Volt Tackle", "Wild Charge", "Wood Hammer"}
        local recoil_slot = 0

        for _, v in ipairs(recoil_moves) do
            recoil_slot = pokemon.get_move_slot(foe[1], v)

            if recoil_slot ~= 0 then
                print_warn("The target has a recoil move. False Swipe won't be used.")
                break
            end
        end

        if recoil_slot == 0 then
            -- Check whether the lead actually has False Swipe
            local false_swipe_slot = pokemon.get_move_slot(party[get_lead_mon_index()], "False Swipe")

            if false_swipe_slot == 0 then
                print_warn("The lead Pokemon can't use False Swipe.")
            else
                use_move_at_slot(false_swipe_slot)
            end
        end
        
        -- Status moves in order of usefulness
        local status_moves = {"Spore", "Sleep Powder", "Lovely Kiss", "Dark Void", "Hypnosis", "Sing", "Grass Whistle",
                              "Thunder Wave", "Glare", "Stun Spore"}
        local status_slot = 0

        for i = 1, #foe[1].type, 1 do
            if foe[1].type[i] == "Ground" then
                print_debug("Foe is Ground-type. Thunder Wave can't be used.")
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
            status_slot = pokemon.get_move_slot(party[get_lead_mon_index()], v)

            if status_slot ~= 0 then
                break
            end
        end

        if status_slot > 0 then
            -- Bot will blindly use the status move once and hope it lands
            use_move_at_slot(status_slot)
        else
            print_warn("The lead Pokemon has no usable status moves.")
        end
    end
end

function catch_pokemon()
    local function get_preferred_ball(balls)
        -- Compare with override ruleset first
        if config.pokeball_override then
            for ball, _ in pairs(config.pokeball_override) do
                if pokemon.matches_ruleset(foe[1], config.pokeball_override[ball]) then
                    local index = balls[string.lower(ball)]

                    if index then
                        print_debug("Bot will use " .. ball .. " from slot " .. ((index - 1) % 6) .. ", page " .. math.floor(index / 6))
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
                    print_debug("Bot will use " .. ball .. " from slot " .. ((index - 1) % 6) .. ", page " .. math.floor(index / 6))
                    return index
                end
            end
        end

        return -1
    end

    local function use_ball(index)
        local page = math.floor((index - 1) / 6)
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
        end

        -- Select and use ball
        local button = (index - 1) % 6 + 1
        local x = 80 * ((button - 1) % 2 + 1)
        local y = 30 + 50 * math.floor((button - 1) / 2)

        touch_screen_at(x, y)
        wait_frames(30)
        touch_screen_at(108, 176) -- USE
    end

    if config.false_swipe then 
        subdue_pokemon()
    end

    while game_state.in_battle do
        local balls = get_usable_balls()
        local ball_index = get_preferred_ball(balls)
        
        if ball_index == -1 then
            abort("No valid Poké Balls to catch the target with")
        end

        while mbyte(pointers.battle_menu_state) ~= 1 do
            press_sequence("B", 8)
        end

        wait_frames(20)

        touch_screen_at(38, 174)
        wait_frames(90)

        touch_screen_at(192, 36)
        wait_frames(90)

        use_ball(ball_index)

        -- Wait until catch failed or battle ended
        while mbyte(pointers.battle_menu_state) ~= 1 and game_state.in_battle do
            press_sequence("B", 8)
            touch_screen_at(0, 0) -- Skip Pokedex entry screen in HGSS without pressing A to avoid accidental menu inputs 
        end
    end

    print("Skipping through all post-battle dialogue... (This may take a few seconds)")

    for i = 0, 59, 1 do
        press_sequence("B", 10)
    end

    if config.save_game_after_catch then
        save_game()
    end
end

function process_wild_encounter()
    clear_all_inputs()
    wait_frames(30)

    -- Check all foes in case of a double battle
    local is_target = false
    local foe_item = false
    local foe_name = foe[1].name

    for i, mon in ipairs(foe) do
        is_target = pokemon.log_encounter(mon) or is_target

        if mon.heldItem ~= "none" then
            foe_item = true
        end
    end

    if is_target then
        print("Wild " .. foe_name .. " is a target!")

        if config.auto_catch then
            while game_state.in_battle do
                catch_pokemon()
            end
        else
            abort("Stopping script for manual catch")
        end
    else
        while game_state.in_battle do
            if #foe == 2 then
                print("Won't battle two targets at once. Fleeing!")
                flee_battle()
            else
                if config.thief_wild_items and foe_item then
                    print(foe_name .. " has a held item, using Thief and fleeing...")
                    do_thief()
                    flee_battle()
                elseif config.battle_non_targets then
                    do_battle()
                else
                    print(foe_name .. " was not a target. Fleeing!")
                    flee_battle()
                end
            end
        end
    end

    if config.pickup then
        do_pickup()
    end
end

function do_pickup()
    local item_count = 0

    for i, mon in ipairs(party) do
        if mon.ability == "Pickup" and mon.heldItem ~= "none" then
            item_count = item_count + 1
        end
    end

    if item_count >= tonumber(config.pickup_threshold) then
        collect_pickup_items()
    else
        print_debug(item_count .. " Pickup items in party. Collecting at " .. config.pickup_threshold)
    end
end

function collect_pickup_items()
    open_menu("Pokemon")

    for _, mon in ipairs(party) do
        if mon.ability == "Pickup" and mon.heldItem ~= "none" then
            press_sequence("A", 8, "Up", 8, "Up", 8, "A", 22, "Down", 8, "A")
            wait_frames(90)
            press_button("B")
        end

        press_sequence("Right", 5)
    end
    
    press_sequence(30, "B", 120, "B", 60)
end