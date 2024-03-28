function update_pointers()
    local anchor = mdword(0x21C489C + _ROM.offset)
    local foe_anchor = mdword(anchor + 0x226FE)
    local bag_page_anchor = mdword(anchor + 0x560EE)

    pointers = {
        items_pocket      = anchor + 0x59E,
        key_items_pocket  = anchor + 0x832,
        tms_hms_pocket    = anchor + 0x8FA,
        medicine_pocket   = anchor + 0xABA,
        berries_pocket    = anchor + 0xB5A,
        poke_balls_pocket = anchor + 0xC5A,
        
        party_count = anchor + 0xE,
        party_data  = anchor + 0x12,

        foe_count   = foe_anchor - 0x2B74,
        current_foe = foe_anchor - 0x2B70,

        map_header  = anchor + 0x11B2,
        menu_option = 0x21CDF22,
        trainer_x   = 0x21CEF70,
        trainer_y   = 0x21CEF74,
        trainer_z   = 0x21CEF78,
        facing      = anchor + 0x247C6,

        bike_gear = anchor + 0x123E,
        bike      = anchor + 0x1242,

        daycare_pid = anchor + 0x156E,

        selected_starter = anchor + 0x427A6,
        starters_ready   = anchor + 0x4282A,
        
        battle_bag_page        = bag_page_anchor + 0x4E,
        battle_menu_state      = anchor + 0x455A6,
        battle_indicator       = 0x21A1B2A + _ROM.offset, -- mostly static
        fishing_bite_indicator = 0x21D5E16,

        trainer_name = anchor - 0x22,
        trainer_id   = anchor - 0x12
    }
end

-----------------------
-- MISC. BOT ACTIONS
-----------------------
-- Wait a random delay after SRing to decrease the odds of hitting similar seeds on loading save
function randomise_reset()
    wait_frames(200) -- Impassable white screen

    local delay = math.random(100, 500)

    print_debug("Delaying " .. delay .. " frames...")
    wait_frames(delay)
end

function save_game()
    print("Saving game...")
    
    open_menu("Save")
    press_sequence("A", 120, "A", 800)

    if _EMU == "BizHawk" then
        client.saveram()
    end

    press_sequence("B", 10)
end

function open_menu(menu)
    local option = {
        Pokedex = 1,
        Pokemon = 2,
        Bag = 4,
        Trainer = 5,
        Save = 7,
        Options = 8
    }

    press_sequence(60, "X", 30)

    while mbyte(pointers.menu_option) ~= option[menu] do
        press_sequence("Down", 8)
    end

    press_sequence("A", 90)
end

-- Progress text efficiently while mimicing imperfect human inputs
-- to increase the randomness of the frames hit
function skip_dialogue()
    hold_button("A")
    wait_frames(math.random(5, 25))
    release_button("A")
    wait_frames(5)
end

function use_move_at_slot(slot)
    -- Skip text to FIGHT menu
    while pointers.battle_state_value == 14 do
        press_sequence(12, "A")
    end

    wait_frames(60)
    touch_screen_at(128, 90) -- FIGHT
    wait_frames(30)

    local xpos = 80 * (((slot - 1) % 2) + 1)
    local ypos = 50 * (math.floor((slot - 1) / 2) + 1)
    touch_screen_at(xpos, ypos) -- Select move slot

    wait_frames(60)
end

function flee_battle()
    while game_state.in_battle do
        touch_screen_at(125, 175) -- Run
        wait_frames(5)
    end

    print("Got away safely!")
end

function get_usable_balls()
    -- Iterate bag pocket for Poke Balls
    local balls = {}
    local slot = 0

    for i = pointers.poke_balls_pocket, pointers.poke_balls_pocket + 0x3A, 4 do
        local count = mword(i + 2)

        if count > 0 then
            local id = mword(i)
            local item_name = _ITEM[id + 1]

            balls[string.lower(item_name)] = slot + 1
        end

        slot = slot + 1
    end

    return balls
end

function fishing_status_changed()
    return mbyte(pointers.fishing_bite_indicator) ~= 0
end

function fishing_has_bite()
    return mbyte(pointers.fishing_bite_indicator) == 1
end

function pathfind_to(target, on_step)
    if not target.x then
        target.x = game_state.trainer_x - 0.5
    elseif not target.z then
        target.z = game_state.trainer_z - 0.5
    end

    while game_state.trainer_x <= target.x - 0.5 do
        hold_button("Right")
        if on_step then on_step() end
    end
    
    while game_state.trainer_x >= target.x + 1.5 do
        hold_button("Left")
        if on_step then on_step() end
    end
    
    while game_state.trainer_z < target.z - 0.5 do
        hold_button("Down")
        if on_step then on_step() end
    end
    
    while game_state.trainer_z > target.z + 1.5 do
        hold_button("Up")
        if on_step then on_step() end
    end
