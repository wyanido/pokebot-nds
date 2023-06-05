-- constants
MAX_MAP_ENTITIES = 16
NUM_OF_FRAMES_PER_PRESS = 5

DEBUG_DISABLE_INPUT_HOOK = false
DEBUG_DISABLE_OUTPUT = true

offsets = {
	entity_positions 	= 0x252220,
	warp_target 		= 0x2592CC,
	starter_box_open 	= 0x26E5B0, -- Unknown address; 0 when opening gift, 1 when gift is open
	hovered_starter 	= 0x269994,	-- Unconfirmed selection in gift box; 0 Snivy, 1 Tepig, 2 Oshawott
	party_slot_1		= 0x2349B4,	-- PID, start of data
	state				= 0x146A48, -- Closest address to a real "state" so far
	-- These seem to gradually change during a room transition, mere frames apart from each other
	map_id 				= 0x24F90C
	-- map_id2 			= 0x27587C,
	-- map_id4 			= 0x275884
}

entity_pos_list = {}
map_player_index = -1

map = 0
last_map = 0

posX = 0
posY = 0
-- last_posX = 0
-- last_posY = 0

json = require "components\\lua\\json"

function mainLoop()
	data = json.encode({
		["trainer"] = getTrainer(), 
		["game_state"] = getGameState()
	})

	comm.mmfWrite("bizhawk_game_info", data .. "\x00")

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

	-- If the first entity index is empty, indicates the game is loading an entire new area
	-- # TODO Make this check more comprehensive.
	-- Sometimes when loading bigger maps, the first index is 0 for a brief moment, despite being a "seamless" load
	if entity_pos_list[1] and entity_pos_list[1][1] == 0 then
		was_loading_zone = true
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
		while memory.read_u8(offsets.entity_positions, "Main RAM") == 0 do
			emu.frameadvance()
		end
	end

	if not DEBUG_DISABLE_OUTPUT then
		gui.addmessage("-----------")
	end

	-- Find the positions of all entities in the map
	for i = 0, MAX_MAP_ENTITIES do
		d = i * 256
		x = memory.read_u8(offsets.entity_positions + d, "Main RAM")
		y = memory.read_u8(offsets.entity_positions + d + 4, "Main RAM")

	   	table.insert(entity_pos_list, {x, y})

	   	if x ~= 0 or y ~= 0 then
	   		last_entity_index = i
	   	end

	   	if not DEBUG_DISABLE_OUTPUT then
		   	if i == map_player_index then
		   		prefix = "PLAYER | "
		   	else
		   		prefix = "ID " .. i .. "   | "
		   	end

		   	gui.addmessage(prefix .. "X: " .. x .. ", Y: " .. y)
		   end
	end

	-- The player is always the last entry in the list, so mark their offset with the last set of valid coordinates
	-- # TODO confirm whether the data always ends in (0, 0), or if other data may begin immediately after
	if set_player then
   		map_player_index = last_entity_index + 1
   		gui.addmessage("New player index is " .. map_player_index)
	end

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

-- Misc. data relevant to ce0x2349B4rtain events
function getGameState()
	local game_state

	game_state = {
		hovered_starter = memory.read_u8(offsets.hovered_starter, "Main RAM"),
		starter_box_open = memory.read_u8(offsets.starter_box_open, "Main RAM"),
		state = memory.read_u8(offsets.state, "Main RAM")
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
		-- console.log("Touch X: " .. x .. ", Touch Y: " .. y)
		-- console.log("")

		-- joypad.set({Touch=1})
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

function readMonData(address)
	local mon = {}
	-- Unencrypted bytes
	mon.pid 		= memory.read_u32_le(address + 0x0, "Main RAM")
	mon.checksum 	= memory.read_u16_le(address + 0x06, "Main RAM")
	
	-- Encrypted Blocks
	ss = {
		{},
		{},
		{},
		{}
	}
	
	seed = mon.checksum

	for i = 0x08, 0x87, 2 do
	    local word = memory.read_u16_le(address + i, "Main RAM")

	    seed = (0x41C64E6D * seed) + 0x00006073
	    local xor = seed >> 16
	    local decryptedByte = word ~ xor
	    local endBytes = decryptedByte & 0xFFFF

	    local blockIndex = math.floor((i - 0x08) / 32) + 1
	    
	    table.insert(ss[blockIndex], endBytes)
	end

	-- for i, value in ipairs(ss0) do
	--     print(string.format("%04X", value))
	-- end
	
	-- Block Order
	shift = ((mon.pid & 0x3E000) >> 0xD) % 24
	blockOrder = substructSelector[shift]

	monTable = {}

	for i = 1, 4 do
		block = ss[blockOrder[i] + 1]

	    for j = 1, 16 do
	        table.insert(monTable, block[j])
	    end
	end

	-- for i, value in ipairs(monTable) do
	-- 	print(string.format("%04X", value))
	-- end

	-- Encrypted bytes
	-- Block A
	mon.species 			= monTable[1]
	mon.heldItem 			= monTable[2]
	mon.otID 				= monTable[3]
	mon.otSID 				= monTable[4]
	mon.experience 			= monTable[5]
	-- mon.friendship 			= memory.read_u8(address + 0x14, "Main RAM")
	-- mon.ability 			= memory.read_u8(address + 0x15, "Main RAM")
	-- mon.markings 			= memory.read_u8(address + 0x16, "Main RAM")
	-- mon.otLanguage 			= memory.read_u8(address + 0x17, "Main RAM")
	-- mon.hpEv 				= memory.read_u8(address + 0x18, "Main RAM")
	-- mon.attackEv 			= memory.read_u8(address + 0x19, "Main RAM")
	-- mon.defenseEV 			= memory.read_u8(address + 0x1A, "Main RAM")
	-- mon.speedEV 			= memory.read_u8(address + 0x1B, "Main RAM")
	-- mon.spAttackEV 			= memory.read_u8(address + 0x1C, "Main RAM")
	-- mon.spDefenseEV 		= memory.read_u8(address + 0x1D, "Main RAM")
	-- mon.cool 				= memory.read_u8(address + 0x1E, "Main RAM")
	-- mon.beauty 				= memory.read_u8(address + 0x1F, "Main RAM")
	-- mon.cute 				= memory.read_u8(address + 0x20, "Main RAM")
	-- mon.smart 				= memory.read_u8(address + 0x21, "Main RAM")
	-- mon.tough 				= memory.read_u8(address + 0x22, "Main RAM")
	-- mon.sheen 				= memory.read_u8(address + 0x23, "Main RAM")
	-- mon.sinnohRibbonSet1 	= memory.read_u16_le(address + 0x24, "Main RAM")
	-- mon.UnovaRibbonSet 		= memory.read_u16_le(address + 0x26, "Main RAM")

	-- Battle stats
	-- mon.status 		= memory.read_u8(address + 0x88, "Main RAM")

	-- console.log(decryptData(mon.status, mon.pid))
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

	if not DEBUG_DISABLE_INPUT_HOOK then
		if emu.framecount() % NUM_OF_FRAMES_PER_PRESS == 0 then
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

-- mon = readMonData(offsets.party_slot_1)

-- print(mon.pid)
-- print(mon.experience)