-- Restore manual touch screen input when the script is stopped
event.onexit(
	function () 
		client.clearautohold() 
	end
)

function touch_screen_at(x, y)
	joypad.setanalog({['Touch X'] = x, ['Touch Y'] = y})
	hold_button("Touch")
	wait_frames(4) -- Hold input briefly since single-frame touchscreen inputs can be missed
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
	wait_frames(1)
end

function release_button(button)
	held_input[button] = false
	input[button] = false
	joypad.set(input)
	clear_unheld_inputs()
end

function press_sequence(...)
  for _, k in ipairs({...}) do
    if type(k) == "number" then
      wait_frames(k)
    else
      input[k] = true
      joypad.set(input)
  		wait_frames(1)
  		input[k] = false
    end
  end
end

-- Most frame advances go through this function, meaning 
-- it can update the game state for other functions without needing asynchronosity
function wait_frames(frames)
	for _ = 1, frames do
		joypad.set(input)
		emu.frameadvance()
		update_pointers()
		update_game_info()
		poll_dashboard_response()
	end

	clear_unheld_inputs()
end

function clear_unheld_inputs()
	for k, _ in pairs(input) do
		if k ~= "Touch X" and k ~= "Touch Y" and not held_input[k] then
	  	input[k] = false
	  end
	end

	joypad.set(input)
end

function clear_all_inputs()
	for k, _ in pairs(input) do
		if k ~= "Touch X" and k ~= "Touch Y" then
	  	input[k] = false
		held_input[k] = false
	  end
	end

	joypad.set(input)
end

function input_init()
	input = joypad.get()

	-- Initialise with no held inputs
	held_input = input
	for k, _ in pairs(held_input) do
		held_input[k] = false
	end

	clear_unheld_inputs()

	return input
end
