-----------------------
-- BW FUNCTION OVERRIDES
-----------------------

function update_pointers()
    local anchor = mdword(0x2141950 + _ROM.offset)

    pointers = {
        -- Bag pouches, 4 byte pairs | 0001 0004 = 4x Master Ball
        items_pouch     = 0x0221D9E4 + _ROM.offset, -- 1240 bytes long
        key_items_pouch = 0x0221DEBC + _ROM.offset, -- 332 bytes long
        tms_hms_case    = 0x0221E008 + _ROM.offset, -- 436 bytes long
        medicine_pouch  = 0x0221E1BC + _ROM.offset, -- 192 bytes long
        berries_pouch   = 0x0221E27C + _ROM.offset, -- 234 bytes long

        running_shoes = 0x0221DEC5 + _ROM.offset, -- 0 before receiving

        -- Party
        party_count = 0x0221E3E8 + _ROM.offset, -- 4 bytes before first index
        party_data  = 0x0221E3EC + _ROM.offset, -- PID of first party member

        step_counter = 0x0221EB5D + _ROM.offset,
        step_cycle   = 0x0221EB5E + _ROM.offset,

        -- Location
        map_header        = 0x0223B444 + _ROM.offset,
        trainer_x         = 0x0223B448 + _ROM.offset,
        trainer_y         = 0x0223B44C + _ROM.offset,
        trainer_z         = 0x0223B450 + _ROM.offset,
        trainer_direction = 0x0223B462 + _ROM.offset, -- 0, 4, 8, 12 -> Up, Left, Down, Right
        on_bike           = 0x0223B484 + _ROM.offset,
        encounter_table   = 0x0223B7B8 + _ROM.offset,
        map_matrix        = 0x0223C3D4 + _ROM.offset,

        phenomenon_x = 0x022427E8 + _ROM.offset,
        phenomenon_z = 0x022427EC + _ROM.offset,

        egg_hatching = 0x0225BB50 + _ROM.offset,

        -- Battle
        battle_indicator = 0x02258D86 + _ROM.offset, -- 0x41 if during a battle
        foe_count        = 0x02258D90 + _ROM.offset, -- 4 bytes before the first index
        current_foe      = 0x02258D94 + _ROM.offset, -- PID of foe, set immediately after the battle transition ends

        -- Misc
        save_indicator            = 0x0223B4F0 + _ROM.offset, -- 1 while save menu is open
        starter_selection_is_open = 0x0219CFE2 + _ROM.offset, -- 0 when opening gift, 1 at starter select
        battle_bag_page           = 0x022845FC + _ROM.offset,
        selected_starter          = 0x022574C4 + _ROM.offset, -- Unconfirmed selection in gift box; 0 Snivy, 1 Tepig, 2 Oshawott, 4 Nothing
        text_interrupt            = 0x216E640 + _ROM.offset, -- 2 when a repel/fishing dialogue box is open, 0 otherwise
        fishing_bite_indicator    = 0x209B3CA + _ROM.offset,
        fishing_no_bite           = 0x214BC62 + _ROM.offset,

        battle_menu_state = anchor + 0x1367C, -- 1 on FIGHT menu, 2 on move select, 4 on switch/run after faint, 0 otherwise
    
        trainer_name = 0x221E9E8 + _ROM.offset,
        trainer_id   = 0x221E9F8 + _ROM.offset
    }
end

function mode_starters()
    cycle_starter_choice()
    
    local balls = {
        [0] = { x = 40, y = 100 }, -- Snivy
        [1] = { x = 128, y = 100 }, -- tepig
        [2] = { x = 210, y = 100 }, -- Oshawott
    }

    if not game_state.in_game then
        print("Waiting to reach overworld...")

        while not game_state.in_game do 
            press_sequence("A", 20) 
        end
    end

    print("Opening Starter Selection...")

    while mbyte(pointers.starter_selection_is_open) ~= 1 do
        press_sequence("A", 5)
    end

    print("Choosing Starter...")

    while mbyte(pointers.starter_selection_is_open) ~= 0 do
        if mbyte(pointers.selected_starter) ~= 4 then
            touch_screen_at(120, 180) -- Pick this one!
            wait_frames(5)
            touch_screen_at(240, 100) -- Yes
            wait_frames(5)
        else
            touch_screen_at(balls[starter].x, balls[starter].y) -- Starter
            wait_frames(5)
        end
    end

    while #party == 0 do 
        press_sequence("A", 5) 
    end

    if not config.hax then
        print("Waiting to see starter...")
        
        for i = 0, 90, 1 do 
            press_sequence("B", 10) 
        end

        -- Party menu
        press_sequence("X", 30)
        touch_screen_at(65, 45)
        wait_frames(90)

        touch_screen_at(80 * ((#party - 1) % 2 + 1), 30 + 50 * math.floor((#party - 1) / 2)) -- Select gift mon
        wait_frames(30)

        touch_screen_at(200, 105) -- SUMMARY
        wait_frames(120)
    end

    local was_target = pokemon.log_encounter(party[1])

    if was_target then
        abort("Starter meets target specs")
    else
        print("Starter was not a target, resetting...")
        soft_reset()
    end
end

function mode_hidden_grottos()
    if game_state.map_header ~= 518 then -- All Hidden Grottos share the same map ID
        abort("Please start the script inside of a Hidden Grotto!")
    end

    hold_button("Down")

    while game_state.map_header == 518 do
        wait_frames(2)
    end

    release_button("Down")
end