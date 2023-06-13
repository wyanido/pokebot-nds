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

function getParty()
	party_size = mem.readbyte(offset.party_count)

	-- Get the checksums of all party members
	local checksums = {}
	for i = 0, party_size - 1 do
		table.insert(checksums, offset.party_data + i * MON_DATA_SIZE + 0x06)
	end

	-- Check for changes in the party data
	-- Necessary for only sending data to the socket when things have changed
	if party_size == #last_party_checksums then
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
	last_party_checksums = checksums
	party = {}

	for i = 0, party_size - 1 do
		local mon = pokemon.read_data(offset.party_data + i * MON_DATA_SIZE)

		if mon then
			mon = pokemon.enrich_data(mon)
			table.insert(party, mon)
		end
	end

	return true
end

function getFoe()
	-- Make sure it's not reading garbage non-battle data
	if mem.readbyte(offset.battle_indicator) ~= 0x41 or mem.readbyte(offset.foe_count) == 0 then
		return nil
	else
		local foe_table = {}
		local foe_count = mem.readbyte(offset.foe_count)

		for i = 0, foe_count - 1 do
			local mon = pokemon.read_data(offset.current_foe + i * MON_DATA_SIZE)

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
		foe = getFoe()
		
		local party_changed = getParty()
		if party_changed then
			comm.socketServerSend(json.encode({
				type = "party",
				data = party
			}) .. "\x00")
		end

		game_state = getGameState()
		comm.socketServerSend(json.encode({
			type = "game",
			data = game_state
		}) .. "\x00")
	end
end

-----------------------
-- BOT MODES
-----------------------
-- Choose a starter and reset until one is shiny
function mode_starters(ball_x, ball_y)
	console.log("Waiting to reach overworld...")

	while not game_state.in_game do
		press_combo("A", 20)
	end

	console.log("Opening Gift Box...")

	while game_state.starter_box_open ~= 1 do
		press_combo("A", 5, "Down", 1)
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

	while party_size == 0 do
		press_combo("A", 5)
	end

	mon = party[1]
	pokemon.log(mon)
	updateDashboardLog()

	console.log("Waiting to start battle...")
	
	while not game_state.in_battle do
		press_combo("A", 5)
	end

	console.log("Waiting to see starter...")

	-- For whatever reason, press_button("A", 5)
	-- does not work on its own within this specific loop
	for i = 0, 118, 1 do
	  press_button("A")
	  clearUnheldInputs()
	  wait_frames(5)
	end

	-- Check both cases because I can't trust it on just one
	if mon.shiny or mon.shinyValue < 8 then
		console.log("------------------------------------------")
		console.log("Found a shiny, pausing emulation! (Make sure to disable the lua script before intervening)")
		console.log("------------------------------------------")
		client.pause()
	else
		console.log("Starter was not shiny, resetting...")
		press_button("Power")
		wait_frames(60)
	end
end

-- Run back and forth until a random encounter is triggered, run if not shiny
function mode_random_encounters()
	local tile_frames = frames_per_move()

	console.log("Attempting to start a battle...")

	hold_button("B")

	while not foe and not game_state.in_battle do
		hold_button("Left")
		wait_frames(tile_frames)
		hold_button("Right")
		wait_frames(tile_frames)
	end

	release_button("B")
	release_button("Right")

	local foe_shiny = false

	for i = 1, #foe, 1 do
		pokemon.log(foe[i])
		updateDashboardLog() -- Only sends the latest encounter to the dashboard, so it needs to be called for every log
		if foe[i].shiny or foe[i].shinyValue < 8 then
			foe_shiny = true
		end
	end

	if foe_shiny then
		console.log("------------------------------------------")
		console.log("Found a shiny, pausing emulation! (Make sure to disable the lua script before intervening)")
		console.log("------------------------------------------")
		client.pause()
	else
		console.log("Wild Pokemon was not shiny, fleeing battle...")

		while game_state.in_battle do
			touch_screen_at(125, 175) -- Run
			wait_frames(5)
		end
	end
end

-- Run back and forth until a phenomenon spawns
-- https://bulbapedia.bulbagarden.net/wiki/Phenomenon
function mode_phenomenon_encounters()
	console.log("Attempting to start a battle...")

	hold_button("B")

	while not foe and not game_state.in_battle do
		hold_button("Left")
		wait_frames(8)
		hold_button("Right")
		wait_frames(8)
	end

	release_button("B")
	release_button("Right")

	local foe_shiny = false

	for i = 1, #foe, 1 do
		pokemon.log(foe[i])
		if foe[i].shiny or foe[i].shinyValue < 8 then
			foe_shiny = true
		end
	end
	updateDashboardLog()

	if foe_shiny then
		console.log("------------------------------------------")
		console.log("Found a shiny, pausing emulation! (Make sure to disable the lua script before intervening)")
		console.log("------------------------------------------")
		client.pause()
	else
		console.log("Wild Pokemon was not shiny, fleeing battle...")

		while game_state.in_battle do
			touch_screen_at(125, 175) -- Run
			wait_frames(5)
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

while true do
	updateGameInfo(true)

	if mode == "starters" then
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
	elseif mode == "phenomenon encounters" then
		mode_phenomenon_encounters()
	else
		console.log("Unknown bot mode: " .. config.mode)
		client.pause()
	end

	joypad.set(input)
	emu.frameadvance()
	clearUnheldInputs()
end