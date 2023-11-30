
-----------------------
-- DP FUNCTION OVERRIDES
-----------------------

function update_pointers()
	local mem_shift = mdword(0x21C0794)
	
	pointers = {
		party_count = mem_shift + 0xB0,
		party_data  = mem_shift + 0xB4,

		foe_count 	= mem_shift + 0x28AE0,
		current_foe = mem_shift + 0x28AE4,
		
		map_header	= mem_shift + 0x1294,
		trainer_x 	= mem_shift + 0x129A,
		trainer_z 	= mem_shift + 0x129E,
		trainer_y 	= mem_shift + 0x12A2,
		facing		= mem_shift + 0x238A4,
		
		battle_state_value = mem_shift + 0x44878, -- 01 is FIGHT menu, 04 is Move Select, 08 is Bag,
		battle_indicator   = 0x021D18F2 -- static
	}
end
