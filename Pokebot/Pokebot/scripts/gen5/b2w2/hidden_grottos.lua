-----------------------------------------------------------------------------
-- B2W2 script for hunting Pokemon in hidden grottos.
-- Author: wyanido, StoryZealot
-----------------------------------------------------------------------------
config_set_default("grotto", 0)

-- Set the 'grotto' value in your config to the value corresponding to the grotto you want to hunt.
-- 0    Floccesy Ranch
-- 2    Route 5
-- 4    Lostlorn Forest
-- 6    Route 6 (Mistralton Cave)
-- 8    Route 6 (South)
-- 10   Route 7
-- 12   Route 13 (East)
-- 14   Route 13 (West)
-- 16   Route 9
-- 18   Giant Chasm
-- 20   Route 22
-- 22   Route 23
-- 24   Abundant Shrine (South)
-- 26   Abundant Shrine (Lakeside)
-- 28   Pinwheel Forest (Inside)
-- 30   Pinwheel Forest (Outside)
-- 32   Route 3 (Lakeside)
-- 34   Route 3 (In Grass)
-- 36   Route 2

local function grotto_has_regenerated()
    local grotto_value = mbyte(pointers.hidden_grottos + _CONFIG.grotto)
    print("Grotto value: ", grotto_value)  -- Debug output
    return bit.band(grotto_value, 1) == 1
end

local function exit_grotto()
    hold_button("B")
    hold_button("Down")
        
    while game_state.map_name == "Hidden Grotto" do
        wait_frames(1)
        if emu.framecount() % 10 == 0 then -- Re-apply repel
            press_button_async("A")
        end
    end
        
    release_button("Down")
    release_button("B")
    wait_frames(180)
end

local function enter_grotto()
    press_sequence("Up", 4, "A")

    while game_state.map_name ~= "Hidden Grotto" do
        progress_text()
    end

    wait_frames(120)

    hold_button("B")
    hold_button("Up")
        
    while game_state.trainer_z > 13 do
        wait_frames(1)
        if emu.framecount() % 10 == 0 then -- Re-apply repel
            press_button_async("A")
        end
    end
        
    release_button("B")
    release_button("Up")
end

function main()
    if game_state.map_name == "Hidden Grotto" then
        exit_grotto()
    end

    print("Waiting for grotto to regenerate...")

    while not grotto_has_regenerated() do
        bike_back_and_forth()
        if game_state.in_battle then
            abort("Please use a Repel while hunting this grotto!")
        end
    end
    
    print("Grotto regenerated!")
    
    enter_grotto()
    
    -- Interact and wait for potential battle
    press_sequence("A", 300)

    if game_state.in_battle then
        process_wild_encounter()
    else
        press_sequence("A", 50, "A") -- Item dialogue
    end
end
