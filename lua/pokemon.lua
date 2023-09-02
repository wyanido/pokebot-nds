local pokemon = {}

function pokemon.read_data(address)
    function rand(seed)
        return (0x41C64E6D * seed) + 0x6073
    end

    function blockDataString(offset, length)
        local data = ""

        for i = 0, length - 1, 2 do
            local value = monTable[offset + i - 0x07] + (monTable[offset + i - 0x07] << 8)

            if value == 0xFFFF or value == 0x0000 then
                break
            else
                data = data .. utf8.char(value & 0xFF)
            end
        end
        return data
    end

    function blockDataString_IV(offset, length)
        local data = ""

        for i = 0, length - 1, 2 do
            local value = monTable[offset + i - 0x07] + (monTable[offset + i - 0x07] << 8)

            if value == 0xFFFF or value == 0x0000 then
                break
            else
                data = data .. utf8.char((value + 0x16) & 0xFF)
            end
        end
        return data
    end

    function loopTable(dataTable, offset, length)
        local data = 0
        for i = 0, length - 1 do
            data = data + (dataTable[offset + i] << i * 8)
        end
        return data
    end

    function blockData(offset, length)
        return loopTable(monTable, offset - 0x07, length)
    end

    function battleData(offset, length)
        return loopTable(battleStats, offset - 0x87, length)
    end

    function substructSelector(index)
        local ss = {
            [0] = { 0, 1, 2, 3 },
            [1] = { 0, 1, 3, 2 },
            [2] = { 0, 2, 1, 3 },
            [3] = { 0, 3, 1, 2 },
            [4] = { 0, 2, 3, 1 },
            [5] = { 0, 3, 2, 1 },
            [6] = { 1, 0, 2, 3 },
            [7] = { 1, 0, 3, 2 },
            [8] = { 2, 0, 1, 3 },
            [9] = { 3, 0, 1, 2 },
            [10] = { 2, 0, 3, 1 },
            [11] = { 3, 0, 2, 1 },
            [12] = { 1, 2, 0, 3 },
            [13] = { 1, 3, 0, 2 },
            [14] = { 2, 1, 0, 3 },
            [15] = { 3, 1, 0, 2 },
            [16] = { 2, 3, 0, 1 },
            [17] = { 3, 2, 0, 1 },
            [18] = { 1, 2, 3, 0 },
            [19] = { 1, 3, 2, 0 },
            [20] = { 2, 1, 3, 0 },
            [21] = { 3, 1, 2, 0 },
            [22] = { 2, 3, 1, 0 },
            [23] = { 3, 2, 1, 0 }
        }

        return ss[index]
    end

    mon = {}

    -- Unencrypted bytes
    mon.pid = mdword(address)
    mon.checksum = mword(address + 0x06)

    -- Encrypted Blocks
    block = { {}, {}, {}, {} }

    seed = mon.checksum

    -- 128 byte block data is decrypted in 2 byte pairs
    for i = 0x08, 0x87, 2 do
        local word = mword(address + i)

        seed = rand(seed)
        local decryptedByte = word ~ (seed >> 16)
        local endBytes = decryptedByte & 0xFFFF

        local blockIndex = math.floor((i - 0x08) / 32) + 1

        -- Insert the two end bytes as single bytes
        table.insert(block[blockIndex], endBytes & 0xFF)
        table.insert(block[blockIndex], (endBytes >> 8) & 0xFF)
    end

    -- Inverse block order
    shift = ((mon.pid & 0x3E000) >> 0xD) % 24
    blockOrder = substructSelector(shift)

    monTable = {}

    -- Iterate through each block and reorganise the data into a single master table
    for i = 1, 4 do
        thisBlock = block[blockOrder[i] + 1]

        for j = 1, 32 do
            table.insert(monTable, thisBlock[j])
        end
    end

    -- Verify checksums
    -- If the mon data is invalid, assume it's unprepared or garbage data
    sum = 0

    for i = 1, #monTable, 2 do
        sum = sum + monTable[i] + (monTable[i + 1] << 8)
    end

    sum = sum & 0xFFFF

    if sum ~= mon.checksum then
        return nil
    end

    -- Block A
    mon.species = blockData(0x08, 2)
    mon.heldItem = blockData(0x0A, 2)
    mon.otID = blockData(0x0C, 2)
    mon.otSID = blockData(0x0E, 2)
    mon.experience = blockData(0x10, 3)
    mon.friendship = blockData(0x14, 1)
    mon.ability = blockData(0x15, 1)
    -- mon.markings 			= blockData(0x16, 1)
    mon.otLanguage = blockData(0x17, 1)
    mon.hpEV = blockData(0x18, 1)
    mon.attackEV = blockData(0x19, 1)
    mon.defenseEV = blockData(0x1A, 1)
    mon.speedEV = blockData(0x1B, 1)
    mon.spAttackEV = blockData(0x1C, 1)
    mon.spDefenseEV = blockData(0x1D, 1)
    -- mon.cool 				= blockData(0x1E, 1)
    -- mon.beauty 				= blockData(0x1F, 1)
    -- mon.cute 				= blockData(0x20, 1)
    -- mon.smart 				= blockData(0x21, 1)
    -- mon.tough 				= blockData(0x22, 1)
    -- mon.sheen 				= blockData(0x23, 1)
    -- mon.sinnohRibbonSet1 	= blockData(0x24, 2)
    -- mon.unovaRibbonSet 		= blockData(0x26, 2)

    -- Block B
    mon.moves = { blockData(0x28, 2), blockData(0x2A, 2), blockData(0x2C, 2), blockData(0x2E, 2) }

    mon.pp = { blockData(0x30, 1), blockData(0x31, 1), blockData(0x32, 1), blockData(0x33, 1) }

    mon.ppUps = blockData(0x34, 4)

    local data = blockData(0x38, 5)
    mon.hp_iv = (data >> 0) & 0x1F
    mon.attack_iv = (data >> 5) & 0x1F
    mon.defense_iv = (data >> 10) & 0x1F
    mon.speed_iv = (data >> 15) & 0x1F
    mon.sp_attack_iv = (data >> 20) & 0x1F
    mon.sp_defense_iv = (data >> 25) & 0x1F
    mon.isEgg = (data >> 30) & 0x01
    mon.isNicknamed = (data >> 31) & 0x01

    -- mon.hoennRibbonSet1		= blockData(0x3C, 2)
    -- mon.hoennRibbonSet2		= blockData(0x3E, 2)

    local data = blockData(0x40, 1)
    -- mon.fatefulEncounter 	= (data >> 0) & 0x01
    mon.gender = (data >> 1) & 0x03
    mon.altForm = (data >> 3) & 0x1F

    if gen == 4 then
        -- mon.leaf_crown				= blockData(0x41, 1)
        mon.nature = mon.pid % 25
    else
        mon.nature = blockData(0x41, 1)
    end
    local data = blockData(0x42, 1)
    -- mon.dreamWorldAbility	= data & 0x01
    -- mon.isNsPokemon			= data & 0x02

    -- Block C
    if gen == 4 then
        mon.nickname = blockDataString_IV(0x48, 21)
    else
        mon.nickname = blockDataString(0x48, 21)
    end

    -- mon.originGame			= blockData(0x5F, 1)
    -- mon.sinnohRibbonSet3	= blockData(0x60, 2)
    -- mon.sinnohRibbonSet3	= blockData(0x62, 2)

    -- Block D
    if gen == 4 then
        mon.otName = blockDataString_IV(0x68, 21)
    else
        mon.otName = blockDataString(0x68, 16)
    end
    -- mon.dateEggReceived		= blockData(0x78, 3)
    -- mon.dateMet				= blockData(0x7B, 3)
    -- mon.eggLocation			= blockData(0x7E, 2)
    -- mon.metLocation			= blockData(0x80, 2)
    mon.pokerus = blockData(0x82, 1)
    mon.pokeball = blockData(0x83, 1)
    -- mon.encounterType		= blockData(0x85, 1)

    -- Battle stats
    battleStats = {}
    seed = mon.pid

    -- Battle stats are also encrypted in 2-byte pairs
    -- # TODO combine both decryption loops into a single method
    for i = 0x88, 0xDB, 2 do
        local word = mword(address + i)

        seed = rand(seed)
        local decryptedByte = word ~ (seed >> 16)
        local endBytes = decryptedByte & 0xFFFF

        -- Insert the two end bytes as single bytes
        table.insert(battleStats, endBytes & 0xFF)
        table.insert(battleStats, (endBytes >> 8) & 0xFF)
    end

    mon.status = battleData(0x88, 1)
    mon.level = battleData(0x8C, 1)
    -- mon.capsuleIndex		= battleData(0x8D, 1)
    mon.currentHP = battleData(0x8E, 2)
    mon.maxHP = battleData(0x90, 2)
    mon.attack = battleData(0x92, 2)
    mon.defense = battleData(0x94, 2)
    mon.speed = battleData(0x96, 2)
    mon.spAttack = battleData(0x98, 2)
    mon.spDefense = battleData(0x9A, 2)
    -- mon.mailMessage			= battleData(0x9C, 37)

    mon.shinyValue = mon.otID ~ mon.otSID ~ ((mon.pid >> 16) & 0xFFFF) ~ (mon.pid & 0xFFFF)
    mon.shiny = mon.shinyValue < 8

    return mon
