-----------------------------------------------------------------------------
-- Dashboard connection and communication
-- Author: wyanido
-- Homepage: https://github.com/wyanido/pokebot-nds
-----------------------------------------------------------------------------
local socket = require("lua\\modules\\socket")
local json = require("lua\\modules\\json")

local disconnected = false

--- Manually loads the config file from the user directory
-- Only required when the dashboard connection fails to initialise, where
-- otherwise it would have been received in the initialisation stage
local function load_config_from_file()
    config = json.load("user\\config.json")
    
    if not config then
        abort("config.json couldn't be loaded! Please connect the bot to the dashboard at least once to generate the user/ folder.")
    end

    disconnected = true
end

--- Attempts to connect to the node server on the default port opened by the dashboard
local function dashboard_connect() 
    dashboard = assert(socket.connect("127.0.0.1", 51055)) 
end

--- Attempts to receive incoming data from the dashboard on the open socket
function dashboard_poll()
    if disconnected then
        return
    end
    
    local _, err, data = dashboard:receive()
    
    if data ~= "" then
        local response = json.decode(data)
        
        if response.type == "apply_config" then
            config = response.data.config
            print_debug("Config updated")
        end
    end

    if err == "closed" then
        print_warn("Dashboard disconnected!")
        disconnected = true
    end
end

--- Attempts to send data to the dashboard via the open socket
function dashboard_send(data)
    if disconnected then
        return 
    end

    dashboard:send(json.encode(data) .. "\0")
end

-----------------------------------------------------------------------------
-- DASHBOARD SOCKET INITIALISATION
-----------------------------------------------------------------------------
print("Connecting to the dashboard... ")

local status, err = pcall(dashboard_connect)

if err then
    print_warn("Failed to connect! The bot will function as normal, but logging and realtime config updates will be unavailable.")
    config = json.load("user\\config.json")

    if not config then
        abort("config.json couldn't be loaded! Please connect the bot to the dashboard at least once to generate the user/ folder.")
    end

    disconnected = true
    return
end

dashboard:settimeout(0)
dashboard_send({
    type = "load_game",
    data = _ROM
})

print("Waiting for dashboard to relay config file... ")

--- Keep emulator running until the dashboard sends the config file
while not config do
    dashboard_poll()

    if _EMU == "BizHawk" then
        emu.yield() -- Allows BizHawk to connect even while the game is paused
    else
        emu.frameadvance()
    end
end