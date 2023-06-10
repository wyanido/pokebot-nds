-- constants
FRAMES_PER_INPUT = 5
FRAMES_PER_MMAP_WRITE = 5
MON_DATA_SIZE = 220

DEBUG_DISABLE_INPUT_HOOK = false
DEBUG_DISABLE_OUTPUT = true

offsets = {
	in_battle			= 0x140520, -- 1 or 0
	state				= 0x146A48, -- Closest address to a real "state" so far

	-- Bag pouches, 4 byte pairs | 0001 0004 = 4x Master Ball
	items_pouch			= 0x233FAC, -- 1240 bytes long
	key_items_pouch		= 0x234484, -- 332 bytes long
	tms_hms_case		= 0x2345D0, -- 436 bytes long
	medicine_pouch		= 0x234784, -- 192 bytes long
	berries_pouch		= 0x234844, -- 234 bytes long

	-- Party
	party_count			= 0x2349B0, -- 4 bytes before first index
	party_data			= 0x2349B4,	-- PID of first party member

	-- Location
	map_header 			= 0x24F90C,
	player_x			= 0x24F910,
	player_y			= 0x24F914,
	player_z			= 0x24F918,
	player_direction	= 0x24F924, -- 0, 4, 8, 12 -> Up, Left, Down, Right
	map_matrix			= 0x250C1C,

	-- Battle
	battle_indicator	= 0x26ACE6, -- 0x41 if during a battle
	opponent_count		= 0x26ACF0, -- 4 bytes before the first index
	current_opponent	= 0x26ACF4,	-- PID of opponent, set immediately after the battle transition ends
	-- battle_type			= 0x270FD0, -- Random address, changes a lot. Stays 1 during a wild battle or 0 during a trainer battle.
	opponents_ready		= 0x2E4A80, -- Random address, changes a lot. Stays on 1 once foe data is safe to read

	-- Misc testing
	entity_positions 	= 0x252220, -- List of positions for every entity in the current map
	-- warp_target 		= 0x2592CC,
	starter_box_open 	= 0x2B0C40, -- 0 when opening gift, 1 at starter select
	hovered_starter 	= 0x269994,	-- Unconfirmed selection in gift box; 0 Snivy, 1 Tepig, 2 Oshawott, 4 Nothing
	map_transition		= 0x216110  -- 1 during a transition, 0 otherwise
}

last_battle_state = 0

dofile "lua\\RAM.lua"

json = require "lua\\json"

function mainLoop()
	-- General game data
	data = {
		trainer = getTrainer(),
		game_state = getGameState(),
		emu_fps = client.get_approx_framerate()
	}

	opponent = getOpponent()
	if opponent ~= nil then
		data["opponent"] = opponent
	end

	comm.mmfWrite("bizhawk_game_info", json.encode(data) .. "\x00")

	-- Party mon
	data = {
		party_count = RAM.readbyte(offsets.party_count),
		party = getParty()
	}

	comm.mmfWrite("bizhawk_party_info", json.encode(data) .. "\x00")
end

g_current_index = 0

function getParty()
	party = {}

	party_size = RAM.readbyte(offsets.party_count)

	for i = 0, party_size - 1 do
		mon = readMonData(offsets.party_data + i * MON_DATA_SIZE)
		table.insert(party, mon)
	end

	return party
end

function getOpponent()
	-- Make sure it's not reading garbage non-battle data
	if RAM.readbyte(offsets.battle_indicator) ~= 0x41 or RAM.readbyte(offsets.opponent_count) == 0 then
		return nil
	else
		foes = {}

		foe_count = RAM.readbyte(offsets.opponent_count)

		for i = 0, foe_count - 1 do
			mon = readMonData(offsets.current_opponent + i * MON_DATA_SIZE)
			table.insert(foes, mon)
		end

		return foes
	end
end

-- Misc. data relevant to certain events
function getGameState()
	local game_state

	game_state = {
		selected_starter = memory.read_u8(offsets.hovered_starter, "Main RAM"),
		starter_box_open = memory.read_u8(offsets.starter_box_open, "Main RAM"),
		state = memory.read_u8(offsets.state, "Main RAM"),
		in_battle = RAM.readbyte(offsets.battle_indicator) == 0x41 and RAM.readbyte(offsets.opponent_count) > 0
	}

	return game_state
end

function getTrainer()
	local trainer
	
	trainer = {
		map_header = RAM.readword(offsets.map_header),
		map_matrix = RAM.readdword(offsets.map_matrix),
		posX = RAM.readdword(offsets.player_x),
		posY = RAM.readdword(offsets.player_y),
		posZ = RAM.readdword(offsets.player_z),
		facing = RAM.readdword(offsets.player_direction)
	}
	
	return trainer
