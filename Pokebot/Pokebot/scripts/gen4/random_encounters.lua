------------------------------------------------------------------------------
-- Gen 5 script for hunting Pokemon through random encounters.
-- Encounters wild Pokemon until a target is found.
-- Author: wyanido
------------------------------------------------------------------------------
hint_config_default("encounter_movement_style", "horizontal")

local function spin()
    -- Prevent accidentally taking a step by
    -- preventing a down input while facing down
    if mbyte(pointers.facing) == 1 then
        press_sequence("Right", 3)
    end

    while not game_state.in_battle do
        press_sequence(
            "Down", 3,
            "Left", 3,
            "Up", 3,
            "Right", 3
        )
    end
end

local function run_back_and_forth()
    local dir1, dir2, start_face
        
    if _CONFIG.encounter_movement_style == "horizontal" then
        dir1 = "Left"
        dir2 = "Right"
        start_face = 2
    else
        dir1 = "Up"
        dir2 = "Down"
        start_face = 0
    end

    if mbyte(pointers.facing) ~= start_face then
        press_sequence(dir2, 8)
    end

    hold_button("B")
        
    while not game_state.in_battle do
        hold_button(dir1)
        wait_frames(7)
        hold_button(dir2)
        wait_frames(7)
    end

    release_button("B")
end

function main()
    check_party_status()
    
    print("Attempting to start a battle...")
    wait_frames(30)

    if _CONFIG.encounter_movement_style == "spin" then
        spin()
    else
        run_back_and_forth()
    end

    process_wild_encounter()
end
