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

	local mem_shift = mdword(0x21C0794)
	offset.battle_state = mem_shift + 0x44878
	offset.battle_state_value = mbyte(offset.battle_state) --01 is FIGHT menu, 04 is Move Select, 08 is Bag,
	offset.current_pokemon = mem_shift + 0x475B8        -- 0A is POkemon menu 0E is animation
	offset.foe_in_battle = offset.current_pokemon + 0xC0
	offset.current_hp = mword(offset.current_pokemon + 0x4C)
	offset.level = mbyte(offset.current_pokemon + 0x34)
	offset.foe_current_hp = mword(offset.foe_in_battle + 0x4C)
	offset.facing_direction = mbyte(mem_shift + 0x238A4)
	--gui.text(100, 100, offset.trainer_x)
	--console.log(string.format("%04X", mword(offset.map_header)))
	--console.log(offset.battle_state_value)
end
