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
		trainer_x   = 0x21C5CCC,
        trainer_y   = 0x21C5CD0,
        trainer_z   = 0x21C5CD4,
		facing		= anchor + 0x238A4,
		
        bike_gear = anchor + 0x1320,
        bike      = anchor + 0x1324,
        
        daycare_pid = anchor + 0x1840,

        selected_starter = anchor + 0x41850,
        starters_ready   = anchor + 0x418D4,

		battle_state_value     = anchor + 0x44878, -- 01 is FIGHT menu, 04 is Move Select, 08 is Bag,
		battle_indicator       = 0x021D18F2, -- static
        fishing_bite_indicator = 0x021CF636,

        trainer_name = anchor + 0x7C,
        trainer_id   = anchor + 0x8C
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

function pathfind_to(target, on_step)
    if not target.x then
        target.x = game_state.trainer_x - 0.5
    elseif not target.z then
        target.z = game_state.trainer_z
    end

    while game_state.trainer_x <= target.x - 0.5 do
        hold_button("Right")
        if on_step then on_step() end
    end
    
    while game_state.trainer_x >= target.x + 1.5 do
        hold_button("Left")
        if on_step then on_step() end
    end
    
    while game_state.trainer_z < target.z - 1 do
        hold_button("Down")
        if on_step then on_step() end
    end
    
    while game_state.trainer_z > target.z + 1 do
        hold_button("Up")
        if on_step then on_step() end
    end
end