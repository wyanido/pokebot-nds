-----------------------------------------------------------------------------
-- Bot method overrides for B2W2
-- Author: wyanido
-- Homepage: https://github.com/wyanido/pokebot-nds
-----------------------------------------------------------------------------
hint_config_default("encounter_movement_style", "horizontal")

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
        trainer_direction = 0x0223B45D + _ROM.offset, -- 0, 0x40, 0x80, 0xC0 -> Up, Left, Down, Right
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
        battle_menu_state         = anchor + 0x1367C, -- 1 on FIGHT menu, 2 on move select, 4 on switch/run after faint, 0 otherwise
        
        fishing_bite_indicator    = 0x209B3CA + _ROM.offset,
        fishing_no_bite           = 0x214BC62 + _ROM.offset,
    
        trainer_name = 0x221E9E8 + _ROM.offset,
        trainer_id   = 0x221E9F8 + _ROM.offset,

        hidden_grottos = 0x22291B0 + _ROM.offset,
        daycare_egg = 0x22264AC + _ROM.offset,
        -- pass_power_1_duration = 0x21410B8 + _ROM.offset,
    }
end

function bike_back_and_forth()
    local horizontal = config.encounter_movement_style == "horizontal"
    local axis = horizontal and pointers.trainer_x or pointers.trainer_z
    local dir1 = horizontal and "Right" or "Down"
    local dir2 = horizontal and "Left" or "Up"

    local function move_in_direction(dir)
        hold_button(dir)
        wait_frames(2)

        local z = mword(axis)
        while mword(axis) == z do
            hold_button(dir)

            if emu.framecount() % 10 == 0 then -- Re-apply repel
                press_button_async("A")
            end

            if game.in_battle() then
                return
            end
        end
    end

    -- Use registered bike if not already riding
    if mbyte(pointers.on_bike) ~= 1 then
        press_sequence("Y", 30, "A")
    end

    move_in_direction(dir1)
    move_in_direction(dir2)

    release_button(dir2)
end

--- Navigates to the Route 3 daycare and releases all hatched Pokemon in the party
function release_hatched_duds()
    local function release(i)
        local x = 40 * ((i - 1) % 2 + 1)
        local y = 72 + 30 * math.floor((i - 1) / 2)
        
        touch_screen_at(x, y) -- Select Pokemon
        wait_frames(30)
        touch_screen_at(211, 121) -- RELEASE
        wait_frames(30)
        touch_screen_at(220, 110) -- YES
        press_sequence(60, "B", 20, "B", 20) -- Bye-bye!
    end

    move_to({x=748}) -- Move to staircase
    move_to({z=557}) -- Move to the door
    move_to({x=749,z=556})
    
    -- Walk to daycare lady at desk
    while game.map_header() ~= 323 do
        hold_button("Up")
    end

    release_button("Up")

    -- Walk to PC
    hold_button("B")
    move_to({z=9})
    move_to({x=9})
    hold_button("Up")
    wait_frames(10)
    release_button("Up")
    wait_frames(10)
    release_button("B")
    
    -- PC Menu
    press_sequence("A", 140, "A", 120, "A", 110, "A", 60, "A", 60, "Down", 5, "Down", 5, "A", 110)

    touch_screen_at(45, 175)
    wait_frames(60)

    -- Release party in reverse order so the positions don't shuffle to fit empty spaces
    for i = #party, 1, -1 do
        if pokemon.is_hatched_dud(party[i]) then
            release(i)
        end
    end

    press_sequence("B", 25, "B", 30, "B", 30, "B", 150, "B", 90) -- Exit PC
    
    -- Exit daycare
    hold_button("B")
    move_to({x=6})
    move_to({z=13})
    press_sequence("Down")

    --Restart the loop
    release_button("B")
    release_button("Down")
    press_sequence(180, "Y", 30, "Y", 30, "Y")
    move_to({z=557})
    move_to({x=748})
    move_to({z=563})
end