end

function write_file(filename, value)
    local file = io.open(filename, "w")

    if file then
        file:write(value)
        file:close()
        return true
    else
        return false
    end
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
    local excess_keys = { "type", "nickname", "hpEV", "attackEV", "defenseEV", "spAttackEV", "spDefenseEV",
        "speedEV", "dreamWorldAbility", "friendship", "isEgg", "isNicknamed", "otLanguage", "otName",
        "pokeball", "pokerus", "ppUps", "status", "isNsPokemon", "pp", "experience" }

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

local mon_ability = json.load("lua/data/ability.json")
local mon_item = json.load("lua/data/item.json")
local mon_move = json.load("lua/data/move.json")
local mon_type = json.load("lua/data/type.json")
local mon_dex = json.load("lua/data/pokedex.json")
local mon_lang = { "none", "日本語", "English", "Français", "Italiano", "Deutsch", "Español", "한국어" }
local mon_gender = { "Male", "Female", "Genderless" }
local mon_nature = { "Hardy", "Lonely", "Brave", "Adamant", "Naughty", "Bold", "Docile", "Relaxed", "Impish", "Lax",
    "Timid", "Hasty", "Serious", "Jolly", "Naive", "Modest", "Mild", "Quiet", "Bashful", "Rash", "Calm",
    "Gentle", "Sassy", "Careful", "Quirky" }

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

    -- Check if species(name) is in list
    local has_other_specs = false
    console.log(has_other_specs)
    if target.species then
        has_other_specs = true
        console.log("has other specs is true")
        local is_species = false
        for i = 1, #target.species, 1 do
            if string.lower(mon.name) == string.lower(target.species[i]) then
                is_species = true
                console.log("Species is true")
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
    local ivs = { "hp_iv", "attack_iv", "defense_iv", "sp_attack_iv", "sp_defense_iv", "speed_iv" }
    local sum = 0

    for _, key in ipairs(ivs) do
        sum = sum + mon[key]
        if target[key] and mon[key] < target[key] then
            has_other_specs = true
            console.debug("Mon " .. key .. " " .. mon.hp_iv .. " does not meet ruleset " .. target.hp_iv)
            return false
        end
    end

    if target.iv_sum then
        has_other_specs = true
        for i = 1, #target.iv_sum, 1 do
            if sum == target.iv_sum[i] then
                console.debug("Mon IV sum of " .. sum .. " meets a value!! " .. target.iv_sum[i])
                break
            else
                console.debug("Mon IV sum of " .. sum .. " does not meet any values set... ")
                return false
            end
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
    console.log(has_other_specs)
    if has_other_specs and not target.shiny then --must always have shiny set true or false in config or this will not work
        console.log("Wild " .. mon.name .. " is a target!")
        return true
    else
        -- If the only specified trait is shiny: true, return false
        -- because the only single property check failed
        return false
    end
end

return pokemon
