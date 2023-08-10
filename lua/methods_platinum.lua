
function validate_offsets()
	offset.party_count = mdword(0x021BF65C) + 18
	offset.party_data = offset.party_count + 4
end
