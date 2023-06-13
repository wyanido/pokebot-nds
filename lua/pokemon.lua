
local pokemon = {}
-- local json = require "json.lua"

function pokemon.read_data(address)
	function rand(seed)
		return (0x41C64E6D * seed) + 0x00006073
	end

	function blockDataString(offset, length)
	    local data = ""
	    
	    for i = 0, length - 1, 2 do
	        local value = monTable[offset + i - 0x07] + (monTable[offset + i - 0x07] << 8)
	        
	        if value == 0xFFFF or value == 0x0000 then
	        	break
	        else
		        data = data .. utf8.char(value & 0xFF)
		    end
	    end
	    return data
	end

	function loopTable(dataTable, offset, length)
		local data = 0 
		for i = 0, length - 1 do
			data = data + (dataTable[offset + i] << i * 8)
		end
		return data
	end

	function blockData(offset, length)
		return loopTable(monTable, offset - 0x07, length)
	end

	function battleData(offset, length)
		return loopTable(battleStats, offset - 0x87, length)
	end

	function substructSelector(index)
		local ss = {
			[ 0] = {0, 1, 2, 3},
			[ 1] = {0, 1, 3, 2},
			[ 2] = {0, 2, 1, 3},
			[ 3] = {0, 3, 1, 2},
			[ 4] = {0, 2, 3, 1},
			[ 5] = {0, 3, 2, 1},
			[ 6] = {1, 0, 2, 3},
			[ 7] = {1, 0, 3, 2},
			[ 8] = {2, 0, 1, 3},
			[ 9] = {3, 0, 1, 2},
			[10] = {2, 0, 3, 1},
			[11] = {3, 0, 2, 1},
			[12] = {1, 2, 0, 3},
			[13] = {1, 3, 0, 2},
			[14] = {2, 1, 0, 3},
			[15] = {3, 1, 0, 2},
			[16] = {2, 3, 0, 1},
			[17] = {3, 2, 0, 1},
			[18] = {1, 2, 3, 0},
			[19] = {1, 3, 2, 0},
			[20] = {2, 1, 3, 0},
			[21] = {3, 1, 2, 0},
			[22] = {2, 3, 1, 0},
			[23] = {3, 2, 1, 0},
		}

	  return ss[index]
	end

	mon = {}

	-- Unencrypted bytes
	mon.pid 		= mem.readdword(address)
	mon.checksum 	= mem.readword(address + 0x06)
	
	-- Encrypted Blocks
	block = { {}, {}, {}, {} }
	
	seed = mon.checksum

	-- 128 byte block data is decrypted in 2 byte pairs
	for i = 0x08, 0x87, 2 do
	    local word = memory.read_u16_le(address + i, "Main RAM")

	    seed = rand(seed)
	    local decryptedByte = word ~ (seed >> 16)
	    local endBytes = decryptedByte & 0xFFFF

	    local blockIndex = math.floor((i - 0x08) / 32) + 1
	    
	    -- Insert the two end bytes as single bytes
	    table.insert(block[blockIndex], endBytes & 0xFF)
	    table.insert(block[blockIndex], (endBytes >> 8) & 0xFF)
	end

	-- Inverse block order
	shift = ((mon.pid & 0x3E000) >> 0xD) % 24
	blockOrder = substructSelector(shift)

	monTable = {}
	
	-- Iterate through each block and reorganise the data into a single master table
	for i = 1, 4 do
		thisBlock = block[blockOrder[i] + 1]

	    for j = 1, 32 do
	        table.insert(monTable, thisBlock[j])
	    end
	end
	
	-- Verify checksums
	-- If the mon data is invalid, assume it's unprepared or garbage data
	sum = 0
	
	for i = 1, #monTable, 2 do
	  sum = sum + monTable[i] + (monTable[i + 1] << 8)
	end

	sum = sum & 0xFFFF

	if sum ~= mon.checksum then
		return nil
	end

	-- Block A
	mon.species 			= blockData(0x08, 2)
	mon.heldItem 			= blockData(0x0A, 2)
	mon.otID 				= blockData(0x0C, 2)
	mon.otSID 				= blockData(0x0E, 2)
	mon.experience 			= blockData(0x10, 3)
	mon.friendship 			= blockData(0x14, 1)
	mon.ability 			= blockData(0x15, 1)
	-- mon.markings 			= blockData(0x16, 1)
	mon.otLanguage 			= blockData(0x17, 1)
	mon.hpEV 				= blockData(0x18, 1)
	mon.attackEV 			= blockData(0x19, 1)
	mon.defenseEV 			= blockData(0x1A, 1)
	mon.speedEV 			= blockData(0x1B, 1)
	mon.spAttackEV 			= blockData(0x1C, 1)
	mon.spDefenseEV 		= blockData(0x1D, 1)
	-- mon.cool 				= blockData(0x1E, 1)
	-- mon.beauty 				= blockData(0x1F, 1)
	-- mon.cute 				= blockData(0x20, 1)
	-- mon.smart 				= blockData(0x21, 1)
	-- mon.tough 				= blockData(0x22, 1)
	-- mon.sheen 				= blockData(0x23, 1)
	-- mon.sinnohRibbonSet1 	= blockData(0x24, 2)
	-- mon.unovaRibbonSet 		= blockData(0x26, 2)

	-- Block B
	mon.moves = {
		blockData(0x28, 2),
		blockData(0x2A, 2),
		blockData(0x2C, 2),
		blockData(0x2E, 2)
	}
	
	mon.pp = {
		blockData(0x30, 1),
		blockData(0x31, 1),
		blockData(0x32, 1),
		blockData(0x33, 1)
	}
	
	mon.ppUps				= blockData(0x34, 4)
	
	local data = blockData(0x38, 5)
	mon.hpIV				= (data >>  0) & 0x1F
	mon.attackIV 			= (data >>  5) & 0x1F
	mon.defenseIV 			= (data >> 10) & 0x1F
	mon.speedIV 			= (data >> 15) & 0x1F
	mon.spAttackIV 			= (data >> 20) & 0x1F
	mon.spDefenseIV			= (data >> 25) & 0x1F
	mon.isEgg				= (data >> 30) & 0x01
	mon.isNicknamed			= (data >> 31) & 0x01

	-- mon.hoennRibbonSet1		= blockData(0x3C, 2)
	-- mon.hoennRibbonSet2		= blockData(0x3E, 2)

	local data = blockData(0x40, 1)
	-- mon.fatefulEncounter 	= (data >> 0) & 0x01
	mon.gender 				= (data >> 1) & 0x03
	mon.altForm				= (data >> 3) & 0x1F

	mon.nature				= blockData(0x41, 1)

	local data = blockData(0x42, 1)
	mon.dreamWorldAbility	= data & 0x01
	mon.isNsPokemon			= data & 0x02

	-- Block C
	mon.nickname 			= blockDataString(0x48, 21)

	-- mon.originGame			= blockData(0x5F, 1)
	-- mon.sinnohRibbonSet3	= blockData(0x60, 2)
	-- mon.sinnohRibbonSet3	= blockData(0x62, 2)
	
	-- Block D
	mon.otName 				= blockDataString(0x68, 16)
	-- mon.dateEggReceived		= blockData(0x78, 3)
	-- mon.dateMet				= blockData(0x7B, 3)
	-- mon.eggLocation			= blockData(0x7E, 2)
	-- mon.metLocation			= blockData(0x80, 2)
	mon.pokerus				= blockData(0x82, 1)
	mon.pokeball			= blockData(0x83, 1)
	-- mon.encounterType		= blockData(0x85, 1)

	-- Battle stats
	battleStats = {}
	seed = mon.pid
	
	-- Battle stats are also encrypted in 2-byte pairs
	-- # TODO combine both decryption loops into a single method
	for i = 0x88, 0xDB, 2 do
	    local word = memory.read_u16_le(address + i, "Main RAM")

	    seed = rand(seed)
	    local decryptedByte = word ~ (seed >> 16)
	    local endBytes = decryptedByte & 0xFFFF

	    -- Insert the two end bytes as single bytes
	    table.insert(battleStats, endBytes & 0xFF)
	    table.insert(battleStats, (endBytes >> 8) & 0xFF)
	end

	mon.status				= battleData(0x88, 1)
	mon.level				= battleData(0x8C, 1)
	-- mon.capsuleIndex		= battleData(0x8D, 1)
	mon.currentHP			= battleData(0x8E, 2)
	mon.maxHP				= battleData(0x90, 2)
	mon.attack				= battleData(0x92, 2)
	mon.defense				= battleData(0x94, 2)
	mon.speed				= battleData(0x96, 2)
	mon.spAttack			= battleData(0x98, 2)
	mon.spDefense			= battleData(0x9A, 2)
	-- mon.mailMessage			= battleData(0x9C, 37)
	
	mon.shinyValue 			= mon.otID ~ mon.otSID ~ ((mon.pid >> 16) & 0xFFFF) ~ (mon.pid & 0xFFFF)
	mon.shiny 				= mon.shinyValue < 8

	return mon
