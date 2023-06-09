-- constants
MAX_MAP_ENTITIES = 20
FRAMES_PER_PRESS = 5
FRAMES_PER_MON_UPDATE = 1
MON_DATA_SIZE = 220

DEBUG_DISABLE_INPUT_HOOK = true
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

	map_id 				= 0x24F90C, -- Changes on room transition

	-- Battle
	current_opponent	= 0x26ACF4,	-- PID of wild opponent, set immediately after the battle transition ends

	-- Misc testing
	entity_positions 	= 0x252220, -- List of positions for every entity in the current map
	entities_ready		= 0x27FEA8, -- 0 or 1
	-- warp_target 		= 0x2592CC,
	starter_box_open 	= 0x2B0C40, -- 0 when opening gift, 1 at starter select
	hovered_starter 	= 0x269994,	-- Unconfirmed selection in gift box; 0 Snivy, 1 Tepig, 2 Oshawott, 4 Nothing
	map_transition		= 0x216110  -- 1 during a transition, 0 otherwise
}

last_battle_state = 0

entity_pos_list = {}
map_player_index = -1

map = 0
last_map = 0

posX = 0
posY = 0
-- last_posX = 0
-- last_posY = 0

dofile "components\\lua\\RAM.lua"

json = require "components\\lua\\json"

function mainLoop()
	if emu.framecount() % FRAMES_PER_MON_UPDATE == 0 then
		data = json.encode({
			["trainer"] = getTrainer(), 
			["game_state"] = getGameState(),
			["party"] = getParty(),
			["opponent"] = getOpponent()
		})
		
		comm.mmfWrite("bizhawk_game_info", data .. "\x00")
	end

	map_updated = poll_mapUpdate()
	if not map_updated then
		updateEntityPositions(false)
	end
	
	if not DEBUG_DISABLE_OUTPUT then
		gui.addmessage("Map: " .. map .. ", Seamless?: " .. tostring(not was_loading_zone))
	end

	-- -- Display new player coordinates
	-- if (last_posX ~= posX) or (last_posY ~= posY) then
	-- 	last_posX, last_posY = posX, posY
	-- 	gui.addmessage("X: " .. posX .. ", Y: " .. posY)
	-- end
end

function onMapChanged()
	was_loading_zone = false

	if memory.read_u16_le(offsets.map_transition, "Main RAM") == 0 then
		was_loading_zone = true

		if not DEBUG_DISABLE_OUTPUT then
			print("yep, that's a loading zone")
		end
	end

	-- # TODO use a more refined solution, this just stops infinite loops on the title screen
	i = 0
	while memory.read_u16_le(offsets.entities_ready, "Main RAM") == 0 and i < 30 do
		emu.frameadvance()
		i = i + 1
	end

	updateEntityPositions(was_loading_zone)
end

function poll_mapUpdate()
	map = memory.read_u16_le(offsets.map_id, "Main RAM")
	if map ~= last_map then
		onMapChanged()
		last_map = map
		return true
	end
	return false
end

function updateEntityPositions(set_player)
	-- # TODO Fix failed entity indexing in Castelia City central
	entity_pos_list = {}
	last_entity_index = 0

	-- Wait for entity data to load
	if set_player then
		i = 0
		while RAM.readbyte(offsets.entities_ready) == 0 and i < 30 do
			emu.frameadvance()
			i = i + 1
		end
	end

	if not DEBUG_DISABLE_OUTPUT then
		gui.addmessage("")
	end

	-- Find the positions of all entities in the map
	for i = 0, MAX_MAP_ENTITIES do
		d = i * 256
		x = memory.read_u16_le(offsets.entity_positions + d, "Main RAM")
		y = memory.read_u16_le(offsets.entity_positions + d + 4, "Main RAM")

	   	table.insert(entity_pos_list, {x, y})

	   	if x == 0 and y == 0 then
	   		if set_player then
				-- Assign the player to the last entity position on the map
		   		map_player_index = i
		   		gui.addmessage("New player index is " .. map_player_index)
				break
			end
	   	elseif not DEBUG_DISABLE_OUTPUT then
		   	if i == map_player_index then
		   		prefix = "X | "
		   	else
		   		prefix = ". | "
		   	end

		   	gui.addmessage(prefix .. "X: " .. x .. ", Y: " .. y)
		end
	end

	-- if emu.framecount() % 5 == 0 then
	-- 	print(last_entity_index)
	-- end

	-- The player is always the last entry in the list, so mark their offset with the last set of valid coordinates
	-- # TODO confirm whether the data always ends in (0, 0), or if other data may begin immediately after
	

	updatePlayerPosition()
end

function updatePlayerPosition()
	player_pos = entity_pos_list[map_player_index]

	if player_pos then
		posX = player_pos[1]
		posY = player_pos[2]
	end
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
	if RAM.readbyte(offsets.in_battle) == 1 then
		return readMonData(offsets.current_opponent)
	else
		return nil
	end
