-----------------------
-- DP FUNCTION OVERRIDES
-----------------------
function update_pointers()
    local mem_shift = mdword(0x21D4158)
    -- Static Pokemon data is inconsistent between locations & resets,
    -- so find the current offset using a relative value
    local foe_offset = mdword(mem_shift + 0x6930)

    pointers = {
        party_count = mem_shift - 0x23F44,
        party_data  = mem_shift - 0x23F40,
        
        foe_count   = foe_offset + 0xC14,
        current_foe = foe_offset + 0xC18,

        map_header  = mem_shift - 0x22DA4,
        trainer_x   = mem_shift - 0x22D9E,
        trainer_z   = mem_shift - 0x22D9A,
        trainer_y   = mem_shift - 0x22D96,
        facing      = mem_shift + 0x25E88,

        battle_state_value = mem_shift + 0x470D4, -- 01 is FIGHT menu, 04 is Move Select, 08 is Bag,
        battle_indicator   = 0x021E76D2, -- Static

        easy_chat_open           = mem_shift + 0x28644,
        easy_chat_category_sizes = mem_shift + 0x200C4,
        easy_chat_word_list      = mem_shift + 0x20124,
    }
end

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

function mode_primo_gift()
    -- Finds the location of a phrase ID within the Easy Chat menu
    local function find_word(target_word)
        local word = tonumber(target_word)
        local addr = pointers.easy_chat_word_list
        local seek = 0x0
        while mword(addr + seek) ~= word and seek < 0xFFFF do
            seek = seek + 0x2
        end

        local category_idx = 0
        local word_idx = seek / 2
        while word_idx >= 0 do
            local category_count = mdword(pointers.easy_chat_category_sizes + category_idx * 4)
            local new_idx = word_idx - category_count
            
            if new_idx >= 0 then
                category_idx = category_idx + 1
                word_idx = new_idx
            else
                break
            end
        end

        console.debug("Found word " .. target_word .. " in category " .. category_idx .. " (position " .. word_idx .. ")")

        return { category_idx, word_idx }
    end

    local function touch_category(index)
        local x = index % 3
        local y = math.floor(index / 3)

        touch_screen_at(50 + x * 75, 64 + y * 20)
    end

    local function touch_word(index)
        local x = index % 2
        local y = math.floor(index / 2)

        touch_screen_at(65 + x * 110, 55 + y * 25)
    end

    -- RAM locations: word 1, 0x22C02A0  word 2, 0x22C02A2
    local function input_word(word)
        local word_location = find_word(word)

        touch_category(word_location[1])
        wait_frames(30)

        local category_count = mdword(pointers.easy_chat_category_sizes + word_location[1] * 4)
        local page_location = word_location[2]
        
        if category_count - 10 < word_location[2] then  
            -- The final page does not scroll fully if the list ends before a multiple of 10,
            -- scroll by rows until the end is reached
            while page_location > 9 do
                page_location = page_location - 2 -- Look down 1 row at a time
            end
        else
            -- Not at the final page, scroll whole pages
            page_location = page_location % 10
        end

        local times_to_scroll = math.ceil((word_location[2] - page_location) / 10)

        console.debug("Scrolling " .. times_to_scroll .. " times and pressing index " .. page_location .. "(" .. word_location[2] .. ")")
        
        while times_to_scroll > 0 do
            touch_screen_at(240, 131)
            wait_frames(30)
            times_to_scroll = times_to_scroll - 1
        end
        
        touch_word(page_location)
    end

    local function input_easy_chat_phrase(word1, word2)
        -- Press A until Easy Chat prompt appears
        console.log('Awaiting Easy Chat prompt...')
        
        while mbyte(pointers.easy_chat_open) ~= 0x1 do
            press_sequence("A", math.random(5, 30))
        end
        
        wait_frames(45)

        touch_screen_at(65, 25) -- Select 1st input box
        wait_frames(30)

        input_word(word1)
        wait_frames(60)
        touch_screen_at(182, 25) -- Select 2nd input box
        wait_frames(30)

        input_word(word2)
        wait_frames(60)

        console.log("Confirming input...")
        touch_screen_at(218, 118) -- CONFIRM
        wait_frames(15)
        touch_screen_at(218, 118) -- YES
        wait_frames(60)
    end

    input_easy_chat_phrase(config.primo1, config.primo2)
    input_easy_chat_phrase(config.primo3, config.primo4)

    -- Now button mash until the egg is received
    local og_party_count = #party
    while #party == og_party_count do
        press_sequence("A", 5)
    end

    local mon = party[#party]
    local was_target = pokemon.log_encounter(mon)

    if was_target then
        if config.save_game_after_catch then
            console.log("Gift Pokemon meets target specs! Saving...")

            if not config.hax then
                press_sequence("B", 120, "B", 120, "B", 60) -- Exit out of menu
            end

            save_game()
        end

        pause_bot("Gift Pokemon meets target specs")
    else
        console.log("Gift Pokemon was not a target, resetting...")
        press_button("Power")
        wait_frames(60)
    end
end
