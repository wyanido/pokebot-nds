function update_pointers()
    -- Nothing here by default!
end

local function get_offset_bw(game)
    local wt = 0x20 and (game_version == version.WHITE) or 0x0 -- White version is offset slightly

    return {
        -- Bag pouches, 4 byte pairs | 0001 0004 = 4x Master Ball
        items_pouch = 0x02233FAC + wt, -- 1240 bytes long
        key_items_pouch = 0x02234484 + wt, -- 332 bytes long
        tms_hms_case = 0x022345D0 + wt, -- 436 bytes long
        medicine_pouch = 0x02234784 + wt, -- 192 bytes long
        berries_pouch = 0x02234844 + wt, -- 234 bytes long

        running_shoes = 0x0223C054 + wt, -- 0 before receiving

        -- Party
        party_count = 0x022349B0 + wt, -- 4 bytes before first index
        party_data = 0x022349B4 + wt, -- PID of first party member

        step_counter = 0x02235125 + wt,
        step_cycle = 0x02235126 + wt,

        -- Location
        map_header = 0x0224F90C + wt,
        -- trainer_name		= 0x24FC00 + wt,
        -- Read the lower word for map-local coordinates
        trainer_x = 0x0224F910 + wt,
        trainer_y = 0x0224F914 + wt,
        trainer_z = 0x0224F918 + wt,
        trainer_direction = 0x0224F924 + wt, -- 0, 4, 8, 12 -> Up, Left, Down, Right
        on_bike = 0x0224F94C + wt,
        encounter_table = 0x0224FFE0 + wt,
        map_matrix = 0x02250C1C + wt,

        phenomenon_x = 0x02257018 + wt,
        phenomenon_z = 0x0225701C + wt,

        egg_hatching = 0x0226DF68 + wt,

        -- Map tile data
        -- 0x2000 bytes, 8 32x32 layers that can be in any order
        -- utilised layers prefixed with 0x20, unused 0x00
        -- layer order is not consistent, is specified by the byte above 0x20 flag
        -- C0 = Collision (Movement)
        -- 80 = Flags

        -- instances separated by 0x1B4D0 bytes
        -- nuvema_1 	= 0x2C4670, -- when exiting cheren's house
        -- nuvema_2		= 0x2DFB38, -- when exiting bianca's house
        -- nuvema_3 	= 0x2FB008, -- when loaded normally
        -- nuvema_4 	= 0x3164D0, -- when exiting home or juniper's lab or flying

        -- Battle
        battle_indicator = 0x0226ACE6 + wt, -- 0x41 if during a battle
        foe_count = 0x0226ACF0 + wt, -- 4 bytes before the first index
        current_foe = 0x0226ACF4 + wt, -- PID of foe, set immediately after the battle transition ends

        -- Misc
        save_indicator = 0x021F0100 + wt, -- 1 while save menu is open
        starter_selection_is_open = 0x022B0C40 + wt, -- 0 when opening gift, 1 at starter select
        battle_menu_state = 0x022D6B04 + wt, -- 1 on FIGHT menu, 2 on move select, 4 on switch/run after faint, 0 otherwise
        battle_bag_page = 0x022962C8 + wt,
        selected_starter = 0x02269994 + wt, -- Unconfirmed selection in gift box; 0 Snivy, 1 Tepig, 2 Oshawott, 4 Nothing
        
        fishing_bite_indicator = 0x20A8362 + wt,
        fishing_no_bite = 0x21509DB + wt,
    }
end

local function get_offset_b2w2(game)
    local wt = 0x40 and (game_version == version.WHITE) or 0x0 -- White version is offset slightly, moreso than original BW

    return {
        -- Bag pouches, 4 byte pairs | 0001 0004 = 4x Master Ball
        items_pouch = 0x0221D9E4 + wt, -- 1240 bytes long
        key_items_pouch = 0x0221DEBC + wt, -- 332 bytes long
        tms_hms_case = 0x0221E008 + wt, -- 436 bytes long
        medicine_pouch = 0x0221E1BC + wt, -- 192 bytes long
        berries_pouch = 0x0221E27C + wt, -- 234 bytes long

        running_shoes = 0x0221DEC5 + wt, -- 0 before receiving

        -- Party
        party_count = 0x0221E3E8 + wt, -- 4 bytes before first index
        party_data = 0x0221E3EC + wt, -- PID of first party member

        step_counter = 0x0221EB5D + wt,
        step_cycle = 0x0221EB5E + wt,

        -- Location
        map_header = 0x0223B444 + wt,
        -- trainer_name		= 0x2 + wt,
        -- Read the lower word for map-local coordinates
        trainer_x = 0x0223B448 + wt,
        trainer_y = 0x0223B44C + wt,
        trainer_z = 0x0223B450 + wt,
        trainer_direction = 0x0223B462 + wt, -- 0, 4, 8, 12 -> Up, Left, Down, Right
        on_bike = 0x0223B484 + wt,
        encounter_table = 0x0223B7B8 + wt,
        map_matrix = 0x0223C3D4 + wt,

        phenomenon_x = 0x022427E8 + wt,
        phenomenon_z = 0x022427EC + wt,

        egg_hatching = 0x0225BB50 + wt,

        -- Battle
        battle_indicator = 0x02258D86 + wt, -- 0x41 if during a battle
        foe_count = 0x02258D90 + wt, -- 4 bytes before the first index
        current_foe = 0x02258D94 + wt, -- PID of foe, set immediately after the battle transition ends

        -- Misc
        save_indicator = 0x0223B4F0 + wt, -- 1 while save menu is open
        starter_selection_is_open = 0x0219CFE2 + wt, -- 0 when opening gift, 1 at starter select
        battle_bag_page = 0x022845FC + wt,
        selected_starter = 0x022574C4 + wt, -- Unconfirmed selection in gift box; 0 Snivy, 1 Tepig, 2 Oshawott, 4 Nothing
        text_interrupt = 0x216E640 + wt, -- 2 when a repel/fishing dialogue box is open, 0 otherwise
        fishing_bite_indicator = 0x209B3CA + wt,
        fishing_no_bite = 0x214BC62 + wt,

        -- NON STATIC ADDRESS
        -- this gets overwritten by update_pointers() to
        -- ensure it stays correct during gameplay
        battle_menu_state = 0x02 + wt, -- 1 on FIGHT menu, 2 on move select, 4 on switch/run after faint, 0 otherwise
    }
