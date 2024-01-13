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
    [0x45414441] = {
        name = "Pokemon Diamond Version",
        gen = 4,
        version = version.DIAMOND,
        language = language.ENGLISH
    },
    [0x44414441] = {
        name = "Pokemon Diamant Edition",
        gen = 4,
        version = version.DIAMOND,
        language = language.GERMAN
    },
    [0x45415041] = {
        name = "Pokemon Pearl Version",
        gen = 4,
        version = version.PEARL,
        language = language.ENGLISH
    },
    [0x45555043] = {
        name = "Pokemon Platinum Version",
        gen = 4,
        version = version.PLATINUM,
        language = language.ENGLISH
    },
    [0x454B5049] = {
        name = "Pokemon HeartGold Version",
        gen = 4,
        version = version.HEARTGOLD,
        language = language.ENGLISH
    },
    [0x45475049] = {
        name = "Pokemon SoulSilver Version",
        gen = 4,
        version = version.SOULSILVER,
        language = language.ENGLISH
    },
    [0x4F425249] = {
        name = "Pokemon Black Version",
        gen = 5,
        version = version.BLACK,
        language = language.ENGLISH
    },
    [0x4F415249] = {
        name = "Pokemon White Version",
        gen = 5,
        version = version.WHITE,
        language = language.ENGLISH
    },
    [0x4F455249] = {
        name = "Pokemon Black Version 2",
        gen = 5,
        version = version.BLACK2,
        language = language.ENGLISH
    },
    [0x4F445249] = {
        name = "Pokemon White Version 2",
        gen = 5,
        version = version.WHITE2,
        language = language.ENGLISH
    }
}

-- Identify game version
local gamecode = mdword(0x023FFE0C)

_ROM = roms[gamecode]

if not _ROM then
    console.log("Unsupported Game or Region")

    while true do
        emu.frameadvance()
    end
end

console.log("Detected Game: " .. _ROM.name)

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