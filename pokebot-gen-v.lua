-- constants
MAX_MAP_ENTITIES = 16
NUM_OF_FRAMES_PER_PRESS = 5

DEBUG_DISABLE_INPUT_HOOK = true

offsets = {
	entity_positions = 	0x252220,
	warp_target = 		0x2592CC,
	hovered_starter =   0x269994,
	-- These seem to change in different states of loading mere frames apart
	map_id = 			0x24F90C
	-- map_id2 = 		0x27587C,
	-- map_id4 = 		0x275884
}

trainer = {}
entity_pos_list = {}

map_player_index = -1

map = 0
last_map = 0

posX = 0
posY = 0
last_posX = 0
last_posY = 0

json = require "components\\lua\\json"

function mainLoop()
	trainer = getTrainer()
	comm.mmfWrite("bizhawk_game_info", json.encode({["trainer"] = trainer}) .. "\x00")

	map_updated = poll_mapUpdate()
	if not map_updated then
		updateEntityPositions(false)
	end

	gui.addmessage("Map: " .. map .. ", Seamless?: " .. tostring(not was_loading_zone))

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

	gui.addmessage("-----------")

	-- Find the positions of all entities in the map
	for i = 0, MAX_MAP_ENTITIES do
		d = i * 256
		x = memory.read_u8(offsets.entity_positions + d, "Main RAM")
		y = memory.read_u8(offsets.entity_positions + d + 4, "Main RAM")

	   	table.insert(entity_pos_list, {x, y})

	   	if x ~= 0 or y ~= 0 then
	   		last_entity_index = i
	   	end

	   	if i == map_player_index then
	   		prefix = "PLAYER | "
	   	else
	   		prefix = "ID " .. i .. "   | "
	   	end

	   	gui.addmessage(prefix .. "X: " .. x .. ", Y: " .. y)
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

function getTrainer()
	local trainer
	
	trainer = {
		map = map,
		posX = posX,
		posY = posY,
		hovered_starter = memory.read_u8(offsets.hovered_starter, "Main RAM")
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

	if x and y then
		console.log("Touch X: " .. x .. ", Touch Y: " .. y)
		console.log("")

		joypad.set({Touch=1})
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
	client.clearautohold()
end