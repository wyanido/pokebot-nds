-----------------------------------------------------------------------------
-- Main Pokebot NDS script
-- Author: wyanido
-- Homepage: https://github.com/wyanido/pokebot-nds
--
-- Responsible for loading the files appropriate to the current state,
-- including emulator, game, language, and configuration.
-----------------------------------------------------------------------------
package.cpath = package.cpath .. ";.\\lua\\modules\\?.dll" -- Allow socket.core to be detected beyond the project root
dofile("lua\\detect_emu.lua")

print("PokeBot NDS v1.1-beta by wyanido")
print("https://github.com/wyanido/pokebot-nds")
print("Running " .. _VERSION .. " on " .. _EMU)
print("")

-- Clear values that might linger after restarting the script
game_state = nil
config = nil
foe = nil
party = {}

pokemon = require("lua\\modules\\pokemon")
dofile("lua\\modules\\input.lua")
dofile("lua\\detect_game.lua")

if _ROM.gen > 5 then
    dofile("lua\\data\\misc_3ds.lua")
else
    dofile("lua\\data\\misc.lua")
end

dofile("lua\\modules\\dashboard.lua")
dofile("lua\\helpers.lua")

-- Get the respective global scope function for the current bot mode
local mode_function = _G["mode_" .. config.mode]

if not mode_function then
    abort("Function for mode '" .. config.mode .. "' does not exist. It may not be compatible with this game.")
end

print("---------------------------")
print("Bot mode set to " .. config.mode)

-----------------------------------------------------------------------------
-- MAIN LOOP
-----------------------------------------------------------------------------
while true do
    joypad.set(input)
    process_frame()
    clear_unheld_inputs()
    
    mode_function()
end