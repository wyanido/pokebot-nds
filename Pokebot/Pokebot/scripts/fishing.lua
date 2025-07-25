-----------------------------------------------------------------------------
-- General script for fishing repeatedly until a target Pokemon is found.
-- Author: wyanido
-----------------------------------------------------------------------------
function main()
    while not game_state.in_battle do
        press_button("Y")
        wait_frames(60)

        while not fishing_status_changed() do 
            wait_frames(1)
        end

        if fishing_has_bite() then
            print("Landed a Pokemon!")
            break
        else
            print("Not even a nibble...")
            press_sequence(30, "A", 20)
        end
    end

    while not game_state.in_battle do
        progress_text()
    end

    process_wild_encounter()

    wait_frames(90)
end
