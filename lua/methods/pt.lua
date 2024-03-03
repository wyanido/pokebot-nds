-----------------------
-- DP FUNCTION OVERRIDES
-----------------------

function update_pointers()
	local mem_shift = mdword(0x21C0794)
	-- Static Pokemon data is inconsistent between locations & resets,
    -- so find the current offset using a relative value	
	local foe_offset = mdword(mem_shift + 0x217A8)
	
	pointers = {
		party_count = mem_shift + 0xB0,
		party_data  = mem_shift + 0xB4,

		foe_count 	= foe_offset - 0x2D5C,
		current_foe = foe_offset - 0x2D58,
		
		map_header	= mem_shift + 0x1294,
		trainer_x 	= mem_shift + 0x129A,
		trainer_z 	= mem_shift + 0x129E,
		trainer_y 	= mem_shift + 0x12A2,
		facing		= mem_shift + 0x238A4,
		
		battle_state_value = mem_shift + 0x44878, -- 01 is FIGHT menu, 04 is Move Select, 08 is Bag,
		battle_indicator   = 0x021D18F2, -- static
        fishing_bite_indicator = 0x021CF636,

        trainer_name = mem_shift + 0x7C,
        trainer_id = mem_shift + 0x8C
	}
	
	-- TODO replace the methods that depend on these pointers
	pointers.current_pokemon   = mem_shift + 0x475B8        -- 0A is POkemon menu 0E is animation
	pointers.foe_in_battle	   = pointers.current_pokemon + 0xC0
	pointers.foe_status		   = pointers.foe_in_battle + 0x6C
	pointers.current_hp		   = mword(pointers.current_pokemon + 0x4C)
	pointers.level			   = mbyte(pointers.current_pokemon + 0x34)
	pointers.foe_current_hp	   = mword(pointers.foe_in_battle + 0x4C)
	pointers.saveFlag		   = mbyte(mem_shift + 0x2832A)
end

function mode_starters(starter) --starters for platinum
    console.log("Waiting to reach overworld...")
    wait_frames(200)

    while mbyte(pointers.battle_indicator) == 0x1D do
        local delay = math.random(6, 21) -- Mimic imperfect human inputs
        press_sequence("A", delay)
    end

    while mbyte(pointers.battle_indicator) ~= 0xFF do
        local delay = math.random(6, 21) -- Mimic imperfect human inputs
        press_sequence("A", delay)
    end
    --we can save right in front of the bag in platinum so all we have to do is open and select are starter

    -- Open briefcase and skip through dialogue until starter select
    console.log("Skipping dialogue to briefcase...")
    local selected_starter = mdword(0x2101DEC) + 0x203E8 -- 0: Turtwig, 1: Chimchar, 2: Piplup
    local starters_ready = selected_starter + 0x84       -- 0 before hand appears, A94D afterwards

    while not (mdword(starters_ready) > 0) do
        press_button("B")
        wait_frames(2)
    end

    -- Need to wait for hand to be visible to find offset
    console.log("Selecting starter...")

    -- Highlight and select target
    while mdword(selected_starter) < starter do
        press_sequence("Right", 10)
    end

    while #party == 0 do
        press_sequence("A", 6)
    end

    console.log("Waiting to see starter...")
    if config.hax then
        mon = party[1]
        local was_target = pokemon.log_encounter(mon)
        if was_target then
            abort("Starter meets target specs!")
        else
            press_button("Power")
        end
    else
        while game_state.in_battle do
            press_sequence(12, "A")
        end
        while game_state.in_battle and pointers.battle_state_value == 0 do
            press_sequence("B", 5)
        end
        wait_frames(50)
        mon = party[1]
        local was_target = pokemon.log_encounter(mon)
        if was_target then
            abort("Starter meets target specs!")
        else
            console.log("Starter was not a target, resetting...")
            selected_starter = 0
            starters_ready = 0
            press_button("Power")
        end
    end
end