end

function get_party_eggs()
    local eggs = {}

    for i = 1, 6, 1 do
        if party[i] then
            eggs[i] = party[i].isEgg == 1
        else
            eggs[i] = true
        end
    end

    return eggs
end

function release_hatched_duds()
    local release = function()
        press_sequence("A", 5, "Up", 5, "Up", 5, "A", 5, "Up", 5, "A", 120, "A", 60, "A", 10)
    end

    clear_all_inputs()

    -- Enter Daycare and release all Lv 1 Pokemon from party
    pathfind_to({z=646 + map_shift})
    pathfind_to({x=553})
    
    press_sequence("Up", 120) -- Enter door
    
    hold_button("B")
    pathfind_to({z=8 + indoor_map_shift})
    pathfind_to({x=4})
    pathfind_to({z=4 + indoor_map_shift})
    clear_all_inputs()

    -- Navigate to MOVE POKEMON
    wait_frames(5)
    press_sequence("A", 90, "A", 60, "A", 60, "A", 20, "Down", 10, "Down", 10, "A", 120)

    -- Navigate to PARTY POKEMON
    press_sequence("Up", 20, "Up", 20, "A", 60)
    press_sequence("Up", 20, "Up", 20)

    -- Release Lv 1 Pokemon from back to front
    -- to accomodate for positions shifting
    release() -- 6
    press_sequence("Left", 10)
    release() -- 5
    press_sequence("Up", 10, "Right", 10)
    release() -- 4
    press_sequence("Left", 10)
    release() -- 3
    press_sequence("Up", 10, "Right", 10)
    release() -- 2

    -- Close PC
    press_sequence("B", 60, "B", 20, "B", 160, "B", 60, "B", 20)

    -- Exit Daycare
    hold_button("B")
    pathfind_to({z=8 + indoor_map_shift})
    pathfind_to({x=9})
    pathfind_to({z=11 + indoor_map_shift})
    wait_frames(60)
    clear_all_inputs()
    
    -- Return to long vertical path
    press_sequence(110, "Y")
    pathfind_to({x=562})
end

function check_hatching_eggs()
    press_button("A")
    
    local new_eggs = get_party_eggs()
    
    for i, is_egg in ipairs(new_eggs) do
        -- Eggs are already considered "hatched" as soon as the animation starts
        if party[i] and party_eggs[i] ~= is_egg then
            clear_all_inputs()
            
            print("Egg is hatching!")
            press_sequence(30, "B", 30)
            
            -- Mon data changes again once animation finishes
            local checksum = party[i].checksum
            while party[i].checksum == checksum do
                press_sequence("B", 5)
            end
            
            local is_target = pokemon.log_encounter(party[i])
            if is_target then
                abort("Hatched a target Pokemon!")
            else
                print("Hatched " .. party[i].name .. " was not a target...")
            end
            
            wait_frames(90)
            break
        end
    end

    party_eggs = new_eggs
    
    -- Check party to see if it's clear of eggs
    if #party == 6 then
        local has_egg = false
        
        for _, is_egg in ipairs(new_eggs) do
            if is_egg then
                has_egg = true
                break
            end
        end

        -- If no eggs are left and no target was found,
        -- we can release all Level 1 Pokemon from party
        if not has_egg then
            print("Party has no room for eggs! Releasing last 5 Pokemon...")
            release_hatched_duds()
        end
    end
end

