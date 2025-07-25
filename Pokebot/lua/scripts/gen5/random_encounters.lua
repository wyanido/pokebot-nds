-----------------------------------------------------------------------------
-- Gen 5 script for hunting Pokemon through random encounters in Gen 5.
-- Author: wyanido
-----------------------------------------------------------------------------
config_set_default("encounter_movement_style", "horizontal")

local home = {
    x = game_state.trainer_x,
    z = game_state.trainer_z
}

local function move_in_direction(dir)
    if emu.framecount() % 10 == 0 then -- Re-apply repel
        press_button_async("A")
    end

    hold_button(dir)
    wait_frames(7)
    release_button(dir)
end

function main()
    check_party_status()

    print("Attempting to start a battle...")

    local dir1 = _CONFIG.encounter_movement_style == "horizontal" and "Left" or "Up"
    local dir2 = _CONFIG.encounter_movement_style == "horizontal" and "Right" or "Down"
        
    wait_frames(60) -- Wait to regain control post-battle
    hold_button("B")

    while not game_state.in_battle do
        move_in_direction(dir1)
        move_in_direction(dir2)
    end
        
    release_button("B")
    release_button(dir2)

    process_wild_encounter()
end
