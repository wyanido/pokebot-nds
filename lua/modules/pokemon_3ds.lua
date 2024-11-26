-----------------------------------------------------------------------------
-- Pokemon function overrides for 3DS games
-- Author: wyanido
-- Homepage: https://github.com/wyanido/pokebot-nds
--
-- Replaces several functions from pokemon.lua in order to
-- correct differences between data formats across the DS and 3DS titles
-----------------------------------------------------------------------------
--- Verifies the checksum of Pokemon data in memory
local function verify_checksums(data, checksum)
    local sum = 0

    for i = 0x09, 0xE8, 2 do
        sum = sum + data[i] + bit.lshift(data[i + 1], 8)
    end

    sum = bit.band(sum, 0xFFFF)

    return sum == checksum and sum ~= 0
end

--- Returns a decrypted byte table of Pokemon data from memory
function pokemon.read_data(address)
    local function rand(seed) -- Thanks Kaphotics
        return (0x4e6d * (seed % 65536) + ((0x41c6 * (seed % 65536) + 0x4e6d * math.floor(seed / 65536)) % 65536) * 65536 + 0x6073) % 4294967296
    end

    local function decrypt_block(start, finish)
        local data = {}

        for i = start, finish, 0x2 do
            local word = mword(address + i)
            seed = rand(seed)

            local rs = bit.rshift(seed, 16)
            word = bit.bxor(word, rs)
            word = bit.band(word, 0xFFFF)
            
            table.insert(data, bit.band(word, 0xFF))
            table.insert(data, bit.band(bit.rshift(word, 8), 0xFF))
        end

        return data
    end

    local function append_bytes(source)
        table.move(source, 1, #source, #data + 1, data)
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
    append_bytes({mbyte(address), mbyte(address + 1), mbyte(address + 2), mbyte(address + 3)}) -- Encryption Key
    append_bytes({mbyte(address) + 4, mbyte(address + 5)}) -- Sanity Placeholder
    append_bytes({mbyte(address + 6), mbyte(address + 7)}) -- Checksum

    -- Unencrypted bytes
    local encryption_key = mdword(address)
    local checksum = mword(address + 0x06)

    -- Find intended order of the shuffled data blocks
    local shift = bit.rshift(bit.band(encryption_key, 0x3E000), 0xD) % 24
    local block_order = substruct[shift]

    -- Decrypt blocks A,B,C,D and rearrange according to the order
    seed = encryption_key

    local _block = {}
    for index = 1, 4 do
        local block = (index - 1) * 0x38
        _block[index] = decrypt_block(0x08 + block, 0x3F + block)
    end

    for _, index in ipairs(block_order) do
        append_bytes(_block[index])
    end

    -- Re-calculate checksum of the data blocks and match it with mon.checksum
    -- If there is no match, assume the Pokemon data is garbage or still being written
    if not verify_checksums(data, checksum) then
        return nil
    end

    -- Party-only status data
    seed = encryption_key
    append_bytes(decrypt_block(0xE8, 0x103))

    return data
end

--- Parses raw Pokemon data from bytes into a human-readable table
-- All properties are included here, but ones that aren't relevant to any
-- bot modes have been commented out to keep the data simple. Customise if needed.
function pokemon.parse_data(data, enrich)
    local function read_real(start, length)
        local bytes = 0
        local j = 0

        for i = start + 1, start + length do
            bytes = bytes + bit.lshift(data[i], j * 8)
            j = j + 1
        end

        return bytes
    end

    if data == nil then
        print_warn("Tried to parse data of a non-existent Pokemon!")
        return nil
    end

    mon = {}
    mon.pid = read_real(0x00, 0x4)
    mon.checksum = read_real(0x06, 0x02)

    -- Block A
    mon.species = read_real(0x08, 2)
    mon.heldItem = read_real(0x0A, 2)
    mon.otID = read_real(0x0C, 2)
    mon.otSID = read_real(0x0E, 2)
    mon.experience = read_real(0x10, 3)
    mon.ability = read_real(0x14, 1)
    mon.pid = read_real(0x18, 4)
    mon.nature = read_real(0x1C, 1)

    local gender_byte = read_real(0x1D, 1)
    local is_female = bit.band(gender_byte, 2) > 0
    local is_genderless = bit.band(gender_byte, 4) > 0
    
    if is_female then
        mon.gender = 1
    elseif is_genderless then
        mon.gender = 2
    else
        mon.gender = 0
    end

    mon.form = bit.rshift(bit.band(gender_byte, 0xF8), 3)
    mon.hpEV = read_real(0x1E, 1)
    mon.attackEV = read_real(0x1F, 1)
    mon.defenseEV = read_real(0x20, 1)
    mon.speedEV = read_real(0x21, 1)
    mon.spAttackEV = read_real(0x22, 1)
    mon.spDefenseEV = read_real(0x23, 1)
    mon.pokerus = read_real(0x2B, 1)

    local tid = mon.otID
    local sid = mon.otSID

    if config.ot_override then
        tid = tonumber(config.tid_override)
        sid = tonumber(config.sid_override)
    end

    mon.shinyValue = bit.bxor(bit.bxor(bit.bxor(tid, sid), (bit.band(bit.rshift(mon.pid, 16), 0xFFFF))), bit.band(mon.pid, 0xFFFF))
    mon.shiny = mon.shinyValue < 8

    -- Block B
    mon.nickname = read_string(data, 0x40)
    mon.moves = {read_real(0x5A, 2), read_real(0x5C, 2), read_real(0x5E, 2), read_real(0x60, 2)}
    mon.pp = {read_real(0x62, 1), read_real(0x63, 1), read_real(0x64, 1), read_real(0x65, 1)}
    mon.otLanguage = read_real(0xE3, 1)
    
    local value = read_real(0x74, 5)
    mon.hpIV = bit.band(value, 0x1F)
    mon.attackIV = bit.band(bit.rshift(value, 5), 0x1F)
    mon.defenseIV = bit.band(bit.rshift(value, 10), 0x1F)
    mon.speedIV = bit.band(bit.rshift(value, 15), 0x1F)
    mon.spAttackIV = bit.band(bit.rshift(value, 20), 0x1F)
    mon.spDefenseIV = bit.band(bit.rshift(value, 25), 0x1F)
    mon.isEgg = bit.band(bit.rshift(value, 30), 0x01) == 1
    
    -- Block D
    mon.pokeball = read_real(0xDC, 1)
    mon.friendship = read_real(0xCA, 1)
    
    -- Battle Stats
    mon.level = read_real(0xEC, 1)
    mon.currentHP = read_real(0xF0, 2)
    mon.maxHP = read_real(0xF2, 2)
    mon.attack = read_real(0xF4, 2)
    mon.defense = read_real(0xF6, 2)
    mon.speed = read_real(0xF8, 2)
    mon.spAttack = read_real(0xFA, 2)
    mon.spDefense = read_real(0xFC, 2)

    -- Substitute property IDs with ingame names
    if enrich then
        mon.pid = string.format("%08X", mon.pid)
        mon.name = _DEX[mon.species + 1][1]
        mon.type = _DEX[mon.species + 1][2]

        -- mon.rating = pokemon.get_rating(mon)
        mon.pokeball = _ITEM[mon.pokeball + 1]
        mon.otLanguage = _LANGUAGE[mon.otLanguage + 1]
        mon.ability = _ABILITY[mon.ability + 1]
        mon.nature = _NATURE[mon.nature + 1]
        mon.heldItem = _ITEM[mon.heldItem + 1]
        mon.gender = _GENDER[mon.gender + 1]

        local move_id = mon.moves
        mon.moves = {}

        for _, move in ipairs(move_id) do
            table.insert(mon.moves, _MOVE[move + 1])
        end

        mon.ivSum = mon.hpIV + mon.attackIV + mon.defenseIV + mon.spAttackIV + mon.spDefenseIV + mon.speedIV

        local hpTypeList = {"fighting", "flying", "poison", "ground", "rock", "bug", "ghost", "steel", "fire", "water",
                            "grass", "electric", "psychic", "ice", "dragon", "dark"}
        local lsb = (mon.hpIV % 2) + (mon.attackIV % 2) * 2 + (mon.defenseIV % 2) * 4 + (mon.speedIV % 2) * 8 +
                        (mon.spAttackIV % 2) * 16 + (mon.spDefenseIV % 2) * 32
        local slsb = bit.rshift((bit.band(mon.hpIV, 2)), 1) + bit.rshift(bit.band(mon.attackIV, 2), 1) * 2 +
                         bit.rshift(bit.band(mon.defenseIV, 2), 1) * 4 + bit.rshift(bit.band(mon.speedIV, 2), 1) * 8 +
                         bit.rshift(bit.band(mon.spAttackIV, 2), 1) * 16 + bit.rshift(bit.band(mon.spDefenseIV, 2), 1) *
                         32

        mon.hpType = hpTypeList[math.floor((lsb * 15) / 63) + 1]
        mon.hpPower = math.floor((slsb * 40) / 63) + 30

        -- Keep a reference of the original data, necessary for exporting pkx
        mon.raw = data
    end

    return mon
end
