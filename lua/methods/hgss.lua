-----------------------
-- DP FUNCTION OVERRIDES
-----------------------
function update_pointers()
    offset.party_count = mdword(0x021D10EC) + 14
    offset.party_data = offset.party_count + 4

    offset.foe_count = mdword(0x21D4158) + 0x7574
    offset.current_foe = offset.foe_count + 4

    offset.map_header = mdword(0x21D2228) + 0x1244
    offset.trainer_x = offset.map_header + 4 + 2
    offset.trainer_y = offset.map_header + 12 + 2
    offset.trainer_z = offset.map_header + 8 + 2

    offset.battle_indicator = 0x021E76D2 -- Static

    -- console.log(string.format("%08X", offset.map_header))
end

function mode_starters()
	wait_frames(30)
	
	-- Get starter data offset for this reset
	local starter_pointer = mdword(0x2111938) + 0x1BF78

    -- Proceed until starters are loaded into RAM
    while mdword(starter_pointer - 0x8) ~= 0 or mdword(starter_pointer - 0x4) == 0 do
        press_sequence("A", 10)
    end

	if not config.hax then
		press_sequence(130, "A", 15)
	else
		wait_frames(5)
	end

	-- Check all Pokémon
	local is_target = false
	for i = 0, 2, 1 do
		local starter = pokemon.read_data(starter_pointer + i * MON_DATA_SIZE)
    	is_target = pokemon.log(pokemon.enrich_data(starter))

		if is_target then
			pause_bot("Starter " .. (i + 1) .. " meets target specs!")
		end

		-- Scroll through each starter and log as they become visible
		if not config.hax and i < 2 then
			press_sequence("Left", 30)
		end
	end

	-- Soft reset otherwise
	press_button("Power")
	wait_frames(30)
end

function mode_voltorb_flip()
    local board_pointer = mdword(0x2111938) + 0x45FCC

    local function proceed_text()
        while mdword(board_pointer - 0x4) ~= 0xA0 or mdword(board_pointer - 0x14) ~= 0 do
            press_sequence("A", 6)
        end
    end

    local function flip_tile(x, y)
        touch_screen_at(x * 30 - 10, y * 30 - 10)
    end

    -- The game corner doesn't let you play while holding the maximum of 50k coins
    local coin_count = mword(board_pointer - 0x69BA8)
    if coin_count == 50000 then
        pause_bot("Can't earn any more coins")
    end

    proceed_text()

    local tile_index = 0

    -- Iterate through board and flip safe tiles
    for y = 1, 5, 1 do
        for x = 1, 5, 1 do
            local tile_offset = board_pointer + tile_index * 12
            local tile_type = mdword(tile_offset)
            local is_flipped = mdword(tile_offset + 8)

            if (tile_type == 2 or tile_type == 3) and is_flipped == 0 then -- a tile_type of 4 is Voltorb
                -- Tap tile until game registers the flip
                while is_flipped == 0 do
                    is_flipped = mdword(tile_offset + 8)

                    proceed_text()

                    flip_tile(x, y)
                    wait_frames(4)
                end

                press_button("A")
                wait_frames(8)
            end

            tile_index = tile_index + 1
        end
    end

    press_sequence("A", 9)
end
