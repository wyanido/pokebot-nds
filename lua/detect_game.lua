function update_pointers()
    -- Nothing here by default!
end

version = {
    DIAMOND = 0,
    PEARL = 1,
    PLATINUM = 2,
    HEARTGOLD = 3,
    SOULSILVER = 4,
    BLACK = 5,
    WHITE = 6,
    BLACK2 = 7,
    WHITE2 = 8
}

language = {
    JAPANESE = 0,
    ENGLISH = 1,
    FRENCH = 2,
    ITALIAN = 3,
    GERMAN = 4,
    SPANISH = 5,
    KOREAN = 6
}

local roms = {
    [0x0044] = {
        gen = 4,
        version = version.DIAMOND,
        region = {
            [0x4A41] = { language.JAPANESE, "ポケットモンスター　ダイヤモンド" },
            [0x4541] = { language.ENGLISH,  "Pokemon Diamond Version" },
            [0x4641] = { language.FRENCH,   "Pokemon Version Diamant" },
            [0x4941] = { language.ITALIAN,  "Pokemon Versione Diamante" },
            [0x4441] = { language.GERMAN,   "Pokemon Diamant-Edition" },
            [0x5341] = { language.SPANISH,  "Pokemon Edicion Diamente" },
        }
    },
    [0x0050] = {
        gen = 4,
        version = version.PEARL,
        region = {
            [0x4A41] = { language.JAPANESE, "ポケットモンスター　パール"},
            [0x4541] = { language.ENGLISH,  "Pokemon Pearl Version" },
            [0x4641] = { language.FRENCH,   "Pokemon Version Perle" },
            [0x4941] = { language.ITALIAN,  "Pokemon Versione Perle"},
            [0x4441] = { language.GERMAN,   "Pokemon Perl-Edition" },
            [0x5341] = { language.SPANISH,  "Pokemon Edicion Perla" },
        }
    },
    [0x4C50] = {
        gen = 4,
        version = version.PLATINUM,
        region = {
            [0x4A55] = { language.JAPANESE, "ポケットモンスター　プラチナ"},
            [0x4555] = { language.ENGLISH,  "Pokemon Platinum Version" },
            [0x4655] = { language.FRENCH,   "Pokemon Version Platine" },
            [0x4955] = { language.ITALIAN,  "Pokemon Versione Platino" },
            [0x4455] = { language.GERMAN,   "Pokemon Platin-Edition" },
            [0x5355] = { language.SPANISH,  "Pokemon Edicion Platino" },
        }
    },
    [0x4748] = {
        gen = 4,
        version = version.HEARTGOLD,
        region = {
            [0x454B] = { language.ENGLISH, "Pokemon HeartGold Version" },
        }
    },
    [0x5353] = {
        gen = 4,
        version = version.SOULSILVER,
        region = {
            [0x4547] = { language.ENGLISH, "Pokemon SoulSilver Version" },
        }
    },
    [0x0042] = {
        gen = 5,
        version = version.BLACK,
        region = {
            [0x4F42] = { language.ENGLISH, "Pokemon Black Version" }
        }
    },
    [0x0057] = {
        gen = 5,
        version = version.WHITE,
        region = {
            [0x4F41] = { language.ENGLISH , "Pokemon White Version" },
        }
    },
    [0x3242] = {
        gen = 5,
        version = version.BLACK2,
        region = {
            [0x4F45] = { language.ENGLISH, "Pokemon Black Version 2" }
        }
    },
    [0x3257] = {
        gen = 5,
        version = version.WHITE2,
        region = {
            [0x4F44] = { language.ENGLISH, "Pokemon White Version 2" }
        }
    }
}

-- Identify game version
local game = mword(0x023FFE08)
local region = mword(0x023FFE0E)

if not roms[game] or not roms[game].region[region] then
    error("Unsupported ROM (game: 0x" .. string.format("%04X", game) .. ", region: 0x" .. string.format("%04X", region) .. ")")
end

_ROM = roms[game]
_ROM.language = _ROM.region[region][1]
_ROM.name = _ROM.region[region][2]
_ROM.region = nil

print("Detected Game: " .. _ROM.name)

pointers = {}
map_names = {}
MAP_HEADER_COUNT = 0
MON_DATA_SIZE = 0

if _ROM.gen == 4 then
    dofile("lua\\methods\\gen_iv.lua")

    MON_DATA_SIZE = 236 -- Gen 4 has 16 extra trailing bytes of ball seals data

    if _ROM.version == version.HEARTGOLD or _ROM.version == version.SOULSILVER then
        -- HG/SS have no differences in map headers
        map_names = json.load("lua\\data\\maps\\hgss.json")
        MAP_HEADER_COUNT = 540 -- HGSS

        dofile("lua\\methods\\hgss.lua")
        return
    end

    map_names = json.load("lua\\data\\maps\\dppt.json")

    if _ROM.version == version.DIAMOND or _ROM.version == version.PEARL then
        -- DP uses Platinum headers with the name changes reverted
        MAP_HEADER_COUNT = 559

        map_names[29] = "GTS"
        map_names[73] = "Eterna City"
        map_names[74] = "Eterna City"
        map_names[75] = "Eterna City"
        map_names[76] = "Eterna City"
        map_names[455] = "Survival Area"
        map_names[465] = "Resort Area"
        return
    end

    -- PLATINUM
    MAP_HEADER_COUNT = 593
    dofile("lua\\methods\\pt.lua")
    return
end

-- BW
dofile("lua\\methods\\gen_v.lua")
map_names = json.load("lua\\data\\maps\\bw.json")
MON_DATA_SIZE = 220

if _ROM.version == version.BLACK or _ROM.version == version.WHITE then
    -- BW uses B2W2 headers with the name changes reverted
    map_names[58] = "Castelia City"
    map_names[192] = "Cold Storage"
    map_names[193] = "Cold Storage"
    map_names[194] = "Cold Storage"
    map_names[415] = "Undella Town"

    MAP_HEADER_COUNT = 427
    return
end

-- B2W2
MAP_HEADER_COUNT = 615
dofile("lua\\methods\\b2w2.lua")