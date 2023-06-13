-----------------------
-- INITIALIZATION
-----------------------
-- Requirements
mem = dofile "lua\\memory.lua"
json = require "lua\\json"
pokemon = require "lua\\pokemon"

function json_load(filename)
    local file = io.open(filename, "r")

    if file then
	    local jsonData = file:read("*a")
	    file:close()

	    return json.decode(jsonData)
	  else
	  	return false
	  end
end

map_names = json_load("lua\\data\\maps.json")

-- Constants
ENCOUNTER_LOG_LIMIT = 30
FRAMES_PER_DATA_REFRESH = 30
MON_DATA_SIZE = 220
MAP_HEADER_COUNT = 426

console.log("\nDetected game: " .. gamename)
console.log("Running Lua version: ".._VERSION)

-- Dashboard
console.log("Trying to establish a connection to the dashboard...")

comm.socketServerSetIp("127.0.0.1") -- Refreshes the connection, the dashboard suppresses the disconnect error this usually causes in favour of an easy solution
comm.socketServerSend('{ "type": "comm_check" }' .. "\x00")
comm.socketServerSetTimeout(50)

console.log("Dashboard connected at server " .. comm.socketServerGetInfo())
console.log("---------------------------")

-----------------------
-- LOGGING
-----------------------

encounters = json_load("logs/encounters.json")
if not encounters then
	encounters = {}
else
	-- Send encounter list to the dashboard to initialize
	comm.socketServerSend(json.encode({
		type = "encounters",
		data = encounters
	}) .. "\x00")
end

stats = json_load("logs/stats.json")
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
	local checksums = {}
	party_size = mem.readbyte(offset.party_count)

	-- Get the checksums of all party members
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

	last_party_checksums = checksums

	-- Update party info
	party = {}

	for i = 0, party_size - 1 do
		local mon = pokemon.read_data(offset.party_data + i * MON_DATA_SIZE)
		-- mon = pokemon.enrich_data(mon)
		table.insert(party, enrich_pokemon_data(mon))
	end

	-- console.log("party changed!")
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
			-- mon = pokemon.enrich_data(mon)
			table.insert(foe_table, mon)
		end

		return foe_table
	end
end

function getGameState()
	local state
	local mh = mem.readword(offset.map_header)

	state = {
		selected_starter = mem.readbyte(offset.selected_starter),
		starter_box_open = mem.readbyte(offset.starter_box_open),
		in_battle = mem.readbyte(offset.battle_indicator) == 0x41 and mem.readbyte(offset.foe_count) > 0,
		in_game = mh ~= 0x0 and mh <= MAP_HEADER_COUNT
	}

	return state
end

function getTrainer()
	local trainer
	local map = mem.readword(offset.map_header)

	trainer = {
		map_header = map,
		map_matrix = mem.readdword(offset.map_matrix),
		name = mem.readdword(offset.trainer_name),
		posX = mem.readword(offset.trainer_x + 2),
		posY = mem.readword(offset.trainer_y + 2),
		posZ = mem.readword(offset.trainer_z + 2),
		facing = mem.readdword(offset.trainer_direction)
	}

	if map == 0 or map > MAP_HEADER_COUNT then
		trainer.map_string = "--"
	else
		trainer.map_string = map_names[map] .. " (" .. map .. ")"
	end

	return trainer
end

