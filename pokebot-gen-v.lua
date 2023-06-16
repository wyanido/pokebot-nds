-----------------------
-- INITIALIZATION
-----------------------
-- Requirements
dofile("lua\\input.lua")

json = require("lua\\json")
mem = dofile("lua\\memory.lua")
pokemon = require("lua\\pokemon")

console.log("\nDetected game: " .. gamename)
console.log("Running Lua version: ".._VERSION)

-- Dashboard
console.log("Trying to establish a connection to the dashboard...")

comm.socketServerSetIp("127.0.0.1") -- Refreshes the connection, the dashboard suppresses the disconnect error this usually causes in favour of an easy solution
comm.socketServerSend('{ "type": "comm_check" }' .. "\x00")
comm.socketServerSetTimeout(50)

console.log("Dashboard connected at server " .. comm.socketServerGetInfo())
console.log("---------------------------")

-- Data
local map_names = json.load("lua\\data\\maps.json")
local config = json.load("config.json")

-- Constants
ENCOUNTER_LOG_LIMIT = 30
MON_DATA_SIZE = 220
MAP_HEADER_COUNT = 426

-----------------------
-- LOGGING
-----------------------

os.execute("mkdir logs")

encounters = json.load("logs/encounters.json")
if not encounters then
	encounters = {}
else
	-- Send full encounter list to the dashboard to initialize
	comm.socketServerSend(json.encode({
		type = "encounters",
		data = encounters
	}) .. "\x00")
end

stats = json.load("logs/stats.json")
if not stats then
	stats = {
		highest_iv_sum = 0,
	    lowest_sv = 65535,
	    encounters = 0
	}
end

-- Also send stats to the dashboard
comm.socketServerSend(json.encode({
	type = "stats",
	data = stats
}) .. "\x00")

-----------------------
-- GAME INFO POLLING
-----------------------

last_party_checksums = {}
party = {}

function getParty()
	local party_size = mem.readbyte(offset.party_count)

	-- Get the checksums of all party members
	local checksums = {}
	for i = 0, party_size - 1 do
		table.insert(checksums, mem.readword(offset.party_data + i * MON_DATA_SIZE + 0x06))
	end

	-- Check for changes in the party data
	-- Necessary for only sending data to the socket when things have changed
	if party_size == #party then
		local party_changed = false

		for i = 1, #checksums, 1 do
			if checksums[i] ~= last_party_checksums[i] then
				party_changed = true
				break
			end
		end

		if not party_changed then
			return false
		end
	end

	-- Party changed, update info
	console.log("| Updating party... |")
	last_party_checksums = checksums
	local new_party = {}

	for i = 1, party_size do
		local mon = pokemon.read_data(offset.party_data + (i - 1) * MON_DATA_SIZE)

		if mon then
			mon = pokemon.enrich_data(mon)

			-- Friendship is used to track egg cycles
			-- Converts cycles to steps
			if mon.isEgg then
				mon.friendship = mon.friendship * 256
				mon.friendship = math.max(0, mon.friendship - mem.readbyte(offset.step_counter) - mem.readbyte(offset.step_cycle) * 256)
			end

			table.insert(new_party, mon)
		else
			-- If any party checksums fail, don't update the party as it may contain more errors
			console.log("### Party checksum failed at slot " .. i .. " ###")
			return party_changed
		end
	end

	party = new_party

	return true
end

function getFoe()
	-- Make sure it's not reading garbage non-battle data
	if mem.readbyte(offset.battle_indicator) ~= 0x41 or mem.readbyte(offset.foe_count) == 0 then
		return nil
	else
		local foe_table = {}
		local foe_count = mem.readbyte(offset.foe_count)

		for i = 1, foe_count do
			local mon = pokemon.read_data(offset.current_foe + (i - 1) * MON_DATA_SIZE)

			if mon then
				mon = pokemon.enrich_data(mon)
				table.insert(foe_table, mon)
			end
		end

		return foe_table
	end
end

