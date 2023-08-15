
-----------------------
-- BW FUNCTION OVERRIDES
-----------------------

starter_gift_direction = "Left"
snivy_ball.x = 40
tepig_ball.y = 100
oshawott_ball.x = 210
take_button.y = 130

function update_pointers()
    offset.battle_menu_state = mdword(0x2141950 + 0x40 * game_version) + 0x135FC + 0x80
    
    -- console.log(string.format("%08X", offset.battle_menu_state))
end

function mode_starters_advance_until_battle()
    hold_button("Down")

    while not game_state.in_battle do
        press_sequence("B", 5)
    end

    release_button("Down")
end
