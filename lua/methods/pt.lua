-----------------------
-- DP FUNCTION OVERRIDES
-----------------------

function update_pointers()
    local anchor = mdword(0x21C0794 + _ROM.offset)
	local foe_anchor = mdword(anchor + 0x217A8)
    
	pointers = {
		party_count = anchor + 0xB0,
		party_data  = anchor + 0xB4,

		foe_count 	= foe_anchor - 0x2D5C,
		current_foe = foe_anchor - 0x2D58,
		
		map_header	= anchor + 0x1294,
		trainer_x 	= anchor + 0x129A,
		trainer_z 	= anchor + 0x129E,
		trainer_y 	= anchor + 0x12A2,
		facing		= anchor + 0x238A4,
        save_indicator = anchor + 0x2832A,
		
        selected_starter = anchor + 0x41850,
        starters_ready   = anchor + 0x418D4,

		battle_state_value     = anchor + 0x44878, -- 01 is FIGHT menu, 04 is Move Select, 08 is Bag,
		battle_indicator       = 0x021D18F2, -- static
        fishing_bite_indicator = 0x021CF636,

        trainer_name = anchor + 0x7C,
        trainer_id   = anchor + 0x8C
	}
end