end

function write_file(filename, value)
    local file = io.open(filename, "w")

    if file then
	    file:write(value)
	    file:close()
	    return true
	else
		return false
	end
end

function pokemon.log(mon)
	-- Values not relevant to encounters
	-- Gets trimmed before being logged
	local excess_keys = {
		"nickname",
		"hpEV",
		"attackEV", 
		"defenseEV", 
		"spAttackEV",
		"spDefenseEV",
		"speedEV",
		"dreamWorldAbility", 
		"friendship",
		"isEgg",
		"isNicknamed",
		"otLanguage",
		"otName",
		"pokeball",
		"pokerus",
		"ppUps",
		"status"
	}

	-- Statistics
	local iv_sum = mon.hpIV + mon.attackIV + mon.defenseIV + mon.spAttackIV + mon.spDefenseIV + mon.speedIV
	stats.highest_iv_sum = math.max(stats.highest_iv_sum, iv_sum)
	stats.encounters = stats.encounters + 1
	stats.lowest_sv = math.min(mon.shinyValue, stats.lowest_sv)

	write_file("logs/stats.json", json.encode(stats))
	
	console.log("--------------")
	console.log("Seen mon #" .. stats.encounters .. ": a " .. mon.nature .. " " .. mon.name .. "!")
	console.log("HP: " .. mon.hpIV ..", ATK: " .. mon.attackIV .. ", DEF: " .. mon.defenseIV .. ", SP.ATK: " .. mon.spAttackIV .. ", SP.DEF: " .. mon.spDefenseIV .. ", SPD: " .. mon.speedIV)
	console.log("Shiny Value: " .. mon.shinyValue .. ", Shiny?: " .. tostring(mon.shiny))
	console.log("")
	console.log("Highest IV sum: " .. stats.highest_iv_sum)
	console.log("Lowest shiny value: " .. stats.lowest_sv)
	console.log("--------------")

	-- Remove excess keys
	for i = 1, #mon, 1 do
	    local key = mon[i]
	    for _, excess_key in ipairs(excess_keys) do
			if key == excess_key then
				table.remove(mon, i)
	        	break
	      	end
		end
	end

	table.insert(encounters, mon)

	write_file("logs/encounters.json", json.encode(encounters))
	
	while #encounters > ENCOUNTER_LOG_LIMIT do
	    table.remove(encounters, 1)
	end
end

return pokemon