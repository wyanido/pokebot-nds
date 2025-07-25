-----------------------------------------------------------------------------
-- Base BW script for hunting Tornadus and Thundurus.
-- Author: wyanido
-----------------------------------------------------------------------------
local function dex_entry_added()
    local tornadus_seen = dex_registered("tornadus", "male") or dex_registered("tornadus", "shiny_male")
    local thundurus_seen = dex_registered("thundurus", "male") or dex_registered("thundurus", "shiny_male")

    return tornadus_seen or thundurus_seen
end

function main()
    while not game_state.in_game do
        print("Not in game yet")
        progress_text()
    end

    -- Exit house
    while game_state.map_header == 344 do
        hold_button("Down")
    end

    release_button("Down")

    -- Skip through cutscene until dex entry is registered
    while not dex_entry_added() do
        progress_text()
    end

    -- Read pre-generated Pokemon from memory
    local data = pokemon.read_data(pointers.roamer)
    local mon = pokemon.parse_data(data, true)
    local is_target = pokemon.log_encounter(mon)

    if is_target then
        abort(mon.name .. " is a target!")
    else
        print(mon.name .. " was not a target, resetting...")
        soft_reset()
    end
end
