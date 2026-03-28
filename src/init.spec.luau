local JestGlobals = require(game.ReplicatedStorage.DevPackages.JestGlobals)

local it = JestGlobals.it
local expect = JestGlobals.expect
local describe = JestGlobals.describe

local BufferStream = require(script.Parent)

describe("copy", function()
	it("should copy the buffer", function()
		local stream = BufferStream.static(buffer.fromstring("Hello world!"))
		local copied = stream:copy()

		expect(stream.buffer == copied.buffer).toEqual(false)
		expect(buffer.tostring(stream.buffer)).toEqual(buffer.tostring(copied.buffer))
	end)
end)

describe("readbytes", function()
	local b = buffer.create(4)
	local stream = BufferStream.static(b)

	it("should read 1 byte", function()
		stream.cursor = 0
		buffer.writeu8(b, 0, 78)
		local u8 = stream:readbytes(1)
		expect(u8).toEqual(78)
	end)

	it("should read 2 bytes", function()
		stream.cursor = 0
		buffer.writeu16(b, 0, 1234)
		local u16 = stream:readbytes(2)
		expect(u16).toEqual(1234)
	end)

	it("should read 4 bytes", function()
		stream.cursor = 0
		buffer.writeu32(b, 0, 1_000_000)
		local u32 = stream:readbytes(4)
		expect(u32).toEqual(1_000_000)
	end)

	it("should not read signed integers", function()
		stream.cursor = 0
		buffer.writeu8(b, 0, -78)
		local u8 = stream:readbytes(1)
		expect(u8 == -78).toEqual(false)
	end)
end)

describe("writebytes", function()
	local stream = BufferStream.static(buffer.create(4))

	it("should write 1 byte", function()
		stream.cursor = 0
		stream:writebytes(1, 78)
		local u8 = buffer.readu8(stream.buffer, 0)
		expect(u8).toEqual(78)
	end)

	it("should write 2 bytes", function()
		stream.cursor = 0
		stream:writebytes(2, 1234)
		local u16 = buffer.readu16(stream.buffer, 0)
		expect(u16).toEqual(1234)
	end)

	it("should write 4 bytes", function()
		stream.cursor = 0
		stream:writebytes(4, 1_000_000)
		local u32 = buffer.readu32(stream.buffer, 0)
		expect(u32).toEqual(1_000_000)
	end)

	it("should not write signed integers", function()
		stream.cursor = 0
		stream:writebytes(1, -78)
		local u8 = buffer.readu8(stream.buffer, 0)
		expect(u8 == -78).toEqual(false)
	end)
end)

describe("readu8", function()
	local b = buffer.create(1)
	buffer.writeu8(b, 0, 122)
	local stream = BufferStream.static(b)

	it("should read u8s", function()
		local u8 = stream:readu8()
		expect(u8).toEqual(122)
	end)
end)

describe("writeu8", function()
	local stream = BufferStream.static(buffer.create(1))

	it("should write u8s", function()
		stream:writeu8(122)
		local u8 = buffer.readu8(stream.buffer, 0)
		expect(u8).toEqual(122)
	end)
end)

describe("readu16", function()
	local b = buffer.create(2)
	buffer.writeu16(b, 0, 10267)
	local stream = BufferStream.static(b)

	it("should read u16s", function()
		local u16 = stream:readu16()
		expect(u16).toEqual(10267)
	end)
end)

describe("writeu16", function()
	local stream = BufferStream.static(buffer.create(2))

	it("should write u16s", function()
		stream:writeu16(10267)
		local u16 = buffer.readu16(stream.buffer, 0)
		expect(u16).toEqual(10267)
	end)
end)

describe("readu32", function()
	local b = buffer.create(4)
	buffer.writeu32(b, 0, 1_000_023)
	local stream = BufferStream.static(b)

	it("should read u32s", function()
		local u32 = stream:readu32()
		expect(u32).toEqual(1_000_023)
	end)
end)

describe("writeu32", function()
	local stream = BufferStream.static(buffer.create(4))

	it("should write u32s", function()
		stream:writeu32(1_000_023)
		local u32 = buffer.readu32(stream.buffer, 0)
		expect(u32).toEqual(1_000_023)
	end)
end)

describe("readu64 / writeu64", function()
	local b = buffer.create(8)
	local stream = BufferStream.static(b)

	it("should read & write u64s", function()
		stream:writeu64(0xFFFFFFFF + 1)
		stream.cursor = 0
		local u64 = stream:readu64()
		expect(u64).toEqual(0xFFFFFFFF + 1)
	end)
end)

describe("readi8", function()
	local b = buffer.create(1)
	buffer.writei8(b, 0, -122)
	local stream = BufferStream.static(b)

	it("should read i8s", function()
		local i8 = stream:readi8()
		expect(i8).toEqual(-122)
	end)
end)

describe("writei8", function()
	local stream = BufferStream.static(buffer.create(1))

	it("should write i8s", function()
		stream:writei8(-122)
		local i8 = buffer.readi8(stream.buffer, 0)
		expect(i8).toEqual(-122)
	end)
end)

describe("readi16", function()
	local b = buffer.create(2)
	buffer.writei16(b, 0, -10267)
	local stream = BufferStream.static(b)

	it("should read i16s", function()
		local i16 = stream:readi16()
		expect(i16).toEqual(-10267)
	end)
end)

describe("writei16", function()
	local stream = BufferStream.static(buffer.create(2))

	it("should write i16s", function()
		stream:writei16(-10267)
		local i16 = buffer.readi16(stream.buffer, 0)
		expect(i16).toEqual(-10267)
	end)
end)

describe("readi32", function()
	local b = buffer.create(4)
	buffer.writei32(b, 0, -1_000_023)
	local stream = BufferStream.static(b)

	it("should read i32s", function()
		local i32 = stream:readi32()
		expect(i32).toEqual(-1_000_023)
	end)
end)

describe("writei32", function()
	local stream = BufferStream.static(buffer.create(4))

	it("should write i32s", function()
		stream:writei32(-1_000_023)
		local i32 = buffer.readi32(stream.buffer, 0)
		expect(i32).toEqual(-1_000_023)
	end)
end)

describe("readi64 / writei64", function()
	local b = buffer.create(8)
	local stream = BufferStream.static(b)

	it("should read & write i64s", function()
		stream:writei64(-0xFFFFFFFF)
		stream.cursor = 0
		local i64 = stream:readi64()
		expect(i64).toEqual(-0xFFFFFFFF)
	end)
end)
