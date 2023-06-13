
function touch_screen_at(x, y)
	joypad.setanalog({['Touch X'] = x, ['Touch Y'] = y})
	press_button("Touch")
	 -- Force release Touch because it gets set to 'held' somehow
	release_button("Touch")
end

function press_button(button)
	input[button] = true
	joypad.set(input)
	wait_frames(1)
	release_button(button)
end

function hold_button(button)
	held_input[button] = true
	input[button] = true

	-- Release conflicting D-pad inputs
	if button == "Left" then
		held_input["Right"] = false
		input["Right"] = false
	elseif button == "Right" then
		held_input["Left"] = false
		input["Left"] = false
	elseif button == "Down" then
		held_input["Up"] = false
		input["Up"] = false
	elseif button == "Up" then
		held_input["Down"] = false
		input["Down"] = false
	end

	joypad.set(input)
end

function release_button(button)
	held_input[button] = false
	input[button] = false
	joypad.set(input)
end

function press_combo(...)
  local args = {...}
  
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

-- Most frame advances go through this function, meaning 
-- it can update the game state for other functions without needing asynchronosity
function wait_frames(frames)
	for _ = 1, frames do
		joypad.set(input)
		emu.frameadvance()
		updateGameInfo()
	end

	clearUnheldInputs()
end

function clearUnheldInputs()
	for k, _ in pairs(input) do
		if k ~= "Touch X" and k ~= "Touch Y" and not held_input[k] then
	  	input[k] = false
	  end
	end

	joypad.set(input)
end