
RAM = {}

function RAM.readdword(addr)
	return memory.read_u32_le(addr, "Main RAM")
end

function RAM.readword(addr)
	return memory.read_u16_le(addr, "Main RAM")
end

function RAM.readbyte(addr)
	return memory.read_u8(addr, "Main RAM")
end