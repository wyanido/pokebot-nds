-----------------------------------------------------------------------------
-- General bot methods for all games
-- Author: wyanido, StoryZealot
-----------------------------------------------------------------------------
_MON_BYTE_LENGTH = 220

function soft_reset()
    press_button("Power")
    randomise_reset()
end

--- Attempts to read the foe(s) data from memory
function update_foes()
    -- Make sure a battle is actually underway before reading
    local battle_value = mbyte(pointers.battle_indicator)

    if not game.save_file_loaded() or
        (battle_value ~= 0x41 and battle_value ~= 0x97 and battle_value ~= 0xC0) then
        foe = nil
        return
    end

    -- If the foe is already known, then don't re-read it within the same battle
    if foe then return end

    local function attempt_fetch()
        local foe_count = mbyte(pointers.foe_count)

        if foe_count == 0 then
            console.debug("Foe data doesn't exist yet, retrying next frame...")
            return
        end

        local foe_table = {}

        for i = 1, foe_count do
            local mon = pokemon.parse_data(pointers.current_foe + (i - 1) * _MON_BYTE_LENGTH)

            if mon then
                table.insert(foe_table, mon)
            else
                console.debug("Foe checksum failed at slot " .. i .. ", retrying next frame...")
                return
            end
        end

        foe = foe_table
    end

    -- Attempt to identify the foe once per frame until it succeeds
    while foe == nil do
        -- Exit in case the bot SR'ed during this stage
        if not game.save_file_loaded() then return end

        attempt_fetch()
        emu.frameadvance()
    end
end

hint_config_default("starter0", true)
hint_config_default("starter1", false)
hint_config_default("starter2", false)

function cycle_starter_choice()
    if starter == nil then starter = -1 end

    -- Alternate between starters specified in config and reset until one is a target
    if not config.starter0 and not config.starter1 and not config.starter2 then
        abort(
            "At least one starter selection must be enabled in config for this bot mode")
    end

    -- Cycle to next enabled starter
    starter = (starter + 1) % 3

    while not config["starter" .. tostring(starter)] do
        starter = (starter + 1) % 3
    end

    return starter
end

--- Returns an array of booleans to indicate the egg state for each party member
function get_party_egg_states()
    local eggs = {}

    for i = 1, 6 do
        if party[i] then
            eggs[i] = party[i].IsEgg
        else
            eggs[i] = true
        end
    end

    return eggs
end

--- Presses A to allow the egg hatch animation to finish if it's currently happening
function check_hatching_eggs()
    if emu.framecount() % 10 == 0 then
        if _ROM.version == "HG" or _ROM.version == "SS" then -- HGSS needs to deny phone calls a lot of the time, so we use B instead
            press_button_async("B")
        else
            press_button_async("A")
        end
    end

    local current_egg_states = get_party_egg_states()

    -- Check for egg hatching
    for i, is_egg in ipairs(current_egg_states) do
        -- Eggs are already considered "hatched" as soon as the animation starts,
        -- so we can tell if an egg is hatching when 'is_egg' has changed since last reference
        if party[i] then
            if party_egg_states[i] ~= is_egg then
                clear_all_inputs()
                hatch_egg(i)

                pokemon.log_encounter(party[i])
                
                if pokemon.is_target(party[i]) then
                    abort("Hatched a target Pokémon: " .. party[i].Species.Name .. "!")
                end

                wait_frames(90)
                break
            end
        end
    end

    party_egg_states = current_egg_states

    -- Check if all eggs are hatched only if the party is full
    if party and #party == 6 then
        local has_egg = false

        -- This should check the current egg states to see if any are still not hatched
        for i, is_egg in ipairs(current_egg_states) do
            if is_egg then
                has_egg = true
                break
            end
        end

        -- Only release hatched duds if all eggs are hatched
        if not has_egg then
            print("Party has no room for eggs! Releasing last 5 Pokemon...")
            release_hatched_duds()
        end
    elseif not party then
        print("Error: Party is nil.")
    end
end