function updateDashboardLog()
	-- Send the latest encounter and updated bot stats to the dashboard
	comm.socketServerSend(json.encode({
		type = "encounters",
		data = {encounters[#encounters]}
	}) .. "\x00")

	comm.socketServerSend(json.encode({
		type = "stats",
		data = stats
	}) .. "\x00")
end

function updateGameInfo(force)
	if emu.framecount() % FRAMES_PER_DATA_REFRESH == 0 or force then
		local party_changed = getParty()
		trainer = getTrainer()
		game_state = getGameState()
		foe = getFoe()
		
		if party_changed then
			comm.socketServerSend(json.encode({
				type = "party",
				data = party
			}) .. "\x00")
		end

		comm.socketServerSend(json.encode({
			type = "game",
			data = trainer
		}) .. "\x00")
	end
end

-----------------------
-- INPUT FUNCTIONS
-----------------------

function touch_screen_at(x, y)
	joypad.setanalog({['Touch X'] = x, ['Touch Y'] = y})
	wait_frames(1)
	press_button("Touch")
end

function press_button(button)
	-- local input = joypad.get()
	input[button] = true
	joypad.set(input)
	wait_frames(1)
end

function press_combo(...)
  local args = {...}
  -- local input = joypad.get()
  
  for _, arg in ipairs(args) do
    if type(arg) == "number" then
      wait_frames(arg)
    else
      input[arg] = true
      joypad.set(input)
  		wait_frames(1)
  		input[arg] = false
    end
  end
end

function wait_frames(frames)
	for _ = 1, frames do
		emu.frameadvance()
		updateGameInfo()
	end

	-- Every frame advance goes through this function
	-- Meaning it can update game state info at the same time without needing async
	clearUnheldInputs()
end

function clearUnheldInputs()
	for k, _ in pairs(input) do
		if k ~= "Touch X" and k ~= "Touch Y" then
	  	input[k] = false
	  end
	end

	joypad.set(input)
end

-----------------------
-- POKEMON HANDLING
-----------------------

mon_ability = json_load("lua/data/ability.json")
mon_item = json_load("lua/data/item.json")
mon_move = json_load("lua/data/move.json")
mon_dex = json_load("lua/data/pokedex.json")
mon_lang = {"none", "日本語", "English", "Français", "Italiano", "Deutsch", "Español", "한국어"}
mon_gender = {"Male", "Female", "Genderless"}
mon_nature = {
  "Hardy", "Lonely", "Brave", "Adamant", "Naughty",
  "Bold", "Docile", "Relaxed", "Impish", "Lax",
  "Timid", "Hasty", "Serious", "Jolly", "Naive",
  "Modest", "Mild", "Quiet", "Bashful", "Rash",
  "Calm", "Gentle", "Sassy", "Careful", "Quirky"
}

function enrich_pokemon_data(mon)
  mon.name = mon_dex[mon.species + 1].name
  -- mon.rating = pokemon.get_rating(mon)
  mon.pokeball = mon_item[mon.pokeball + 1]
  mon.otLanguage = mon_lang[mon.otLanguage + 1]
  mon.ability = mon_ability[mon.ability + 1]
  mon.nature = mon_nature[mon.nature + 1]
  mon.heldItem = mon_item[mon.heldItem + 1]
  mon.gender = mon_gender[mon.gender + 1]
  
  local move_id = mon.moves
  mon.moves = {}

  for _, move in ipairs(move_id) do
    table.insert(mon.moves, mon_move[move + 1])
  end
  
  return mon
end

-----------------------
-- BOT MODES
-----------------------

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
		console.log("Found a shiny! Ending the script.")
		console.log("------------------------------------------")
		
		while true do
			wait_frames(1)
		end
	else
		console.log("Starter was not shiny, resetting...")
		press_button("Power")
		wait_frames(60)
	end
end

function mode_randomEncounters()
	console.log("Waiting for battle")

	while not foe and not game_state.in_battle do
		wait_frames(1)
	end

	for i in foe do
		pokemon.log(i)
		updateDashboardLog()
	end

	console.log("Waiting for battle to end")

	while game_state.in_battle do
		wait_frames(1)
	end
end

-----------------------
-- MAIN BOT LOGIC
-----------------------

input = joypad.get()
starter = 0

while true do
	updateGameInfo(true)

	local s = starter % 3

	if s == 0 then
		mode_starters(60, 100)
	elseif s == 1 then
		mode_starters(128, 75)
	elseif s == 2 then
		mode_starters(185, 100)
	end

	starter = starter + 1

	emu.frameadvance()
	clearUnheldInputs()
end