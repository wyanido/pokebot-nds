-----------------------------------------------------------------------------
-- Logs wild encounters without automated inputs while the user plays.
-- Author: wyanido
-----------------------------------------------------------------------------
function main()
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
