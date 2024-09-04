local function get_game_code()
    local byte1 = mbyte(0x023FFE08)
    local byte2 = mbyte(0x023FFE09)

    if byte2 == 0 then
        return utf8.char(byte1) -- Don't return null character for single-letter codes
    else
        return utf8.char(byte1, byte2)
    end
end

local function get_language_code()
    local byte = mbyte(0x023FFE0F)
    local languages = {
        [0x4A] = "JP",
        [0x45] = "EN", -- Gen 4
        [0x4F] = "EN", -- Gen 5
        [0x46] = "FR",
        [0x49] = "IT",
        [0x44] = "DE",
        [0x53] = "ES"
    }

    return languages[byte]
end

local games = {
    ["D"] = {
        gen = 4,
        offset = {
            ["JP"] = 0x1860,
            ["EN"] = 0x0,
            ["FR"] = 0x180,
            ["IT"] = 0xE0,
            ["DE"] = 0x140,
            ["ES"] = 0x1A0
        }
    },
    ["P"] = {
        gen = 4,
        offset = {
            ["JP"] = 0x1860,
            ["EN"] = 0x0,
            ["FR"] = 0x180,
            ["IT"] = 0xE0,
            ["DE"] = 0x140,
            ["ES"] = 0x1A0
        }
    },
    ["PL"] = {
        gen = 4,
        offset = {
            ["JP"] = -0xC00,
            ["EN"] = 0x0,
            ["FR"] = 0x1E0,
            ["IT"] = 0x160,
            ["DE"] = 0x1A0,
            ["ES"] = 0x200
        }
    },
    ["HG"] = {
        gen = 4,
        offset = {
            ["JP"] = -0x3B08,
            ["EN"] = 0x0,
            ["FR"] = 0x20,
            ["IT"] = -0x60,
            ["DE"] = -0x20,
            ["ES"] = 0x20
        }
    },
    ["SS"] = {
        gen = 4,
        offset = {
            ["JP"] = -0x3B08,
            ["EN"] = 0x0,
            ["FR"] = 0x20,
            ["IT"] = -0x60,
            ["DE"] = -0x20,
            ["ES"] = 0x40
        }
    },
    ["B"] = {
        gen = 5,
        offset = {
            ["JP"] = -0x1A0,
            ["EN"] = 0x0,
            ["FR"] = -0x80,
            ["IT"] = -0x100,
            ["DE"] = -0xC0,
            ["ES"] = -0x40
        }
    },
    ["W"] = {
        gen = 5,
        offset = {
            ["JP"] = -0x180,
            ["EN"] = 0x20,
            ["FR"] = -0x60,
            ["IT"] = -0xE0,
            ["DE"] = -0xA0,
            ["ES"] = -0x40
        }
    },
    ["B2"] = {
        gen = 5,
        offset = {
            ["JP"] = -0x660,
            ["EN"] = 0x0,
            ["FR"] = 0x20,
            ["IT"] = -0x100,
            ["DE"] = -0xC0,
            ["ES"] = -0x40
        }
    },
    ["W2"] = {
        gen = 5,
        offset = {
            ["JP"] = -0x640,
            ["EN"] = 0x40,
            ["FR"] = 0x40,
            ["IT"] = -0xE0,
            ["DE"] = -0xA0,
            ["ES"] = -0x20
        }
    }
}

-- Identify game version
local game_code = get_game_code()
local language_code = get_language_code()

if not game_code or not games[game_code] or not language_code or not games[game_code].offset[language_code] then
    error("Unsupported Game: " .. game_code .. " (" .. language_code .. ")")
end

_ROM = games[game_code]
_ROM.offset = _ROM.offset[language_code]
_ROM.version = game_code

print("Detected Game: " .. game_code .. " (" .. language_code .. ")")

dofile("lua\\methods\\global.lua")

if _ROM.gen == 4 then
    dofile("lua\\methods\\gen_iv.lua")
    _MON_BYTE_LENGTH = 236 -- Gen 4 has 16 extra trailing bytes of ball seals data
    
    if _ROM.version == "HG" or _ROM.version == "SS" then
        dofile("lua\\data\\maps\\hgss.lua")
        dofile("lua\\methods\\hgss.lua")
    else
        dofile("lua\\data\\maps\\gen_iv.lua")
        
        if _ROM.version == "PL" then
            dofile("lua\\methods\\pt.lua")
        end
    end
else
    dofile("lua\\methods\\gen_v.lua")
    dofile("lua\\data\\maps\\gen_v.lua")
    _MON_BYTE_LENGTH = 220

    if _ROM.version == "B2" or _ROM.version == "W2" then
        dofile("lua\\methods\\b2w2.lua")
    end
end