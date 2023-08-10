
function validate_offsets()
	offset.party_count = mdword(0x021D10EC) + 14
	offset.party_data = offset.party_count + 4
end
