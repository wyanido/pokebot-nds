-----------------------------------------------------------------------------
-- Game detection and bot method setup
-- Author: wyanido
-- Homepage: https://github.com/wyanido/pokebot-nds
-----------------------------------------------------------------------------

--- The list of games that can be detected by the bot.
-- The 'offset' represents the position difference in pointers
-- relative to the English language version of each game
local RECOGNISED_GAMES = {
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

--- Returns the current game version as a short, readable string, e.g. B, W, B2, W2
local function get_game_code()
    local gamecode_addr = 0x23FFE08
    local byte1 = mbyte(gamecode_addr)
    local byte2 = mbyte(gamecode_addr + 1)

    if byte2 == 0 then
        return utf8.char(byte1) -- Single-letter codes
    else
        return utf8.char(byte1, byte2)
    end
end

--- Returns the current game's language as a readable string
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

--- Attempts to match the loaded game with one in the RECOGNISED_GAMES list
local function identify_game()
    -- Identify 3DS titles
    if _EMU == "BizHawk" then
        if memory.getcurrentmemorydomainsize() >= 200000000 then
            local game_code = mdword(0x74CD340)

            -- Temporary
            local version = game_code == 0x55E00 and "Y" or "X"
            return {version = version, offset = 0, gen = 6}
        end
    end

    local game_code = get_game_code()
    local language_code = get_language_code()
    local game_is_recognised = not (not game_code or not RECOGNISED_GAMES[game_code] or not language_code or not RECOGNISED_GAMES[game_code].offset[language_code])
    
    if not game_is_recognised then
        error("Unsupported Game: " .. game_code .. " (" .. language_code .. ")")
    end

    print("Detected Game: " .. game_code .. " (" .. language_code .. ")")
    
    local rom = RECOGNISED_GAMES[game_code]
    rom.offset = rom.offset[language_code]
    rom.version = game_code

    return rom
end

-----------------------------------------------------------------------------
-- BOT MODES INITIALISATION
-----------------------------------------------------------------------------
_ROM = identify_game()

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
elseif _ROM.gen == 5 then
    dofile("lua\\methods\\gen_v.lua")
    dofile("lua\\data\\maps\\gen_v.lua")
    _MON_BYTE_LENGTH = 220

    if _ROM.version == "B2" or _ROM.version == "W2" then
        dofile("lua\\methods\\b2w2.lua")
    end
else
    _MON_BYTE_LENGTH = 232 + 28

    dofile("lua\\data\\maps\\gen_vi.lua")
    dofile("lua\\methods\\gen_vi.lua")
end