end

function poll_TouchScreen()
	local pcall_result, touchscreen = pcall(comm.mmfRead,"bizhawk_touchscreen", 1024)

	if pcall_result == false then
		gui.addmessage("pcall fail list")
		return false
	end

	-- Split at comma
	x, y = touchscreen:match("([^,]+),([^,]+)")

	if x ~= nil and y ~= nil then
	 	joypad.setanalog({['Touch X'] = x, ['Touch Y'] = y})
	end
end

function traverseNewInputs()
	local pcall_result, input_list = pcall(comm.mmfRead,"bizhawk_input_list", 4096)

	if pcall_result == false then
		gui.addmessage("pcall fail list")
		return false
	end

	local current_index = g_current_index
	python_current_index = input_list:byte(101)

	while current_index ~= python_current_index do
		current_index = current_index + 1

		if current_index > 100 then
			current_index = 0
		end

		button = utf8.char(input_list:byte(current_index))

		if button then
			-- A, B, X, and Y are all identical in their byte form
	  	if button == "U" then button = "Up"
	  	elseif button == "D" then button = "Down"
	  	elseif button == "L" then button = "Left"
	  	elseif button == "R" then button = "Right"
	  	elseif button == "S" then button = "Start"
	  	elseif button == "s" then button = "Select"
	  	elseif button == "l" then button = "L"
	  	elseif button == "r" then button = "R"
	  	elseif button == "P" then button = "Power"
	  	elseif button == "T" then button = "Touch"
	  	end

	  	if input[button] ~= nil then
				input[button] = true
			end
		end
	end

	g_current_index = current_index
	joypad.set(input)
end

function clearUnheldInputs()
	for k, v in pairs(input) do
		if k ~= "Touch X" and k ~= "Touch Y" then
	  	input[k] = false
	  end
	end

	joypad.set(input)
end

