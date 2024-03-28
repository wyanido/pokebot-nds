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