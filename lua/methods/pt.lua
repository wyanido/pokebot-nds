
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

	-- TODO replace the methods that depend on these pointers
	local mem_shift = mdword(0x21C0794)
	
	pointers.in_starter_battle = mbyte(pointers.battle_indicator)
	pointers.current_pokemon   = mem_shift + 0x475B8        -- 0A is POkemon menu 0E is animation
	pointers.foe_in_battle	   = pointers.current_pokemon + 0xC0
	pointers.foe_status		   = pointers.foe_in_battle + 0x6C
	pointers.current_hp		   = mword(pointers.current_pokemon + 0x4C)
	pointers.level			   = mbyte(pointers.current_pokemon + 0x34)
	pointers.foe_current_hp	   = mword(pointers.foe_in_battle + 0x4C)
	pointers.foe_PID		   = mdword(pointers.foe_in_battle + 0x68)
	pointers.foe_TID		   = mword(pointers.foe_in_battle + 0x74)
	pointers.foe_SID		   = mword(pointers.foe_in_battle + 0x75)
	pointers.saveFlag		   = mbyte(mem_shift + 0x2832A)
	pointers.fishOn			   = mbyte(0x021CF636)
end
