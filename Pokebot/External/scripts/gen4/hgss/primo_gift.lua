-----------------------------------------------------------------------------
-- HGSS script for hunting gift Pokemon received from Primo in Violet City.
-- Author: wyanido
-----------------------------------------------------------------------------
hint_config_default("primo1", "0x0499")
hint_config_default("primo2", "0x058E")
hint_config_default("primo3", "0x05CF")
hint_config_default("primo4", "0x05CD")

function main()
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
        print('Awaiting Easy Chat prompt...')
        
        while mbyte(pointers.easy_chat_open) ~= 0x1 do
            progress_text()
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
        progress_text()
    end

    local mon = party[#party]
    local is_target = pokemon.is_target(mon)
    pokemon.log_encounter(mon)

    if is_target then
        abort(mon.Species.Name .. " is a target!")
    else
        print(mon.Species.Name .. " was not a target, resetting...")
        soft_reset()
        wait_frames(60)
    end
end
