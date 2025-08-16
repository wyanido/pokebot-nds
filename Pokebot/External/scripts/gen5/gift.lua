-----------------------------------------------------------------------------
-- Gen 5 script for hunting gift Pokemon.
-- Author: wyanido
-----------------------------------------------------------------------------
function main()
    if not game.save_file_loaded() then
        print("Waiting to reach overworld...")

        while not game.save_file_loaded() do
            progress_text()
        end

        wait_frames(200)
    end

    local og_party_count = #party
    while #party == og_party_count do
        progress_text()
    end

    local party = game.party()
    local mon = party[#party - 1]
    local is_target = pokemon.is_target(mon)
    pokemon.log_encounter(mon)

    if is_target then
        abort(mon.Species.Name .. " is a target!")
    else
        print(mon.Species.Name .. " was not a target, resetting...")
        soft_reset()
    end
end