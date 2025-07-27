-----------------------------------------------------------------------------
-- Gen 5 script for hunting Pokemon through phenomena.
-- Author: wyanido, StoryZealot
-----------------------------------------------------------------------------
hint_config_default("encounter_movement_style", "horizontal")

local home = {
    x = game_state.trainer_x,
    z = game_state.trainer_z
}

local function accept_interrupt_text()
    local interrupted = false

    while mdword(pointers.text_interrupt) == 2 do
        press_sequence("Up", 1, "A", 1)
        interrupted = true
    end

    if interrupted then
        move_to(home)
    end
end

local function move_in_direction(dir)
    accept_interrupt_text()

    hold_button("B")
    hold_button(dir)
    wait_frames(4)
    release_button(dir)
    release_button("B")
end

function main()
    check_party_status()

    local function do_encounter()
        local dir1 = _CONFIG.encounter_movement_style == "horizontal" and "Left" or "Up"
        local dir2 = _CONFIG.encounter_movement_style == "horizontal" and "Right" or "Down"

        while game_state.phenomenon_x == 0 and game_state.phenomenon_z == 0 do
            move_in_direction(dir1)
            move_in_direction(dir2)
        end

        print("Phenomenon detected! Moving...")
        move_to({ x = game_state.phenomenon_x, z = game_state.phenomenon_z })

        wait_frames(300) --- Needs a moment before checking the encounter.

        if game_state.in_battle then
            process_wild_encounter()
        else
            print("Item received.")
            accept_interrupt_text()
        end
            
        move_to(home)
    end

    do_encounter()
end
