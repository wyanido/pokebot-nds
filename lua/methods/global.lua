-- No bot logic, just log encounters as the user plays
function mode_manual()
    while true do
        while not game_state.battle do
            process_frame()
        end

        for i = 1, #foe, 1 do
            pokemon.log_encounter(foe[i])
        end

        while game_state.battle do
            process_frame()
        end
    end
end

function mode_fishing()
    local fishing_status_changed = function()
        if _ROM.gen == 4 then
            return mbyte(pointers.fishing_bite_indicator) ~= 0
        else
            return not (mword(pointers.fishing_bite_indicator) ~= 0xFFF1 and mbyte(pointers.fishing_no_bite) == 0)
        end
    end

    local fishing_has_bite = function ()
        if _ROM.gen == 4 then
            return mbyte(pointers.fishing_bite_indicator) == 1
        else
            return mword(pointers.fishing_bite_indicator) == 0xFFF1
        end
    end

    while not game_state.battle do
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

    while not game_state.battle do
        press_sequence("A", 5)
    end

    process_wild_encounter()
    wait_frames(90)
end

function check_party_status()
    if #party == 0 or game_state.battle then -- Don't check party status if bot was started during a battle
        return
    end

    -- Check how many valid move uses the lead has remaining
    local lead_pp_sum = 0

    for i = 1, #party[1].moves, 1 do
        if party[1].moves[i].power ~= nil then
            lead_pp_sum = lead_pp_sum + party[1].pp[i]
        end
    end

    local lead_is_exchausted = party[1].currentHP < party[1].maxHP / 5

    if lead_is_exchausted or (lead_pp_sum == 0 and config.battle_non_targets) then
        if config.cycle_lead_pokemon then
            print("Lead Pokemon can no longer battle. Replacing...")

            -- Find suitable replacement
            local healthy_pokemon = get_healthy_pokemon()

            if #healthy_pokemon == 0 then
                abort("No suitable Pokemon left to battle")
            end

            local new_lead = healthy_pokemon[1]
            print_debug("Best replacement was " .. party[new_lead].name .. " (Slot " .. new_lead .. ")")
            
            open_menu("Pokemon")
            manage_party(1, "Switch", new_lead)
            close_menu()
        else
            abort("Lead Pokemon can no longer battle, and current config disallows cycling lead")
        end
    end

    -- Check leading Pokemon for held items
    if config.thief_wild_items then
        local item_leads = {}
        local lead_mon = get_lead_mon_index()

        if party[lead_mon].heldItem ~= "none" then
            print("Thief Pokemon already holds an item. Removing...")
            
            open_menu("Pokemon")
            manage_party(1, "Item", "Take")
            close_menu()
        end
    end
end

-- Returns the index of a move within a Pokemon's moveset
function get_move_slot(mon, move_name)
    for i, v in ipairs(mon.moves) do
        if v.name == move_name and mon.pp[i] > 0 then
            return i
        end
    end
    return 0
end

-- Returns the first non-fainted Pokémon in the party
function get_lead_mon_index()
    for i = 1, #party, 1 do
        if party[i].currentHP ~= 0 then
            return i
        end
    end
end

-- Returns a list of all party Pokemon in suitable battling condition
function get_healthy_pokemon()
    local healthy_pokemon = {}

    for i = 2, #party, 1 do
        local mon = party[i]

        if mon.currentHP >= mon.maxHP / 5 then
            local pp_sum = 0

            for j = 1, #mon.moves, 1 do
                if mon.moves[j].power ~= nil then
                    pp_sum = pp_sum + mon.pp[j]
                end
            end

            if pp_sum > 4 then
                table.insert(healthy_pokemon, i)
            end
        end
    end

    return healthy_pokemon
end

