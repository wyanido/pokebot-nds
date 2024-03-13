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
    JAPANESE = "JP",
    ENGLISH = "EN",
    FRENCH = "FR",
    ITALIAN = "IT",
    GERMAN = "DE",
    SPANISH = "ES",
    KOREAN = "KO",
}

local roms = {
    [0x0044] = {
        gen = 4,
        version = version.DIAMOND,
        name = "Pokemon Diamond Version",
        region = {
            [0x4A] = { language.JAPANESE, 0x1860 },
            [0x45] = { language.ENGLISH,  0x0 },
            [0x46] = { language.FRENCH,   0x180 },
            [0x49] = { language.ITALIAN,  0xE0 },
            [0x44] = { language.GERMAN,   0x140 },
            [0x53] = { language.SPANISH,  0x1A0 },
        }
    },
    [0x0050] = {
        gen = 4,
        version = version.PEARL,
        name = "Pokemon Pearl Version",
        region = {
            [0x4A] = { language.JAPANESE, 0x1860 },
            [0x45] = { language.ENGLISH,  0x0 },
            [0x46] = { language.FRENCH,   0x180 },
            [0x49] = { language.ITALIAN,  0xE0 },
            [0x44] = { language.GERMAN,   0x140 },
            [0x53] = { language.SPANISH,  0x1A0 },
        }
    },
    [0x4C50] = {
        gen = 4,
        version = version.PLATINUM,
        name = "Pokemon Platinum Version",
        region = {
            [0x4A] = { language.JAPANESE, -0xC00 },
            [0x45] = { language.ENGLISH,   0x0 },
            [0x46] = { language.FRENCH,    0x1E0 },
            [0x49] = { language.ITALIAN,   0x160 },
            [0x44] = { language.GERMAN,    0x1A0 },
            [0x53] = { language.SPANISH,   0x200 },
        }
    },
    [0x4748] = {
        gen = 4,
        version = version.HEARTGOLD,
        name = "Pokemon HeartGold Version",
        region = {
            [0x4A] = { language.JAPANESE, -0x3B08 },
            [0x45] = { language.ENGLISH,   0x0 },
            [0x46] = { language.FRENCH,    0x20 },
            [0x49] = { language.ITALIAN,  -0x60 },
            [0x44] = { language.GERMAN,   -0x20 },
            [0x53] = { language.SPANISH,   0x20 },
        }
    },
    [0x5353] = {
        gen = 4,
        version = version.SOULSILVER,
        name = "Pokemon SoulSilver Version",
        region = {
            [0x4A] = { language.JAPANESE, -0x3B08 },
            [0x45] = { language.ENGLISH,   0x0 },
            [0x46] = { language.FRENCH,    0x20 },
            [0x49] = { language.ITALIAN,  -0x60 },
            [0x44] = { language.GERMAN,   -0x20 },
            [0x53] = { language.SPANISH,   0x40 },
        }
    },
    [0x0042] = {
        gen = 5,
        version = version.BLACK,
        name = "Pokemon Black Version",
        region = {
            [0x4F] = { language.ENGLISH, 0x0 }
        }
    },
    [0x0057] = {
        gen = 5,
        version = version.WHITE,
        name = "Pokemon White Version",
        region = {
            [0x4F] = { language.ENGLISH , 0x0 },
        }
    },
    [0x3242] = {
        gen = 5,
        version = version.BLACK2,
        name = "Pokemon Black Version 2",
        region = {
            [0x4F] = { language.ENGLISH, 0x0 }
        }
    },
    [0x3257] = {
        gen = 5,
        version = version.WHITE2,
        name = "Pokemon White Version 2",
        region = {
            [0x4F] = { language.ENGLISH, 0x0 }
        }
    }
}

-- Identify game version
local game = mword(0x023FFE08)
local region = mbyte(0x023FFE0F)

if not roms[game] or not roms[game].region[region] then
    error("Unsupported ROM (game: 0x" .. string.format("%04X", game) .. ", region: 0x" .. string.format("%04X", region) .. ")")
end

_ROM = roms[game]
_ROM.language = _ROM.region[region][1]
_ROM.mem_shift = _ROM.region[region][2]
_ROM.region = nil

print("Detected Game: " .. _ROM.name .. " (" .. _ROM.language .. ")")

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