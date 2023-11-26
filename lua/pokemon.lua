local pokemon = {}

function pokemon.read_data(address)
    function rand(seed)
        return (0x41C64E6D * seed) + 0x6073
    end

    local decrypt_block = function(start, finish)
        local data = {}

        for i = start, finish, 0x2 do
            seed = rand(seed)
            
            local word = mword(address + i)
            local decrypted = word ~ (seed >> 16)
            local end_word = decrypted & 0xFFFF

            table.insert(data, end_word & 0xFF)
            table.insert(data, (end_word >> 8) & 0xFF)
        end

        return data
    end

    local verify_checksums = function(checksum)
        local sum = 0

        for j = 1, 4 do
            for i = 1, #block[j], 2 do
                sum = sum + block[j][i] + (block[j][i + 1] << 8)
            end
        end

        sum = sum & 0xFFFF

        return sum == checksum
    end
    
    -- Unencrypted bytes
    local pid = mdword(address)
    local checksum = mword(address + 0x06)
    
    -- Find intended order of the shuffled data blocks
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

    -- Decrypt blocks A,B,C,D and rearrange them according to the block order
    seed = checksum

    local _block = {}
    _block[1] = decrypt_block(0x08, 0x27)
    _block[2] = decrypt_block(0x28, 0x47)
    _block[3] = decrypt_block(0x48, 0x67)
    _block[4] = decrypt_block(0x68, 0x87)
    
    local shift = ((pid & 0x3E000) >> 0xD) % 24
    local block_order = substruct[shift]

    block = {}
    block[1] = _block[block_order[1]]
    block[2] = _block[block_order[2]]
    block[3] = _block[block_order[3]]
    block[4] = _block[block_order[4]]

    -- Re-calculate the checksum of the blocks and match it with mon.checksum
    -- If the checksum fails, assume it's the data is garbage or still being written
    if not verify_checksums(checksum) then
        return nil
    end
    
    -- Battle stats
    seed = pid
    
    return {
        blockA = block[1],
        blockB = block[2],
        blockC = block[3],
        blockD = block[4],
        battle_stats = decrypt_block(0x88, 0xDB)
    }
end

