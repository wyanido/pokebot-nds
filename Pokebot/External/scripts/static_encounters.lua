-----------------------------------------------------------------------------
-- General script for resetting overworld Pokemon until a target is found
-- Author: wyanido
-----------------------------------------------------------------------------
hint_config_default("auto_catch", false)

function main()
    while not game.in_battle() do
        if game.map_name() == "Dreamyard" then
            hold_button("Right")
        elseif game.map_name() == "Spear Pillar" then
            hold_button("Up")
        end

        progress_text()
    end

    local mon = foe[1]
    local is_target = pokemon.is_target(mon)
    pokemon.log_encounter(mon)

    if is_target then
        if config.auto_catch then
            while game.in_battle() do
                catch_pokemon()
            end

            abort("Target " .. mon.Species.Name .. " was caught!")
        else
            abort(mon.Species.Name .. " is a target!")
        end
    else
        print(mon.Species.Name .. " was not a target, resetting...")
        soft_reset()
    end
end