-- Collect items from Pokemon with the Pickup ability in party
function do_pickup()
    local item_count = 0

    for i, mon in ipairs(party) do
        if mon.ability == "Pickup" and mon.heldItem ~= "none" then
            item_count = item_count + 1
        end
    end

    if item_count < tonumber(config.pickup_threshold) then
        print_debug("Pickup items in party: " .. item_count .. ". Collecting at threshold: " .. config.pickup_threshold)
    else
        -- Collect items from each Pickup Pokemon
        open_menu("Pokemon")
        local actions = {}

        for i, mon in ipairs(party) do
            if mon.heldItem ~= "none" then
                table.insert(actions, #actions, {i, "Item", "Take"})
            end
        end

        manage_party(actions)
        close_menu()
    end
end

function use_move_at_slot(slot)
    local x = 90 * slot
    local y = 50 * math.floor((slot + 1) / 2)

    touch_screen_at(x, y)
    wait_frames(20)
end

function do_thief()
    local thief_slot = get_move_slot(party[get_lead_mon_index()], "Thief")

    if thief_slot == 0 then
        print_warn("Thief was enabled in config, but the lead Pokemon can't use the move")
        return false
    end

    if #foe == 1 then -- Single battle
        while game_state.battle do
            use_move_at_slot(thief_slot)

            -- Assume the item was stolen and flee
            flee_battle()
        end
    end
end

function do_battle()
    local best_move = pokemon.find_best_move()

    while mbyte(pointers.battle_menu_state) ~= 1 do
        press_sequence("A", 5)
    end

    if best_move then
        -- Action select
        if mbyte(pointers.battle_menu_state) == 1 then
            touch_screen_at(127, 84) -- FIGHT
            wait_frames(20)
        end

        -- Move select
        if mbyte(pointers.battle_menu_state) == 3 then
            print_debug("Best move is " .. best_move.name .. " (Power: " .. best_move.power .. ")")
            use_move_at_slot(best_move.index)
        end
        
        -- Turn processing
        while mbyte(pointers.battle_menu_state) == 0xD do
            press_sequence("A", 5)
            
            local new_state = mbyte(pointers.battle_menu_state + 0xC)
            if new_state == 0x2A then
                print("Battle won!")

                while mbyte(pointers.battle_menu_state + 0xC) == new_state do
                    process_frame()
                end

                -- Evolution screen, cancelling it is the safer option
                while mbyte(pointers.battle_menu_state + 0xC) == 0x44 do
                    press_sequence("B", 5)
                end

                -- Standard battle end
                while game_state.battle do
                    press_sequence("A", 5)
                end

                return
            elseif new_state == 0xC then
                print("Fainted!")

                while game_state.battle do
                    touch_screen_at(127, 140)
                    wait_frames(6)
                end

                return
            elseif new_state == 0xD then
                print("Evolving!")

                while game_state.battle do
                    press_sequence("B", 5)
                end

                return
            end
        end

        process_frame()
    else
        -- Wait another frame for valid battle data
        process_frame()
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
                catch_pokemon()
            else
                abort("Wild Pokemon meets target specs, but Auto-catch is disabled")
            end
        end
    else
        print("Wild " .. foe[1].name .. " was not a target, attempting next action...")

        update_pointers()

        while game_state.battle do
            if config.thief_wild_items and foe_item and not double then
                print("Wild Pokemon has a held item, trying to use Thief...")
                local success = do_thief()

                if not success then
                    flee_battle()
                end
            elseif config.battle_non_targets and not double then
                do_battle()
            else
                if not double and config.thief_wild_items and not foe_item then
                    print("Wild Pokemon had no held item. Fleeing!")
                elseif double then
                    print("Won't battle two targets at once. Fleeing!")
                end

                flee_battle()
            end
        end
    end
end

function mode_static_encounters()
    print("Waiting for battle to start...")

    while not game_state.battle do
        if game_state.map_name == "Dreamyard" then -- Gen 5 Latias/Latios
            press_button("Right")
        elseif game_state.map_name == "Spear Pillar" then -- Gen 4 Dialga/Palkia
            press_button("Up")
        end

        press_sequence("A", 5)
    end

    local is_target = pokemon.log_encounter(foe[1])

    -- Wait for Pokémon to fully appear on screen
    if not config.hax then
        for i = 0, 22, 1 do
            press_sequence("A", 5)
        end
    end

    if is_target then
        if config.auto_catch then
            catch_pokemon()

            if config.save_game_after_catch then
                save_game()
            end

            abort("Battle with static encounter ended!")
        else
            abort("Pokemon meets target specs, but Auto-catch is disabled")
        end
    else
        print("Wild " .. foe[1].name .. " was not a target, resetting...")
        soft_reset()
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

    -- Decline nickname and finish dialogue per gift type
    if game_state.map_name == "Dreamyard" then
        press_sequence(300, "B", 120, "B", 150, "B", 110, "B", 30) 
    else
        press_sequence(180, "B", 60)
    end

    if not config.hax then
        open_menu("Pokemon")
        manage_party(#party, "Summary")
    end

    local mon = party[#party]
    local is_target = pokemon.log_encounter(mon)

    if is_target then
        if config.save_game_after_catch then
            print("Gift Pokemon meets target specs! Saving...")

            if not config.hax then
                close_menu()
            end

            save_game()
        end

        abort("Gift Pokemon meets target specs")
    else
        print("Gift Pokemon was not a target, resetting...")
        soft_reset()
    end
end

function catch_pokemon()
    local use_ball = function(index)
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

    if config.false_swipe or config.inflict_status then
        subdue_pokemon()
    end

    while game_state.battle do
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

        use_ball(ball_index)

        -- Wait until catch failed or battle ended
        while mbyte(pointers.battle_menu_state) ~= 1 and game_state.battle do
            press_sequence("B", 5)
        end
    end

    print("Skipping through all post-battle dialogue... (This may take a few seconds)")

    for i = 0, 118, 1 do
        press_sequence("B", 5)
    end

    if config.save_game_after_catch then
        save_game()
    end
end

function subdue_pokemon()
    if config.false_swipe then
        -- Ensure target has no recoil moves before attempting to weaken it
        local recoil_moves = {"Brave Bird", "Double-Edge", "Flare Blitz", "Head Charge", "Head Smash", "Self-Destruct",
                              "Take Down", "Volt Tackle", "Wild Charge", "Wood Hammer"}
        local recoil_slot = 0

        for _, v in ipairs(recoil_moves) do
            recoil_slot = get_move_slot(foe[1], v)

            if recoil_slot ~= 0 then
                print_warn("The target has a recoil move. False Swipe won't be used.")
                break
            end
        end

        if recoil_slot == 0 then
            -- Check whether the lead actually has False Swipe
            local false_swipe_slot = get_move_slot(party[get_lead_mon_index()], "False Swipe")

            if false_swipe_slot == 0 then
                print_warn("The lead Pokemon can't use False Swipe.")
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
            status_slot = get_move_slot(party[get_lead_mon_index()], v)

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