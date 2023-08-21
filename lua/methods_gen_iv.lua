function update_pointers()
    offset.party_count = mdword(0x021C489C) + 14
    offset.party_data = offset.party_count + 4

    offset.foe_count = mdword(0x21C5A08) + 0x729C
    offset.current_foe = offset.foe_count + 4

    offset.map_header = mdword(0x21C489C) + 0x11B2
    offset.trainer_x = offset.map_header + 4 + 2
    offset.trainer_y = offset.map_header + 12 + 2
    offset.trainer_z = offset.map_header + 8 + 2
    -- console.log()
    -- offset.trainer_x = 

    -- console.log(string.format("%08X", offset.map_header))
end

function flee_battle()
    while game_state.in_battle do
		touch_screen_at(125, 175) -- Run
		wait_frames(20)
    end
end

function process_wild_encounter()
    -- Check all foes in case of a double battle in Eterna Forest
    local foe_is_target = false
    for i = 1, #foe, 1 do
        foe_is_target = pokemon.log(foe[i]) or foe_is_target
    end
	
    wait_frames(30)
    
    if foe_is_target then
        pause_bot("Wild Pokemon meets target specs!")
    else
        console.log("Wild " .. foe[1].name .. " was not a target, fleeing!")

        flee_battle()
    end
end

-----------------------
-- BOT MODES
-----------------------

function mode_starters(starter)
	if not game_state.in_game then 
		console.log("Waiting to reach overworld...")

		while not game_state.in_game do
			skip_dialogue()
		end
	end

	hold_button("Up") -- Enter Lake Verity
	console.log("Waiting to reach briefcase...")

	-- Skip through dialogue until starter select
	while not (mdword(offset.starters_ready) > 0) do
		skip_dialogue()
	end

	release_button("Up")

	-- Highlight and select target
	console.log("Selecting starter...")

	while mdword(offset.selected_starter) < starter do
		press_sequence("Right", 5)
	end

	while #party == 0 do 
		press_sequence("A", 6)
	end

	if not config.hax then
		console.log("Waiting to see starter...")
		
		for i = 0, 86, 1 do
		  press_button("A")
		  clear_unheld_inputs()
		  wait_frames(6)
		end
	end

	mon = party[1]
	local was_target = pokemon.log(mon)
	
	if was_target then
		pause_bot("Starter meets target specs!")
	else
		console.log("Starter was not a target, resetting...")
		press_button("Power")
		wait_frames(180)
	end
end

function mode_random_encounters()
    console.log("Attempting to start a battle...")

    local tile_frames = frames_per_move() - 2
    local dir1 = config.move_direction == "Horizontal" and "Left" or "Up"
    local dir2 = config.move_direction == "Horizontal" and "Right" or "Down"
    
    while not foe and not game_state.in_battle do
        hold_button("B")
        hold_button(dir1)
        wait_frames(tile_frames)
        release_button(dir1)
        release_button("B")

        hold_button("B")
        hold_button(dir2)
        wait_frames(tile_frames)
        release_button(dir2)
        release_button("B")
    end
    
    release_button(dir2)

    process_wild_encounter()
end
