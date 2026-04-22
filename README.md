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

- `u64`
- `i64`
- `f8`
- `f16`