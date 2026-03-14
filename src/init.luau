--!strict

local BufferStreamStatic = {}

local BufferStreamClass = {}
BufferStreamClass.__index = BufferStreamClass
BufferStreamClass.ClassName = "BufferStream"

export type BufferStream = typeof(setmetatable(
	{} :: {
		b: buffer,
		cursor: number,
		length: number,
	},
	BufferStreamClass
))

function BufferStreamStatic.new(b: buffer)
	local self = setmetatable({}, BufferStreamClass) :: BufferStream

	self.b = b
	self.cursor = 0
	self.length = buffer.len(b)

	return self
end

-- Methods

@native
function BufferStreamClass.readu(self: BufferStream, bits: number)
	local result = buffer.readbits(self.b, self.cursor, bits)
	self.cursor = self.cursor + bits
	return result
end

@native
function BufferStreamClass.writeu(self: BufferStream, bits: number, value: number)
	buffer.writebits(self.b, self.cursor, bits, value)
	self.cursor = self.cursor + bits
end

@native
function BufferStreamClass.readi(self: BufferStream, bits: number)
	local unsignedValue = buffer.readbits(self.b, self.cursor, bits)
	self.cursor = self.cursor + bits
	if unsignedValue >= 2 ^ (bits - 1) then
		return unsignedValue - (2 ^ bits)
	end
	return unsignedValue
end

@native
function BufferStreamClass.writei(self: BufferStream, bits: number, value: number)
	if value < 0 then
		value = value + (2 ^ bits)
	end
	buffer.writebits(self.b, self.cursor, bits, value)
	self.cursor = self.cursor + bits
end

--

return BufferStreamStatic