function read_string(input, pointer)
    local char_table = {
        "　", "ぁ", "あ", "ぃ", "い", "ぅ", "う", "ぇ", "え", "ぉ", "お", "か", "が", "き", "ぎ",
        "く", "ぐ", "け", "げ", "こ", "ご", "さ", "ざ", "し", "じ", "す", "ず", "せ", "ぜ", "そ", "ぞ",
        "た", "だ", "ち", "ぢ", "っ", "つ", "づ", "て", "で", "と", "ど", "な", "に", "ぬ", "ね", "の",
        "は", "ば", "ぱ", "ひ", "び", "ぴ", "ふ", "ぶ", "ぷ", "へ", "べ", "ぺ", "ほ", "ぼ", "ぽ", "ま",
        "み", "む", "め", "も", "ゃ", "や", "ゅ", "ゆ", "ょ", "よ", "ら", "り", "る", "れ", "ろ", "わ",
        "を", "ん", "ァ", "ア", "ィ", "イ", "ゥ", "ウ", "ェ", "エ", "ォ", "オ", "カ", "ガ", "キ", "ギ",
        "ク", "グ", "ケ", "ゲ", "コ", "ゴ", "サ", "ザ", "シ", "ジ", "ス", "ズ", "セ", "ゼ", "ソ", "ゾ",
        "タ", "ダ", "チ", "ヂ", "ッ", "ツ", "ヅ", "テ", "デ", "ト", "ド", "ナ", "ニ", "ヌ", "ネ", "ノ",
        "ハ", "バ", "パ", "ヒ", "ビ", "ピ", "フ", "ブ", "プ", "ヘ", "ベ", "ペ", "ホ", "ボ", "ポ", "マ",
        "ミ", "ム", "メ", "モ", "ャ", "ヤ", "ュ", "ユ", "ョ", "ヨ", "ラ", "リ", "ル", "レ", "ロ", "ワ",
        "ヲ", "ン", "０", "１", "２", "３", "４", "５", "６", "７", "８", "９", "Ａ", "Ｂ", "Ｃ", "Ｄ",
        "Ｅ", "Ｆ", "Ｇ", "Ｈ", "Ｉ", "Ｊ", "Ｋ", "Ｌ", "Ｍ", "Ｎ", "Ｏ", "Ｐ", "Ｑ", "Ｒ", "Ｓ", "Ｔ",
        "Ｕ", "Ｖ", "Ｗ", "Ｘ", "Ｙ", "Ｚ", "ａ", "ｂ", "ｃ", "ｄ", "ｅ", "ｆ", "ｇ", "ｈ", "ｉ", "ｊ",
        "ｋ", "ｌ", "ｍ", "ｎ", "ｏ", "ｐ", "ｑ", "ｒ", "ｓ", "ｔ", "ｕ", "ｖ", "ｗ", "ｘ", "ｙ", "ｚ",
        "",   "！", "？", "、", "。", "…", "・", "／", "「", "」", "『", "』", "（", "）", "♂", "♀",
        "＋", "ー", "×", "÷", "＝", "～", "：", "；", "．", "，", "♠", "♣", "♥", "♦", "★", "◎",
        "○", "□", "△", "◇", "＠", "♪", "％", "☀", "☁", "☂", "☃", "😑", "☺", "☹", "😠", "⤴︎",
        "⤵︎", "💤", "円", "💰", "🗝️", "💿", "✉️", "💊", "🍓", "◓", "💥", "←", "↑", "↓", "→", "►",
        "＆", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E",
        "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U",
        "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k",
        "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "À",
        "Á", "Â", "Ã", "Ä", "Å", "Æ", "Ç", "È", "É", "Ê", "Ë", "Ì", "Í", "Î", "Ï", "Ð",
        "Ñ", "Ò", "Ó", "Ô", "Õ", "Ö", "×", "Ø", "Ù", "Ú", "Û", "Ü", "Ý", "Þ", "ß", "à",
        "á", "â", "ã", "ä", "å", "æ", "ç", "è", "é", "ê", "ë", "ì", "í", "î", "ï", "ð",
        "ñ", "ò", "ó", "ô", "õ", "ö", "÷", "ø", "ù", "ú", "û", "ü", "ý", "þ", "ÿ", "Œ",
        "œ", "Ş", "ş", "ª", "º", "er", "re", "r", "₽", "¡", "¿", "!", "?", ",", ".", "…",
        "･", "/", "‘", "’", "“", "”", "„", "«", "»", "(", ")", "♂", "♀", "+", "-", "*",
        "#", "=", "&", "~", ":", ";", "♠", "♣", "♥", "♦", "★", "◎", "○", "□", "△", "◇",
        "@", "♪", "%", "☀", "☁", "☂", "☃", "😑", "☺", "☹", "😠", "⤴︎", "⤵︎", "💤", " ", "e",
        "PK", "MN", " ", " ", " ", "", " ", " ", "°", "_", "＿", "․", "‥",
    }
    local text = ""

    if type(input) == "table" then
        -- Read data from an inputted table of bytes
        for i = pointer + 1, #input, 2 do
            local value = input[i] + bit.lshift(input[i + 1], 8)

            if value == 0xFFFF or value == 0x0000 then -- Null terminator
                break
            end

            text = text .. (char_table[value] or "?")
        end
    else
        -- Read data from an inputted address
        for i = input, input + 32, 2 do
            local value = mword(i)

            if value == 0xFFFF or value == 0x0000 then -- Null terminator
                break
            end

            text = text .. (char_table[value] or "?")
        end
    end

    return text
end