function getGameState()
	local state = {}
	local map = mem.readword(offset.map_header)
	local in_game = map ~= 0x0 and map <= MAP_HEADER_COUNT
	
	-- Set default values for the dashboard
	state = {
		map_matrix = 0,
		map_header = 0,
		map_name = "--",
		trainer_x = 0,
		trainer_y = 0,
		trainer_z = 0,
		phenomenon_x = 0,
		phenomenon_z = 0,
	}

	-- Update in-game values
	if in_game then
		state = {
			selected_starter = mem.readbyte(offset.selected_starter),
			starter_box_open = mem.readbyte(offset.starter_box_open),
			map_matrix = mem.readdword(offset.map_matrix),
			map_header = map,
			map_name = map_names[map + 1],
			trainer_x = mem.readword(offset.trainer_x + 2),
			trainer_y = mem.readword(offset.trainer_y + 2),
			trainer_z = mem.readword(offset.trainer_z + 2),
			phenomenon_x = mem.readword(offset.phenomenon_x + 2),
			phenomenon_z = mem.readword(offset.phenomenon_z + 2),
			trainer_name = mem.readdword(offset.trainer_name),
			trainer_dir = mem.readdword(offset.trainer_direction),
			in_battle = mem.readbyte(offset.battle_indicator) == 0x41 and mem.readbyte(offset.foe_count) > 0,
		}
	end

	state.in_game = in_game

	return state
end

