local socket = require('lua\\modules\\socket')

local disconnected = false

function poll_dashboard_response()
    if disconnected then
        return
    end
    
    local _, err, data = dashboard:receive()
    
    if data and data ~= "" then
        response = json.decode(data)
        
        if response.type == "apply_config" then
            if config ~= nil then
                print_debug("Config updated")
            end

            config = response.data.config
        elseif response.type == "disconnect" then
            print_warn("Dashboard disconnected!")
            disconnected = true
        end
    elseif err == 'closed' then
        print_warn("Dashboard disconnected abruptly!")
        disconnected = true
    elseif err ~= 'timeout' then
        print_warn('Error: ' .. err)
    end
end

print("Connecting to the dashboard... ")

local status, err = pcall(function () 
    dashboard = assert(socket.connect('127.0.0.1', 51055)) 
end)
if err then
    print("WARNING: Failed to connect! The bot will function as normal, but logging and realtime config updates will be unavailable.")

    config = json.load("user\\config.json")
    disconnected = true
    
    dashboard = {
        send = function() end
    }
    return
end

dashboard:settimeout(0)
dashboard:send(json.encode({
    type = "load_game",
    data = _ROM
}) .. "\0")

print("Waiting for dashboard to relay config file... ")

while config == nil do
    poll_dashboard_response()
    emu.frameadvance()
end