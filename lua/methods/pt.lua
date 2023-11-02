
-----------------------
-- DP FUNCTION OVERRIDES
-----------------------

function update_pointers()
	offset.party_count = mdword(0x021BF65C) + 18
	offset.party_data = offset.party_count + 4

	offset.foe_count = mdword(0x21C07DC) + 0x7304
	offset.current_foe = offset.foe_count + 4

	offset.map_header = mdword(0x21C0794) + 0x1294
    offset.trainer_x = offset.map_header + 4 + 2
    offset.trainer_y = offset.map_header + 12 + 2
    offset.trainer_z = offset.map_header + 8 + 2

	offset.battle_indicator = 0x021D18F2 -- Static
	
	-- console.log(string.format("%08X", offset.foe_count))
end
