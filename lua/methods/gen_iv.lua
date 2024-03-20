-----------------------
-- BASE GEN IV FUNCTIONS
-----------------------
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
        party_data = anchor + 0x12,

        foe_count = foe_anchor - 0x2B74,
        current_foe = foe_anchor - 0x2B70,

        map_header = anchor + 0x11B2,
        trainer_x = anchor + 0x11B8,
        trainer_z = anchor + 0x11BC,
        trainer_y = anchor + 0x11C0,
        facing = anchor + 0x247C6,

        selected_starter = anchor + 0x427A6,
        starters_ready = anchor + 0x4282A,

        battle_ally = anchor + 0x482E6,
        battle_foe = anchor + 0x483A6,

        battle_menu_state = anchor + 0x455A6,
        battle_indicator = 0x021A1B2A + _ROM.offset, -- mostly static
        fishing_bite_indicator = 0x21D5E16,
        battle_bag_page = bag_page_anchor + 0x4E,

        trainer_name = anchor - 0x22,
        trainer_id = anchor - 0x12
    }

    -- print(string.format("%08X", 0x22C367C - anchor))
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
    press_sequence("X", 30)

    -- SAVE button is at a different position before choosing starter
    if mword(pointers.map_header) == 0156 then -- No dex (not a perfect fix)
        while mbyte(0x021C4C86) ~= 04 do
            press_sequence("Up", 10)
        end
    else
        while mbyte(0x021C4C86) ~= 07 do
            press_sequence("Up", 10)
        end
    end

    press_sequence("A", 10)
    hold_button("B")
    wait_frames(100)
    release_button("B")
    press_button("A")
    wait_frames(30)
    hold_button("B")
    wait_frames(100)
    release_button("B")
    press_sequence("A", 5)

    while mbyte(pointers.save_indicator) == 0 do
        press_sequence("B", 12)
    end

    if _EMU == "BizHawk" then
        client.saveram() -- Flush save ram to the disk	
    end

    wait_frames(50)
end

function open_menu(menu)
    local option = {
        [1] = "Pokedex",
        [2] = "Pokemon",
        [4] = "Bag",
        [5] = "Trainer",
        [7] = "Save",
        [8] = "Options"
    }
    
    press_sequence(60, "X", 30)

    while mbyte(0x21CDF22) ~= option[menu] do
        press_button("Down", 5)
    end
    
    wait_frames(90)
end

function skip_nickname()
    while game_state.battle do
        touch_screen_at(125, 140)
        wait_frames(20)
    end
    wait_frames(150)
    save_game()
end

function find_usable_ball()
    -- Iterate bag pocket for Poke Balls
    local balls = {}
    local ball_count = 0
    local slot = 0

    for i = pointers.poke_balls_pocket, pointers.poke_balls_pocket + 0x3A, 4 do
        local count = mword(i + 2)
        
        if count > 0 then
            local id = mword(i)
            local item_name = _ITEM[id]

            balls[string.lower(item_name)] = slot
            ball_count = ball_count + count
        end

        slot = slot + 1
    end

    if ball_count == 0 then
        return -1
    end

    -- Compare with pokeball override
    if config.pokeball_override then
        for ball, _ in pairs(config.pokeball_override) do
            if pokemon.matches_ruleset(foe[1], config.pokeball_override[ball]) then
                local index = balls[string.lower(ball)]

                if index then
                    print_debug("Using " .. ball .. " from slot " .. ((index - 1) % 6) .. ", page " .. math.floor(index / 6))
                    return index
                end
            end
        end
    end

    -- If no override rules were matched, default to priority
    if config.pokeball_priority then
        for _, ball in ipairs(config.pokeball_priority) do
            local index = balls[string.lower(ball)]

            if index then
                print_debug("Using " .. ball .. " from slot " .. ((index - 1) % 6) .. ", page " .. math.floor(index / 6))
                return index
            end
        end
    end

    return -1
end

-----------------------
-- BATTLE BOT ACTIONS
-----------------------

function flee_battle()
    while game_state.battle do
        touch_screen_at(125, 175) -- Run
        wait_frames(5)
    end

    print("Got away safely!")
end

