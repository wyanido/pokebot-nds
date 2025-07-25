-----------------------------------------------------------------------------
-- HGSS script for hunting Pokemon by headbutting trees.
-- The script assumes at least one Pokemon in the party knows Headbutt.
-- Author: wyanido
-----------------------------------------------------------------------------
function main()
    local function find_move_in_party(move_name)
        for i = 1, #party, 1 do
            for j = 1, #party[i].moves, 1 do
                local move = party[i].moves[j].name

                if move == move_name then
                    return true
                end
            end
        end

        return false
    end

    if not find_move_in_party("Headbutt") then
        abort("No Headbutt user found in party!")
    end

    while true do
        local og_dir = mbyte(pointers.facing)
        local og_x = game_state.trainer_x
        local og_z = game_state.trainer_z

        -- Press A until following Pokemon pushes you out of the way
        while game_state.trainer_x == og_x and game_state.trainer_z == og_z do
            progress_text()
        end

        -- Wait for battle to start
        wait_frames(400)

        if game_state.in_battle then
            process_wild_encounter()
            wait_frames(90)
        else
            -- Headbut Trees in HGSS have a 100% encounter rate, so if
            -- nothing is encountered, this tree will never spawn anything
            abort("This tree doesn't yield any Pokemon!")
        end
        
        -- Return to original position
        local dir = mbyte(pointers.facing)

        if dir == 0 then     press_button("Down")
        elseif dir == 1 then press_button("Up")
        elseif dir == 2 then press_button("Right")
        elseif dir == 3 then press_button("Left") end

        wait_frames(24)

        -- Face the tree again
        if og_dir == 0 then     press_button("Up")
        elseif og_dir == 1 then press_button("Down")
        elseif og_dir == 2 then press_button("Left")
        elseif og_dir == 3 then press_button("Right") end
    end
end
