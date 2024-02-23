local socket = require('lua\\modules\\socket')

console.write("\nTrying to establish a connection to the dashboard... ")

dashboard = assert(socket.connect('127.0.0.1', 51055), "Failed to connect to the dashboard! Make sure the node.js server is running before starting this script.")
dashboard:settimeout(50)
dashboard:send('{"type":"comm_check"}' .. "\x00")

console.log("Connected!")
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
                console.log("Initialised!")
                console.log("---------------------------")
            else
                console.debug("Config updated")
            end

            config = response.data.config
        elseif response.type == "disconnect" then
            console.warning("Dashboard disconnected!")
            disconnected = true
        end
    elseif err == 'closed' then
        console.warning("Dashboard disconnected abruptly!")
        disconnected = true
    elseif err ~= 'timeout' then
        console.warning('Error: ' .. err)
    end
end
