-- constants
MAX_MAP_ENTITIES = 8

-- Offset in RAM for the positions of all NPCs in the current map
-- The player is always the last item in this list before a sea of (0, 0)
-- # TODO confirm whether the data always ends in (0, 0), or if other data may begin immediately after
entity_pos_offset = 0x252220
map_player_index = 0

posX = 0
posY = 0
last_posX = 0
last_posY = 0

function mainLoop()
	map_player_index = -1
	entity_positions = {}

	-- Find the positions of all entities in the map
	for i = 0, MAX_MAP_ENTITIES do
		d = i * 256
		x = memory.read_u8(entity_pos_offset + d, "Main RAM")
		y = memory.read_u8(entity_pos_offset + d + 4, "Main RAM")

	   	table.insert(entity_positions, {x, y})

	   	-- The player is always the last item in the list, so mark their offset
	   	if map_player_index == -1 and x == 0 and y == 0 then
	   		map_player_index = i
	   		player_pos = entity_positions[map_player_index]

	   		if player_pos then
		   		posX = player_pos[1]
		   		posY = player_pos[2]
	   		else
	   			onMapChanged()
	   		end
	   	end
	end

	-- Show new player coordinates on screen
	if (last_posX ~= posX) or (last_posY ~= posY) then
		last_posX = posX
		last_posY = posY
		gui.addmessage("X: " .. posX .. ", Y: " .. posY)
	end

	emu.frameadvance()
end


function onMapChanged()
	console.log("Map changed!")
	gui.addmessage("Map changed!")
end

while true do
	mainLoop()
end