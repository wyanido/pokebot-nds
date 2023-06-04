-- constants
MAX_MAP_ENTITIES = 8

-- Map IDs
-- Nuvema Town		| 389
-- Juniper's Lab 	| 396
-- Home F1			| 390

-- Offset in RAM for the positions of all NPCs in the current map
-- The player is always the last item in this list before a sea of (0, 0)
-- # TODO confirm whether the data always ends in (0, 0), or if other data may begin immediately after

offsets = {
	entity_positions = 	0x252220,
	warp_target = 		0x2592CC,
	map_id = 			0x27587C
	-- These seem to change in different states of loading mere frames apart
	-- map_id2 = 			0x24F90C,
	-- map_id4 = 			0x275884
}

map_player_index = -1

map = 0
last_map = 0

posX = 0
posY = 0
last_posX = 0
last_posY = 0

function mainLoop()
	-- Test for map updates
	map = memory.read_u16_le(offsets.map_id, "Main RAM")
	console.log(map)
	if map ~= last_map then
		onMapChanged()
		last_map = map
	end

	updateEntityPositions(false)

	-- Display new player coordinates
	if (last_posX ~= posX) or (last_posY ~= posY) then
		last_posX, last_posY = posX, posY
		gui.addmessage("X: " .. posX .. ", Y: " .. posY)
	end

	emu.frameadvance()
end

function onMapChanged()
	gui.addmessage("Map changed! Old: " .. last_map .. ", New: " .. map)
	updateEntityPositions(true)
end

function updateEntityPositions(set_player)
	pos_list = {}
	last_entity_index = 0

	-- Allow room to load (player position takes longer to register than NPCs)
	waitFrames(60)

	-- Find the positions of all entities in the map
	for i = 0, MAX_MAP_ENTITIES do
		d = i * 256
		x = memory.read_u8(offsets.entity_positions + d, "Main RAM")
		y = memory.read_u8(offsets.entity_positions + d + 4, "Main RAM")

	   	table.insert(pos_list, {x, y})

	   	if x ~= 0 or y ~= 0 then
	   		last_entity_index = i
	   	else
	   		break
	   	end

	   	-- gui.addmessage("-----" .. i .. "-----")
	   	-- gui.addmessage("X: " .. x .. ", Y: " .. y)
	end

	-- The player is always the last entry in the list, so mark their offset with the last set of valid coordinates
	if set_player then
   		map_player_index = last_entity_index + 1
   		gui.addmessage("New player index is " .. map_player_index)
	end

	updatePlayerPosition()
end

function updatePlayerPosition()
	player_pos = pos_list[map_player_index]

	if player_pos then
		posX = player_pos[1]
		posY = player_pos[2]
	end
end

function waitFrames(frames)
	if set_player then
		for i = 0, frames do
			emu.frameadvance()
		end
	end
end

while true do
	mainLoop()
end