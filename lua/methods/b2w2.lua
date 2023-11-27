-----------------------
-- BW FUNCTION OVERRIDES
-----------------------
snivy_ball.x = 40
tepig_ball.y = 100
oshawott_ball.x = 210
take_button.y = 130

function update_pointers()
    offset.battle_menu_state = mdword(0x2141950 + 0x40 * game_version) + 0x135FC + 0x80
    
    -- console.log(string.format("%08X", offset.battle_menu_state))
end

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

    while mbyte(offset.starter_selection_is_open) ~= 1 do
        press_sequence("A", 5, "Left", 1)
    end

    console.log("Choosing Starter...")

    while mbyte(offset.starter_selection_is_open) ~= 0 do
        if mbyte(offset.selected_starter) ~= 4 then
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

    for i = 0, 116, 1 do
        press_sequence("B", 10)
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

    mon = party[1]
    local was_target = pokemon.log_encounter(mon)

    if was_target then
        pause_bot("Starter meets target specs")
    else
        console.log("Starter was not a target, resetting...")
        press_button("Power")
        wait_frames(60)
    end
end
