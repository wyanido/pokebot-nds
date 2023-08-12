
-----------------------
-- BW FUNCTION OVERRIDES
-----------------------

starter_gift_direction = "Left"
snivy_ball.x = 40
tepig_ball.y = 100
oshawott_ball.x = 210
take_button.y = 130

function update_pointers()
    if game_version == 0 then -- black 2
        offset.battle_menu_state = mdword(0x2141950) + 0x135FC + 0x80
    else -- white 2
        offset.battle_menu_state = mdword(0x213B2F4) + 0x13588 + 0x80 
    end
    -- console.log(string.format("%08X", offset.battle_menu_state))
end

function mode_starters_advance_until_battle()
    hold_button("Down")

    while not game_state.in_battle do
        press_sequence("B", 5)
    end

    release_button("Down")
end
