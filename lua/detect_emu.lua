-----------------------------------------------------------------------------
-- Emulator detection and setup
-- Author: wyanido
-- Homepage: https://github.com/wyanido/pokebot-nds
--
-- Defines important functions to ensure behavioural consistency
-- across different emulators and Lua versions.
-----------------------------------------------------------------------------

function print_debug(message)
    if config.debug then
        print("- " .. message)
    end
end

function print_warn(message)
    print("# " .. message .. " #")
end

local game_is_loaded

_EMU = bizstring ~= nil and "BizHawk" or "DeSmuME" -- Arbitrary method for emulator detection, assuming only BizHawk or DeSmuME will be used

if _EMU == "BizHawk" then
    mbyte = memory.read_u8
    mword = memory.read_u16_le
    mdword = memory.read_u32_le

    game_is_loaded = gameinfo.getromhash() ~= ""
    
    function soft_reset()
        press_button("Power")
        randomise_reset()
    end

    console.clear()

    client.clearautohold()

    -- Suppress deprecation warnings for bitwise operations replaced in newer versions of BizHawk.
    -- The bot uses the old methods to maintain compatibility with DeSmuME which still uses them
    bit = (require "migration_helpers").EmuHawk_pre_2_9_bit();
    
    -- When stopped, attempt to restore display and reset the touch screen position override
    event.onexit(function() 
        joypad.setanalog({['Touch X'] = nil, ['Touch Y'] = nil})
        client.clearautohold() 
        client.invisibleemulation(false)
    end)
else
    mbyte = memory.readbyte
    mword = memory.readwordunsigned
    mdword = memory.readdwordunsigned
    
    game_is_loaded = emu.emulating()
    
    function soft_reset()
        emu.reset()
        randomise_reset()
    end

    -- Lua 5.1 compatability scripts
    require("lua\\compatability\\utf8")
    require("lua\\compatability\\table")
end

if not game_is_loaded then
    error("Please load a ROM before enabling the script!")
end