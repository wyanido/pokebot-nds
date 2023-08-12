

function update_pointers()
    if game_version == 0 then
        offset.battle_menu_state = mdword(0x2141950) + 0x135FC + 0x80
    else
        offset.battle_menu_state = mdword(0x213B2F4) + 0x13588 + 0x80 
    end
    -- console.log(string.format("%08X", offset.battle_menu_state))
end

function mode_starters(starter)
    local ball_x
    local ball_y

    if starter == 0 then
        ball_x = 40
        ball_y = 100
    elseif starter == 1 then
        ball_x = 128
        ball_y = 100
    elseif starter == 2 then
        ball_x = 210
        ball_y = 100
    end

    if not game_state.in_game then
        console.log("Waiting to reach overworld...")

        while not game_state.in_game do
            press_sequence("A", 20)
        end
    end

    console.log("Opening Gift Box...")

    while game_state.starter_selection_is_open ~= 1 do
        press_sequence("A", 5, "Left", 1)
    end

    console.log("Choosing Starter...")

    while game_state.starter_selection_is_open ~= 0 do
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

        hold_button("Down")

        while not game_state.in_battle do
            press_sequence("B", 5)
        end

        release_button("Down")

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
    
    if was_target then
        pause_bot("Starter meets target specs")
    else
        console.log("Starter was not a target, resetting...")
        press_button("Power")
        wait_frames(60)
    end
end