function pokemon.parse_data(address)
    local read_string = function(this_block, start, length)
        local text = ""
        start = start - block_start

        for i = 0, length - 1, 2 do
            local value = this_block[start + i] + (this_block[start + i] << 8)

            if value == 0xFFFF or value == 0x0000 then -- Null terminator
                break
            end

            if gen == 4 then -- Gen 4 characters have a different byte offset
                value = value + 0x16
            end

            text = text .. utf8.char(value & 0xFF)
        end
        
        return text
    end

    local read_data = function(this_block, start, length)
        local data = 0
        
        start = start - block_start

        for i = 0, length - 1 do
            data = data + (this_block[start + i] << i * 8)
        end
        
        return data
    end

    
    mon = {}
    mon.pid = mdword(address)
    mon.checksum = mword(address + 0x06)
    
    -- Block A
    local data = pokemon.read_data(address)
    block_start = 0x07

    mon.species          = read_data(data.blockA, 0x08, 2)
    mon.heldItem         = read_data(data.blockA, 0x0A, 2)
    mon.otID             = read_data(data.blockA, 0x0C, 2)
    mon.otSID            = read_data(data.blockA, 0x0E, 2)
    mon.experience       = read_data(data.blockA, 0x10, 3)
    mon.friendship       = read_data(data.blockA, 0x14, 1)
    mon.ability          = read_data(data.blockA, 0x15, 1)
    -- mon.markings         = read_data(data.blockA, 0x16, 1)
    mon.otLanguage       = read_data(data.blockA, 0x17, 1)
    mon.hpEV             = read_data(data.blockA, 0x18, 1)
    mon.attackEV         = read_data(data.blockA, 0x19, 1)
    mon.defenseEV        = read_data(data.blockA, 0x1A, 1)
    mon.speedEV          = read_data(data.blockA, 0x1B, 1)
    mon.spAttackEV       = read_data(data.blockA, 0x1C, 1)
    mon.spDefenseEV      = read_data(data.blockA, 0x1D, 1)
    -- mon.cool 			 = read_data(data.blockA, 0x1E, 1)
    -- mon.beauty 			 = read_data(data.blockA, 0x1F, 1)
    -- mon.cute 			 = read_data(data.blockA, 0x20, 1)
    -- mon.smart 			 = read_data(data.blockA, 0x21, 1)
    -- mon.tough 			 = read_data(data.blockA, 0x22, 1)
    -- mon.sheen 			 = read_data(data.blockA, 0x23, 1)
    -- mon.sinnohRibbonSet1 = read_data(data.blockA, 0x24, 2)
    -- mon.unovaRibbonSet 	 = read_data(data.blockA, 0x26, 2)

    mon.shinyValue = mon.otID ~ mon.otSID ~ ((mon.pid >> 16) & 0xFFFF) ~ (mon.pid & 0xFFFF)
    mon.shiny = mon.shinyValue < 8

    -- Block B
    block_start = 0x27
    mon.moves = {
        read_data(data.blockB, 0x28, 2), 
        read_data(data.blockB, 0x2A, 2), 
        read_data(data.blockB, 0x2C, 2), 
        read_data(data.blockB, 0x2E, 2)
    }

    mon.pp = {
        read_data(data.blockB, 0x30, 1), 
        read_data(data.blockB, 0x31, 1), 
        read_data(data.blockB, 0x32, 1), 
        read_data(data.blockB, 0x33, 1)
    }

    mon.ppUps = read_data(data.blockB, 0x34, 4)

    local value = read_data(data.blockB, 0x38, 5)
    mon.hpIV        = (value >>  0) & 0x1F
    mon.attackIV    = (value >>  5) & 0x1F
    mon.defenseIV   = (value >> 10) & 0x1F
    mon.speedIV     = (value >> 15) & 0x1F
    mon.spAttackIV  = (value >> 20) & 0x1F
    mon.spDefenseIV = (value >> 25) & 0x1F
    mon.isEgg       = (value >> 30) & 0x01
    mon.isNicknamed = (value >> 31) & 0x01
    
    -- mon.hoennRibbonSet1		= read_data(data.blockB, 0x3C, 2)
    -- mon.hoennRibbonSet2		= read_data(data.blockB, 0x3E, 2)

    local value = read_data(data.blockB, 0x40, 1)
    mon.fatefulEncounter = (value >> 0) & 0x01
    mon.gender           = (value >> 1) & 0x03
    mon.altForm	         = (value >> 3) & 0x1F

    if gen == 4 then
        -- mon.leaf_crown = read_data(data.blockB, 0x41, 1)
        mon.nature     = mon.pid % 25
    else
        mon.nature = read_data(data.blockB, 0x41, 1)
        
        local data = read_data(data.blockB, 0x42, 1)
        mon.dreamWorldAbility = data & 0x01
        -- mon.isNsPokemon		  = data & 0x02
    end

    -- Block C
    block_start = 0x47
    mon.nickname         = read_string(data.blockC, 0x48, 21)
    mon.originGame		 = read_data(data.blockC, 0x5F, 1)
    -- mon.sinnohRibbonSet3 = read_data(data.blockC, 0x60, 2)
    -- mon.sinnohRibbonSet3 = read_data(data.blockC, 0x62, 2)

    -- Block D
    block_start = 0x67
    mon.otName          = read_string(data.blockD, 0x68, 16)
    mon.dateEggReceived	= read_data(data.blockD, 0x78, 3)
    mon.dateMet			= read_data(data.blockD, 0x7B, 3)
    mon.eggLocation		= read_data(data.blockD, 0x7E, 2)
    mon.metLocation		= read_data(data.blockD, 0x80, 2)
    mon.pokerus         = read_data(data.blockD, 0x82, 1)
    mon.pokeball        = read_data(data.blockD, 0x83, 1)
    mon.encounterType	= read_data(data.blockD, 0x85, 1)

    -- Battle Stats
    block_start = 0x87
    mon.status       = read_data(data.battle_stats, 0x88, 1)
    mon.level        = read_data(data.battle_stats, 0x8C, 1)
    mon.capsuleIndex = read_data(data.battle_stats, 0x8D, 1)
    mon.currentHP    = read_data(data.battle_stats, 0x8E, 2)
    mon.maxHP        = read_data(data.battle_stats, 0x90, 2)
    mon.attack       = read_data(data.battle_stats, 0x92, 2)
    mon.defense      = read_data(data.battle_stats, 0x94, 2)
    mon.speed        = read_data(data.battle_stats, 0x96, 2)
    mon.spAttack     = read_data(data.battle_stats, 0x98, 2)
    mon.spDefense    = read_data(data.battle_stats, 0x9A, 2)
    -- mon.mailMessage	 = read_data(data.battle_stats, 0x9C, 37)

    return mon
