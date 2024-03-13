-----------------------
-- DP FUNCTION OVERRIDES
-----------------------

function update_pointers()
    local anchor = mdword(0x21C0794 + _ROM.mem_shift)
	local foe_offset = mdword(anchor + 0x217A8)
    
	pointers = {
		party_count = anchor + 0xB0,
		party_data  = anchor + 0xB4,

		foe_count 	= foe_offset - 0x2D5C,
		current_foe = foe_offset - 0x2D58,
		
		map_header	= anchor + 0x1294,
		trainer_x 	= anchor + 0x129A,
		trainer_z 	= anchor + 0x129E,
		trainer_y 	= anchor + 0x12A2,
		facing		= anchor + 0x238A4,
		
        selected_starter = anchor + 0x41850,
        starters_ready   = anchor + 0x418D4,

		battle_state_value = anchor + 0x44878, -- 01 is FIGHT menu, 04 is Move Select, 08 is Bag,
		battle_indicator   = 0x021D18F2, -- static
        fishing_bite_indicator = 0x021CF636,

        trainer_name = anchor + 0x7C,
        trainer_id = anchor + 0x8C
	}
	
	-- TODO replace the methods that depend on these pointers
	pointers.current_pokemon   = anchor + 0x475B8        -- 0A is POkemon menu 0E is animation
	pointers.foe_in_battle	   = pointers.current_pokemon + 0xC0
	pointers.foe_status		   = pointers.foe_in_battle + 0x6C
	pointers.current_hp		   = mword(pointers.current_pokemon + 0x4C)
	pointers.level			   = mbyte(pointers.current_pokemon + 0x34)
	pointers.foe_current_hp	   = mword(pointers.foe_in_battle + 0x4C)
	pointers.saveFlag		   = mbyte(anchor + 0x2832A)
end
