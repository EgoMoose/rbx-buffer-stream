# BufferStream

BufferStream is an abstraction for buffers that allows reading and writing data in sequence.

### Static vs Dynamic

BufferStream offers support for both static and dynamic size buffers. If you want your buffer to adhere to a fixed size use `BufferStream.static(buffer.create(FIXED_SIZE))`. If you want you buffer to dynamically increase in size as you write to it then use `BufferStream.dynamic(buffer.create(0))`.

### Additionally read / writes

At the time of writing Roblox's buffer library lacks a couple of read and write functions for some helpful numeric types. BufferStream adds read and write support for the following:

- `u64`
- `i64`
- `f8`
- `f16`