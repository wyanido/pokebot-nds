-----------------------
-- DP FUNCTION OVERRIDES
-----------------------
function update_pointers()
    local mem_shift = mdword(0x21D4158)

    pointers = {
        party_count = mem_shift - 0x23F44,
        party_data  = mem_shift - 0x23F40,
        
        foe_count   = mem_shift + 0x7574,
        current_foe = mem_shift + 0x7578,

        map_header  = mem_shift - 0x22DA4,
        trainer_x   = mem_shift - 0x22D9E,
        trainer_z   = mem_shift - 0x22D9A,
        trainer_y   = mem_shift - 0x22D96,
        facing      = mem_shift + 0x25E88,

        battle_state_value = mem_shift + 0x470D4, -- 01 is FIGHT menu, 04 is Move Select, 08 is Bag,
        battle_indicator   = 0x021E76D2 -- Static
    }

    if mword(pointers.map_header) == 340 then -- Bell Tower
        -- Wild Ho-oh's data is located at a different address to standard encounters
        -- May apply to other statics too -- research?
        pointers.foe_count = mem_shift + 0x977C
    end

    -- TODO replace the methods that depend on these pointers
    local mem_shift = mdword(0x21D2228) -- 27C1E0  --value @ 2C32B4

    pointers.current_pokemon = mem_shift + 0x49E14 -- 0A is POkemon menu 0E is animation
    pointers.foe_in_battle = pointers.current_pokemon + 0xC0 -- 2C5ff4
    pointers.foe_status = pointers.foe_in_battle + 0x6C
    pointers.current_hp = mword(pointers.current_pokemon + 0x4C)
    pointers.level = mbyte(pointers.current_pokemon + 0x34)
    pointers.foe_current_hp = mword(pointers.foe_in_battle + 0x4C)
end

local save_counter = 0

function save_game()
    console.log("Saving game...")
    touch_screen_at(125, 75)
    wait_frames(30)
    hold_button("B")
    wait_frames(100)
    release_button("B")
    wait_frames(10)
    touch_screen_at(230, 95)
    wait_frames(30)
    hold_button("B")
    wait_frames(100)
    release_button("B")
    wait_frames(10)
    touch_screen_at(230, 95)
    wait_frames(800)

    console.log("Saving ram")
    client.saveram() -- Flush save ram to the disk	

    press_sequence("B", 10)
end

function mode_starters()
    -- Get starter data offset for this reset
    local starter_pointer = mdword(0x2111938) + 0x1BF78

    -- Proceed until starters are loaded into RAM
    while mdword(starter_pointer - 0x8) ~= 0 or mdword(starter_pointer - 0x4) == 0 do
        starter_pointer = mdword(0x2111938) + 0x1BF78

        local delay = math.random(6, 21) -- Mimic imperfect human inputs
        press_sequence("A", delay)
    end

    if not config.hax then
        press_sequence(130, "A", 15)
    else
        wait_frames(5)
    end

    -- Check all Pokémon
    local is_target = false
    for i = 0, 2, 1 do
        local mon_data = pokemon.decrypt_data(starter_pointer + i * MON_DATA_SIZE)
        local starter = pokemon.parse_data(mon_data, true)

        is_target = pokemon.log_encounter(starter)

        if is_target then
            pause_bot("Starter " .. (i + 1) .. " meets target specs!")
        end

        -- Scroll through each starter and log as they become visible
        if not config.hax and i < 2 then 
            press_sequence("Left", 30) 
        end
    end

    -- Soft reset otherwise
    press_button("Power")
    wait_frames(30)

    -- Wait a random number of frames before mashing A next reset
    -- to decrease the odds of hitting similar seeds
    local delay = math.random(1, 90)
    console.debug("Delaying " .. delay .. " frames...")
    wait_frames(delay)
end

function mode_voltorb_flip()
    local board_pointer = mdword(0x2111938) + 0x45FCC

    local function proceed_text()
        while mdword(board_pointer - 0x4) ~= 0xA0 or mdword(board_pointer - 0x14) ~= 0 do 
            press_sequence("A", 6) 
        end
    end

    local function flip_tile(x, y) touch_screen_at(x * 30 - 10, y * 30 - 10) end

    -- The game corner doesn't let you play while holding the maximum of 50k coins
    local coin_count = mword(board_pointer - 0x69BA8)
    if coin_count == 50000 then pause_bot("Can't earn any more coins") end

    proceed_text()

    local tile_index = 0

    -- Iterate through board and flip safe tiles
    for y = 1, 5, 1 do
        for x = 1, 5, 1 do
            local tile_offset = board_pointer + tile_index * 12
            local tile_type = mdword(tile_offset)
            local is_flipped = mdword(tile_offset + 8)

            if (tile_type == 2 or tile_type == 3) and is_flipped == 0 then -- a tile_type of 4 is Voltorb
                -- Tap tile until game registers the flip
                while is_flipped == 0 do
                    is_flipped = mdword(tile_offset + 8)

                    proceed_text()

                    flip_tile(x, y)
                    wait_frames(4)
                end

                press_button("A")
                wait_frames(8)
            end

            tile_index = tile_index + 1
        end
    end

    press_sequence("A", 9)
end

function mode_static_encounters()
    console.log("Waiting for battle to start...")
    
    while not foe and not game_state.in_battle do
        local delay = math.random(6, 21) -- Mimic imperfect human inputs
        press_sequence("A", delay)
    end

    foe_is_target = pokemon.log_encounter(foe[1])

    if not config.hax then
        -- Wait for Pokémon to fully appear on screen
        for i = 0, 22, 1 do press_sequence("A", 6) end
    end

    if foe_is_target then
        pause_bot("Wild Pokémon meets target specs!")
    else
        console.log("Wild " .. foe[1].name .. " was not a target, resetting...")
        press_button("Power")
        wait_frames(30)
    end

    -- Wait a random number of frames before mashing A next reset
    -- to decrease the odds of hitting similar seeds
    local delay = math.random(1, 90)
    console.debug("Delaying " .. delay .. " frames...")
    wait_frames(delay)
end
