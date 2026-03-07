# memray

**Memory profiler for Python** | v1.14+ (latest 1.19.x) | `pip install memray`

Tracks every allocation in Python code, native extensions, and the interpreter itself. Produces rich HTML reports, live terminal UIs, and integrates with pytest.

## Quick Start

```bash
# Profile a script
memray run -o output.bin python_script.py

# Generate an HTML flamegraph
memray flamegraph output.bin -o report.html

# Live terminal view (no intermediate file)
memray run --live python_script.py
```

## CLI Commands

### memray run -- Capture allocations

```bash
memray run [OPTIONS] [-o OUTPUT] script.py [ARGS...]
memray run [OPTIONS] [-o OUTPUT] -m module [ARGS...]
```

| Flag | Description |
|------|-------------|
| `-o, --output <FILE>` | Output capture file (default: `memray-<script>.<pid>.bin`) |
| `--native` | Track C/C++ native allocations too |
| `--follow-fork` | Continue tracking after `fork()` |
| `--trace-python-allocators` | Track individual Python object creation/destruction |
| `--live` | Show live terminal UI instead of writing a file |
| `--live-port <PORT>` | Serve live UI on a remote port |
| `-f, --force` | Overwrite existing output file |
| `-q, --quiet` | Suppress memray output |

### memray attach / detach -- Profile running processes

```bash
memray attach <PID>           # Start tracking a running process
memray detach <PID>           # Stop tracking
```

### Reporter Commands

All reporters read a `.bin` capture file produced by `memray run`.

#### memray flamegraph

```bash
memray flamegraph [OPTIONS] <RESULTS.bin>
```

| Flag | Description |
|------|-------------|
| `-o, --output <FILE>` | Output HTML file |
| `--leaks` | Show only memory that was leaked (not freed) |
| `--temporal` | Temporal flamegraph showing usage over time |
| `--inverted` | Inverted flamegraph (roots at bottom) |
| `--temporary-allocations` | Show short-lived allocations instead of peak |

#### memray table

```bash
memray table [OPTIONS] <RESULTS.bin>
```

Generates an HTML table of all allocations at peak memory, sortable by size.

#### memray tree

```bash
memray tree <RESULTS.bin>
```

Terminal-based tree view of call stacks at peak memory.

#### memray summary

```bash
memray summary <RESULTS.bin>
```

Terminal summary of functions allocating the most memory.

#### memray stats

```bash
memray stats [--json] <RESULTS.bin>
```

High-level allocation statistics. Use `--json` for machine-readable output.

#### memray transform

```bash
memray transform <FORMAT> <RESULTS.bin>
```

Convert to other formats: `gprof2dot`, `csv`.

## pytest Integration

```bash
pip install pytest-memray
pytest --memray tests/
```

### Markers

```python
import pytest

# Fail if test allocates more than 50 MiB
@pytest.mark.limit_memory("50 MiB")
def test_data_processing():
    process_large_dataset()

# Fail if any call stack leaks more than 1 MiB
@pytest.mark.limit_leaks("1 MiB")
def test_no_leaks():
    create_and_destroy_objects()
```

### Configuration (pyproject.toml)

```toml
[tool.pytest.ini_options]
memray = true               # Always enable (no need for --memray flag)
```

## Examples

### 1. Find peak memory usage in a data pipeline

```bash
memray run -o pipeline.bin -- python etl_pipeline.py
memray flamegraph pipeline.bin -o pipeline.html
# Open pipeline.html in browser -- click to zoom into hot call stacks
```

### 2. Track memory leaks

```bash
memray run -o server.bin -- python server.py &
# Let it run, then Ctrl+C
memray flamegraph --leaks server.bin -o leaks.html
```

### 3. Live monitoring during development

```bash
memray run --live python train_model.py
# Terminal UI updates in real-time showing top allocators
```

## Pitfalls

- **Linux/macOS only** -- memray does not support Windows (it uses `ptrace` and platform-specific allocation hooks).
- **--native has significant overhead** -- Native tracking instruments every `malloc`/`free`. Use only when you suspect a C extension is the culprit.
- **--trace-python-allocators is very slow** -- Records every single object. Use for targeted debugging, not routine profiling.
- **Capture files can be huge** -- Long-running processes produce multi-GB `.bin` files. Use `--follow-fork` carefully with multiprocessing.
- **--temporal granularity** -- Default is ~10ms. Fine for long runs, insufficient for sub-millisecond analysis.
- **pytest-memray measures RSS** -- The `limit_memory` marker checks peak resident memory, which includes memory mapped files and shared libraries. Thresholds may need tuning per platform.
