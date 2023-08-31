-----------------------
-- DP FUNCTION OVERRIDES
-----------------------
function update_pointers()
    offset.mem_shift = mdword(0x21D4158) -- Value differs per reset

    if offset.mem_shift == 0 then
        offset.mem_shift = 0xFFFFF -- Bad code, this is an improvised solution to multiple errors
    end
    
    offset.party_count = offset.mem_shift - 0x23F52 + 0xE
    offset.party_data = offset.party_count + 4
    
    offset.map_header = offset.mem_shift - 0x22DA4
    offset.trainer_x = offset.map_header + 4 + 2
    offset.trainer_y = offset.map_header + 12 + 2
    offset.trainer_z = offset.map_header + 8 + 2
    
    if mword(offset.map_header) == 340 then -- Bell Tower
        -- Wild Ho-oh's data is located at a different address to standard encounters
        -- May apply to other statics too -- research?
        offset.foe_count = offset.mem_shift + 0x977C
    else
        offset.foe_count = offset.mem_shift + 0x7574
    end
    offset.current_foe = offset.foe_count + 4

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

function mode_static_encounters()
    console.log("Waiting for battle to start...")
    while not foe and not game_state.in_battle do
        press_sequence("A", 6)
    end

    foe_is_target = pokemon.log(foe[1])

    if not config.hax then
        -- Wait for Pokémon to fully appear on screen
        for i = 0, 22, 1 do
            press_sequence("A", 6)
        end
    end

    if foe_is_target then
        pause_bot("Wild Pokémon meets target specs!")
    else
        console.log("Wild " .. foe[1].name .. " was not a target, resetting...")
        press_button("Power")
        wait_frames(60)
    end
end