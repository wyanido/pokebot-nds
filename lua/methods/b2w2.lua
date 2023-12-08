-----------------------
-- BW FUNCTION OVERRIDES
-----------------------
snivy_ball.x = 40
tepig_ball.y = 100
oshawott_ball.x = 210
take_button.y = 130

function update_pointers()
    local offset = (_ROM.version == version.WHITE2) and 0x40 or 0x0 -- White version is offset slightly, moreso than original BW

    pointers = {
        -- Bag pouches, 4 byte pairs | 0001 0004 = 4x Master Ball
        items_pouch = 0x0221D9E4 + offset, -- 1240 bytes long
        key_items_pouch = 0x0221DEBC + offset, -- 332 bytes long
        tms_hms_case = 0x0221E008 + offset, -- 436 bytes long
        medicine_pouch = 0x0221E1BC + offset, -- 192 bytes long
        berries_pouch = 0x0221E27C + offset, -- 234 bytes long

        running_shoes = 0x0221DEC5 + offset, -- 0 before receiving

        -- Party
        party_count = 0x0221E3E8 + offset, -- 4 bytes before first index
        party_data = 0x0221E3EC + offset, -- PID of first party member

        step_counter = 0x0221EB5D + offset,
        step_cycle = 0x0221EB5E + offset,

        -- Location
        map_header = 0x0223B444 + offset,
        trainer_x = 0x0223B448 + offset,
        trainer_y = 0x0223B44C + offset,
        trainer_z = 0x0223B450 + offset,
        trainer_direction = 0x0223B462 + offset, -- 0, 4, 8, 12 -> Up, Left, Down, Right
        on_bike = 0x0223B484 + offset,
        encounter_table = 0x0223B7B8 + offset,
        map_matrix = 0x0223C3D4 + offset,

        phenomenon_x = 0x022427E8 + offset,
        phenomenon_z = 0x022427EC + offset,

        egg_hatching = 0x0225BB50 + offset,

        -- Battle
        battle_indicator = 0x02258D86 + offset, -- 0x41 if during a battle
        foe_count = 0x02258D90 + offset, -- 4 bytes before the first index
        current_foe = 0x02258D94 + offset, -- PID of foe, set immediately after the battle transition ends

        -- Misc
        save_indicator = 0x0223B4F0 + offset, -- 1 while save menu is open
        starter_selection_is_open = 0x0219CFE2 + offset, -- 0 when opening gift, 1 at starter select
        battle_bag_page = 0x022845FC + offset,
        selected_starter = 0x022574C4 + offset, -- Unconfirmed selection in gift box; 0 Snivy, 1 Tepig, 2 Oshawott, 4 Nothing
        text_interrupt = 0x216E640 + offset, -- 2 when a repel/fishing dialogue box is open, 0 otherwise
        fishing_bite_indicator = 0x209B3CA + offset,
        fishing_no_bite = 0x214BC62 + offset,

        battle_menu_state = mdword(0x2141950 + offset) + 0x1367C -- 1 on FIGHT menu, 2 on move select, 4 on switch/run after faint, 0 otherwise
    }
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

        while not game_state.in_game do press_sequence("A", 20) end
    end

    console.log("Opening Starter Selection...")

    while mbyte(pointers.starter_selection_is_open) ~= 1 do
        press_sequence("A", 5, "Left", 1)
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

    while #party == 0 do press_sequence("A", 5) end

    for i = 0, 116, 1 do press_sequence("B", 10) end

    if not config.hax then
        -- Party menu
        press_sequence("X", 30)
        touch_screen_at(65, 45)
        wait_frames(90)

        touch_screen_at(80 * ((#party - 1) % 2 + 1),
                        30 + 50 * ((#party - 1) // 2)) -- Select gift mon
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
