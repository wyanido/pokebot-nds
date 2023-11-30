
-----------------------
-- DP FUNCTION OVERRIDES
-----------------------

function update_pointers()
	pointers.party_count = mdword(0x021BF65C) + 18
	pointers.party_data = pointers.party_count + 4

	pointers.foe_count = mdword(0x21C07DC) + 0x7304
	pointers.current_foe = pointers.foe_count + 4
	
	local mem_shift = mdword(0x21C0794)
	
	pointers.map_header 		  = mem_shift + 0x1294
	pointers.trainer_x 		  = pointers.map_header + 4 + 2
	pointers.trainer_y 		  = pointers.map_header + 12 + 2
	pointers.trainer_z 		  = pointers.map_header + 8 + 2
	pointers.facing_direction	  = mbyte(mem_shift + 0x238A4)
	
	pointers.battle_indicator   = 0x021D18F2 -- Static
	pointers.in_starter_battle  = mbyte(pointers.battle_indicator)
	pointers.battle_state 	  = mem_shift + 0x44878
	pointers.battle_state_value = mbyte(pointers.battle_state) --01 is FIGHT menu, 04 is Move Select, 08 is Bag,
	pointers.current_pokemon	  = mem_shift + 0x475B8        -- 0A is POkemon menu 0E is animation
	pointers.foe_in_battle	  = pointers.current_pokemon + 0xC0
	pointers.foe_status		  = pointers.foe_in_battle + 0x6C
	pointers.current_hp		  = mword(pointers.current_pokemon + 0x4C)
	pointers.level			  = mbyte(pointers.current_pokemon + 0x34)
	pointers.foe_current_hp	  = mword(pointers.foe_in_battle + 0x4C)
	pointers.foe_PID			  = mdword(pointers.foe_in_battle + 0x68)
	pointers.foe_TID			  = mword(pointers.foe_in_battle + 0x74)
	pointers.foe_SID			  = mword(pointers.foe_in_battle + 0x75)
	pointers.saveFlag			  = mbyte(mem_shift + 0x2832A)
	pointers.fishOn			  = mbyte(0x021CF636)
end
