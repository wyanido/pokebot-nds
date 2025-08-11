-----------------------------------------------------------------------------
-- HGSS script for hunting starter Pokemon.
-- Author: wyanido
-----------------------------------------------------------------------------
function main()
    print("Waiting to see starters...")

    while mdword(pointers.starter_data - 0x8) ~= 0 or mdword(pointers.starter_data - 0x4) == 0 do
        progress_text()
    end

    wait_frames(9) -- Ensure all starters are loaded into memory

    -- Check all Pokémon
    local target = false

    for i = 0, 2, 1 do
        local starter = pokemon.parse_data(pointers.starter_data + i * _MON_BYTE_LENGTH)
        pokemon.log_encounter(starter)
        target = pokemon.is_target(mon) or target
    end

    if target then
        abort("")
    end

    -- Soft reset otherwise
    print("No starter were targets, resetting...")
    soft_reset()
end
