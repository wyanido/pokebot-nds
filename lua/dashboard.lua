
local socket = require('lua\\modules\\socket')
print("Connecting to the dashboard... ")

dashboard = assert(socket.connect('127.0.0.1', 51055), "Failed to connect to the dashboard! Make sure the node.js server is running before starting this script.")
dashboard:settimeout(0)

config = nil

local disconnected = false

function poll_dashboard_response()
    if disconnected then
        return
    end
    
    local _, err, data = dashboard:receive()
    
    if data and data ~= "" then
        response = json.decode(data)
        
        if response.type == "apply_config" then
            if config == nil then
                print("---------------------------")
            else
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
        console.warning('Error: ' .. err)
    end
end
