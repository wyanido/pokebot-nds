
-----------------------
-- DP FUNCTION OVERRIDES
-----------------------

function update_pointers()
	offset.party_count = mdword(0x021D10EC) + 14
	offset.party_data = offset.party_count + 4

	offset.foe_count = mdword(0x21D4158) + 0x7574
	offset.current_foe = offset.foe_count + 4

	-- console.log(string.format("%08X", offset.foe_count))
end
