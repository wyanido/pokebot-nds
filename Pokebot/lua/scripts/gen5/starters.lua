-----------------------------------------------------------------------------
-- Base BW script for hunting starter Pokemon.
-- Author: wyanido
-----------------------------------------------------------------------------
function main()
    cycle_starter_choice()
    
    local balls = {
        [0] = { x = 60, y = 100 }, -- Snivy
        [1] = { x = 128, y = 75 }, -- tepig
        [2] = { x = 185, y = 100 }, -- Oshawott
    }

    if not game_state.in_game then
        print("Waiting to reach overworld...")

        while not game_state.in_game do
            progress_text()
        end
    end

    -- Ensure value has reset before trying to pick starter, otherwise the box will be assumed open too early
    while mbyte(pointers.starter_selection_is_open) ~= 0 do
        process_frame()
    end
    
    print("Opening Starter Selection...")

    while mbyte(pointers.starter_selection_is_open) == 0 do
        progress_text()
    end

    print("Choosing Starter...")

    while mbyte(pointers.starter_selection_is_open) ~= 0 do
        if mbyte(pointers.selected_starter) ~= 4 then
            touch_screen_at(120, 180) -- Pick this one!
            wait_frames(5)
            touch_screen_at(240, 100) -- Yes
            wait_frames(5)
        else
            touch_screen_at(balls[starter].x, balls[starter].y) -- Starter
            wait_frames(5)
        end
    end

    while #party == 0 do
        progress_text()
    end

    local mon = party[1]
    local is_target = pokemon.log_encounter(mon)

    if is_target then
        abort(mon.name .. " is a target!")
    else
        print(mon.name .. " was not a target, resetting...")
        soft_reset()
    end
end