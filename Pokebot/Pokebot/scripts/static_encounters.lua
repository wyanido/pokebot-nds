-----------------------------------------------------------------------------
-- General script for resetting overworld Pokemon until a target is found
-- Author: wyanido
-----------------------------------------------------------------------------
config_set_default("auto_catch", false)

function main()
    while not game_state.in_battle do
        if game_state.map_name == "Dreamyard" then
            hold_button("Right")
        elseif game_state.map_name == "Spear Pillar" then
            hold_button("Up")
        end

        progress_text()
    end

    local mon = foe[1]
    local is_target = pokemon.log_encounter(mon)

    if is_target then
        if _CONFIG.auto_catch then
            while game_state.in_battle do
                catch_pokemon()
            end

            abort("Target " .. mon.name .. " was caught!")
        else
            abort(mon.name .. " is a target!")
        end
    else
        print(mon.name .. " was not a target, resetting...")
        soft_reset()
    end
end
