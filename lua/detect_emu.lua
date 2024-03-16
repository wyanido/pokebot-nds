_EMU = bizstring ~= nil and "BizHawk" or "DeSmuME"

local game_loaded

if _EMU == "BizHawk" then
    bit = (require "migration_helpers").EmuHawk_pre_2_9_bit(); -- Suppress deprecation warnings
    console.clear()
    
    mbyte = function(addr) return memory.read_u8(math.max(addr, 0)) end
    mword = function(addr) return memory.read_u16_le(math.max(addr, 0)) end
    mdword = function(addr) return memory.read_u32_le(math.max(addr, 0)) end

    game_loaded = gameinfo.getromhash() ~= ""

    client.clearautohold()
    -- When the script is stopped, restore display
    -- and touch screen ability
    event.onexit(function() 
        client.clearautohold() 
        client.invisibleemulation(false)
    end)

    function soft_reset()
        press_button("Power")
        randomise_reset()
    end
else
    mbyte = function(addr) return memory.readbyte(math.max(addr, 0)) end
    mword = function(addr) return memory.readwordunsigned(math.max(addr, 0)) end
    mdword = function(addr) return memory.readdwordunsigned(math.max(addr, 0)) end
    
    game_loaded = emu.emulating()
    
    function soft_reset()
        emu.reset()
        randomise_reset()
    end

    -- Lua 5.1 compatability
    require("lua\\compatability\\utf8")
    require("lua\\compatability\\table")
end

if not game_loaded then
    error("Please load a ROM before enabling the script!")
end

print_debug = function(message)
    if config.debug then
        print("- " .. message)
    end
end

print_warn = function(message)
    print("# " .. message .. " #")
end