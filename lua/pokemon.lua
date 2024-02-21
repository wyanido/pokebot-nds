local pokemon = {}

-- Interprets a region of RAM as Pokemon data and decrypts it as such
function pokemon.decrypt_data(address)
    local rand = function(old_seed)
        local new_seed = (0x41C64E6D * old_seed) + 0x6073
        seed = new_seed
        return seed
    end

    local decrypt_block = function(start, finish)
        local data = {}

        for i = start, finish, 0x2 do
            local word = mword(address + i)
            local decrypted = word ~ (rand(seed) >> 16)
            local end_word = decrypted & 0xFFFF

            table.insert(data, end_word & 0xFF)
            table.insert(data, (end_word >> 8) & 0xFF)
        end

        return data
    end

    local verify_checksums = function(checksum)
        local sum = 0

        for i = 0x09, 0x88, 2 do
            sum = sum + data[i] + (data[i + 1] << 8)
        end

        sum = sum & 0xFFFF

        return sum == checksum
    end

    local concat_table = function(dest, source)
        table.move(source, 1, #source, #dest + 1, dest)
    end
    
    local substruct = {
        [0] = {1, 2, 3, 4},
        [1] = {1, 2, 4, 3},
        [2] = {1, 3, 2, 4},
        [3] = {1, 4, 2, 3},
        [4] = {1, 3, 4, 2},
        [5] = {1, 4, 3, 2},
        [6] = {2, 1, 3, 4},
        [7] = {2, 1, 4, 3},
        [8] = {3, 1, 2, 4},
        [9] = {4, 1, 2, 3},
        [10] = {3, 1, 4, 2},
        [11] = {4, 1, 3, 2},
        [12] = {2, 3, 1, 4},
        [13] = {2, 4, 1, 3},
        [14] = {3, 2, 1, 4},
        [15] = {4, 2, 1, 3},
        [16] = {3, 4, 1, 2},
        [17] = {4, 3, 1, 2},
        [18] = {2, 3, 4, 1},
        [19] = {2, 4, 3, 1},
        [20] = {3, 2, 4, 1},
        [21] = {4, 2, 3, 1},
        [22] = {3, 4, 2, 1},
        [23] = {4, 3, 2, 1}
    }

    data = {} 
    concat_table(data, memory.read_bytes_as_array(address, 0x4))
    concat_table(data, {0x0, 0x0})
    concat_table(data, memory.read_bytes_as_array(address + 0x06, 0x2))

    -- Unencrypted bytes
    local pid = mdword(address)
    local checksum = mword(address + 0x06)
    
    -- Find intended order of the shuffled data blocks
    local shift = ((pid & 0x3E000) >> 0xD) % 24
    local block_order = substruct[shift]

    -- Decrypt blocks A,B,C,D and rearrange according to the order
    seed = checksum

    local _block = {}
    for index = 1, 4 do
        local block = (index - 1) * 0x20
        _block[index] = decrypt_block(0x08 + block, 0x27 + block)
    end

    for _, index in ipairs(block_order) do
        concat_table(data, _block[index])
    end

    -- Re-calculate the checksum of the blocks and match it with mon.checksum
    -- If the checksum fails, assume it's the data is garbage or still being written
    if not verify_checksums(checksum) then
        return nil
    end

    -- Party-only status data
    seed = pid
    concat_table(data, decrypt_block(0x88, 0xDB))

    if _ROM.gen == 4 then -- Write blank ball seal data
        for i = 0x1, 0x10 do
            table.insert(data, 0x0)
        end
    end

    return data
end

local mon_ability = json.load("lua/data/abilities.json")
local mon_item = json.load("lua/data/items.json")
local mon_move = json.load("lua/data/moves.json")
local mon_type = json.load("lua/data/type_matchups.json")
local mon_dex = json.load("lua/data/dex.json")
local mon_lang = {"none", "日本語", "English", "Français", "Italiano", "Deutsch", "Español", "한국어"}
local mon_gender = {"Male", "Female", "Genderless"}
local mon_nature = {"Hardy", "Lonely", "Brave", "Adamant", "Naughty", "Bold", "Docile", "Relaxed", "Impish", "Lax",
                    "Timid", "Hasty", "Serious", "Jolly", "Naive", "Modest", "Mild", "Quiet", "Bashful", "Rash", "Calm",
                    "Gentle", "Sassy", "Careful", "Quirky"}
local char_table_iv = {"💰", "🗝️", "💿", "✉️", "💊", "🍓", "◓", "💥", "←", "↑", "↓", "→",
                       "►", "＆", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F",
                       "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y",
                       "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r",
                       "s", "t", "u", "v", "w", "x", "y", "z", "À", "Á", "Â", "Ã", "Ä", "Å", "Æ", "Ç", "È",
                       "É", "Ê", "Ë", "Ì", "Í", "Î", "Ï", "Ð", "Ñ", "Ò", "Ó", "Ô", "Õ", "Ö", "×", "Ø",
                       "Ù", "Ú", "Û", "Ü", "Ý", "Þ", "ß", "à", "á", "â", "ã", "ä", "å", "æ", "ç", "è",
                       "é", "ê", "ë", "ì", "í", "î", "ï", "ð", "ñ", "ò", "ó", "ô", "õ", "ö", "÷", "ø",
                       "ù", "ú", "û", "ü", "ý", "þ", "ÿ", "Œ", "œ", "Ş", "ş", "ª", "º", "er", "re", "r",
                       "₽", "¡", "¿", "!", "?", ", ", ".", "…", "･", "/", "‘", "’", "“", "”", "„",
                       "«", "»", "(", ")", "♂", "♀", "+", "-", "*", "#", "=", "&", "~", ":", ";", "♠", "♣",
                       "♥", "♦", "★", "◎", "○", "□", "△", "◇", "@", "♪", "%", "☀", "☁", "☂",
                       "☃", "😑", "☺", "☹", "😠", "⤴︎", "⤵︎", "💤", " ", "PK", "MN", " ", " ",
                       " ", " ", " ", "°", "_", "＿", "․", "‥"}

-- Parses decrypted data into a human-readable table of key value pairs
function pokemon.parse_data(data, enrich)
    local read_string = function(start, length)
        local text = ""

        for i = start + 1, start + length, 2 do
            local value = data[i] + (data[i] << 8)

            if value == 0xFFFF or value == 0x0000 then -- Null terminator
                break
            end

            if _ROM.gen == 4 then -- Gen 4 characters have a different byte offset
                text = text .. char_table_iv[(value - 0x112) & 0xFF]
            else
                text = text .. utf8.char(value & 0xFF)
            end
        end
        
        return text
    end

    local read_real = function(start, length)
        local bytes = 0
        local j = 0

        for i = start + 1, start + length do
            bytes = bytes + (data[i] << j * 8)
            j = j + 1
        end
        
        return bytes
    end

    if data == nil then
        console.warning("Tried to parse data of a non-existent Pokemon!")
        return nil
    end

    mon = {}
    mon.pid              = read_real(0x00, 0x4)
    mon.checksum         = read_real(0x06, 0x02)
    
    -- Block A
    mon.species          = read_real(0x08, 2)
    mon.heldItem         = read_real(0x0A, 2)
    mon.otID             = read_real(0x0C, 2)
    mon.otSID            = read_real(0x0E, 2)
    mon.experience       = read_real(0x10, 3)
    mon.friendship       = read_real(0x14, 1)
    mon.ability          = read_real(0x15, 1)
    -- mon.markings         = read_real(0x16, 1)
    mon.otLanguage       = read_real(0x17, 1)
    mon.hpEV             = read_real(0x18, 1)
    mon.attackEV         = read_real(0x19, 1)
    mon.defenseEV        = read_real(0x1A, 1)
    mon.speedEV          = read_real(0x1B, 1)
    mon.spAttackEV       = read_real(0x1C, 1)
    mon.spDefenseEV      = read_real(0x1D, 1)
    -- mon.cool 			 = read_real(0x1E, 1)
    -- mon.beauty 			 = read_real(0x1F, 1)
    -- mon.cute 			 = read_real(0x20, 1)
    -- mon.smart 			 = read_real(0x21, 1)
    -- mon.tough 			 = read_real(0x22, 1)
    -- mon.sheen 			 = read_real(0x23, 1)
    -- mon.sinnohRibbonSet1 = read_real(0x24, 2)
    -- mon.unovaRibbonSet 	 = read_real(0x26, 2)

    mon.shinyValue = mon.otID ~ mon.otSID ~ ((mon.pid >> 16) & 0xFFFF) ~ (mon.pid & 0xFFFF)
    mon.shiny = mon.shinyValue < 8

    -- Block B
    mon.moves = {
        read_real(0x28, 2), 
        read_real(0x2A, 2), 
        read_real(0x2C, 2), 
        read_real(0x2E, 2)
    }

    mon.pp = {
        read_real(0x30, 1), 
        read_real(0x31, 1), 
        read_real(0x32, 1), 
        read_real(0x33, 1)
    }

    mon.ppUps = read_real(0x34, 4)

    local value = read_real(0x38, 5)
    mon.hpIV        = (value >>  0) & 0x1F
    mon.attackIV    = (value >>  5) & 0x1F
    mon.defenseIV   = (value >> 10) & 0x1F
    mon.speedIV     = (value >> 15) & 0x1F
    mon.spAttackIV  = (value >> 20) & 0x1F
    mon.spDefenseIV = (value >> 25) & 0x1F
    mon.isEgg       = (value >> 30) & 0x01
    -- mon.isNicknamed = (value >> 31) & 0x01
    
    -- mon.hoennRibbonSet1		= read_real(0x3C, 2)
    -- mon.hoennRibbonSet2		= read_real(0x3E, 2)

    local value = read_real(0x40, 1)
    -- mon.fatefulEncounter = (value >> 0) & 0x01
    mon.gender           = (value >> 1) & 0x03
    mon.altForm	         = (value >> 3) & 0x1F

    if _ROM.gen == 4 then
        -- mon.leaf_crown = read_real(0x41, 1)
        mon.nature     = mon.pid % 25
    else
        mon.nature = read_real(0x41, 1)
        
        local data = read_real(0x42, 1)
        -- mon.dreamWorldAbility = data & 0x01
        -- mon.isNsPokemon		  = data & 0x02
    end

    -- Block C
    mon.nickname         = read_string(0x48, 21)
    -- mon.originGame		 = read_real(0x5F, 1)
    -- mon.sinnohRibbonSet3 = read_real(0x60, 2)
    -- mon.sinnohRibbonSet3 = read_real(0x62, 2)

    -- Block D
    -- mon.otName          = read_string(0x68, 16)
    -- mon.dateEggReceived	= read_real(0x78, 3)
    -- mon.dateMet			= read_real(0x7B, 3)
    -- mon.eggLocation		= read_real(0x7E, 2)
    -- mon.metLocation		= read_real(0x80, 2)
    mon.pokerus         = read_real(0x82, 1)
    mon.pokeball        = read_real(0x83, 1)
    -- mon.encounterType	= read_real(0x85, 1)

    -- Battle Stats
    -- mon.status       = read_real(0x88, 1)
    mon.level        = read_real(0x8C, 1)
    -- mon.capsuleIndex = read_real(0x8D, 1)
    mon.currentHP    = read_real(0x8E, 2)
    mon.maxHP        = read_real(0x90, 2)
    mon.attack       = read_real(0x92, 2)
    mon.defense      = read_real(0x94, 2)
    mon.speed        = read_real(0x96, 2)
    mon.spAttack     = read_real(0x98, 2)
    mon.spDefense    = read_real(0x9A, 2)
    -- mon.mailMessage	 = read_real(0x9C, 37)

    -- -- Substitute property IDs with ingame names
    if enrich then
        mon.name = mon_dex[mon.species + 1].name
        mon.type = mon_dex[mon.species + 1].type

        -- mon.rating = pokemon.get_rating(mon)
        mon.pokeball = mon_item[mon.pokeball + 1]
        mon.otLanguage = mon_lang[mon.otLanguage + 1]
        mon.ability = mon_ability[mon.ability + 1]
        mon.nature = mon_nature[mon.nature + 1]
        mon.heldItem = mon_item[mon.heldItem + 1]
        mon.gender = mon_gender[mon.gender + 1]
        
        local move_id = mon.moves
        mon.moves = {}

        for _, move in ipairs(move_id) do
            table.insert(mon.moves, mon_move[move + 1])
        end
    end

    return mon
end

function pokemon.check_battle_moves(ally)
    for i = 1, #ally.moves, 1 do
        local pp = ally.pp[i]
        local power = ally.moves[i].power
        local total_pp = 0
        if pp ~= 0 and power ~= nil then
            total_pp = total_pp + pp
        end
    end
end

function pokemon.export_pkx(data)
    local mon = pokemon.parse_data(data, false)

    -- Match PKHeX default filename format (as best as possible)
    local hex_string = string.format("%04X", mon.checksum) .. string.format("%08X", mon.pid)
    local filename = mon.species .. " - " .. mon.nickname .. " - " .. hex_string
    
    -- Write Pokémon data to file and save in /user/targets
    local file = io.open("user/targets/" .. filename .. ".pk" .. _ROM.gen, "wb")
    
    file:write(string.char(table.unpack(data)))
    file:close()
end

local function shallow_copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function pokemon.log_encounter(mon)
    if not mon then
        console.debug("Tried to log a non-existent Pokémon!")
        return false
    end

    -- Create a watered down copy of the Pokemon data for logging only
    local mon_new = shallow_copy(mon)
    
    mon_new.pid = string.format("%08X", mon_new.pid) -- Convert PID to hex

    local key_whitelist = {
        "pid", "species", "name", "level", "gender", "nature", "heldItem",
        "shiny", "shinyValue", "ability", "hpIV", "attackIV", "defenseIV",
        "spAttackIV", "spDefenseIV", "speedIV", "altForm"
    }
    
    for k, v in pairs(mon_new) do
        local allowed = false
        
        for _, k2 in ipairs(key_whitelist) do
            if k2 == k then
                allowed = true
                break
            end
        end
    
        if not allowed then
            mon_new[k] = nil
        end
    end

    -- Send encounter to dashboard for logging
    local was_target = pokemon.matches_ruleset(mon, config.target_traits)
    local msg_type = was_target and "seen_target" or "seen"

    if was_target then
        console.log("Wild " .. mon.name .. " is a target!")
    end

    dashboard:send(json.encode({
        type = msg_type,
        data = mon_new
    }) .. "\x00")

    return was_target
end

local function table_contains(table_, item)
    if type(table_) ~= "table" then
        table_ = {table_}
        -- console.debug("Ruleset entry was not a table. Fixing.")
    end

    for _, table_item in pairs(table_) do
        if string.lower(table_item) == string.lower(item) then
            return true
        end
    end

    return false
end

function pokemon.find_best_move(ally, foe)
    local max_power_index = 1
    local max_power = 0

    -- Sometimes, beyond all reasonable explanation, key values are completely missing
    -- Do nothing in this case to prevent crashes
    if not foe or not ally or not foe.type or not ally.moves then
        console.warning("Pokemon values were completely absent, couldn't determine best move")
        return nil
    end

    for i = 1, #ally.moves, 1 do
        local type = ally.moves[i].type
        local power = ally.moves[i].power

        -- Ignore useless moves
        if ally.pp[i] ~= 0 and power ~= nil then
            local type_matchup = mon_type[type]

            -- Calculate effectiveness against foe's type(s)
            for j = 1, #foe.type do
                local foe_type = foe.type[j]

                if table_contains(type_matchup.cant_hit, foe_type) then
                    power = 0
                elseif table_contains(type_matchup.resisted_by, foe_type) then
                    power = power / 2
                elseif table_contains(type_matchup.super_effective, foe_type) then
                    power = power * 2
                end
            end

            -- STAB
            for j = 1, #ally.type do
                if ally.type[j] == type then
                    power = power * 1.5
                    break
                end
            end

            if power > max_power then
                max_power = power
                max_power_index = i
            end
        end

        i = i + 1
    end

    return {
        name = ally.moves[max_power_index].name,
        index = max_power_index,
        power = max_power
    }
end

function pokemon.matches_ruleset(mon, ruleset)
    if not ruleset then
        console.warning("Can't check Pokemon against an empty ruleset")
        return false
    end

    -- Other traits don't matter with this override
    if config.always_catch_shinies and mon.shiny then
        return true
    end

    -- Default trait comparison
    if ruleset.shiny ~= mon.shiny then
        console.debug("Mon shininess does not match ruleset")
        return false
    end

    if ruleset.species then
        if not table_contains(ruleset.species, mon.name) then
            console.debug("Mon species " .. mon.name .. " is not in ruleset")
            return false
        end
    end

    if ruleset.gender then
        local mon_gender = string.lower(mon.gender)
        local target_gender = string.lower(ruleset.gender)

        if mon_gender ~= target_gender then
            console.debug("Mon gender " .. mon_gender .. " does not match rule" .. target_gender)
            return false
        end
    end

    if ruleset.level then
        local mon_level = tonumber(mon.level)
        local target_level = tonumber(ruleset.level)

        if mon_level < target_level then
            console.debug("Mon level " .. tostring(mon.level) .. " does not meet rule " .. ruleset.level)
            return false
        end
    end
    
    if ruleset.ability then
        if not table_contains(ruleset.ability, mon.ability) then
            console.debug("Mon ability " .. mon.ability .. " is not in ruleset")
            return false
        end
    end

    if ruleset.nature then
        if not table_contains(ruleset.nature, mon.nature) then
            console.debug("Mon nature " .. mon.nature .. " is not in ruleset")
            return false
        end
    end

    -- Check that individual IVs meet target thresholds
    local ivs = {"hpIV", "attackIV", "defenseIV", "spAttackIV", "spDefenseIV", "speedIV"}
    local sum = 0

    for _, key in ipairs(ivs) do
        sum = sum + mon[key]
        if ruleset[key] and mon[key] < ruleset[key] then
            console.debug("Mon " .. key .. " " .. mon.hpIV .. " does not meet ruleset " .. ruleset.hpIV)
            return false
        end
    end

    if ruleset.iv_sum then
        if sum < ruleset.iv_sum then
            console.debug("Mon IV sum of " .. sum .. " does not meet threshold " .. ruleset.iv_sum)
            return false
        end
    end

    if ruleset.move then
        local has_move = false

        for i = 1, #ruleset.move, 1 do
            if table_contains(mon.moves, ruleset.move[i]) then
                has_move = true
                break
            end
        end

        if not has_move then
            console.debug("Mon moveset does not contain ruleset")
            return false
        end
    end

    if ruleset.type then
        local has_type = false

        for i = 1, #ruleset.type, 1 do
            if table_contains(mon.type, ruleset.type[i]) then
                has_type = true
                break
            end
        end

        if not has_type then
            console.debug("Mon type is not in ruleset")
            return false
        end
    end

    return true
end

return pokemon
