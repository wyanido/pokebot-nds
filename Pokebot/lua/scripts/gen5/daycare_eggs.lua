-----------------------------------------------------------------------------
-- Gen 5 script for hunting Pokemon via the daycare.
-- The script assumes your key items menu has the Bicycle selected.
-- Author: wyanido, StoryZealot
-----------------------------------------------------------------------------
function main()
    local bike_state = mbyte(pointers.on_bike)

    local function mount_bike()
        -- Re-check bike state after any prior checks
        bike_state = mbyte(pointers.on_bike) -- Ensure you get the latest state
        if bike_state ~= 1 then 
            press_sequence("Y", 30, "Y")
        end
    end

    -- Execute the function to mount bike
    mount_bike()
    
    -- Check the bike state again after mounting attempt
    bike_state = mbyte(pointers.on_bike)

    local function check_and_collect_egg()
        print("Checking for eggs...")

        -- Don't bother if party is full
        if #party == 6 then
            print("Party is full, cannot collect more eggs.")
            return
        end

        if mdword(pointers.daycare_egg) == 0 then
            print("No eggs available to collect.")
            return
        end

        print("That's an egg!")
        move_to({x = 748}, check_hatching_eggs)
        move_to({z = 557}, check_hatching_eggs)
        clear_all_inputs()

        local party_count = #party
        while #party == party_count do
            -- Check for egg availability within the loop
            if #party < 6 and mdword(pointers.daycare_egg) > 0 then
                progress_text() 
            end
        end

        -- Return to long horizontal path 
        press_sequence(30, "B")
        move_to({z = 563}, check_hatching_eggs)
    end

    -- Initialise party state for future reference
    process_frame()
    party_egg_states = get_party_egg_states()

    move_to({z = 563}, check_hatching_eggs)

    while true do
        move_to({x = 680}, check_hatching_eggs)

        move_to({x = 748}, check_hatching_eggs)
        check_and_collect_egg()

        move_to({x = 759}, check_hatching_eggs)

        move_to({x = 748}, check_hatching_eggs)
        check_and_collect_egg()

        -- Check if the party is full and if there are no eggs remaining
        if #party == 6 then  -- Check if party is full
            local current_egg_states = get_party_egg_states()  -- Refresh the egg states

            -- Only release if there are no eggs left in the party
            local has_egg = false
            for _, is_egg in ipairs(current_egg_states) do
                if is_egg then
                    has_egg = true
                    break
                end
            end
            
            if not has_egg then
                print("All eggs hatched. Releasing hatched duds...")
                release_hatched_duds()
            else
                print("Some eggs are still unhatched. Not releasing.")
            end
        end
    end
end