
if _EMU == "BizHawk" then
    function touch_screen_at(x, y)
        joypad.setanalog({['Touch X'] = x, ['Touch Y'] = y})
        hold_button("Touch")
        wait_frames(4) -- Hold touch briefly, single-frame touchscreen inputs may be missed
        release_button("Touch")
    end
else
    function touch_screen_at(x, y)
        stylus.set({x = x, y = y, touch = true})
        wait_frames(4) -- Hold touch briefly, single-frame touchscreen inputs may be missed
        stylus.set({touch = false})
    end
end 

function press_button(button)
    button = adjust_case(button)
    input[button] = true
    joypad.set(input)
    wait_frames(4)
    release_button(button)
end

function hold_button(button)
    button = adjust_case(button)
    held_input[button] = true
    input[button] = true

    -- Release conflicting D-pad inputs
    local opposite
    if     string.lower(button) == "left"  then opposite = "Right"
    elseif string.lower(button) == "right" then opposite = "Left"
    elseif string.lower(button) == "down"  then opposite = "Up"
    elseif string.lower(button) == "up"    then opposite = "Down" end
    
    if opposite then
        opposite = adjust_case(opposite)
        
        held_input[opposite] = false
        input[opposite] = false
    end

    joypad.set(input)
    wait_frames(1)
end

function release_button(button)
    button = adjust_case(button)
    held_input[button] = false
    input[button] = false
    joypad.set(input)
    clear_unheld_inputs()
end

-- Adjust for differences in d-pad key names between emulators
function adjust_case(button)
    if _EMU == "DeSmuME" then
        if button == "Up" or button == "Down" or button == "Left" or button == "Right" then 
            return string.lower(button)
        end
    end

    return button
end

function press_sequence(...)
    for _, k in ipairs({...}) do
        if type(k) == "number" then
            wait_frames(k)
        else
            press_button(k)
        end
    end
end

-- Most frame advances go through this function, meaning 
-- it can update the game state for other functions without needing asynchronosity
function wait_frames(frames)
    for _ = 1, frames do
        joypad.set(input)
        process_frame()
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
    for k, _ in pairs(held_input) do held_input[k] = false end

    clear_unheld_inputs()

    return input
end