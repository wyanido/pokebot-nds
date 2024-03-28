-----------------------
-- DP FUNCTION OVERRIDES
-----------------------
function update_pointers()
    local anchor = mdword(0x21D4158 + _ROM.offset)
    local foe_anchor = mdword(anchor + 0x6930)

    pointers = {
        party_count = anchor - 0x23F44,
        party_data  = anchor - 0x23F40,
        
        foe_count   = foe_anchor + 0xC14,
        current_foe = foe_anchor + 0xC18,

        map_header  = anchor - 0x22DA4,
        trainer_x   = 0x21DA6F4,
        trainer_y   = 0x21DA6F8,
        trainer_z   = 0x21DA6FC,
        facing      = anchor + 0x1DC4,

        bike = anchor - 0x22D34,

        daycare_pid = anchor - 0x22804,

        battle_state_value     = anchor + 0x470D4, -- 01 is FIGHT menu, 04 is Move Select, 08 is Bag,
        battle_indicator       = 0x021E76D2, -- Static
        fishing_bite_indicator = 0x21DD853,

        easy_chat_open           = anchor + 0x28644,
        easy_chat_category_sizes = anchor + 0x200C4,
        easy_chat_word_list      = anchor + 0x20124,
        
        trainer_name = anchor - 0x23F74,
        trainer_id   = anchor - 0x23F64,

        starter_data = anchor + 0x1BC00
        -- registered_key_item_1 = anchor - 0x231FC,
    }
end

function save_game()
    print("Saving game...")
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
    print("Waiting to see starters...")

    while mdword(pointers.starter_data - 0x8) ~= 0 or mdword(pointers.starter_data - 0x4) == 0 do
        skip_dialogue()
    end

    if not config.hax then
        press_sequence(130, "A", 15)
    else
        wait_frames(9) -- Ensure all starters are loaded
    end

    -- Check all Pokémon
    for i = 0, 2, 1 do
        local mon_data = pokemon.decrypt_data(pointers.starter_data + i * _MON_BYTE_LENGTH)
        local starter = pokemon.parse_data(mon_data, true)
        local is_target = pokemon.log_encounter(starter)

        if is_target then
            abort("Starter " .. (i + 1) .. " meets target specs!")
        end

        -- Scroll through each starter and log as they become visible
        if not config.hax and i < 2 then 
            press_sequence("Left", 30) 
        end
    end

    -- Soft reset otherwise
    print("No starter were targets, resetting...")
    soft_reset()
end

