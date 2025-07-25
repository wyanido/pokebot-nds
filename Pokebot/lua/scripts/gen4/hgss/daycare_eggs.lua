-----------------------------------------------------------------------------
-- HGSS script for hunting Pokemon by hatching eggs.
-- Author: wyanido, StoryZealot
-----------------------------------------------------------------------------
function main()
    local function mount_bike()
        if mbyte(pointers.bike) ~= 1 then 
            press_sequence("Y")
        end
    end
    
    local function check_and_collect_egg()
        -- Don't bother with additional eggs if party is full
        if #party == 6 or mdword(pointers.daycare_egg) == 0 then
            return
        end

        print("That's an egg!")

        move_to({z=410}, check_hatching_eggs)
        move_to({x=364}, check_hatching_eggs)
        clear_all_inputs()

        local party_count = #party
        while #party == party_count do
            progress_text()
        end

        -- Return to long vertical path 
        press_sequence(30, "B")
        move_to({x=358}, check_hatching_eggs)
    end

    -- Initialise party state for future reference
    process_frame()
    party_egg_states = get_party_egg_states()

    mount_bike()
    move_to({x=358}, check_hatching_eggs)
    
    while true do
        move_to({z=380}, check_hatching_eggs)
        check_and_collect_egg()
        move_to({z=410}, check_hatching_eggs)
    end
end
