--!strict

local BufferStreamStatic = {}

local BufferStreamClass = {}
BufferStreamClass.__index = BufferStreamClass
BufferStreamClass.ClassName = "BufferStream"

export type BufferStream = typeof(setmetatable(
	{} :: {
		buffer: buffer,
		cursor: number,
		length: number,
		dynamic: boolean,
	},
	BufferStreamClass
))

function BufferStreamStatic.static(b: buffer)
	local self = setmetatable({}, BufferStreamClass) :: BufferStream

	self.buffer = b
	self.cursor = 0
	self.length = buffer.len(b)
	self.dynamic = false

	return self
end

function BufferStreamStatic.dynamic(b: buffer)
	local stream = BufferStreamStatic.static(b)
	stream.dynamic = true
	return stream
end

-- Methods

function BufferStreamClass.copy(self: BufferStream)
	local copy = buffer.create(self.length)
	buffer.copy(copy, 0, self.buffer)
	local stream = BufferStreamStatic.static(copy)
	stream.dynamic = self.dynamic
	return stream
end

function BufferStreamClass.getCursor(self: BufferStream)
	return self.cursor
end

function BufferStreamClass.setCursor(self: BufferStream, cursor: number)
	self.cursor = math.clamp(cursor, 0, self.length)
end

local function dynamicWrite<T...>(self: BufferStream, bytes: number, callback: (buffer, number, T...) -> (), ...: T...)
	if self.dynamic then
		local newCursor = self.cursor + bytes
		if newCursor > self.length then
			self.length = self.length + (newCursor - self.length)
			local expanded = buffer.create(self.length)
			buffer.copy(expanded, 0, self.buffer)
			self.buffer = expanded
		end
	end
	callback(self.buffer, self.cursor, ...)
	self.cursor = self.cursor + bytes
end

function BufferStreamClass.readbytes(self: BufferStream, bytes: number)
	local bits = bytes * 8
	local result = buffer.readbits(self.buffer, self.cursor * 8, bits)
	self.cursor = self.cursor + bytes
	return result
end

local function writebits(b: buffer, offset: number, bytes: number, value: number)
	return buffer.writebits(b, offset * 8, bytes * 8, value)
end

function BufferStreamClass.writebytes(self: BufferStream, bytes: number, value: number)
	return dynamicWrite(self, bytes, writebits, bytes, value)
end

function BufferStreamClass.readu8(self: BufferStream)
	local result = buffer.readu8(self.buffer, self.cursor)
	self.cursor = self.cursor + 1
	return result
end

function BufferStreamClass.writeu8(self: BufferStream, value: number)
	return dynamicWrite(self, 1, buffer.writeu8, value)
end

function BufferStreamClass.readu16(self: BufferStream)
	local result = buffer.readu16(self.buffer, self.cursor)
	self.cursor = self.cursor + 2
	return result
end

function BufferStreamClass.writeu16(self: BufferStream, value: number)
	return dynamicWrite(self, 2, buffer.writeu16, value)
end

function BufferStreamClass.readu32(self: BufferStream)
	local result = buffer.readu32(self.buffer, self.cursor)
	self.cursor = self.cursor + 4
	return result
end

function BufferStreamClass.writeu32(self: BufferStream, value: number)
	return dynamicWrite(self, 4, buffer.writeu32, value)
end

function BufferStreamClass.readu64(self: BufferStream)
	local low = buffer.readu32(self.buffer, self.cursor)
	local high = buffer.readu32(self.buffer, self.cursor + 4)
	self.cursor = self.cursor + 8
	return high * 4294967296 + low
end

local function writeu64(b: buffer, offset: number, value: number)
	local low = value % 4294967296
	local high = math.floor(value / 4294967296)
	buffer.writeu32(b, offset, low)
	buffer.writeu32(b, offset + 4, high)
end

function BufferStreamClass.writeu64(self: BufferStream, value: number)
	return dynamicWrite(self, 8, writeu64, value)
end

function BufferStreamClass.readi8(self: BufferStream)
	local result = buffer.readi8(self.buffer, self.cursor)
	self.cursor = self.cursor + 1
	return result
end

function BufferStreamClass.writei8(self: BufferStream, value: number)
	return dynamicWrite(self, 1, buffer.writei8, value)