end

function pokemon.export_pkx(address)
    local data = pokemon.read_data(address)
    local mon = pokemon.parse_data(address)

    local pid = mdword(address)
    local checksum = mword(address + 0x06)

    -- Match PKHeX default filename format (as best as possible)
    local hex_string = string.format("%04X", checksum) .. string.format("%08X", pid)
    local filename = mon.species

    -- UTF-8 symbols are not supported by this lua environment
    -- if not mon.shiny then
    --     filename = filename .. " ★"
    -- end
    
    local filename = filename .. " - " .. mon.nickname .. " - " .. hex_string
    
    -- Write Pokémon data to file and save in /user/targets
    local file = io.open("user/targets/" .. filename .. ".pk" .. gen, "wb")
    
    file:write(string.pack("<I4", pid))
    file:write(string.pack("<I2", 0x0))
    file:write(string.pack("<I2", checksum))
    file:write(string.char(table.unpack(data.blockA)))
    file:write(string.char(table.unpack(data.blockB)))
    file:write(string.char(table.unpack(data.blockC)))
    file:write(string.char(table.unpack(data.blockD)))
    file:write(string.char(table.unpack(data.battle_stats)))
    
    if gen == 4 then -- Gen 4 exclusive ball seal data
        for i = 1, 0x10, 2 do
            file:write(string.pack("<I2", 0x0))
        end
    end

    file:close()
end

local function shallowcopy(orig)
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

function pokemon.log(mon)
    -- Create a watered down copy of the Pokemon data for logging only
    local mon_new = shallowcopy(mon)
    
    if not mon or not mon_new then
        console.debug("Tried to log a non-existent Pokémon!")
        return false
    end

    if type(mon_new.pid) == "number" then
        mon_new.pid = string.format("%08X", mon_new.pid) -- Convert PID to standard hex format
    end

    -- Values not relevant to the encounter log, gets removed
    local excess_keys = {"type", "nickname", "hpEV", "attackEV", "defenseEV", "spAttackEV", "spDefenseEV",
                         "speedEV", "dreamWorldAbility", "friendship", "isEgg", "isNicknamed", "otLanguage", "otName",
                         "pokeball", "pokerus", "ppUps", "status", "isNsPokemon", "pp", "experience"}

    for _, key in ipairs(excess_keys) do
        mon_new[key] = nil
    end

    local was_target = pokemon.matches_ruleset(mon, config.target_traits)

    -- Send encounter to dashboard
    if was_target then
        comm.socketServerSend(json.encode({
            type = "seen_target",
            data = mon_new
        }) .. "\x00")
    else
        comm.socketServerSend(json.encode({
            type = "seen",
            data = mon_new
        }) .. "\x00")
    end

    return was_target
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

function pokemon.enrich_data(mon)
    if not mon then
        console.warning("Tried to enrich data of a non-existent Pokémon!")
        return
    end

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

    return mon
end

function pokemon.find_best_move(ally, foe)
    local function table_contains(tbl, type_check)
        for _, type in pairs(tbl) do
            if type == type_check then
                return true
            end
        end
        return false
    end

    local max_power_index = 1
    local max_power = 0

    -- Sometimes, beyond all reasonable explanation, key values are completely missing
    -- Do nothing in this case to prevent crashes
    if not foe or not ally or not foe.type or not ally.moves then
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

