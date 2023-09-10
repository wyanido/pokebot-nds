console.log("\nTrying to establish a connection to the dashboard...")

comm.socketServerSetTimeout(50)
comm.socketServerSetIp("127.0.0.1") -- Refreshes the connection, the dashboard suppresses the disconnect error this usually causes in favour of an easy solution
comm.socketServerSend('{"type":"comm_check"}' .. "\x00")

console.log("Dashboard connected at server " .. comm.socketServerGetInfo())
comm.socketServerSetTimeout(5)

config = nil

local disconnected = false

function poll_dashboard_response()
	-- Check for server packets twice per second
	if emu.framecount() % 30 ~= 0 or disconnected then
		return
	end
	
	-- comm.socketServerResponse() causes BizHawk to freeze when called on the same frame a socket disconnects
	local response = comm.socketServerResponse()
	
	if not comm.socketServerSuccessful() then
		if not disconnected then
			console.warning("Dashboard disconnected abruptly!")
			disconnected = true
		end

		emu.yield() -- Prevents freeze
		return
	end

	if response == nil or response == "" then -- Ignore blank responses
		return 
	end

	response = json.decode(response)

	if response.type == "apply_config" then
		if config == nil then
			console.log("Config initialised!")
			console.log("---------------------------")
		else
			console.debug("Config Updated")
		end

		config = response.data.config
	elseif response.type == "disconnect" then
		console.warning("Dashboard disconnected!")
		disconnected = true
	end
end
