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

-- Buffer library functions

BufferStreamStatic.readu8 = buffer.readu8
BufferStreamStatic.writeu8 = buffer.writeu8
BufferStreamStatic.readu16 = buffer.readu16
BufferStreamStatic.writeu16 = buffer.writeu16
BufferStreamStatic.readu32 = buffer.readu32
BufferStreamStatic.writeu32 = buffer.writeu32
BufferStreamStatic.readi8 = buffer.readi8
BufferStreamStatic.writei8 = buffer.writei8
BufferStreamStatic.readi16 = buffer.readi16
BufferStreamStatic.writei16 = buffer.writei16
BufferStreamStatic.readi32 = buffer.readi32
BufferStreamStatic.writei32 = buffer.writei32
BufferStreamStatic.readf32 = buffer.readf32
BufferStreamStatic.writef32 = buffer.writef32
BufferStreamStatic.readf64 = buffer.readf64
BufferStreamStatic.writef64 = buffer.writef64

-- Buffer library extensions

function BufferStreamStatic.readu24(b: buffer, offset: number)
	local low = buffer.readu16(b, offset)
	local high = buffer.readu8(b, offset + 2)
	return high * 65536 + low
end

function BufferStreamStatic.writeu24(b: buffer, offset: number, value: number)
	buffer.writeu16(b, offset, value)
	buffer.writeu8(b, offset + 2, bit32.rshift(value, 16))
end

function BufferStreamStatic.readu64(b: buffer, offset: number)
	local low = buffer.readu32(b, offset)
	local high = buffer.readu32(b, offset + 4)
	return high * 4294967296 + low
end

function BufferStreamStatic.writeu64(b: buffer, offset: number, value: number)
	local low = value % 4294967296
	local high = math.floor(value / 4294967296)
	buffer.writeu32(b, offset, low)
	buffer.writeu32(b, offset + 4, high)
end

function BufferStreamStatic.readi24(b: buffer, offset: number)
	local low = buffer.readu16(b, offset)
	local high = buffer.readi8(b, offset + 2)
	return high * 65536 + low
end

-- two's complement means the low 24 bits are the same as the unsigned write
BufferStreamStatic.writei24 = BufferStreamStatic.writeu24

function BufferStreamStatic.readi64(b: buffer, offset: number)
	local low = buffer.readu32(b, offset)
	local high = buffer.readi32(b, offset + 4)
	return high * 4294967296 + low
end

function BufferStreamStatic.writei64(b: buffer, offset: number, value: number)
	local low = value % 4294967296
	local high = math.floor(value / 4294967296)
	buffer.writeu32(b, offset, low)
	buffer.writei32(b, offset + 4, high)
end

function BufferStreamStatic.readf8(b: buffer, offset: number)
	local packed = buffer.readu8(b, offset)

	local sign = bit32.extract(packed, 7, 1) == 1 and -1 or 1
	local exponent = bit32.extract(packed, 3, 4)
	local fraction = bit32.extract(packed, 0, 3)

	if exponent == 0 then
		return sign * (fraction / 8) * math.pow(2, -6)
	end

	return sign * (1 + fraction / 8) * math.pow(2, exponent - 7)
end

function BufferStreamStatic.writef8(b: buffer, offset: number, value: number)
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

	buffer.writeu8(b, offset, packed)
end

function BufferStreamStatic.readf16(b: buffer, offset: number)
	local packed = buffer.readu16(b, offset)

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

function BufferStreamStatic.writef16(b: buffer, offset: number, value: number)
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

	buffer.writeu16(b, offset, packed)
end

-- 1 sign bit, 7 exponent bits (bias 63), 16 fraction bits
function BufferStreamStatic.readf24(b: buffer, offset: number)
	local packed = BufferStreamStatic.readu24(b, offset)

	local sign = bit32.extract(packed, 23, 1) == 1 and -1 or 1
	local exponent = bit32.extract(packed, 16, 7)
	local fraction = bit32.extract(packed, 0, 16)

	if exponent == 0 then
		return sign * (fraction / 65536) * math.pow(2, -62)
	elseif exponent == 127 then
		return fraction == 0 and (sign * math.huge) or (0 / 0)
	end

	return sign * (1 + fraction / 65536) * math.pow(2, exponent - 63)
end

local function packf24(value: number)
	if value == 0 then
		return 0
	elseif value ~= value then
		return 0x7FFFFF
	end

	local sign = value < 0 and 1 or 0
	local magnitude = math.abs(value)
	local exponent, fraction

	if magnitude == math.huge then
		exponent, fraction = 127, 0
	else
		local mantissa
		mantissa, exponent = math.frexp(magnitude)
		exponent = exponent + 62

		if exponent <= 0 then
			-- subnormal, rounding may carry into the smallest normal exponent
			exponent, fraction = 0, math.round(magnitude / math.pow(2, -62) * 65536)
		else
			fraction = math.round((mantissa * 2 - 1) * 65536)
			if fraction == 65536 then
				exponent, fraction = exponent + 1, 0
			end
			if exponent >= 127 then
				exponent, fraction = 127, 0
			end
		end
	end

	return sign * 0x800000 + exponent * 65536 + fraction
end

function BufferStreamStatic.writef24(b: buffer, offset: number, value: number)
	BufferStreamStatic.writeu24(b, offset, packf24(value))