-----------------------
-- BOT ENCOUNTER MODES
-----------------------
-- Progress text efficiently while mimicing imperfect human inputs
-- to increase the randomness of the frames hit
function skip_dialogue()
    hold_button("A")
    wait_frames(math.random(5, 25))
    release_button("A")
    wait_frames(5)
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

        while not game_state.battle do
            press_sequence("Down", 3, "Left", 3, "Up", 3, "Right", 3)
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

        hold_button("B")

        if mbyte(pointers.facing) ~= start_face then
            press_sequence(dir2, 8)
        end

        while not game_state.battle do
            hold_button(dir1)
            wait_frames(7)
            hold_button(dir2)
            wait_frames(7)
        end

        release_button("B")
        release_button(dir2)
    end

    process_wild_encounter()

    if config.pickup then
        do_pickup()
    end
end

function read_string(input, pointer)
    local char_table = {"　", "ぁ", "あ", "ぃ", "い", "ぅ", "う", "ぇ", "え", "ぉ", "お", "か", "が",
                        "き", "ぎ", "く", "ぐ", "け", "げ", "こ", "ご", "さ", "ざ", "し", "じ", "す",
                        "ず", "せ", "ぜ", "そ", "ぞ", "た", "だ", "ち", "ぢ", "っ", "つ", "づ", "て",
                        "で", "と", "ど", "な", "に", "ぬ", "ね", "の", "は", "ば", "ぱ", "ひ", "び",
                        "ぴ", "ふ", "ぶ", "ぷ", "へ", "べ", "ぺ", "ほ", "ぼ", "ぽ", "ま", "み", "む",
                        "め", "も", "ゃ", "や", "ゅ", "ゆ", "ょ", "よ", "ら", "り", "る", "れ", "ろ",
                        "わ", "を", "ん", "ァ", "ア", "ィ", "イ", "ゥ", "ウ", "ェ", "エ", "ォ", "オ",
                        "カ", "ガ", "キ", "ギ", "ク", "グ", "ケ", "ゲ", "コ", "ゴ", "サ", "ザ", "シ",
                        "ジ", "ス", "ズ", "セ", "ゼ", "ソ", "ゾ", "タ", "ダ", "チ", "ヂ", "ッ", "ツ",
                        "ヅ", "テ", "デ", "ト", "ド", "ナ", "ニ", "ヌ", "ネ", "ノ", "ハ", "バ", "パ",
                        "ヒ", "ビ", "ピ", "フ", "ブ", "プ", "ヘ", "ベ", "ペ", "ホ", "ボ", "ポ", "マ",
                        "ミ", "ム", "メ", "モ", "ャ", "ヤ", "ュ", "ユ", "ョ", "ヨ", "ラ", "リ", "ル",
                        "レ", "ロ", "ワ", "ヲ", "ン", "０", "１", "２", "３", "４", "５", "６", "７",
                        "８", "９", "Ａ", "Ｂ", "Ｃ", "Ｄ", "Ｅ", "Ｆ", "Ｇ", "Ｈ", "Ｉ", "Ｊ", "Ｋ",
                        "Ｌ", "Ｍ", "Ｎ", "Ｏ", "Ｐ", "Ｑ", "Ｒ", "Ｓ", "Ｔ", "Ｕ", "Ｖ", "Ｗ", "Ｘ",
                        "Ｙ", "Ｚ", "ａ", "ｂ", "ｃ", "ｄ", "ｅ", "ｆ", "ｇ", "ｈ", "ｉ", "ｊ", "ｋ",
                        "ｌ", "ｍ", "ｎ", "ｏ", "ｐ", "ｑ", "ｒ", "ｓ", "ｔ", "ｕ", "ｖ", "ｗ", "ｘ",
                        "ｙ", "ｚ", "", "！", "？", "、", "。", "…", "・", "／", "「", "」", "『", "』",
                        "（", "）", "♂", "♀", "＋", "ー", "×", "÷", "＝", "～", "：", "；", "．", "，",
                        "♠", "♣", "♥", "♦", "★", "◎", "○", "□", "△", "◇", "＠", "♪", "％",
                        "☀", "☁", "☂", "☃", "😑", "☺", "☹", "😠", "⤴︎", "⤵︎", "💤", "円",
                        "💰", "🗝️", "💿", "✉️", "💊", "🍓", "◓", "💥", "←", "↑", "↓", "→",
                        "►", "＆", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F",
                        "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y",
                        "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r",
                        "s", "t", "u", "v", "w", "x", "y", "z", "À", "Á", "Â", "Ã", "Ä", "Å", "Æ", "Ç", "È",
                        "É", "Ê", "Ë", "Ì", "Í", "Î", "Ï", "Ð", "Ñ", "Ò", "Ó", "Ô", "Õ", "Ö", "×", "Ø",
                        "Ù", "Ú", "Û", "Ü", "Ý", "Þ", "ß", "à", "á", "â", "ã", "ä", "å", "æ", "ç", "è",
                        "é", "ê", "ë", "ì", "í", "î", "ï", "ð", "ñ", "ò", "ó", "ô", "õ", "ö", "÷", "ø",
                        "ù", "ú", "û", "ü", "ý", "þ", "ÿ", "Œ", "œ", "Ş", "ş", "ª", "º", "er", "re", "r",
                        "₽", "¡", "¿", "!", "?", ",", ".", "…", "･", "/", "‘", "’", "“", "”", "„",
                        "«", "»", "(", ")", "♂", "♀", "+", "-", "*", "#", "=", "&", "~", ":", ";", "♠", "♣",
                        "♥", "♦", "★", "◎", "○", "□", "△", "◇", "@", "♪", "%", "☀", "☁", "☂",
                        "☃", "😑", "☺", "☹", "😠", "⤴︎", "⤵︎", "💤", " ", "e", "PK", "MN", " ",
                        " ", " ", "", " ", " ", "°", "_", "＿", "․", "‥"}
    local bytes_to_string = function(start, finish, get_value)
        local text = ""

        for i = start, finish, 2 do
            local value = get_value(i)

            if value == 0xFFFF or value == 0x0000 then -- Null terminator
                break
            end

            text = text .. (char_table[value] or "?")
        end

        return text
    end

    if type(input) == "table" then
        -- Read data from a table of bytes
        return bytes_to_string(pointer + 1, #input, function(i)
            return input[i] + bit.lshift(input[i + 1], 8)
        end)
    else
        -- Read data from an address
        return bytes_to_string(input, input + 32, function (i)
            return mword(i)
        end)
    end
