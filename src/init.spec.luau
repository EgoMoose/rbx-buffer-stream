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

describe("readUnsignedBytes", function()
	local b = buffer.create(4)
	local stream = BufferStream.static(b)

	it("should read 1 byte", function()
		stream.cursor = 0
		buffer.writeu8(b, 0, 78)
		local u8 = stream:readUnsignedBytes(1)
		expect(u8).toEqual(78)
	end)

	it("should read 2 bytes", function()
		stream.cursor = 0
		buffer.writeu16(b, 0, 1234)
		local u16 = stream:readUnsignedBytes(2)
		expect(u16).toEqual(1234)
	end)

	it("should read 4 bytes", function()
		stream.cursor = 0
		buffer.writeu32(b, 0, 1_000_000)
		local u32 = stream:readUnsignedBytes(4)
		expect(u32).toEqual(1_000_000)
	end)

	it("should not read signed integers", function()
		stream.cursor = 0
		buffer.writeu8(b, 0, -78)
		local u8 = stream:readUnsignedBytes(1)
		expect(u8 == -78).toEqual(false)
	end)
end)

describe("writeUnsignedBytes", function()
	local stream = BufferStream.static(buffer.create(4))

	it("should write 1 byte", function()
		stream.cursor = 0
		stream:writeUnsignedBytes(1, 78)
		local u8 = buffer.readu8(stream.buffer, 0)
		expect(u8).toEqual(78)
	end)

	it("should write 2 bytes", function()
		stream.cursor = 0
		stream:writeUnsignedBytes(2, 1234)
		local u16 = buffer.readu16(stream.buffer, 0)
		expect(u16).toEqual(1234)
	end)

	it("should write 4 bytes", function()
		stream.cursor = 0
		stream:writeUnsignedBytes(4, 1_000_000)
		local u32 = buffer.readu32(stream.buffer, 0)
		expect(u32).toEqual(1_000_000)
	end)

	it("should not write signed integers", function()
		stream.cursor = 0
		stream:writeUnsignedBytes(1, -78)
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

describe("readu24 / writeu24", function()
	local b = buffer.create(3)
	local stream = BufferStream.static(b)

	it("should read & write u24s", function()
		stream:writeu24(0xFFFFFF)
		stream.cursor = 0
		local u24 = stream:readu24()
		expect(u24).toEqual(0xFFFFFF)
		expect(stream.cursor).toEqual(3)
	end)

	it("should be little endian", function()
		stream.cursor = 0
		stream:writeu24(0x123456)
		expect(buffer.readu8(b, 0)).toEqual(0x56)
		expect(buffer.readu8(b, 1)).toEqual(0x34)
		expect(buffer.readu8(b, 2)).toEqual(0x12)
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

describe("readi24 / writei24", function()
	local b = buffer.create(3)
	local stream = BufferStream.static(b)

	it("should read & write i24s", function()
		for _, value in { -8388608, -1_000_023, -1, 0, 1, 8388607 } do
			stream.cursor = 0
			stream:writei24(value)
			stream.cursor = 0
			local i24 = stream:readi24()
			expect(i24).toEqual(value)
		end
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

describe("readf8 / writef8", function()
	local b = buffer.create(1)
	local stream = BufferStream.static(b)

	it("should read & write f8s", function()
		stream:writef8(-1)
		stream.cursor = 0
		local f8 = stream:readf8()
		expect(f8).toEqual(-1)
		expect(stream.cursor).toEqual(1)
	end)
end)

describe("readf16 / writef16", function()
	local b = buffer.create(2)
	local stream = BufferStream.static(b)

	it("should read & write f16s", function()
		stream:writef16(1)
		stream.cursor = 0
		local f16 = stream:readf16()
		expect(f16).toEqual(1)
		expect(stream.cursor).toEqual(2)
	end)
end)

describe("readf24 / writef24", function()
	local b = buffer.create(3)
	local stream = BufferStream.static(b)

	local function roundtrip(value: number)
		stream.cursor = 0
		stream:writef24(value)
		stream.cursor = 0
		return stream:readf24()
	end

	it("should read & write f24s", function()
		for _, value in { 0, 1, -1, 0.5, 1234.5, -65535 } do
			expect(roundtrip(value)).toEqual(value)
		end
		expect(stream.cursor).toEqual(3)
	end)

	it("should approximate values", function()
		expect(math.abs(roundtrip(math.pi) - math.pi) < 1e-4).toEqual(true)
	end)

	it("should handle subnormals", function()
		local value = math.pow(2, -70)
		expect(roundtrip(value)).toEqual(value)
	end)

	it("should handle infinity & nan", function()
		expect(roundtrip(math.huge)).toEqual(math.huge)
		expect(roundtrip(-math.huge)).toEqual(-math.huge)
		expect(roundtrip(1e300)).toEqual(math.huge)

		local nan = roundtrip(0 / 0)
		expect(nan ~= nan).toEqual(true)
	end)
end)

describe("readf32", function()
	local b = buffer.create(4)
	buffer.writef32(b, 0, 1)
	local stream = BufferStream.static(b)

	it("should read f32s", function()
		local f32 = stream:readf32()
		expect(f32).toEqual(1)
	end)
end)

describe("writef32", function()
	local stream = BufferStream.static(buffer.create(4))

	it("should write f32s", function()
		stream:writef32(1)
		local f32 = buffer.readf32(stream.buffer, 0)
		expect(f32).toEqual(1)
	end)
end)

describe("readf64", function()
	local b = buffer.create(8)
	buffer.writef64(b, 0, 1)
	local stream = BufferStream.static(b)

	it("should read f64s", function()
		local f64 = stream:readf64()
		expect(f64).toEqual(1)
	end)
end)

describe("writef64", function()
	local stream = BufferStream.static(buffer.create(8))

	it("should write f64s", function()
		stream:writef64(1)
		local f64 = buffer.readf64(stream.buffer, 0)
		expect(f64).toEqual(1)
	end)
end)

local HELLO = "Hello world!"
local HELLO_LEN = #HELLO

describe("readString", function()
	local b = buffer.fromstring(HELLO)
	local stream = BufferStream.static(b)

	it("should read strings", function()
		local str = stream:readString(HELLO_LEN)
		expect(str).toEqual(HELLO)
	end)
end)

describe("writeString", function()
	local stream = BufferStream.static(buffer.create(HELLO_LEN))

	it("should read strings", function()
		stream:writeString(HELLO)
		local str = buffer.readstring(stream.buffer, 0, HELLO_LEN)
		expect(str).toEqual(HELLO)
	end)
end)

describe("readBuffer", function()
	local b = buffer.fromstring(HELLO)
	local stream = BufferStream.static(b)

	it("should read buffers", function()
		local readB = stream:readBuffer(buffer.len(b))
		expect(typeof(readB)).toEqual("buffer")
		expect(buffer.tostring(readB)).toEqual(buffer.tostring(b))
	end)
end)

describe("writeBuffer", function()
	local bLen = buffer.len(buffer.fromstring(HELLO))
	local stream = BufferStream.static(buffer.create(bLen))

	it("should read strings", function()
		stream:writeBuffer(buffer.fromstring(HELLO))
		local readB = buffer.fromstring(buffer.readstring(stream.buffer, 0, bLen))
		expect(typeof(readB)).toEqual("buffer")
		expect(buffer.tostring(readB)).toEqual(HELLO)
	end)
end)

describe("expand", function()
	it("should expand dynamic streams", function()
		local stream = BufferStream.dynamic(buffer.create(4))
		stream:expand(8)
		expect(stream.length).toEqual(4 + 8)
	end)

	it("should not expand static streams", function()
		local stream = BufferStream.static(buffer.create(4))
		local success, _err = pcall(function()
			stream:expand(8)
		end)
		expect(success).toEqual(false)
		expect(stream.length).toEqual(4)
	end)
end)

describe("buffer library functions", function()
	local cases: { { any } } = {
		{ "u8", 1, 122 },
		{ "u16", 2, 10267 },
		{ "u24", 3, 0xFFFFFF },
		{ "u32", 4, 1_000_023 },
		{ "u64", 8, 0xFFFFFFFF + 1 },
		{ "i8", 1, -122 },
		{ "i16", 2, -10267 },
		{ "i24", 3, -1_000_023 },
		{ "i32", 4, -1_000_023 },
		{ "i64", 8, -0xFFFFFFFF },
		{ "f8", 1, -1 },
		{ "f16", 2, 1 },
		{ "f24", 3, 1234.5 },
		{ "f32", 4, 1.5 },
		{ "f64", 8, math.pi },
	}

	for _, case in cases do
		local name, bytes, value = case[1], case[2], case[3]

		it(`should read & write {name}s at an offset`, function()
			local b = buffer.create(bytes + 2)
			BufferStream[`write{name}`](b, 1, value)
			expect(BufferStream[`read{name}`](b, 1)).toEqual(value)
			expect(buffer.readu8(b, 0)).toEqual(0)
			expect(buffer.readu8(b, bytes + 1)).toEqual(0)
		end)

		it(`should match the stream {name} methods`, function()
			local b = buffer.create(bytes)
			BufferStream[`write{name}`](b, 0, value)

			local stream = BufferStream.static(buffer.create(bytes))
			stream[`write{name}`](stream, value)
			expect(buffer.tostring(stream.buffer)).toEqual(buffer.tostring(b))
		end)
	end

	it("should read buffers at an offset", function()
		local b = buffer.fromstring(HELLO)
		local readB = BufferStream.readbuffer(b, 6, 5)
		expect(buffer.tostring(readB)).toEqual("world")
		expect(readB == b).toEqual(false)
	end)

	it("should write buffers at an offset", function()
		local b = buffer.fromstring("Hello there!")
		BufferStream.writebuffer(b, 6, buffer.fromstring("--world--"), 2, 5)
		expect(buffer.tostring(b)).toEqual(HELLO)
	end)

	it("should write the whole buffer by default", function()
		local b = buffer.create(HELLO_LEN + 2)
		BufferStream.writebuffer(b, 1, buffer.fromstring(HELLO))
		expect(buffer.readstring(b, 1, HELLO_LEN)).toEqual(HELLO)
	end)

	it("should write the rest of the source by default", function()
		local b = buffer.fromstring("Hello there!")
		BufferStream.writebuffer(b, 6, buffer.fromstring("--world!"), 2)
		expect(buffer.tostring(b)).toEqual(HELLO)
	end)

	it("should read & write strings at an offset", function()
		local b = buffer.create(HELLO_LEN + 2)
		BufferStream.writestring(b, 1, HELLO)
		expect(BufferStream.readstring(b, 1, HELLO_LEN)).toEqual(HELLO)
		expect(buffer.readu8(b, 0)).toEqual(0)
		expect(buffer.readu8(b, HELLO_LEN + 1)).toEqual(0)
	end)

	it("should write part of a string", function()
		local b = buffer.fromstring("Hello there!")
		BufferStream.writestring(b, 6, "world!!!", 5)
		expect(buffer.tostring(b)).toEqual(HELLO)
	end)

	it("should read & write unsigned bytes at an offset", function()
		for _, bytes in { 1, 2, 3, 4 } do
			local value = 2 ^ (bytes * 8) - 2
			local b = buffer.create(bytes + 2)
			BufferStream.writeubytes(b, 1, bytes, value)
			expect(BufferStream.readubytes(b, 1, bytes)).toEqual(value)
			expect(buffer.readu8(b, 0)).toEqual(0)
			expect(buffer.readu8(b, bytes + 1)).toEqual(0)
		end
	end)
end)

describe("writeBuffer defaults", function()
	it("should write the rest of the source from an offset by default", function()
		local stream = BufferStream.dynamic(buffer.create(0))
		stream:writeBuffer(buffer.fromstring("--Hello world!"), 2)
		expect(buffer.tostring(stream.buffer)).toEqual(HELLO)
		expect(stream:getCursor()).toEqual(HELLO_LEN)
	end)
end)

describe("cursor modifiers", function()
	local stream = BufferStream.dynamic(buffer.create(0))

	stream:writeu8(10)
	stream:writef64(math.pi)
	stream:writef16(0)

	it("should have its cursor at the end of the stream", function()
		expect(stream:getCursor()).toEqual(stream:getLength())
	end)

	it("shouldn't be possible to have the cursor past the end of the stream", function()
		stream:setCursor(stream:getLength() + 10)
		expect(stream:getCursor()).toEqual(stream:getLength())
	end)

	it("should reset the cursor to the front of the stream", function()
		stream:setCursor(0)
		expect(stream:getCursor()).toEqual(0)
	end)

	it("should read the three values", function()
		local u8 = stream:readu8()
		local f64 = stream:readf64()
		local f16 = stream:readf16()

		expect(u8).toEqual(10)
		expect(f64).toEqual(math.pi)
		expect(f16).toEqual(0)
	end)

	it("should jump to a specific bytes", function()
		stream:setCursor(1)
		local f64 = stream:readf64()
		expect(f64).toEqual(math.pi)
	end)

	it("should advance the cursor past small floats", function()
		local small = BufferStream.dynamic(buffer.create(0))
		small:writef8(-1)
		small:writef16(1)
		small:writef24(2)
		small:writeu8(10)

		small:setCursor(0)
		expect(small:readf8()).toEqual(-1)
		expect(small:readf16()).toEqual(1)
		expect(small:readf24()).toEqual(2)
		expect(small:readu8()).toEqual(10)
		expect(small:getCursor()).toEqual(small:getLength())
	end)

	it("should skip past certain bytes", function()
		stream:setCursor(0)
		stream:skip(9)
		local f16 = stream:readf16()
		expect(f16).toEqual(0)
	end)
end)