end

-- Methods

function BufferStreamClass.copy(self: BufferStream)
	local copy = buffer.create(self.length)
	buffer.copy(copy, 0, self.buffer)
	local stream = BufferStreamStatic.static(copy)
	stream.dynamic = self.dynamic
	return stream
end

function BufferStreamClass.getLength(self: BufferStream)
	return self.length
end

function BufferStreamClass.getCursor(self: BufferStream)
	return self.cursor
end

function BufferStreamClass.setCursor(self: BufferStream, cursor: number)
	self.cursor = math.clamp(cursor, 0, self.length)
end

function BufferStreamClass.skip(self: BufferStream, bytes: number)
	self:setCursor(self.cursor + bytes)
end

local function expand(self: BufferStream, bytes: number)
	self.length = self.length + bytes
	local expanded = buffer.create(self.length)
	buffer.copy(expanded, 0, self.buffer)
	self.buffer = expanded
end

local function dynamicWrite<T...>(self: BufferStream, bytes: number, callback: (buffer, number, T...) -> (), ...: T...)
	if self.dynamic then
		local newCursor = self.cursor + bytes
		if newCursor > self.length then
			expand(self, newCursor - self.length)
		end
	end
	callback(self.buffer, self.cursor, ...)
	self.cursor = self.cursor + bytes
end

function BufferStreamClass.expand(self: BufferStream, bytes: number)
	assert(self.dynamic, "Cannot expand a static buffer stream.")
	expand(self, bytes)
end

function BufferStreamClass.readUnsignedBytes(self: BufferStream, bytes: number)
	local bits = bytes * 8
	-- selene: allow(incorrect_standard_library_use)
	local result = buffer.readbits(self.buffer, self.cursor * 8, bits)
	self.cursor = self.cursor + bytes
	return result
end

local function writebits(b: buffer, offset: number, bytes: number, value: number)
	-- selene: allow(incorrect_standard_library_use)
	return buffer.writebits(b, offset * 8, bytes * 8, value)
end

function BufferStreamClass.writeUnsignedBytes(self: BufferStream, bytes: number, value: number)
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

function BufferStreamClass.readu24(self: BufferStream)
	local result = BufferStreamStatic.readu24(self.buffer, self.cursor)
	self.cursor = self.cursor + 3
	return result
end

function BufferStreamClass.writeu24(self: BufferStream, value: number)
	return dynamicWrite(self, 3, BufferStreamStatic.writeu24, value)
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
	local result = BufferStreamStatic.readu64(self.buffer, self.cursor)
	self.cursor = self.cursor + 8
	return result
end

function BufferStreamClass.writeu64(self: BufferStream, value: number)
	return dynamicWrite(self, 8, BufferStreamStatic.writeu64, value)
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

function BufferStreamClass.readi24(self: BufferStream)
	local result = BufferStreamStatic.readi24(self.buffer, self.cursor)
	self.cursor = self.cursor + 3
	return result
end

function BufferStreamClass.writei24(self: BufferStream, value: number)
	return dynamicWrite(self, 3, BufferStreamStatic.writei24, value)
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
	local result = BufferStreamStatic.readi64(self.buffer, self.cursor)
	self.cursor = self.cursor + 8
	return result
end

function BufferStreamClass.writei64(self: BufferStream, value: number)
	return dynamicWrite(self, 8, BufferStreamStatic.writei64, value)
end

function BufferStreamClass.readf8(self: BufferStream)
	local result = BufferStreamStatic.readf8(self.buffer, self.cursor)
	self.cursor = self.cursor + 1
	return result
end

function BufferStreamClass.writef8(self: BufferStream, value: number)
	return dynamicWrite(self, 1, BufferStreamStatic.writef8, value)
end

function BufferStreamClass.readf16(self: BufferStream)
	local result = BufferStreamStatic.readf16(self.buffer, self.cursor)
	self.cursor = self.cursor + 2
	return result
end

function BufferStreamClass.writef16(self: BufferStream, value: number)
	return dynamicWrite(self, 2, BufferStreamStatic.writef16, value)
end

function BufferStreamClass.readf24(self: BufferStream)
	local result = BufferStreamStatic.readf24(self.buffer, self.cursor)
	self.cursor = self.cursor + 3
	return result
end

function BufferStreamClass.writef24(self: BufferStream, value: number)
	return dynamicWrite(self, 3, BufferStreamStatic.writef24, value)
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

function BufferStreamClass.readString(self: BufferStream, bytes: number)
	local result = buffer.readstring(self.buffer, self.cursor, bytes)
	self.cursor = self.cursor + bytes
	return result
end

function BufferStreamClass.writeString(self: BufferStream, value: string, count: number?)
	local length = (count or #value)
	dynamicWrite(self, length, buffer.writestring, value, length)
end

function BufferStreamClass.readBuffer(self: BufferStream, bytes: number)
	local b = buffer.create(bytes)
	buffer.copy(b, 0, self.buffer, self.cursor, bytes)
	self.cursor = self.cursor + bytes
	return b
end

function BufferStreamClass.writeBuffer(self: BufferStream, b: buffer, offset: number?, count: number?)
	local length = count or buffer.len(b)
	dynamicWrite(self, length, buffer.copy, b, offset or 0, length)
end

--

return BufferStreamStatic