end

-- Thanks Poke J
-- https://projectpokemon.org/home/forums/topic/55238-structure-of-pok%C3%A9mon-in-ram-from-generation-4-games/
function get_battle_state()
    local read_mon = function(addr)
        -- Multipliers for base stats
        local mult = { 0.33, 0.36, 0.43, 0.5, 0.6, 0.75, 1.0, 1.33, 1.66, 2.0, 2.33, 2.66, 3.0}

        -- Stat modifiers (-6 to +6)
        local mod = {
            -- hp    = mbyte(addr + 0x18), -- unused, no effect
            attack    = mbyte(addr + 0x19),
            defense   = mbyte(addr + 0x1A),
            speed     = mbyte(addr + 0x1B),
            spAttack  = mbyte(addr + 0x1C),
            spDefense = mbyte(addr + 0x1D),
            -- accuracy  = mbyte(addr + 0x1E),
            -- evasion   = mbyte(addr + 0x1F),
        }

        local id = mword(addr)
        
        if id == 0 then
            return nil
        end
        
        return {
            species   = id,
            name      = _DEX[id + 1][1],
            type      = _DEX[id + 1][2],
            attack    = mword(addr + 0x2) * mult[mod.attack + 1],
            defense   = mword(addr + 0x4) * mult[mod.defense + 1],
            speed     = mword(addr + 0x6) * mult[mod.speed + 1],
            spAttack  = mword(addr + 0x8) * mult[mod.spAttack + 1],
            spDefense = mword(addr + 0xA) * mult[mod.spDefense + 1],
            moves = {
                _MOVE[mword(addr + 0xC) + 1],
                _MOVE[mword(addr + 0xE) + 1],
                _MOVE[mword(addr + 0x10) + 1],
                _MOVE[mword(addr + 0x12) + 1]
            },
            ability = _ABILITY[mbyte(addr + 0x27) + 1],
            pp = {
                mbyte(addr + 0x2C),
                mbyte(addr + 0x2D),
                mbyte(addr + 0x2E),
                mbyte(addr + 0x2F)
            },
            level = mbyte(addr + 0x34),
            -- happiness = mbyte(addr + 0x35),
            currentHP = mword(addr + 0x4C),
            maxHP = mword(addr + 0x50),
            hasStatusCondition = mbyte(addr + 0x6C) ~= 0
        }
    end

    local state = {
        ally = read_mon(pointers.battle_ally),
        foe = read_mon(pointers.battle_foe),
    }

    if not state.ally or not state.foe then
        return nil
    end

    return state
end