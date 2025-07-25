-----------------------------------------------------------------------------
-- Platinum script for hunting Pokemon by hatching eggs.
-- The bot bikes through Solaceon Town until the party is full of hatched eggs,
-- then frees up party space at the PC if no targets were hatched.
-- Author: wyanido
-----------------------------------------------------------------------------
function main()
    local function mount_bike()
        if mbyte(pointers.bike) ~= 1 then press_sequence("Y", 5) end
        if mbyte(pointers.bike_gear) ~= 1 then press_button("B") end
    end
    
    local function check_and_collect_egg()
        -- Don't bother with additional eggs if party is full
        if #party == 6 or mdword(pointers.daycare_egg) == 0 then
            return
        end

        print("That's an egg!")

        move_to({z=648}, check_hatching_eggs)
        move_to({x=556}, check_hatching_eggs)
        clear_all_inputs()

        local party_count = #party
        while #party == party_count do
            progress_text()
        end

        -- Return to long vertical path 
        move_to({x=562}, check_hatching_eggs)
    end

    -- Initialise party state for future reference
    process_frame()
    party_egg_states = get_party_egg_states()

    mount_bike()
    move_to({x=562}, check_hatching_eggs)
    
    while true do
        move_to({z=630}, check_hatching_eggs)
        check_and_collect_egg()
        move_to({z=675}, check_hatching_eggs)
        check_and_collect_egg()
    end
end
