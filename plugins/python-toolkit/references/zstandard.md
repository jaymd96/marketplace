# zstandard

**Zstandard compression for Python** | v0.23+ (latest 0.25.x) | `pip install zstandard`

Python bindings for Facebook's Zstandard (zstd) compression algorithm. Supports one-shot, streaming, dictionary compression, and multi-threaded operation.

## Quick Start

```python
import zstandard as zstd

# Compress
cctx = zstd.ZstdCompressor(level=3)
compressed = cctx.compress(b"Hello, world!" * 1000)

# Decompress
dctx = zstd.ZstdDecompressor()
original = dctx.decompress(compressed)
```

## Core API

### ZstdCompressor

```python
zstd.ZstdCompressor(
    level=3,              # 1 (fast) to 22 (max compression), default 3
    dict_data=None,       # ZstdCompressionDict for dictionary compression
    compression_params=None,  # ZstdCompressionParameters for fine-tuning
    write_checksum=False, # Append xxhash64 checksum to frame
    write_content_size=True,  # Embed original size in frame header
    write_dict_id=True,   # Embed dictionary ID in frame header
    threads=0,            # 0=single-threaded, -1=auto (num CPUs), N=N threads
)
```

**Key methods:**

| Method | Description |
|--------|-------------|
| `compress(data)` | One-shot: bytes in, compressed bytes out |
| `stream_writer(dest)` | Streaming: returns writer; call `.write(chunk)` then `.flush()` |
| `stream_reader(source)` | Streaming: returns file-like reader of compressed data |
| `read_to_iter(reader, size=...)` | Yields compressed chunks from a readable source |
| `copy_stream(src, dest)` | Compress from one stream to another |
| `compressobj()` | Returns incremental compressor (like `zlib.compressobj`) |
| `chunker(size=...)` | Yields compressed chunks of a target size |
| `multi_compress_to_buffer(data_list)` | Compress multiple inputs in one call |

### ZstdDecompressor

```python
zstd.ZstdDecompressor(
    dict_data=None,       # Must match dictionary used during compression
    max_window_size=0,    # Limit memory usage (0=no limit)
    format=zstd.FORMAT_ZSTD1,  # FORMAT_ZSTD1 (frame) or FORMAT_ZSTD1_MAGICLESS
)
```

**Key methods:**

| Method | Description |
|--------|-------------|
| `decompress(data, max_output_size=...)` | One-shot decompression |
| `stream_writer(dest)` | Write compressed data in, decompressed flows to dest |
| `stream_reader(source)` | Read from source, get decompressed data |
| `read_to_iter(reader, size=...)` | Yields decompressed chunks |
| `copy_stream(src, dest)` | Decompress from one stream to another |
| `decompressobj()` | Incremental decompressor (like `zlib.decompressobj`) |
| `multi_decompress_to_buffer(frames)` | Decompress multiple frames in one call |

### Dictionary Compression

```python
# Train a dictionary from sample data
dict_data = zstd.train_dictionary(
    dict_size=131072,     # Target dictionary size in bytes
    samples=[b"sample1", b"sample2", ...],  # Representative data
)

# Use for compression (huge wins on small, similar documents)
cctx = zstd.ZstdCompressor(dict_data=dict_data)
dctx = zstd.ZstdDecompressor(dict_data=dict_data)
```

## Compression Levels

| Level | Speed | Ratio | Use Case |
|-------|-------|-------|----------|
| 1-3 | Fast | Lower | Real-time, logging, IPC |
| 4-6 | Moderate | Good | General purpose, network transfer |
| 7-12 | Slower | Better | Storage, archival |
| 13-19 | Slow | High | Cold storage |
| 20-22 | Very slow | Maximum | One-time archival |

Negative levels (-1 to -131072) are "fast" modes trading ratio for speed.

## Frame vs Block

- **Frame**: Self-contained unit with header (magic number, content size, dict ID) and optional checksum. Default output of `compress()`. Can be concatenated.
- **Block**: Internal unit within a frame. `FLUSH_BLOCK` flushes the current block without ending the frame (useful for streaming). `FLUSH_FRAME` ends the current frame.

## Examples

### 1. Streaming file compression

```python
import zstandard as zstd

cctx = zstd.ZstdCompressor(level=5)
with open("input.dat", "rb") as fin, open("output.zst", "wb") as fout:
    cctx.copy_stream(fin, fout)
```

### 2. Streaming decompression with stream_reader

```python
import zstandard as zstd

dctx = zstd.ZstdDecompressor()
with open("output.zst", "rb") as fin:
    with dctx.stream_reader(fin) as reader:
        while chunk := reader.read(16384):
            process(chunk)
```

### 3. Dictionary compression for small JSON documents

```python
import zstandard as zstd

# Train on representative samples
samples = [json.dumps(doc).encode() for doc in training_docs]
dict_data = zstd.train_dictionary(131072, samples)

# Compress -- dramatic ratio improvement on small data
cctx = zstd.ZstdCompressor(dict_data=dict_data, level=6)
compressed = cctx.compress(json.dumps(new_doc).encode())

# Decompress -- must use same dictionary
dctx = zstd.ZstdDecompressor(dict_data=dict_data)
original = dctx.decompress(compressed)
```

## Pitfalls

- **decompress() without content size** -- If the frame doesn't embed content size (older data, streaming), you must pass `max_output_size` or you get `ZstdError`. Use `stream_reader()` instead for unknown-size data.
- **Dictionary must match** -- Compressor and decompressor must use the exact same dictionary. Serialize with `dict_data.as_bytes()` and reconstruct with `ZstdCompressionDict(data)`.
- **threads > 0 changes output** -- Multi-threaded compression produces different (but compatible) output than single-threaded. Don't use if you need deterministic output.
- **stream_writer needs flush()** -- Forgetting to call `.flush(FLUSH_FRAME)` on a stream writer leaves data in internal buffers. Use as a context manager: `with cctx.stream_writer(f) as writer:`.
- **Level 20+ is rarely worth it** -- Levels above 19 have dramatically diminishing returns and massive memory usage. Level 3 (default) is usually the right choice.
- **Not compatible with gzip/zlib** -- zstd is a different format. Files use `.zst` extension and `28 b5 2f fd` magic bytes.