function readMonData(address)
	function rand(seed)
		return (0x41C64E6D * seed) + 0x00006073
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

	local substructSelector = require("lua\\substructSelector")

	mon = {}

	-- Unencrypted bytes
	mon.pid 		= RAM.readdword(address)
	mon.checksum 	= RAM.readword(address + 0x06)
	
	-- Encrypted Blocks
	block = { {}, {}, {}, {} }
	
	seed = mon.checksum

	-- 128 byte block data is decrypted in 2 byte pairs
	for i = 0x08, 0x87, 2 do
	    local word = memory.read_u16_le(address + i, "Main RAM")

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
	mon.species 			= blockData(0x08, 2)
	mon.heldItem 			= blockData(0x0A, 2)
	mon.otID 				= blockData(0x0C, 2)
	mon.otSID 				= blockData(0x0E, 2)
	mon.experience 			= blockData(0x10, 3)
	mon.friendship 			= blockData(0x14, 1)
	mon.ability 			= blockData(0x15, 1)
	-- mon.markings 			= blockData(0x16, 1)
	mon.otLanguage 			= blockData(0x17, 1)
	mon.hpEV 				= blockData(0x18, 1)
	mon.attackEV 			= blockData(0x19, 1)
	mon.defenseEV 			= blockData(0x1A, 1)
	mon.speedEV 			= blockData(0x1B, 1)
	mon.spAttackEV 			= blockData(0x1C, 1)
	mon.spDefenseEV 		= blockData(0x1D, 1)
	-- mon.cool 				= blockData(0x1E, 1)
	-- mon.beauty 				= blockData(0x1F, 1)
	-- mon.cute 				= blockData(0x20, 1)
	-- mon.smart 				= blockData(0x21, 1)
	-- mon.tough 				= blockData(0x22, 1)
	-- mon.sheen 				= blockData(0x23, 1)
	-- mon.sinnohRibbonSet1 	= blockData(0x24, 2)
	-- mon.unovaRibbonSet 		= blockData(0x26, 2)

	-- Block B
	mon.moves = {
		blockData(0x28, 2),
		blockData(0x2A, 2),
		blockData(0x2C, 2),
		blockData(0x2E, 2)
	}
	
	mon.pp = {
		blockData(0x30, 1),
		blockData(0x31, 1),
		blockData(0x32, 1),
		blockData(0x33, 1)
	}
	
	mon.ppUps				= blockData(0x34, 4)
	
	local data = blockData(0x38, 5)
	mon.hpIV				= (data >>  0) & 0x1F
	mon.attackIV 			= (data >>  5) & 0x1F
	mon.defenseIV 			= (data >> 10) & 0x1F
	mon.speedIV 			= (data >> 15) & 0x1F
	mon.spAttackIV 			= (data >> 20) & 0x1F
	mon.spDefenseIV			= (data >> 25) & 0x1F
	mon.isEgg				= (data >> 30) & 0x01
	mon.isNicknamed			= (data >> 31) & 0x01

	-- mon.hoennRibbonSet1		= blockData(0x3C, 2)
	-- mon.hoennRibbonSet2		= blockData(0x3E, 2)

	local data = blockData(0x40, 1)
	-- mon.fatefulEncounter 	= (data >> 0) & 0x01
	mon.gender 				= (data >> 1) & 0x03
	mon.altForm				= (data >> 3) & 0x1F

	mon.nature				= blockData(0x41, 1)

	local data = blockData(0x42, 1)
	mon.dreamWorldAbility	= data & 0x01
	mon.isNsPokemon			= data & 0x02

	-- Block C
	mon.nickname 			= blockDataString(0x48, 21)

	-- mon.originGame			= blockData(0x5F, 1)
	-- mon.sinnohRibbonSet3	= blockData(0x60, 2)
	-- mon.sinnohRibbonSet3	= blockData(0x62, 2)
	
	-- Block D
	mon.otName 				= blockDataString(0x68, 16)
	-- mon.dateEggReceived		= blockData(0x78, 3)
	-- mon.dateMet				= blockData(0x7B, 3)
	-- mon.eggLocation			= blockData(0x7E, 2)
	-- mon.metLocation			= blockData(0x80, 2)
	mon.pokerus				= blockData(0x82, 1)
	mon.pokeball			= blockData(0x83, 1)
	-- mon.encounterType		= blockData(0x85, 1)

	-- Battle stats
	battleStats = {}
	seed = mon.pid
	
	-- Battle stats are also encrypted in 2-byte pairs
	-- # TODO combine both decryption loops into a single method
	for i = 0x88, 0xDB, 2 do
	    local word = memory.read_u16_le(address + i, "Main RAM")

	    seed = rand(seed)
	    local decryptedByte = word ~ (seed >> 16)
	    local endBytes = decryptedByte & 0xFFFF

	    -- Insert the two end bytes as single bytes
	    table.insert(battleStats, endBytes & 0xFF)
	    table.insert(battleStats, (endBytes >> 8) & 0xFF)
	end

	mon.status				= battleData(0x88, 1)
	mon.level				= battleData(0x8C, 1)
	-- mon.capsuleIndex		= battleData(0x8D, 1)
	mon.currentHP			= battleData(0x8E, 2)
	mon.maxHP				= battleData(0x90, 2)
	mon.attack				= battleData(0x92, 2)
	mon.defense				= battleData(0x94, 2)
	mon.speed				= battleData(0x96, 2)
	mon.spAttack			= battleData(0x98, 2)
	mon.spDefense			= battleData(0x9A, 2)
	-- mon.mailMessage			= battleData(0x9C, 37)

	mon.shinyValue 			= mon.otID ~ mon.otSID ~ ((mon.pid >> 16) & 0xFFFF) ~ (mon.pid & 0xFFFF)

	return mon
end

-- Setup
if not DEBUG_DISABLE_INPUT_HOOK then
	input = joypad.get()
	clearUnheldInputs()

	-- Create memory mapped input files for Python script to write to
	-- comm.mmfWrite("bizhawk_hold_input", json.encode(input) .. "\x00")
	comm.mmfWrite("bizhawk_input_list", string.rep("\x00", 512))

	input_list = {}
	for i = 0, 100 do --101 entries, the final entry is for the index.
		input_list[i] = 0
	end

	comm.mmfWriteBytes("bizhawk_input_list", input_list)
	comm.mmfWrite("bizhawk_touchscreen", string.rep("\x00", 16))
end

comm.mmfWrite("bizhawk_game_info", string.rep("\x00", 4096))
comm.mmfWrite("bizhawk_party_info", string.rep("\x00", 8192))

-- Main stuff
while true do
	if emu.framecount() % FRAMES_PER_MMAP_WRITE == 0 then
		mainLoop()
	end

	-- Send inputs if not disabled
	if not DEBUG_DISABLE_INPUT_HOOK then
		if emu.framecount() % FRAMES_PER_INPUT == 0 then
			clearUnheldInputs()
		else
			traverseNewInputs()
			poll_TouchScreen()
		end
	end

	emu.frameadvance()

	-- Allows manual touch screen input if the script is stopped
	-- # TODO run this only when the script is stopped
	-- client.clearautohold()
end