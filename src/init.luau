local fs = require("@lune/fs")
local process = require("@lune/process")

local data_buffer = buffer.fromstring(fs.readFile(`samples/{process.args[1]}.header`))

type HHeader = {
	signature: string,
	string_size: number,
}

type StringOffsets = {
	__start: number,
	__end: number,
}

local function parseHeader(): HHeader
	local signature_u32 = buffer.readu32(data_buffer, 0)

	local data = {
		signature = utf8.char(
			bit32.band(signature_u32, 0xFF),
			bit32.band(bit32.rshift(signature_u32, 8), 0xFF),
			bit32.band(bit32.rshift(signature_u32, 16), 0xFF),
			bit32.rshift(signature_u32, 24)
		),
		string_size = buffer.readu8(data_buffer, 8),
	}

	return data
end

local function parseString(offsets: StringOffsets): string
	local result = ""

	for i = offsets.__start, offsets.__end - 1 do
		result ..= string.char(buffer.readu8(data_buffer, i))
	end

	return result
end

local function parseIDs(header_data: HHeader): { number }
	local IDs = {}

	for i = 0, (header_data.string_size - 1) * 4, 4 do
		table.insert(IDs, buffer.readu32(data_buffer, 16 + i))
	end

	return IDs
end

local function parseOffsets(header_data: HHeader): { StringOffsets }
	local offsets = {}
	local read_offset = header_data.string_size * 4

	for i = 0, (header_data.string_size - 2) * 4, 4 do
		table.insert(offsets, {
			__start = buffer.readu16(data_buffer, (16 + read_offset) + i),
			__end = buffer.readu16(data_buffer, (20 + read_offset) + i),
		})
	end

	table.insert(offsets, {
		__start = offsets[#offsets].__end,
		__end = buffer.len(data_buffer),
	})

	return offsets
end

local function parseAll()
    local header = parseHeader()
    local IDs = parseIDs(header)
    local offsets = parseOffsets(header)
    local data = {}
    
    for i, ID in IDs do
        data[ID] = parseString(offsets[i])
    end

    return data
end

print(parseAll())
