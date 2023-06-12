-----------------------
-- Initialization
-----------------------
-- Constants
FRAMES_PER_MMAP_WRITE = 12
MON_DATA_SIZE = 220
MAP_HEADER_COUNT = 426

DEBUG_DISABLE_INPUT_HOOK = false
DEBUG_DISABLE_OUTPUT = true

-- Memory-mapped files, read by the .py dashboard
comm.mmfWrite("bizhawk_party_info", string.rep("\x00", 8192))
comm.mmfWrite("bizhawk_foe_info", string.rep("\x00", 8192))
comm.mmfWrite("bizhawk_general_info", string.rep("\x00", 1024))
comm.mmfWrite("bizhawk_encounter", string.rep("\x00", 1024))

-- Bot setup
mem = dofile "lua\\memory.lua"
json = require "lua\\json"
pokemon = require "lua\\pokemon"

console.log("\nDetected game: " .. gamename)
console.log("Running Lua version: ".._VERSION)
console.log("---------------------------")

os.execute("start pythonw.exe components\\dashboard.py")

-----------------------
-- GAME INFO POLLING
-----------------------

function getParty()
	local party = {}
	party_size = mem.readbyte(offset.party_count)

	for i = 0, party_size - 1 do
		local mon = pokemon.read_data(offset.party_data + i * MON_DATA_SIZE)
		-- mon = pokemon.enrich_data(mon)
		table.insert(party, mon)
	end

	return party
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
	
	trainer = {
		map_header = mem.readword(offset.map_header),
		map_matrix = mem.readdword(offset.map_matrix),
		posX = mem.readdword(offset.player_x),
		posY = mem.readdword(offset.player_y),
		posZ = mem.readdword(offset.player_z),
		facing = mem.readdword(offset.player_direction)
	}
	
	return trainer
end

function updateGameInfo()
	trainer = getTrainer()
	game_state = getGameState()
	emu_fps = client.get_approx_framerate()
	party_count = mem.readbyte(offset.party_count)
	party = getParty()
	foe = getFoe()

	-- Only write data for the dashboard occasionally to save on memory
	if (emu.framecount() % FRAMES_PER_MMAP_WRITE) == 0 then

		comm.mmfWrite("bizhawk_party_info", json.encode({
			party = party,
			party_count = party_count
		}) .. "\x00")

		comm.mmfWrite("bizhawk_foe_info", json.encode(foe) .. "\x00")
		comm.mmfWrite("bizhawk_general_info", json.encode({
			trainer = trainer
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
	end

	-- Every frame advance goes through this function
	-- Meaning it can update game state info at the same time without needing async
	clearUnheldInputs()
	updateGameInfo()
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
-- BOT MODES
-----------------------

function mode_starters(ball_x, ball_y)
	console.log("Waiting to reach overworld...")

	while not game_state.in_game do
		press_combo("A", 1)
	end

	console.log("Opening Gift Box...")

	while game_state.starter_box_open ~= 1 do
		press_combo("A", 5, "Down", 1)
	end

	console.log("Choosing Starter...")

	while game_state.starter_box_open ~= 0 do
		if game_state.selected_starter ~= 4 then
			touch_screen_at(120, 180) -- Pick this one!
			wait_frames(1)
			touch_screen_at(240, 100) -- Yes
			wait_frames(1)
		else
			touch_screen_at(ball_x, ball_y) -- Starter
			wait_frames(1)
		end
	end

	while party_size == 0 do
		press_combo("A", 1)
	end

	mon = party[1]
	pokemon.log(mon)
	console.log("Waiting to start battle...")
	
	while not game_state.in_battle do
		press_combo("A", 1)
	end

	console.log("Waiting to see starter...")

	-- For whatever reason, press_button("A", 1)
	-- does not work on its own within this specific loop
	for i = 0, 340, 1 do
	  press_button("A")
	  clearUnheldInputs()
	  wait_frames(1)
	end

	if not mon.shiny then
		console.log("Starter was not shiny, resetting...")
		press_button("Power")
		wait_frames(60)
	else
		console.log("------------------------------------------")
		console.log("Found a shiny! Ending the script.")
		console.log("------------------------------------------")
		
		while true do
			emu.frameadvance()
		end
	end
end

function mode_randomEncounters()
	console.log("Waiting for battle")

	while not foe and not game_state.in_battle do
		wait_frames(1)
	end

	for i in foe do
		pokemon.log(i)
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
	updateGameInfo()

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