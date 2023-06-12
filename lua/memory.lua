
local mem = {}

-- Shortened RAM reading functions for convenience
function mem.readdword(addr)
	return memory.read_u32_le(addr, "Main RAM")
end

function mem.readword(addr)
	return memory.read_u16_le(addr, "Main RAM")
end

function mem.readbyte(addr)
	return memory.read_u8(addr, "Main RAM")
end

-- Identify game version
local gamecode = memory.read_u32_le(0x3FFE0C, "Main RAM") 
local game

if gamecode == 0x4F415249 then
	gamename = "Pokemon White Version (U)"
	game = 1
elseif gamecode == 0x4F425249 then
	gamename = "Pokemon Black Version (U)"
	game = 0
else
	gamename = "Unsupported Game"
	game = 0
end

------------- RAM offsets
-- White version is offset slightly
local wt = 0x20 * game

offset = {
	-- state				= 0x146A48, -- Closest address to a real "state" so far

	-- Bag pouches, 4 byte pairs | 0001 0004 = 4x Master Ball
	items_pouch			= 0x233FAC + wt, -- 1240 bytes long
	key_items_pouch		= 0x234484 + wt, -- 332 bytes long
	tms_hms_case		= 0x2345D0 + wt, -- 436 bytes long
	medicine_pouch		= 0x234784 + wt, -- 192 bytes long
	berries_pouch		= 0x234844 + wt, -- 234 bytes long
	
	-- Party
	party_count			= 0x2349B0 + wt, -- 4 bytes before first index
	party_data			= 0x2349B4 + wt,	-- PID of first party member
	
	-- Location
	map_header 			= 0x24F90C + wt,
	player_x			= 0x24F910 + wt, -- Player X, read the lower word for local X
	player_y			= 0x24F914 + wt,
	player_z			= 0x24F918 + wt,
	player_direction	= 0x24F924 + wt, -- 0, 4, 8, 12 -> Up, Left, Down, Right
	encounter_table		= 0x24FFE0 + wt,
	map_matrix			= 0x250C1C + wt,
	
	phenomena_x			= 0x25701A + wt,
	phenomena_y			= 0x25701E + wt,

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
	battle_indicator	= 0x26ACE6 + wt, -- 0x41 if during a battle
	foe_count			= 0x26ACF0 + wt, -- 4 bytes before the first index
	current_foe			= 0x26ACF4 + wt, -- PID of foe, set immediately after the battle transition ends

	-- Misc testing
	starter_box_open 	= 0x2B0C40 + wt, -- 0 when opening gift, 1 at starter select
	selected_starter 	= 0x269994 + wt, -- Unconfirmed selection in gift box; 0 Snivy, 1 Tepig, 2 Oshawott, 4 Nothing
}

return mem