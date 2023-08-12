
function update_pointers()
	offset.party_count = mdword(0x021C489C) + 14
	offset.party_data = offset.party_count + 4

	offset.foe_count = mdword(0x21C5A08) + 0x729C
	offset.current_foe = offset.foe_count + 4
	
	-- console.log(string.format("%08X", offset.foe_count))
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