end

-- Misc. data relevant to certain events
function getGameState()
	local game_state

	game_state = {
		selected_starter = memory.read_u8(offsets.hovered_starter, "Main RAM"),
		starter_box_open = memory.read_u8(offsets.starter_box_open, "Main RAM"),
		state = memory.read_u8(offsets.state, "Main RAM"),
		in_battle = RAM.readbyte(offsets.in_battle)
		-- entities_ready = memory.read_u8(offsets.entities_ready, "Main RAM")
	}

	return game_state
end

function getTrainer()
	local trainer
	
	trainer = {
		map = map,
		posX = posX,
		posY = posY	
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
		if not (k == "Touch X" or k == "Touch Y") then
	  	input[k] = false
	  end
	end

	joypad.set(input)
end

function rand(seed)
	return (0x41C64E6D * seed) + 0x6073
end

substructSelector = {
	[ 0] = {0, 1, 2, 3},
	[ 1] = {0, 1, 3, 2},
	[ 2] = {0, 2, 1, 3},
	[ 3] = {0, 3, 1, 2},
	[ 4] = {0, 2, 3, 1},
	[ 5] = {0, 3, 2, 1},
	[ 6] = {1, 0, 2, 3},
	[ 7] = {1, 0, 3, 2},
	[ 8] = {2, 0, 1, 3},
	[ 9] = {3, 0, 1, 2},
	[10] = {2, 0, 3, 1},
	[11] = {3, 0, 2, 1},
	[12] = {1, 2, 0, 3},
	[13] = {1, 3, 0, 2},
	[14] = {2, 1, 0, 3},
	[15] = {3, 1, 0, 2},
	[16] = {2, 3, 0, 1},
	[17] = {3, 2, 0, 1},
	[18] = {1, 2, 3, 0},
	[19] = {1, 3, 2, 0},
	[20] = {2, 1, 3, 0},
	[21] = {3, 1, 2, 0},
	[22] = {2, 3, 1, 0},
	[23] = {3, 2, 1, 0},
}

function rand(seed)
	return (0x41C64E6D * seed) + 0x00006073
end

function blockDataString(offset, length)
    local data = ""
    i = 0
    while i < length - 1 do
        local value = monTable[offset + i - 0x07]
        
        if value == 0xFF then
        	break
        end

        data = data .. utf8.char(value)
        i = i + 2
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

function readMonData(address)
	local mon = {}
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
	blockOrder = substructSelector[shift]

	monTable = {}
	
	-- Iterate through each block and reorganise the data into a single master table
	for i = 1, 4 do
		thisBlock = block[blockOrder[i] + 1]

	    for j = 1, 32 do
	        table.insert(monTable, thisBlock[j])
	    end
	end

	-- Block A
	mon.species 			= blockData(0x08, 2)
	mon.heldItem 			= blockData(0x0A, 2)
	mon.otID 				= blockData(0x0C, 2)
	mon.otSID 				= blockData(0x0E, 2)
	mon.experience 			= blockData(0x10, 3)
	mon.friendship 			= blockData(0x14, 1)
	mon.ability 			= blockData(0x15, 1)
	mon.markings 			= blockData(0x16, 1)
	mon.otLanguage 			= blockData(0x17, 1)
	mon.hpEv 				= blockData(0x18, 1)
	mon.attackEv 			= blockData(0x19, 1)
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
	mon.fatefulEncounter 	= (data >> 0) & 0x01
	mon.gender 				= (data >> 1) & 0x03
	mon.altForm				= (data >> 3) & 0x1F

	mon.nature				= blockData(0x41, 1)

	local data = blockData(0x42, 1)
	mon.dreamWorldAbility	= data & 0x01
	mon.isNsPokemon			= data & 0x02

	-- Block C
	mon.nickname 			= blockDataString(0x48, 23)

	mon.originGame			= blockData(0x5F, 1)
	-- mon.sinnohRibbonSet3	= blockData(0x60, 2)
	-- mon.sinnohRibbonSet3	= blockData(0x62, 2)
	
	-- Block D
	mon.otName 				= blockDataString(0x68, 16)
	mon.dateEggReceived		= blockData(0x78, 3)
	mon.dateMet				= blockData(0x7B, 3)
	mon.eggLocation			= blockData(0x7E, 2)
	mon.metLocation			= blockData(0x80, 2)
	mon.pokerus				= blockData(0x83, 1)
	mon.pokeball			= blockData(0x84, 1)
	mon.encounterType		= blockData(0x85, 1)

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

-- Main stuff
while true do
	mainLoop()

	-- Send inputs if not disabled
	if not DEBUG_DISABLE_INPUT_HOOK then
		if emu.framecount() % FRAMES_PER_PRESS == 0 then
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