end

function BufferStreamClass.readi16(self: BufferStream)
	local result = buffer.readi16(self.buffer, self.cursor)
	self.cursor = self.cursor + 2
	return result
end

function BufferStreamClass.writei16(self: BufferStream, value: number)
	return dynamicWrite(self, 2, buffer.writei16, value)
end

function BufferStreamClass.readi32(self: BufferStream)
	local result = buffer.readi32(self.buffer, self.cursor)
	self.cursor = self.cursor + 4
	return result
end

function BufferStreamClass.writei32(self: BufferStream, value: number)
	return dynamicWrite(self, 4, buffer.writei32, value)
end

function BufferStreamClass.readi64(self: BufferStream)
	local low = buffer.readu32(self.buffer, self.cursor)
	local high = buffer.readi32(self.buffer, self.cursor + 4)
	self.cursor = self.cursor + 8
	return high * 4294967296 + low
end

local function writei64(b: buffer, offset: number, value: number)
	local low = value % 4294967296
	local high = math.floor(value / 4294967296)
	buffer.writeu32(b, offset, low)
	buffer.writei32(b, offset + 4, high)
end

function BufferStreamClass.writei64(self: BufferStream, value: number)
	return dynamicWrite(self, 8, writei64, value)
end

function BufferStreamClass.readf8(self: BufferStream)
	local packed = buffer.readu8(self.buffer, self.cursor)

	local sign = bit32.extract(packed, 7, 1) == 1 and -1 or 1
	local exponent = bit32.extract(packed, 3, 4)
	local fraction = bit32.extract(packed, 0, 3)

	if exponent == 0 then
		return sign * (fraction / 8) * math.pow(2, -6)
	end

	return sign * (1 + fraction / 8) * math.pow(2, exponent - 7)
end

function BufferStreamClass.writef8(self: BufferStream, value: number)
	local packed = 0
	if value ~= 0 then
		local sign = value < 0 and 1 or 0
		local mantissa, exponent = math.frexp(math.abs(value))
		local frac = math.round((mantissa * 2 - 1) * 8)

		-- stylua: ignore
		packed = bit32.bor(
			bit32.lshift(sign, 7),
			bit32.lshift(math.clamp(exponent + 6, 0, 15), 3),
			math.clamp(frac, 0, 7)
		)
	end

	return dynamicWrite(self, 1, buffer.writeu8, packed)
end

function BufferStreamClass.readf16(self: BufferStream)
	local packed = buffer.readu16(self.buffer, self.cursor)

	local sign = bit32.extract(packed, 15, 1) == 1 and -1 or 1
	local exponent = bit32.extract(packed, 10, 5)
	local fraction = bit32.extract(packed, 0, 10)

	if exponent == 0 then
		return sign * (fraction / 1024) * math.pow(2, -14)
	elseif exponent == 31 then
		return fraction == 0 and (sign * math.huge) or (0 / 0)
	end

	return sign * (1 + fraction / 1024) * math.pow(2, exponent - 15)
end

function BufferStreamClass.writef16(self: BufferStream, value: number)
	local packed = 0
	if value ~= 0 then
		local sign = value < 0 and 1 or 0
		local mantissa, exponent = math.frexp(math.abs(value))
		local frac = math.round((mantissa * 2 - 1) * 1024)

		packed = bit32.bor(
			bit32.lshift(sign, 15),
			bit32.lshift(math.clamp(exponent + 14, 0, 31), 10),
			math.clamp(frac, 0, 1023)
		)
	end

	return dynamicWrite(self, 2, buffer.writeu16, packed)
end

function BufferStreamClass.readf32(self: BufferStream)
	local result = buffer.readf32(self.buffer, self.cursor)
	self.cursor = self.cursor + 4
	return result
end

function BufferStreamClass.writef32(self: BufferStream, value: number)
	return dynamicWrite(self, 4, buffer.writef32, value)
end

function BufferStreamClass.readf64(self: BufferStream)
	local result = buffer.readf64(self.buffer, self.cursor)
	self.cursor = self.cursor + 8
	return result
end

function BufferStreamClass.writef64(self: BufferStream, value: number)
	return dynamicWrite(self, 8, buffer.writef64, value)
end

--

return BufferStreamStatic