function mode_voltorb_flip()
    local board_pointer = mdword(0x2111938) + 0x45FCC

    local function proceed_text()
        while mdword(board_pointer - 0x4) ~= 0xA0 or mdword(board_pointer - 0x14) ~= 0 do 
            skip_dialogue()
        end
    end

    local function flip_tile(x, y) touch_screen_at(x * 30 - 10, y * 30 - 10) end

    -- The game corner doesn't let you play while holding the maximum of 50k coins
    local coin_count = mword(board_pointer - 0x69BA8)
    if coin_count == 50000 then abort("Can't earn any more coins") end

    proceed_text()

    local tile_index = 0

    -- Iterate through board and flip safe tiles
    for y = 1, 5, 1 do
        for x = 1, 5, 1 do
            local tile_pointer = board_pointer + tile_index * 12
            local tile_type = mdword(tile_pointer)
            local is_flipped = mdword(tile_pointer + 8)

            if (tile_type == 2 or tile_type == 3) and is_flipped == 0 then -- a tile_type of 4 is Voltorb
                -- Tap tile until game registers the flip
                while is_flipped == 0 do
                    is_flipped = mdword(tile_pointer + 8)

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

        print_debug("Found word " .. target_word .. " in category " .. category_idx .. " (position " .. word_idx .. ")")

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

        print_debug("Scrolling " .. times_to_scroll .. " times and pressing index " .. page_location .. "(" .. word_location[2] .. ")")
        
        while times_to_scroll > 0 do
            touch_screen_at(240, 131)
            wait_frames(30)
            times_to_scroll = times_to_scroll - 1
        end
        
        touch_word(page_location)
    end

    local function input_easy_chat_phrase(word1, word2)
        -- Press A until Easy Chat prompt appears
        print('Awaiting Easy Chat prompt...')
        
        while mbyte(pointers.easy_chat_open) ~= 0x1 do
            skip_dialogue()
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

        print("Confirming input...")
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
        skip_dialogue()
    end

    local mon = party[#party]
    local is_target = pokemon.log_encounter(mon)

    if is_target then
        if config.save_game_after_catch then
            print("Gift Pokemon meets target specs! Saving...")

            if not config.hax then
                press_sequence("B", 120, "B", 120, "B", 60) -- Exit out of menu
            end

            save_game()
        end

        abort("Gift Pokemon meets target specs")
    else
        print("Gift Pokemon was not a target, resetting...")
        soft_reset()
        wait_frames(60)
    end
end

function mode_headbutt()
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
            skip_dialogue()
        end

        -- Wait for battle to start
        wait_frames(400)

        if game_state.in_battle then
            process_wild_encounter()
            wait_frames(90)
        else
            -- Headbut Trees in HGSS have a 100% encounter rate, so if
            -- nothing is encountered, this tree will never spawn anything
            abort("This tree doesn't yield any Pokémon!")
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

function release_hatched_duds()
    local release = function()
        press_sequence("A", 5, "Up", 5, "Up", 5, "A", 5, "Up", 5, "A", 120, "A", 60, "A", 10)
    end

    clear_all_inputs()
    
    -- Enter Daycare and release all Lv 1 Pokemon from party
    pathfind_to({z=411})
    pathfind_to({x=368})
    
    press_sequence("Up", 120) -- Enter door
    
    hold_button("B")
    pathfind_to({x=1,z=8})
    clear_all_inputs()

    -- Open PARTY PKMN menu
    wait_frames(20)
    press_sequence("A", 80, "A", 80, "A", 80, "A", 40)
    touch_screen_at(62, 94)
    wait_frames(120)
    touch_screen_at(46, 177)
    wait_frames(60)

    for i = 6, 2, -1 do
        local release = function(i)
            touch_screen_at(40 + 40 * ((i - 1) % 2), 70 + 30 * math.floor((i - 1) / 2))
        end

        release(i)
        wait_frames(30)
        touch_screen_at(228, 144)
        wait_frames(30)
        touch_screen_at(222, 109)
        wait_frames(100)
        press_button("B")
        wait_frames(15)
        press_button("B")
        wait_frames(15)
    end

    press_sequence("B", 40, "B", 20, "B", 150, "B", 60)

    -- Exit Daycare
    hold_button("B")
    pathfind_to({x=3})
    pathfind_to({z=12})
    wait_frames(60)
    clear_all_inputs()
    
    -- Return to long vertical path
    press_sequence(120, "Y", 5)
    pathfind_to({x=358})
end

function mode_daycare_eggs()
    local function mount_bike()
        if mbyte(pointers.bike) ~= 1 then 
            press_sequence("Y")
        end
    end
    
    local function check_and_collect_egg()
        -- Don't bother with additional eggs if party is full
        if #party == 6 or mdword(pointers.daycare_pid) == 0 then
            return
        end

        print("That's an egg!")

        pathfind_to({z=410}, check_hatching_eggs)
        pathfind_to({x=364}, check_hatching_eggs)
        clear_all_inputs()

        local party_count = #party
        while #party == party_count do
            press_sequence("A", 5)
        end

        -- Return to long vertical path 
        press_sequence(30, "B")
        pathfind_to({x=358}, check_hatching_eggs)
    end

    -- Initialise party state for future reference
    process_frame()
    party_eggs = get_party_eggs()

    mount_bike()
    pathfind_to({x=358})
    
    while true do
        pathfind_to({z=380}, check_hatching_eggs)
        check_and_collect_egg()
        pathfind_to({z=409}, check_hatching_eggs)
    end
end