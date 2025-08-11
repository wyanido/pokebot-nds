-----------------------------------------------------------------------------
-- DPPL script for hunting starter Pokemon.
-- Picks the specified starter Pokemon each reset until it's a target
-- Author: wyanido
-----------------------------------------------------------------------------
function main()
    cycle_starter_choice()
    
    -- Diamond and Pearl need to skip through a cutscene before the briefcase
    local platinum = _ROM.version == "PT"

    if not platinum then 
        hold_button("Up")

        while game.map_name() ~= "Lake Verity" do
            progress_text()
        end
        
        release_button("Up")
    end
    
    print("Waiting to open briefcase...")
    
    -- Skip until the starter can be selected, which
    -- is known when the lower 4 bits of the byte at
    -- the starters pointer equals the ready value
    local ready_value = platinum and 0xD or 0x5

    if _ROM.language == "JP" and not platinum then
        ready_value = 0x1
    end

    while bit.band(bit.band(mbyte(pointers.starters_ready), 15), ready_value) ~= ready_value do
        progress_text()
    end

    print("Selecting starter...")

    while mbyte(pointers.selected_starter) < starter do
        press_sequence("Right", 5)
    end

    -- Wait until starter is added to party
    while #party == 0 do
        progress_text()
    end

    -- Log encounter, stopping if necessary
    local mon = party[1]
    local is_target = pokemon.is_target(mon)
    pokemon.log_encounter(mon)

    if is_target then
        abort(mon.Species.Name .. " is a target!")
    else
        print(mon.Species.Name .. " was not a target, resetting...")
        soft_reset()
    end
end