-----------------------
-- BOT ENCOUNTER MODES
-----------------------
function mode_static_encounters()
    print("Waiting for battle to start...")

    while not game_state.in_battle do
        if game_state.map_name == "Spear Pillar" then
            hold_button("Up")
        end

        skip_dialogue()
    end

    release_button("Up")

    local is_target = pokemon.log_encounter(foe[1])

    if not config.hax then
        -- Wait for Pokémon to fully appear on screen
        for i = 0, 22, 1 do 
            skip_dialogue()
        end
    end

    if is_target then
        abort("Wild Pokémon meets target specs!")
    else
        print("Wild " .. foe[1].name .. " was not a target, resetting...")
        soft_reset()
    end
end

function mode_starters()
    cycle_starter_choice()
    
    -- Diamond and Pearl need to skip through a cutscene before the briefcase
    local platinum = _ROM.version == "PL"

    if not platinum then 
        hold_button("Up")

        while game_state.map_name ~= "Lake Verity" do
            skip_dialogue()
        end
        
        release_button("Up")
    end
    
    print("Waiting to open briefcase...")
    
    -- Skip until starter selection is available
    local ready_value = platinum and 0x4D or 0x75

    while mbyte(pointers.starters_ready) ~= ready_value do
        skip_dialogue()
    end

    print("Selecting starter...")

    while mbyte(pointers.selected_starter) < starter do
        press_sequence("Right", 5)
    end

    -- Wait until starter is added to party
    while #party == 0 do
        skip_dialogue()
    end

    if not config.hax then
        print("Waiting until starter is visible...")

        for i = 0, 86, 1 do
            skip_dialogue()
        end
    end

    -- Log encounter, stopping if necessary
    local is_target = pokemon.log_encounter(party[1])

    if is_target then
        abort("Starter meets target specs!")
    else
        print("Starter was not a target, resetting...")
        soft_reset()
    end
end

function mode_random_encounters()
    print("Attempting to start a battle...")
    wait_frames(30)

    if config.move_direction == "spin" then
        -- Prevent accidentally taking a step by
        -- preventing a down input while facing down
        if mbyte(pointers.facing) == 1 then
            press_sequence("Right", 3)
        end
        
        while not game_state.in_battle do
            press_sequence(
                "Down", 3,
                "Left", 3,
                "Up", 3,
                "Right", 3
            )
        end
    else
        local dir1, dir2, start_face
        
        if config.move_direction == "horizontal" then
            dir1 = "Left"
            dir2 = "Right"
            start_face = 2
        else
            dir1 = "Up"
            dir2 = "Down"
            start_face = 0
        end

        if mbyte(pointers.facing) ~= start_face then
            press_sequence(dir2, 8)
        end

        hold_button("B")
        
        while not game_state.in_battle do
            hold_button(dir1)
            wait_frames(7)
            hold_button(dir2)
            wait_frames(7)
        end

        release_button("B")
    end

    process_wild_encounter()
end

function mode_gift()
    if not game_state.in_game then
        print("Waiting to reach overworld...")

        while not game_state.in_game do
            skip_dialogue()
        end
    end

    local og_party_count = #party
    while #party == og_party_count do
        skip_dialogue()
    end
    
    if not config.hax then
        press_sequence(180, "B", 60) -- Decline nickname
        
        -- Party menu
        press_sequence("X", 30)
        touch_screen_at(65, 45)
        wait_frames(90)

        touch_screen_at(80 * ((#party - 1) % 2 + 1), 30 + 50 * math.floor((#party - 1) / 2)) -- Select gift mon
        wait_frames(30)

        touch_screen_at(200, 105) -- SUMMARY
        wait_frames(120)
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
    end
end

function mode_daycare_eggs()
    local function mount_bike()
        if mbyte(pointers.bike) ~= 1 then press_sequence("Y", 5) end
        if mbyte(pointers.bike_gear) ~= 1 then press_button("B") end
    end
    
    local function check_and_collect_egg()
        -- Don't bother with additional eggs if party is full
        if #party == 6 or mdword(pointers.daycare_pid) == 0 then
            return
        end

        print("That's an egg!")

        pathfind_to({z=648 + map_shift})
        pathfind_to({x=556})
        clear_all_inputs()

        local party_count = #party
        while #party == party_count do
            press_sequence("A", 5)
        end

        -- Return to long vertical path 
        pathfind_to({x=562})
    end

    -- Initialise party state for future reference
    process_frame()
    party_eggs = get_party_eggs()

    -- Map coords shift slightly between DP and Pt
    map_shift = _ROM.version == "PL" and 22 or 0
    indoor_map_shift = _ROM.version == "PL" and 63 or 0

    mount_bike()
    pathfind_to({x=562})
    
    while true do
        pathfind_to({z=630 + map_shift}, check_hatching_eggs)
        check_and_collect_egg()
        pathfind_to({z=675 + map_shift}, check_hatching_eggs)
        check_and_collect_egg()
    end
end
