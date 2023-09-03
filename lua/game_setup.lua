function update_pointers()
    -- Nothing here by default!
end

function to_signed(unsigned)
    return (unsigned + 32768) % 65536 - 32768
end

local function get_blank_offsets()
    return {
        party_count = 0x0,
        party_data = 0x0,
        map_header = 0x0,
        trainer_x = 0x0,
        trainer_y = 0x0,
        trainer_z = 0x0,
        on_bike = 0x0,
        encounter_table = 0x0,
        map_matrix = 0x0,
        battle_indicator = 0x0,
        foe_count = 0x0,
        current_foe = 0x0
    }
end

local function get_offset_dp(game)
    local offset = get_blank_offsets()

    offset.battle_indicator = 0x021A1B2A

    offset.starters_ready = 0x022AFE14   -- 0 before hand appears, random number afterwards
    offset.selected_starter = 0x022AFD90 -- 0: Turtwig, 1: Chimchar, 2: Piplup

    return offset
end

local function get_offset_hgss(game)
    local offset = get_blank_offsets()

    offset.battle_indicator = 0x021E76D2

    return offset
end

local function get_offset_pt()
    local offset = get_blank_offsets()

    offset.battle_indicator = 0x021D18F2

    --offset.selected_starter = mdword(0x2101DEC) + 0x203E8
    --offset.starters_ready = offset.selected_starter + 0x84
    --offset.battle_menu_state = mbyte(0x21C0794) + 0x44878
    --offset.battle_menu_state = 0x0236F793 -- 1 on FIGHT menu (sometimes 0), 2 on move select, 4 on switch/run after faint, 0 otherwise --2E FIGHT MENU, 2F move select BB on switch/run after fainted

    return offset
end


-- Version data
local ver = {
    DIAMOND_U = {
        code = 0x45414441,
        name = "Pokemon Diamond Version (U)",
        gen = 4,
        version = 0
    },
    PEARL_U = {
        code = 0x45415041,
        name = "Pokemon Pearl Version (U)",
        gen = 4,
        version = 1
    },
    PLATINUM_U = {
        code = 0x45555043,
        name = "Pokemon Platinum Version (U)",
        gen = 4,
        version = 2
    },
    HEARTGOLD_U = {
        code = 0x454B5049,
        name = "Pokemon HeartGold Version (U)",
        gen = 4,
        version = 0
    },
    SOULSILVER_U = {
        code = 0x45475049,
        name = "Pokemon SoulSilver Version (U)",
        gen = 4,
        version = 1
    }
}

-- Identify game version
local gamecode = mdword(0x023FFE0C)

for k, _ in pairs(ver) do
    if gamecode == ver[k].code then
        game_name = ver[k].name
        game_version = ver[k].version
        gen = ver[k].gen
        break
    end
end

if not gen then
    console.log("Unsupported Game or Region")

    while true do
        emu.frameadvance()
    end
end

console.log("Detected Game: " .. game_name)

local game_status = gameinfo.getstatus()

if game_status == "BadDump" then
    console.warning(
        "Your copy of this game is a bad dump, and as such, pokebot-nds may not function correctly. It is heavily recommended that you replace it with a better copy.")
elseif game_status == "Hack" then
    console.warning(
        "You are playing a modified version of this game. The memory addresses of ROM hacks will not always line up with the base game, and will likely cause issues.")
end

-- Index game-specific map headers
if gen == 4 then
    dofile("lua\\methods_gen_iv.lua") -- Define Gen IV functions

    if gamecode == ver.HEARTGOLD_U.code or gamecode == ver.SOULSILVER_U.code then
        -- HG/SS have no differences in map headers
        map_names = json.load("lua\\data\\maps_hgss.json")
        MAP_HEADER_COUNT = 540 -- HGSS

        offset = get_offset_hgss()
        dofile("lua\\methods_hgss.lua")
    else
        map_names = json.load("lua\\data\\maps_dppt.json")
        MAP_HEADER_COUNT = 593 -- Pt

        -- DP uses Platinum headers with the name changes reverted
        if gamecode == ver.DIAMOND_U.code or gamecode == ver.PEARL_U.code then
            MAP_HEADER_COUNT = 559 -- DP

            map_names[29] = "GTS"
            map_names[73] = "Eterna City"
            map_names[74] = "Eterna City"
            map_names[75] = "Eterna City"
            map_names[76] = "Eterna City"
            map_names[455] = "Survival Area"
            map_names[465] = "Resort Area"

            offset = get_offset_dp()
        else
            dofile("lua\\methods_platinum.lua")
            offset = get_offset_pt()
        end
    end

    MON_DATA_SIZE = 236 -- Gen 4 has 16 extra trailing bytes of ball seals data
end