--- Returns the index of the first non-fainted Pokémon in the party
function get_lead_mon_index()
    for i = 1, 6, 1 do if party[i].CurrentHP ~= 0 then return i end end
end

--- Finds and uses the best available options to safely weaken the foe
function subdue_pokemon()
    -- Ensure target has no recoil moves before attempting to weaken it
    local recoil_moves = {
        "Brave Bird", "Double-Edge", "Flare Blitz", "Head Charge", "Head Smash",
        "Self-Destruct", "Take Down", "Volt Tackle", "Wild Charge",
        "Wood Hammer"
    }
    local recoil_slot = 0

    for _, v in ipairs(recoil_moves) do
        recoil_slot = pokemon.get_move_slot(foe[1], v)

        if recoil_slot ~= 0 then
            console.warn(
                "The target has a recoil move. False Swipe won't be used.")
            break
        end
    end

    if recoil_slot == 0 then
        -- Check whether the lead actually has False Swipe
        local false_swipe_slot = pokemon.get_move_slot(party[get_lead_mon_index()], "False Swipe")

        if false_swipe_slot == 0 then
            console.warn("The lead Pokemon can't use False Swipe.")
        else
            use_move(false_swipe_slot)
        end
    end

    -- Status moves in order of usefulness
    local status_moves = {
        "Spore", "Sleep Powder", "Lovely Kiss", "Dark Void", "Hypnosis", "Sing",
        "Grass Whistle", "Thunder Wave", "Glare", "Stun Spore"
    }
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
        local grass_moves = {
            "Spore", "Sleep Powder", "Grass Whistle", "Stun Spore"
        }

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

        if status_slot ~= 0 then break end
    end

    if status_slot > 0 then
        -- Bot will blindly use the status move once and hope it lands
        use_move(status_slot)
    else
        console.warn("The lead Pokemon has no usable status moves.")
    end
end

hint_config_default("pokeball_override", {
    ["Repeat Ball"] = {
       ["name"] = {
            "Lillipup",
            "Bidoof",
            "Sentret"
        }
    },
    ["Net Ball"] = {
        ["type"] = {
            "Bug",
            "Water"
        }
    }
})
hint_config_default("pokeball_priority", {
    "Premier Ball",
    "Ultra Ball",
    "Great Ball",
    "Poke Ball"
})
hint_config_default("subdue_target", false)
hint_config_default("save_game_after_catch", false)
hint_config_default("ot_override", false)
hint_config_default("tid_override", "000000")
hint_config_default("sid_override", "000000")

--- Continuously tries to catch the foe until the battle ends, or there are no valid Poke Balls left
function catch_pokemon()
    local function get_preferred_ball(balls)
        -- Compare with override ruleset first
        if config.pokeball_override then
            for ball, _ in pairs(config.pokeball_override) do
                if pokemon.matches_ruleset(foe[1], config.pokeball_override[ball]) then
                    local index = balls[string.lower(ball)]

                    if index then
                        console.debug("Bot will use " .. ball .. " from slot " .. ((index - 1) % 6) .. ", page " .. math.floor(index / 6))
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
                    console.debug("Bot will use " .. ball .. " from slot " .. ((index - 1) % 6) .. ", page " .. math.floor(index / 6))
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

    if config.subdue_target then subdue_pokemon() end

    while game.in_battle() do
        local balls = get_usable_balls()
        local ball_index = get_preferred_ball(balls)

        if ball_index == -1 then
            abort("No valid Poke Balls to catch the target with")
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
        while mbyte(pointers.battle_menu_state) ~= 1 and game.in_battle() do
            press_sequence("B", 8)
            touch_screen_at(0, 0) -- Skip Pokedex entry screen in HGSS without pressing A to avoid accidental menu inputs 
        end
    end

    print(
        "Skipping through all post-battle dialogue... (This may take a few seconds)")

    for i = 0, 59, 1 do press_sequence("B", 10) end

    if config.save_game_after_catch then save_game() end
end

hint_config_default("battle_non_targets", false)
hint_config_default("pickup", false)
hint_config_default("pickup_threshold", 2)
hint_config_default("cycle_lead_pokemon", false)
hint_config_default("thief_wild_items", false)