function updateDashboardLog()
	-- Send the latest encounter and updated bot stats to the dashboard
	comm.socketServerSend(json.encode({
		type = "encounters",
		data = {encounters[#encounters]},
	}) .. "\x00")

	comm.socketServerSend(json.encode({
		type = "stats",
		data = stats,
	}) .. "\x00")
end

function frames_per_move()
	if mem.readbyte(offset.on_bike) == 1 then
		return 4
	elseif mem.readbyte(offset.running_shoes) == 0xE then
		return 8
	end

	return 16
end

function updateGameInfo(force)
	-- Refresh data at the rate it takes to move 1 tile
	local refresh_frames = frames_per_move() / 2

	if emu.framecount() % refresh_frames == 0 or force then
		game_state = getGameState()
		comm.socketServerSend(json.encode({
			type = "game",
			data = game_state
		}) .. "\x00")
		
		foe = getFoe()
	end

	local party_changed = getParty()
	if party_changed then
		comm.socketServerSend(json.encode({
			type = "party",
			data = party
		}) .. "\x00")
	end
end

-----------------------
-- MISC. BOT ACTIONS
-----------------------

function do_pickup()
	local pickup_count = 0
	local item_count = 0
	local items = {}

	for i = 1, #party, 1 do
		-- Insert all item names, even none, to preserve party order
		table.insert(items, party[i].heldItem)

		if party[i].ability == "Pickup" then
			pickup_count = pickup_count + 1

			if party[i].heldItem ~= "none" then
				item_count = item_count + 1
			end
		end
	end

	if pickup_count > 0 then
		if item_count < config.pickup_threshold then
			console.log("Pickup items in party: " .. item_count .. ". Collecting at threshold: " .. config.pickup_threshold)
		else
			press_sequence(60, "X", 30)
			touch_screen_at(65, 45)
			wait_frames(90)

			-- Collect items from each Pickup member
			for i = 1, #items, 1 do
				if items[i] ~= "none" then
					touch_screen_at(80 * ((i - 1) % 2 + 1), 30 + 50 * ((i - 1) // 2)) -- Select Pokemon

					wait_frames(30)
					touch_screen_at(200, 155) -- Item
					wait_frames(30)
					touch_screen_at(200, 155) -- Take
					press_sequence(120, "B", 30)
				end
			end

			-- Exit out of menu
			press_sequence(30, "B", 120, "B", 60)
		end
	else
		console.log("Pickup was enabled in config, but no party Pokemon have the Pickup ability. Was this a mistake?")
	end
end

function do_battle()
	local best_move = pokemon.find_best_move(party[1], foe[1])

	if best_move then
		-- Press B until battle state has advanced
		local battle_state = 0

		while game_state.in_battle and battle_state == 0 do
			press_sequence("B", 5)
			battle_state = mem.readbyte(offset.battle_menu_state)
		end

		if not game_state.in_battle then -- Battle over
			return
		elseif battle_state == 4 then -- Fainted or learning new move
			wait_frames(30)
			touch_screen_at(128, 100) -- RUN or KEEP OLD MOVES
			wait_frames(140)
			touch_screen_at(128, 50) -- FORGET or nothing if fainted

			while game_state.in_battle do
				press_sequence("B", 5)
			end
			return
		end

		if best_move.power > 0 then
			-- Manually decrement PP count
			-- The game only updates this itself at the end of the battle
			local pp_dec = 1
			if foe[1].ability == "Pressure" then
				pp_dec = 2
			end

			party[1].pp[best_move.index] = party[1].pp[best_move.index] - pp_dec

			console.log("Best move against foe is " .. best_move.name .. " (Effective base power is " .. best_move.power .. ")")
			wait_frames(30)
			touch_screen_at(128, 90) -- FIGHT
			wait_frames(30)

			touch_screen_at(80 * ((best_move.index - 1) % 2 + 1), 50 * (((best_move.index - 1) // 2) + 1)) -- Select move slot
			wait_frames(30)
		else
			console.log("Lead Pokemon has no valid moves left to battle! Fleeing...")
		
			while game_state.in_battle do
				touch_screen_at(125, 175) -- Run
				wait_frames(5)
			end
		end
	else
		-- Wait another frame for valid battle data
		wait_frames(1)
	end
end

function pause_bot(reason)
	clearUnheldInputs()
	client.clearautohold()

	console.log("###################################")
	console.log(reason .. ". Pausing emulation! (Make sure to disable the lua script before intervening)")
	client.pause()
end

function check_party_status()
	-- Check how many valid move uses the lead has remaining
	local lead_pp_sum = 0

	for i = 1, #party[1].moves, 1 do
	    if party[1].moves[i].power ~= nil then
	    	lead_pp_sum = lead_pp_sum + party[1].pp[i]
		end
    end

	if party[1].currentHP == 0 or lead_pp_sum == 0 then
		if config.cycle_lead_pokemon then
			console.log("Lead Pokemon can no longer battle. Replacing...")

			-- Find suitable replacement
			local most_usable_pp = 0
			local best_index = 1

			for i = 2, #party, 1 do
				local ally = party[i]

				if ally.currentHP > 0 then
					local pp_sum = 0

					for j = 1, #ally.moves, 1 do
					    if ally.moves[j].power ~= nil then
					    	-- Multiply PP by level to weight selections toward
					    	-- higher level party members
					    	pp_sum = pp_sum + ally.pp[j] * ally.level
						end
				    end

				    if pp_sum > most_usable_pp then
				    	most_usable_pp = pp_sum
				    	best_index = i
				    end
				end
			end

			if most_usable_pp == 0 then
				pause_bot("No suitable Pokemon left to battle")
			else
				console.log("Best replacement was "  .. party[best_index].name .. " (Slot " .. best_index .. ")")
				-- Party menu
				press_sequence(60, "X", 30)
				touch_screen_at(65, 45)
				wait_frames(90)

				touch_screen_at(80, 30) -- Select fainted lead
						
				wait_frames(30)
				touch_screen_at(200, 130) -- SWITCH
				wait_frames(30)
				
				touch_screen_at(80 * ((best_index - 1) % 2 + 1), 30 + 50 * ((best_index - 1) // 2)) -- Select Pokemon
				wait_frames(30)

				press_sequence(30, "B", 120, "B", 60) -- Exit out of menu
			end
		else
			pause_bot("Lead Pokemon can no longer battle, and current config disallows cycling lead")
		end
	end
end

-----------------------
-- BOT MODES
-----------------------

function mode_starters(ball_x, ball_y)
	if not game_state.in_game then 
		console.log("Waiting to reach overworld...")

		while not game_state.in_game do
			press_sequence("A", 20)
		end
	end

	console.log("Opening Gift Box...")

	while game_state.starter_box_open ~= 1 do
		press_sequence("A", 5, "Down", 1)
	end

	console.log("Choosing Starter...")

	while game_state.starter_box_open ~= 0 do
		if game_state.selected_starter ~= 4 then
			touch_screen_at(120, 180) -- Pick this one!
			wait_frames(5)
			touch_screen_at(240, 100) -- Yes
			wait_frames(5)
		else
			touch_screen_at(ball_x, ball_y) -- Starter
			wait_frames(5)
		end
	end

	while #party == 0 do
		press_sequence("A", 5)
	end

	if not config.hax then
		console.log("Waiting to start battle...")
		
		while not game_state.in_battle do
			press_sequence("A", 5)
		end

		console.log("Waiting to see starter...")

		-- For whatever reason, press_button("A", 5)
		-- does not work on its own within this specific loop
		for i = 0, 118, 1 do
		  press_button("A")
		  clearUnheldInputs()
		  wait_frames(5)
		end
	end

	mon = party[1]
	pokemon.log(mon)
	updateDashboardLog()

	-- Check both cases because I can't trust it on just one
	if mon.shiny or mon.shinyValue < 8 then
		pause_bot("Starter is shiny")
	else
		console.log("Starter was not shiny, resetting...")
		press_button("Power")
		wait_frames(60)
	end
end

function mode_random_encounters()
	check_party_status()

	console.log("Attempting to start a battle...")

	hold_button("B")

	local tile_frames = frames_per_move()
	
	while not foe and not game_state.in_battle do
		hold_button("Left")
		wait_frames(tile_frames)
		hold_button("Right")
		wait_frames(tile_frames)
	end

	release_button("B")
	release_button("Right")


	-- Check all foes in case of a double battle
	local foe_shiny = false
	for i = 1, #foe, 1 do
		pokemon.log(foe[i])
		updateDashboardLog() -- Only sends the latest encounter to the dashboard, so it needs to be called for every log
		if foe[i].shiny or foe[i].shinyValue < 8 then
			foe_shiny = true
		end
	end

	if foe_shiny then
		wait_frames(120)
		
		pause_bot("Wild Pokemon is shiny")
	else
		console.log("Wild Pokemon was not shiny, attempting next action...")

		while game_state.in_battle do
			if config.battle_non_targets then
				do_battle()
			else
				touch_screen_at(125, 175) -- Run
				wait_frames(5)
			end
		end

		if config.pickup then
			do_pickup()
		end
	end
end

function mode_gift()
	if not game_state.in_game then
		console.log("Waiting to reach overworld...")

		while not game_state.in_game do
			press_sequence("A", 20)
		end
	end

	wait_frames(60)

	local in_dreamyard = game_state.map_header == 152

	local og_party_count = #party
	while #party == og_party_count do
		if in_dreamyard then
			press_sequence("A", 5)
		else
			press_sequence("A", 5)
		end
	end

	-- Dialogue varies per gift type
	if in_dreamyard then
		press_sequence(300, "B", 120, "B", 150, "B", 110, "B", 30) -- Decline nickname and progress text afterwards
	else
		press_sequence(180, "B", 60) -- Decline nickname
	end

	if not config.hax then
		-- Party menu
		press_sequence("X", 30)
		touch_screen_at(65, 45)
		wait_frames(90)

		touch_screen_at(80 * ((#party - 1) % 2 + 1), 30 + 50 * ((#party - 1) // 2)) -- Select gift mon
		wait_frames(30)

		touch_screen_at(200, 105) -- SUMMARY
		wait_frames(120)
	end

	local mon = party[#party]
	pokemon.log(mon)
	updateDashboardLog()

	-- Check both cases because I can't trust it on just one
	if mon.shiny or mon.shinyValue < 8 then
		pause_bot("Gift Pokemon is shiny")
	else
		console.log("Gift Pokemon was not shiny, resetting...")
		press_button("Power")
		wait_frames(60)
	end
end

function mode_phenomenon_encounters()
	pause_bot("This mode is unfinished")

	check_party_status()

	console.log("Running until a phenomenon spawns...")
	
	hold_button("B")

	local tile_frames = frames_per_move()

	while game_state.phenomenon_x == 0 and game_state.phenomenon_z == 0 do
		hold_button("Left")
		wait_frames(tile_frames)
		hold_button("Right")
		wait_frames(tile_frames)
	end

	console.log("Phenomena spawned! Attempting to start encounter...")
end

function mode_daycare_eggs()
	local function collect_daycare_egg()
		console.log("That's an egg!")
			
		release_button("Right")
		press_sequence(60, "B")
		hold_button("Up")

		while game_state.trainer_z ~= 557 do -- Bike up to daycare man
			wait_frames(8)
		end

		release_button("Up")

		local og_party_count = #party -- Press A until egg in party
		while #party == og_party_count do
			press_sequence("A", 5)
		end

		press_sequence(200, "B", 90, "B") -- End dialogue
	end

	-- Daycare routine below
	if game_state.map_header ~= 321 then
		pause_bot("Please place the bot on Route 3")
	end

	-- If the party is full, assert that at least one is still unhatched
	if #party == 6 then
		local has_egg = false
		for i = 1, #party, 1 do
			if party[i].isEgg == 1 then
				has_egg = true
				break
			end
		end

		-- Otherwise free up party slots at PC
		if not has_egg then
			console.log("Party is clear of eggs. Depositing hatched Pokemon...")
			hold_button("B")

			-- Reach staircase
			while game_state.trainer_x < 742 do
				hold_button("Right")
				wait_frames(1)
			end

			while game_state.trainer_x > 748 do
				hold_button("Left")
				wait_frames(1)
			end

			release_button("Right")
			release_button("Left")

			-- Ascend staircase
			while game_state.trainer_z > 558 do
				hold_button("Up")
				wait_frames(1)
			end

			release_button("Up")

			-- Align with door
			while game_state.trainer_x < 749 do
				hold_button("Right")
				wait_frames(1)
			end

			release_button("Right")

			-- Walk to daycare lady at desk
			while game_state.map_header ~= 323 or game_state.trainer_z ~= 9 do
				hold_button("Up")
				wait_frames(1)
			end

			release_button("Up")

			-- Walk to PC
			while game_state.trainer_x < 9 do
				hold_button("Right")
				wait_frames(1)
			end

			release_button("B")
			release_button("Right")

			wait_frames(frames_per_move())
			press_sequence("Up", 16, "A", 140, "A", 120, "A", 110, "A", 100)

			-- Temporary, add this to config once I figure out PC storage limitations
			local release_hatched_duds = true

			if release_hatched_duds then
				press_sequence("Down", 5, "Down", 5, "A", 110)

				touch_screen_at(45, 175)
				wait_frames(60)

				-- Release party in reverse order so the positions don't shuffle to fit empty spaces
				for i = #party, 1, -1 do
					if party[i].level == 1 and not party[i].shiny and party[i].shinyValue >= 8 then
						touch_screen_at(40 * ((i - 1) % 2 + 1), 72 + 30 * ((i - 1) // 2)) -- Select Pokemon
						wait_frames(30)
						touch_screen_at(211, 121) -- RELEASE
						wait_frames(30)
						touch_screen_at(220, 110) -- YES
						press_sequence(60, "B", 20, "B", 20) -- Bye-bye!
					end
				end
			else
				-- Unfinished
				press_sequence("A", 120)

				pause_bot("This code shouldn't be running right now")
			end

			press_sequence("B", 30, "B", 30, "B", 30, "B", 150, "B", 90) -- Exit PC

			hold_button("B")

			while game_state.trainer_x > 6 do -- Align with door
				hold_button("Left")
				wait_frames(1)
			end

			release_button("Left")

			while game_state.map_header ~= 321 do -- Exit daycare
				hold_button("Down")
				wait_frames(1)
			end

			while game_state.trainer_z ~= 558 do
				hold_button("Down")
				wait_frames(1)
			end

			release_button("Down")

			press_sequence(20, "Left", 20, "Y") -- Mount Bicycle and with staircase
		end
	end

	-- Move down until on the two rows used for egg hatching
	if game_state.trainer_x >= 742 and game_state.trainer_x <= 748 and game_state.trainer_z < 563 then
		hold_button("Down")

		local stuck_frames = 0
		local last_z = game_state.trainer_z
		while game_state.trainer_z ~= 563 and game_state.trainer_z ~= 564 do
			wait_frames(1)

			if game_state.trainer_z == last_z then
				stuck_frames = stuck_frames + 1

				if stuck_frames > 60 then -- Interrupted by daycare man as you were JUST leaving
					collect_daycare_egg()
				end
			end

			last_z = game_state.trainer_z
		end

		release_button("Down")
	else
		local tile_frames = frames_per_move() * 4

		-- Hold left until interrupted
		hold_button("Left")

		local last_x = 0
		while last_x ~= game_state.trainer_x do
			last_x = game_state.trainer_x
			wait_frames(tile_frames)

			-- Reached left route boundary
			press_button("B")
			if game_state.trainer_x <= 681 then
				break
			end
		end

		-- Hold right until interrupted
		hold_button("Right")

		local last_x = 0
		while last_x ~= game_state.trainer_x do
			last_x = game_state.trainer_x
			wait_frames(tile_frames)

			-- Right route boundary
			press_button("B")
			if game_state.trainer_x >= 758 then
				break
			end
		end

		if mem.readdword(offset.egg_hatching) == 1 then -- Interrupted by egg hatching
			console.log("Oh?")

			release_button("Right")
			release_button("Left")

			press_sequence("B", 60)

			-- Remember which Pokemon are currently eggs
			local party_eggs = {}
			for i = 1, #party, 1 do
				party_eggs[i] = party[i].isEgg
			end

			while mem.readdword(offset.egg_hatching) == 1 do
				press_sequence(15, "B")
			end

			-- Find newly hatched party member and add to the log
			for i = 1, #party, 1 do
				if party_eggs[i] == 1 and party[i].isEgg == 0 then
					pokemon.log(party[i])
					updateDashboardLog()

					if party[i].shiny or party[i].shinyValue < 8 then
						pause_bot("Hatched a shiny Pokemon")
					end
					break
				end
			end
			
			console.log("Egg finished hatching.")
		elseif game_state.trainer_x == 748 then -- Interrupted by daycare man
			collect_daycare_egg()
		end
	end
end

-----------------------
-- MAIN BOT LOGIC
-----------------------

input = joypad.get()

-- Initialise with no held inputs
held_input = input
for k, _ in pairs(held_input) do
	held_input[k] = false
end

console.log("Bot mode set to " .. config.mode)
local mode = string.lower(config.mode)

updateGameInfo(true)

while true do
	if mode == "starters" then
		-- Choose a starter and reset until one is shiny
		local s = config.starter % 3

		if s == 0 then
			mode_starters(60, 100)
		elseif s == 1 then
			mode_starters(128, 75)
		elseif s == 2 then
			mode_starters(185, 100)
		end

		if config.cycle_starters then
			config.starter = config.starter + 1
		end
	elseif mode == "random encounters" then
		mode_random_encounters()
		-- Run back and forth until a random encounter is triggered, run if not shiny
	elseif mode == "phenomenon encounters" then
		-- Run back and forth until a phenomenon spawns, then encounter it
		-- https://bulbapedia.bulbagarden.net/wiki/Phenomenon
		mode_phenomenon_encounters()
	elseif mode == "gift" then
		-- Receive a gift Pokemon and reset if not shiny
		mode_gift()
	elseif mode == "daycare eggs" then
		-- Cycle to hatch and collect eggs until party is full, then release and repeat until a shiny is found
		mode_daycare_eggs()
	elseif mode == "manual" then
		-- No bot logic, just manual gameplay with a dashboard
		while true do
			updateGameInfo()
			emu.frameadvance()
		end
	else
		console.log("Unknown bot mode: " .. config.mode)
		client.pause()
	end

	joypad.set(input)
	emu.frameadvance()
	clearUnheldInputs()
	updateGameInfo()
end