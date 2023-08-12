console.log("\nTrying to establish a connection to the dashboard...")

comm.socketServerSetTimeout(50)
comm.socketServerSetIp("127.0.0.1") -- Refreshes the connection, the dashboard suppresses the disconnect error this usually causes in favour of an easy solution
comm.socketServerSend('{ "type": "comm_check" }' .. "\x00")

console.log("Dashboard connected at server " .. comm.socketServerGetInfo())
comm.socketServerSetTimeout(5)

config = nil

local disconnected = false

function poll_dashboard_response()
	-- Check for server packets frequently
	if emu.framecount() % 20 ~= 0 then
		return
	end
	
	local response = comm.socketServerResponse()

	-- If the dashboard couldn't be detected, poll it less often
	if not comm.socketServerSuccessful() then
		if not disconnected then
			console.log("### Dashboard disconnected! ### ")
			disconnected = true
		end

		comm.socketServerSetTimeout(1000)
		emu.frameadvance() -- Prevents freeze
		return
	end

	-- Ignore blank responses
	if response == nil or response == "" then
		return
	end

	response = json.decode(response)

	-- Interpret message
	if response.type == "init" then
		comm.socketServerSend(json.encode({
			type = "init",
			data = {
				gen = gen,
				game = game_name,
			}
		}) .. "\x00")

		if response.data.page == "dashboard" then
			-- Show game data and stats on page load
			comm.socketServerSend(json.encode({
				type = "party",
				data = party,
			}) .. "\x00")
		end
	elseif response.type == "apply_config" then
		if config == nil then
			console.log("Config initialised!")
			console.log("---------------------------")
		else
			console.log("### Config Updated ###")
		end

		config = response.data.config
	end
end