end

version = {
    DIAMOND    = 0,
    PEARL      = 1,
    PLATINUM   = 2,
    HEARTGOLD  = 3,
    SOULSILVER = 4,
    BLACK      = 5,
    WHITE      = 6,
    BLACK2     = 7,
    WHITE2     = 8
}

lang = {
    JAPANESE = 0, 
    ENGLISH  = 1, 
    FRENCH   = 2, 
    ITALIAN  = 3, 
    GERMAN   = 4, 
    SPANISH  = 5, 
    KOREAN   = 6
}

-- Version data
local ver = {
    DIAMOND_U = {
        code = 0x45414441,
        name = "Pokemon Diamond Version",
        gen = 4,
        version = version.DIAMOND,
        language = lang.ENGLISH
    },
    DIAMOND_G = {
        code = 0x44414441,
        name = "Pokemon Diamant Edition",
        gen = 4,
        version = version.DIAMOND,
        language = lang.GERMAN
    },
    PEARL_U = {
        code = 0x45415041,
        name = "Pokemon Pearl Version",
        gen = 4,
        version = version.PEARL,
        language = lang.ENGLISH
    },
    PLATINUM_U = {
        code = 0x45555043,
        name = "Pokemon Platinum Version",
        gen = 4,
        version = version.PLATINUM,
        language = lang.ENGLISH
    },
    HEARTGOLD_U = {
        code = 0x454B5049,
        name = "Pokemon HeartGold Version",
        gen = 4,
        version = version.HEARTGOLD,
        language = lang.ENGLISH
    },
    SOULSILVER_U = {
        code = 0x45475049,
        name = "Pokemon SoulSilver Version",
        gen = 4,
        version = version.SOULSILVER,
        language = lang.ENGLISH
    },
    BLACK_U = {
        code = 0x4F425249,
        name = "Pokemon Black Version",
        gen = 5,
        version = version.BLACK,
        language = lang.ENGLISH
    },
    WHITE_U = {
        code = 0x4F415249,
        name = "Pokemon White Version",
        gen = 5,
        version = version.WHITE,
        language = lang.ENGLISH
    },
    BLACK2_U = {
        code = 0x4F455249,
        name = "Pokemon Black Version 2",
        gen = 5,
        version = version.BLACK2,
        language = lang.ENGLISH
    },
    WHITE2_U = {
        code = 0x4F445249,
        name = "Pokemon White Version 2",
        gen = 5,
        version = version.WHITE2,
        language = lang.ENGLISH
    }
}

-- Identify game version
local gamecode = mdword(0x023FFE0C)

for k, _ in pairs(ver) do
    if gamecode == ver[k].code then
        game_name = ver[k].name
        game_version = ver[k].version
        gen = ver[k].gen
        language = ver[k].language
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
    offset = {} -- Most Gen 4 offsets are non-static, so these are set each frame through update_pointers()
    dofile("lua\\methods\\gen_iv.lua")

    if game_version == version.HEARTGOLD or game_version == version.SOULSILVER then
        -- HG/SS have no differences in map headers
        map_names = json.load("lua\\data\\maps\\hgss.json")
        MAP_HEADER_COUNT = 540 -- HGSS

        dofile("lua\\methods\\hgss.lua")
    else
        map_names = json.load("lua\\data\\maps\\dppt.json")
        MAP_HEADER_COUNT = 593 -- Pt

        -- DP uses Platinum headers with the name changes reverted
        if game_version == version.DIAMOND or game_version == version.PEARL then
            MAP_HEADER_COUNT = 559 -- DP

            map_names[29] = "GTS"
            map_names[73] = "Eterna City"
            map_names[74] = "Eterna City"
            map_names[75] = "Eterna City"
            map_names[76] = "Eterna City"
            map_names[455] = "Survival Area"
            map_names[465] = "Resort Area"
        else
            dofile("lua\\methods\\pt.lua")
        end
    end

    MON_DATA_SIZE = 236 -- Gen 4 has 16 extra trailing bytes of ball seals data

elseif gen == 5 then
    dofile("lua\\methods\\gen_v.lua") -- Define Gen V functions

    map_names = json.load("lua\\data\\maps\\bw.json")
    MAP_HEADER_COUNT = 615 -- B2W2

    -- BW uses B2W2 headers with the name changes reverted
    if game_version == version.BLACK or game_version == version.WHITE then
        map_names[58] = "Castelia City"
        map_names[192] = "Cold Storage"
        map_names[193] = "Cold Storage"
        map_names[194] = "Cold Storage"
        map_names[415] = "Undella Town"

        MAP_HEADER_COUNT = 427
        offset = get_offset_bw(game_version)
    else
        -- B2W2 uses BW methods with a few overrides to match game changes
        dofile("lua\\methods\\b2w2.lua")
        offset = get_offset_b2w2(game_version)
    end

    MON_DATA_SIZE = 220
end
