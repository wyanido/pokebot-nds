function update_pointers()
    local anchor = mdword(0x21C0794 + _ROM.offset)
	local foe_anchor = mdword(anchor + 0x217A8)
    
	pointers = {
        start_value = 0x2101008, -- 0 until save has been loaded
		party_count = anchor + 0xB0,
		party_data  = anchor + 0xB4,

		foe_count 	= foe_anchor - 0x2D5C,
		current_foe = foe_anchor - 0x2D58,
		
		map_header	= anchor + 0x1294,
        menu_option = 0x21C4C86 + _ROM.offset,
		trainer_x   = 0x21C5CE4 + _ROM.offset,
        trainer_y   = 0x21C5CE8 + _ROM.offset,
        trainer_z   = 0x21C5CEC + _ROM.offset,
		facing		= anchor + 0x238A4,
		
        bike_gear = anchor + 0x1320,
        bike      = anchor + 0x1324,
        
        daycare_egg = anchor + 0x1840,

        selected_starter = anchor + 0x41850,
        starters_ready   = anchor + 0x418D4,

		battle_menu_state      = anchor + 0x44878, -- 01 is FIGHT menu, 04 is Move Select, 08 is Bag,
		battle_menu_state2     = anchor + 0x7E282,
		battle_indicator       = 0x021D18F2 + _ROM.offset,
        fishing_bite_indicator = 0x021CF636 + _ROM.offset,

        trainer_name = anchor + 0x7C,
        trainer_id   = anchor + 0x8C,

        roamer = mdword(anchor + 0x28364),
	}
end