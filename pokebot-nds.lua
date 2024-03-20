-----------------------
-- INITIALISATION
-----------------------
dofile("lua\\detect_emu.lua")

print("Pokebot NDS v1.0-beta by NIDO (wyanido)")
print("Running " .. _VERSION .. " on " .. _EMU)
print("https://github.com/wyanido/pokebot-nds")
print("")

-- Clear values that might linger after restarting script
game_state = nil
config = nil
foe = nil
party_hash = ""
party = {}

pokemon = require("lua\\pokemon")
dofile("lua\\input.lua")
dofile("lua\\detect_game.lua")
dofile("lua\\dashboard.lua")
dofile("lua\\helpers.lua")

-----------------------
-- MAIN BOT LOOP
-----------------------
local mode_function = _G["mode_" .. config.mode] -- Get the respective global scope function for the current bot mode
    
if not mode_function then
    abort("Function for mode '" .. config.mode .. "' does not exist. It may not be compatible with this game.")
end

print("---------------------------")
print("Bot mode set to " .. config.mode)

while true do
    joypad.set(input)
    process_frame()
    clear_unheld_inputs()
    
    mode_function()
end