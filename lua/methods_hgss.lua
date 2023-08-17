
-----------------------
-- DP FUNCTION OVERRIDES
-----------------------

function update_pointers()
	offset.party_count = mdword(0x021D10EC) + 14
	offset.party_data = offset.party_count + 4

	offset.foe_count = mdword(0x21D4158) + 0x7574
	offset.current_foe = offset.foe_count + 4

	offset.map_header = mdword(0x21D2228) + 0x1244
    offset.trainer_x = offset.map_header + 4 + 2
    offset.trainer_y = offset.map_header + 12 + 2
    offset.trainer_z = offset.map_header + 8 + 2

	-- console.log(string.format("%08X", offset.map_header))
end
