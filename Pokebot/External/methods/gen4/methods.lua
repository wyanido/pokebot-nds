-----------------------------------------------------------------------------
-- General bot methods for gen 4 games (DPPt, HGSS)
-- Author: wyanido, storyzealot
-- Homepage: https://github.com/wyanido/pokebot-nds
-----------------------------------------------------------------------------

_MON_BYTE_LENGTH = 236

function update_pointers()
    local anchor = mdword(0x21C489C + _ROM.offset)
    local foe_anchor = mdword(anchor + 0x226FE)
    local bag_page_anchor = mdword(anchor + 0x560EE)
    local roamer_anchor = mdword(anchor + 0x4272A)

    pointers = {
        start_value = 0x21066D4, -- 0 until save has been loaded
        -- items_pocket      = anchor + 0x59E,
        -- key_items_pocket  = anchor + 0x832,
        -- tms_hms_pocket    = anchor + 0x8FA,
        -- medicine_pocket   = anchor + 0xABA,
        -- berries_pocket    = anchor + 0xB5A,
        poke_balls_pocket = anchor + 0xC5A,
        
        party_count = anchor + 0xE,
        party_data  = anchor + 0x12,

        foe_count   = foe_anchor - 0x2B74,
        current_foe = foe_anchor - 0x2B70,

        map_header  = anchor + 0x11B2,
        menu_option = 0x21CDF22 + _ROM.offset,
        trainer_x   = 0x21CEF70 + _ROM.offset,
        trainer_y   = 0x21CEF74 + _ROM.offset,
        trainer_z   = 0x21CEF78 + _ROM.offset,
        facing      = anchor + 0x247C6,

        bike_gear = anchor + 0x123E,
        bike      = anchor + 0x1242,

        daycare_egg = anchor + 0x156E,

        selected_starter = anchor + 0x427A6,
        starters_ready   = anchor + 0x4282A,
        
        battle_bag_page        = bag_page_anchor + 0x4E,
        battle_menu_state      = anchor + 0x455A6,
        battle_menu_state2     = anchor - 0xD3FC,
        battle_indicator       = 0x21A1B2A + _ROM.offset,
        fishing_bite_indicator = 0x21D5E16 + _ROM.offset,

        trainer_name = anchor - 0x22,
        trainer_id   = anchor - 0x12,

        save_indicator = 0x21C491F + _ROM.offset,
        
        roamer = roamer_anchor + 0x20,
    }
end

--- Waits a random duration after a reset to decrease the odds of hitting duplicate seeds
function randomise_reset()
    wait_frames(200) -- White screen on startup

    local delay = math.random(100, 500)

    console.debug("Delaying " .. delay .. " frames...")
    wait_frames(delay)

    while not game.save_file_loaded() do
        press_sequence("Start", 20, "A", math.random(8, 28))
    end
end

--- Opens the menu and selects the specified option
-- @param menu Name of the menu to open
function open_menu(menu)
    local option = {
        Pokedex = 1,
        Pokemon = 2,
        Bag = 4,
        Trainer = 5,
        Save = 7,
        Options = 8,
        Exit = 10
    }

    press_sequence("X", 8)
    
    -- Scroll up or down based on which navigation is shorter (doesn't acknowledge that the menu wraps around)
    local direction = option[menu] > mbyte(pointers.menu_option) and "Down" or "Up"
    while mbyte(pointers.menu_option) ~= option[menu] do
        press_sequence(direction, 8)
    end

    press_sequence("A", 90)
end

--- Returns an array of all Poke Balls within the Poke Balls bag pocket
function get_usable_balls()
    local balls = {}
    local slot = 0

    for i = pointers.poke_balls_pocket, pointers.poke_balls_pocket + 0x3A, 4 do
        local count = mword(i + 2)

        if count > 0 then
            local id = mword(i)
            local item_name = game.item_name(id)

            balls[string.lower(item_name)] = slot + 1
        end

        slot = slot + 1
    end

    return balls
end

--- Returns true if the rod state has changed from being cast
function fishing_status_changed()
    return mbyte(pointers.fishing_bite_indicator) ~= 0
end

--- Returns true if a Pokemon is on the hook
function fishing_has_bite()
    return mbyte(pointers.fishing_bite_indicator) == 1
end

--- Navigates to the Solaceon Town daycare and releases all hatched Pokemon in the party
function release_hatched_duds()
    local function release()
        press_sequence("A", 5, "Up", 5, "Up", 5, "A", 5, "Up", 5, "A", 120, "A", 60, "A", 10)
    end

    clear_all_inputs()

    move_to({z=646})
    move_to({x=553})
    
    -- Enter door
    hold_button("Up")
    wait_frames(60)
    release_button("Up")
    wait_frames(120)
    
    hold_button("B")
    move_to({z=8})
    move_to({x=4})
    move_to({z=4})
    clear_all_inputs()

    -- Navigate to MOVE POKEMON
    wait_frames(5)
    press_sequence("A", 90, "A", 60, "A", 60, "A", 20, "Down", 10, "Down", 10, "A", 150)

    -- Navigate to PARTY POKEMON
    press_sequence("Up", 20, "Up", 20, "A", 60)
    press_sequence("Up", 20, "Up", 20)

    -- Release Lv 1 Pokemon from back to front to accomodate for positions shifting
    if pokemon.is_hatched_dud(game.party()[5]) then release() end
    press_sequence("Left", 10)
    if pokemon.is_hatched_dud(game.party()[4]) then release() end
    press_sequence("Up", 10, "Right", 10)
    if pokemon.is_hatched_dud(game.party()[3]) then release() end
    press_sequence("Left", 10)
    if pokemon.is_hatched_dud(game.party()[2]) then release() end
    press_sequence("Up", 10, "Right", 10)
    if pokemon.is_hatched_dud(game.party()[1]) then release() end

    -- Close PC
    press_sequence("B", 60, "B", 20, "B", 160, "B", 60, "B", 20)

    -- Exit Daycare
    hold_button("B")
    move_to({z=8})
    move_to({x=9})
    move_to({z=11})
    wait_frames(60)
    clear_all_inputs()
    
    -- Return to long vertical path
    press_sequence(110, "Y")
    move_to({x=562})
end

--- Proceeds until the egg hatch animation finishes
function hatch_egg(slot)
    press_sequence(30, "B", 30)
            
    -- Mon data changes again once animation finishes
    local checksum = game.party()[slot].checksum

    while game.party()[slot].checksum == checksum do
        press_sequence("B", 5)
    end
end

--- Converts bytes into readable text using the game's respective encoding method.
-- @param input Table of bytes or memory address to read from
-- @param pointer Offset into the byte table if provided
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

--- Returns the current stage of the battle as a simple string
function get_battle_state()
    if not game.in_battle() then
        return nil
    end

    if mbyte(pointers.battle_menu_state2) == 0x2F then
        return "New Move"
    end
    
    local state = mbyte(pointers.battle_menu_state)

    if state == 0x1 then
        return "Menu"
    elseif state == 0x3 then
        return "Fight"
    elseif state == 0x7 then
        return "Bag"
    elseif state == 0x9 then
        return "Pokemon"
    end

    return nil
end