--- Logs the current wild foes and decides the next actions to take
function process_wild_encounter()
    clear_all_inputs()
    wait_frames(30)

    -- Check all foes in case of a double battle
    local is_target = false
    local foe_item = false
    local foe_name = foe[1].Species.Name

    for i, mon in ipairs(foe) do
        pokemon.log_encounter(mon)
    
        is_target = pokemon.is_target(mon) or is_target

        if mon.HeldItem ~= "none" then foe_item = true end
    end

    if is_target then
        print("Wild " .. foe_name .. " is a target!")

        if config.auto_catch then
            while game.in_battle() do catch_pokemon() end
        else
            abort("Stopping script for manual catch")
        end
    else
        while game.in_battle() and foe do
            if #foe == 2 then
                print("Won't battle two targets at once. Fleeing!")
                flee_battle()
            else
                -- Thief wild items (previously do_thief)
                local lead = get_lead_mon_index()
                local thief_slot = pokemon.get_move_slot(party[lead], "Thief")

                if config.thief_wild_items and foe_item and thief_slot ~= 0 then
                    print(foe_name ..
                              " has a held item. Using Thief and fleeing...")

                    while get_battle_state() ~= "Menu" do
                        press_sequence("B", 5)
                    end

                    use_move(thief_slot)
                    flee_battle()
                elseif config.battle_non_targets then
                    print(foe_name .. " was not a target. Battling...")

                    while game.in_battle() do
                        battle_foe()
                    end
                else
                    print(foe_name .. " was not a target. Fleeing!")
                    flee_battle()
                end
            end
        end
    end

    wait_frames(90)

    if config.pickup then do_pickup() end
end

--- Collects held items from Pickup Pokemon if enough have accumulated
function do_pickup()
    local item_count = 0

    for i, mon in ipairs(party) do
        if mon.Ability == "Pickup" and mon.HeldItem ~= nil then
            item_count = item_count + 1
        end
    end

    if item_count >= tonumber(config.pickup_threshold) then
        open_menu("Pokemon")

        for _, mon in ipairs(party) do
            if mon.Ability == "Pickup" and mon.HeldItem ~= nil then
                press_sequence("A", 8, "Up", 8, "Up", 8, "A", 22, "Down", 8, "A")
                wait_frames(90)
                press_button("B")
            end

            press_sequence("Right", 5)
        end

        press_sequence(30, "B", 120, "B", 60)
    else
        console.debug(item_count .. " Pickup items in party. Collecting at " .. config.pickup_threshold)
    end
end

--- Saves the game
function save_game()
    print("Saving game...")

    open_menu("Save")
    press_sequence("A", 90, "A", 60)

    while mbyte(pointers.save_indicator) ~= 0 do press_sequence("A", 12) end

    if _EMU == "BizHawk" then
        client.saveram() -- Flush save ram to the disk	
    end

    press_sequence("B", 10)
end

-- Selects a move on the FIGHT menu
-- @param id The move index in the moveset
function use_move(id)
    wait_frames(30)
    touch_screen_at(128, 90)
    wait_frames(30)

    local x = 80 * ((id - 1) % 2 + 1)
    local y = 50 * (math.floor((id - 1) / 2) + 1)
    touch_screen_at(x, y)
    wait_frames(60)
end

--- Attemps to KO the current foe
function battle_foe()
    while get_battle_state() ~= "Menu" do
        press_sequence("B", 5) -- Also cancels evolutions

        if not get_battle_state() then -- Battle finished, back in the overworld
            return
        elseif get_battle_state() == "New Move" then -- These cases are annoying and require specific inputs to cancel
            wait_frames(30)
            touch_screen_at(125, 115)
            wait_frames(100)
            press_button("B")
            wait_frames(100)
            touch_screen_at(125, 65)
            wait_frames(60)
            press_button("B")
            wait_frames(120)
            return
        end
    end

    local best_move = pokemon.find_best_attacking_move(
                          party[get_lead_mon_index()], foe[1])

    if best_move.power > 0 then
        console.debug("Best move is " .. best_move.name .. " (Avg Power: " ..
                        best_move.power .. ")")
        use_move(best_move.index)
    else
        print("Lead Pokemon has no valid moves left to battle! Fleeing...")
        flee_battle()
    end