function pokemon.matches_ruleset(mon, target)
    if not target then
        console.warning("Mon was not a target, because no target was specified.")
        return false
    end

    -- If shiny Pokemon are specific as a target, ignore other
    -- config and always catch it
    if target.shiny then
        if mon.shiny or mon.shinyValue < 8 then
            return true
        else
            console.debug("Mon was not shiny, checking other traits...")
        end
    end

    -- Check if species is in list
    local has_other_specs = false

    if target.species then
        has_other_specs = true
        local is_species = false
        for i = 1, #target.species, 1 do
            if string.lower(mon.name) == string.lower(target.species[i]) then
                is_species = true
                break
            end
        end

        if not is_species then
            console.debug("Mon species " .. mon.name .. " is not in ruleset")
            return false
        end
    end

    -- Check if gender matches target
    if target.gender then
        has_other_specs = true

        local mon_gender = string.lower(mon.gender)
        local target_gender = string.lower(target.gender)

        if mon_gender ~= target_gender then
            console.debug("Mon gender " .. mon_gender .. " does not match target of " .. target_gender)
            return false
        end
    end

    -- Check if level is above threshold
    if target.level then
        has_other_specs = true

        local mon_level = tonumber(mon.level)
        local target_level = tonumber(target.level)

        if mon_level < target_level then
            console.debug("Mon level " .. tostring(mon.level) .. " does not meet target of " .. target.level)
            return false
        end
    end
    
    -- Check if ability is in list
    if target.ability then
        has_other_specs = true
        local meets_ability = false
        for i = 1, #target.ability, 1 do
            if string.lower(mon.ability) == string.lower(target.ability[i]) then
                meets_ability = true
                break
            end
        end

        if not meets_ability then
            console.debug("Mon ability " .. mon.ability .. " is not in ruleset")
            return false
        end
    end

    -- Check if nature is in list
    if target.nature then
        has_other_specs = true
        local is_nature = false
        for i = 1, #target.nature, 1 do
            if string.lower(mon.nature) == string.lower(target.nature[i]) then
                is_nature = true
                break
            end
        end

        if not is_nature then
            console.debug("Mon nature " .. mon.nature .. " is not in ruleset")
            return false
        end
    end

    -- Check that IVs meet target thresholds
    local ivs = {"hpIV", "attackIV", "defenseIV", "spAttackIV", "spDefenseIV", "speedIV"}
    local sum = 0

    for _, key in ipairs(ivs) do
        sum = sum + mon[key]
        if target[key] and mon[key] < target[key] then
            has_other_specs = true
            console.debug("Mon " .. key .. " " .. mon.hpIV .. " does not meet ruleset " .. target.hpIV)
            return false
        end
    end

    if target.iv_sum then
        has_other_specs = true

        if sum < target.iv_sum then
            console.debug("Mon IV sum of " .. sum .. " does not meet threshold " .. target.iv_sum)
            return false
        end
    end

    -- Check moveset for target moves
    if target.move then
        has_other_specs = true
        local has_move = false
        for i = 1, #target.move, 1 do
            for j = 1, #mon.moves, 1 do
                if string.lower(mon.move[j].name) == string.lower(target.move[i]) then
                    has_move = true
                    break
                end
            end
        end

        if not has_move then
            console.debug("Mon moveset does not contain ruleset")
            return false
        end
    end

    -- Check types in target
    if target.type then
        has_other_specs = true
        local has_type = false
        for i = 1, #target.type, 1 do
            for j = 1, #mon.type, 1 do
                if string.lower(mon.type[j]) == string.lower(target.type[i]) then
                    has_type = true
                    break
                end
            end
        end

        if not has_type then
            console.debug("Mon type is not in ruleset")
            return false
        end
    end

    if has_other_specs and not target.shiny then
        console.log("Wild " .. mon.name .. " is a target!")
        return true
    else
        -- If the only specified trait is shiny: true, return false
        -- because the only single property check failed
        return false
    end
end

return pokemon
