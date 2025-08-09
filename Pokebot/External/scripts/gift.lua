-----------------------------------------------------------------------------
-- General script for receiving and checking multiple gift Pokemon types
-- Author: wyanido
-----------------------------------------------------------------------------
function main()
    if not game_state.in_game then
        print("Waiting to reach overworld...")

        while not game_state.in_game do
            progress_text()
        end
    end

    local og_party_count = #party
    while #party == og_party_count do
        progress_text()
    end

    local mon = party[#party]
    local is_target = pokemon.log_encounter(mon)

    if is_target then
        abort(mon.name .. " is a target!")
    else
        print(mon.name .. " was not a target, resetting...")
        soft_reset()
    end
end