end

--- Manages the party between battles to make sure the bot can proceed with its task
function check_party_status()
    local function is_healthy(mon)
        local pp = 0

        for i, move in ipairs(mon.Moves) do
            if move.Power ~= nil then pp = pp + move.PP end
        end

        return mon.CurrentHP > mon.Stats.HP / 5 and pp > 3 and not mon.IsEgg
    end

    if #party == 0 or game.in_battle() then -- Don't check party status if bot was started during a battle
        return nil
    end

    if not is_healthy(party[get_lead_mon_index()]) then
        if not config.cycle_lead_pokemon then
            abort(
                "Lead Pokemon is not suitable to battle, and the config disallows replacing it")
        end

        print("Lead Pokemon is not suitable to battle. Replacing...")

        local replacement

        for i, ally in ipairs(party) do
            if is_healthy(ally) then
                replacement = i
                break
            end
        end

        if not replacement then
            abort("No suitable Pokemon left to battle")
        end

        print("Next replacement is " .. party[replacement].name .. " (Slot " .. replacement .. ")")
        open_menu("Pokemon")

        -- Highlight lead
        local i = 1
        while i ~= get_lead_mon_index() do
            press_sequence("Right", 5)
            i = i + 1
        end

        -- Switch
        press_sequence("A", 30, "Up", 8, "Up", 8, "Up", 8, "A", 30)

        -- Highlight replacement
        local i = 1
        while i ~= replacement do
            press_sequence("Right", 5)
            i = i + 1
        end

        press_sequence("A", 30, "B", 120, "B", 120, "B", 30) -- Exit out of menu
    end

    if config.thief_wild_items then
        -- Check leading Pokemon for held items
        local lead = get_lead_mon_index()

        if party[lead].HeldItem ~= nil and
            pokemon.get_move_slot(party[lead], "Thief") ~= 0 then
            print("Thief Pokemon already holds an item. Removing...")
            clear_all_inputs()

            open_menu("Pokemon")

            local i = 1
            while i ~= lead do
                press_sequence("Right", 5)
                i = i + 1
            end

            -- Take item
            press_sequence("A", 8, "Up", 8, "Up", 8, "A", 22, "Down", 8, "A")
            wait_frames(90)
            press_button("B")

            press_sequence(30, "B", 120, "B", 60) -- Exit out of menu
        end
    end
end

--- Moves the bot toward a position on the map
-- @param target Target position (x, z)
-- @param on_move Function called each frame while moving
function move_to(target, on_move)
    if target.x then
        target.x = target.x + 0.5

        while game.trainer_position().X < target.x - 0.5 do
            hold_button("Right")
            if on_move then on_move() end
        end

        while game.trainer_position().X > target.x + 0.5 do
            hold_button("Left")
            if on_move then on_move() end
        end
    end

    if target.z then
        target.z = target.z + 0.5

        while game.trainer_position().Z < target.z - 0.5 do
            hold_button("Down")
            if on_move then on_move() end
        end

        while game.trainer_position().Z > target.z + 0.5 do
            hold_button("Up")
            if on_move then on_move() end
        end
    end
end

-- Same as above essentially, but won't gradually move the player off course
function move_to_fixed(target)
    while game.trainer_position().X < target.x do hold_button("Right") end

    while game.trainer_position().X > target.x do hold_button("Left") end

    while game.trainer_position().Z < target.z do hold_button("Down") end

    while game.trainer_position().Z > target.z do hold_button("Up") end
end

--- Presses the RUN button until the battle is over
function flee_battle()
    while game.in_battle() do
        touch_screen_at(125, 175)
        wait_frames(5)
    end

    print("Got away safely!")
end

--- Progress text with imperfect inputs to increase the randomness of frames hit
function progress_text()
    hold_button("A")
    wait_frames(math.random(5, 20))
    release_button("A")
    wait_frames(5)
end
