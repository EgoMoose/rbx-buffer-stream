<!-- Links -->

[bufferstream/releases]: https://github.com/EgoMoose/rbx-buffer-stream/releases
[bufferstream/wally]: https://wally.run/package/egomoose/buffer-stream

<!-- Badges -->

[badges/github]: https://raw.githubusercontent.com/gist/cxmeel/0dbc95191f239b631c3874f4ccf114e2/raw/github.svg
[badges/wally]: https://raw.githubusercontent.com/gist/cxmeel/0dbc95191f239b631c3874f4ccf114e2/raw/wally.svg

# rbx-buffer-stream

[![Get it on Github][badges/github]][bufferstream/releases] [![Get it on Wally][badges/wally]][bufferstream/wally]

An abstraction for buffers that allows reading and writing data in sequence.

### Static vs Dynamic

BufferStream offers support for both static and dynamic size buffers. If you want your buffer to adhere to a fixed size use `BufferStream.static(buffer.create(FIXED_SIZE))`. If you want you buffer to dynamically increase in size as you write to it then use `BufferStream.dynamic(buffer.create(0))`.

### Additional read / writes

At the time of writing Roblox's buffer library lacks a couple of read and write functions for some helpful numeric types. BufferStream adds read and write support for the following:

- `readu24` / `writeu24`
- `readu48` / `writeu48`
- `readu64` / `writeu64`
- `readi24` / `writei24`
- `readi48` / `writei48`
- `readi64` / `writei64`
- `readf8` / `writef8`
- `readf16` / `writef16`
- `readf24` / `writef24` (1 sign bit, 7 exponent bits, 16 fraction bits)
- `readf48` / `writef48` (1 sign bit, 11 exponent bits, 36 fraction bits)
- `readBuffer` / `writeBuffer`
- `readUnsignedBytes` / `writeUnsignedBytes`

### Standalone read / writes

Every fixed size numeric type (`u8` through `f64`, including the additions above) is also available as a standalone function that works on any buffer. They share the same signatures as the buffer library, so they can be used as a drop-in for it:

```luau
local b = buffer.create(5)
BufferStream.writef16(b, 0, 1.5)
BufferStream.writeu24(b, 2, 0xABCDEF)

print(BufferStream.readf16(b, 0)) -- 1.5
print(BufferStream.readu24(b, 2)) -- 11259375
```

Strings, buffers, and unsigned bytes can be read and written the same way:

- `BufferStream.readstring(b, offset, count)` / `BufferStream.writestring(b, offset, value, count?)` are the same as `buffer.readstring` / `buffer.writestring`.

- `BufferStream.readbuffer(b, offset, count)` returns a new buffer containing `count` bytes of `b` starting at `offset`.
- `BufferStream.writebuffer(b, offset, source, sourceOffset?, count?)` writes `source` into `b` at `offset`. If `count` is omitted the rest of `source` from `sourceOffset` is written. This is the same as `buffer.copy`.
- `BufferStream.readubytes(b, offset, bytes)` reads an unsigned integer that is `bytes` bytes long.
- `BufferStream.writeubytes(b, offset, bytes, value)` writes an unsigned integer that is `bytes` bytes long.