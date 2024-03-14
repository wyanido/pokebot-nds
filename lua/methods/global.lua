-- No bot logic, just log encounters as the user plays
function mode_manual()
    while true do
        while not game_state.in_battle do
            process_frame()
        end

        for i = 1, #foe, 1 do
            pokemon.log_encounter(foe[i])
        end

        while game_state.in_battle do
            process_frame()
        end
    end
end

function mode_fishing()
    while not game_state.in_battle do
        press_button("Y")
        wait_frames(60)

        while not fishing_status_changed() do 
            wait_frames(1)
        end

        if fishing_has_bite() then
            print("Landed a Pokémon!")
            break
        else
            print("Not even a nibble...")
            press_sequence(30, "A", 20)
        end
    end

    while not game_state.in_battle do
        press_sequence("A", 5)
    end

    process_wild_encounter()

    wait_frames(90)
end