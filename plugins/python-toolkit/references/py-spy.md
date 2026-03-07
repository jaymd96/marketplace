# py-spy

**Sampling profiler for Python programs** | v0.4.x | `pip install py-spy`

Zero-overhead profiler that works by reading the Python program's memory. Does not require code changes or restarts. Runs as a separate process.

## Quick Start

```bash
# Profile a script and generate a flamegraph
py-spy record -o profile.svg -- python myapp.py

# Attach to a running process
py-spy record -o profile.svg --pid 12345

# Live top-like view
py-spy top --pid 12345

# Dump current stack traces
py-spy dump --pid 12345
```

## Commands

### record -- Generate profile output

```bash
py-spy record [OPTIONS] --output <OUTPUT> [-- <CMD>...]
```

| Flag | Description |
|------|-------------|
| `-o, --output <FILE>` | Output filename (required) |
| `-f, --format <FMT>` | `flamegraph` (default), `raw`, `speedscope` |
| `-d, --duration <SECS>` | Record for N seconds then stop |
| `-r, --rate <HZ>` | Sampling rate in Hz (default: 100) |
| `-p, --pid <PID>` | Attach to running process by PID |
| `-s, --subprocesses` | Profile child Python processes too |
| `-t, --threads` | Show thread IDs in output |
| `-n, --native` | Include native C/C++/Cython frames |
| `-i, --idle` | Include idle/waiting frames |
| `-F, --function` | Aggregate by function (not line number) |
| `--nonblocking` | Don't pause the target process |
| `--full-filenames` | Show full file paths |

### top -- Live view of function time

```bash
py-spy top [OPTIONS] [-- <CMD>...]
```

Same flags as `record` minus `--output` and `--format`. Shows a continuously updating table of functions sorted by CPU time, similar to Unix `top`.

### dump -- One-shot stack trace

```bash
py-spy dump [OPTIONS]
```

| Flag | Description |
|------|-------------|
| `-p, --pid <PID>` | Process ID to dump (required) |
| `-l, --locals` | Print local variables per frame |
| `-n, --native` | Include native frames |
| `--nonblocking` | Don't pause the target process |
| `--full-filenames` | Show full file paths |
| `-j, --json` | Output as JSON |

## Examples

### 1. Flamegraph SVG from a running web server

```bash
# Attach for 30 seconds, include subprocesses (e.g. gunicorn workers)
py-spy record -o profile.svg --pid 54321 --duration 30 --subprocesses
# Open profile.svg in a browser -- it's interactive (hover/click to zoom)
```

### 2. Speedscope format for detailed analysis

```bash
py-spy record -o profile.speedscope --format speedscope -- python train_model.py
# Upload profile.speedscope to https://speedscope.app
```

### 3. Quick diagnosis of a stuck process

```bash
# See what every thread is doing right now
py-spy dump --pid 12345 --locals

# Watch it live
py-spy top --pid 12345 --idle
```

## Pitfalls

- **Root/sudo required on Linux** -- py-spy reads `/proc/<pid>/mem`. Run with `sudo` or set `kernel.yama.ptrace_scope=0`.
- **macOS SIP blocks profiling** -- System Integrity Protection prevents attaching to system Python. Use a Homebrew or pyenv Python.
- **Docker containers** -- Add `--cap-add SYS_PTRACE` to `docker run`, or use `--privileged`.
- **--idle inflates flamegraphs** -- Without `--idle`, py-spy skips frames where the interpreter is waiting (I/O, sleep). Enable it only when diagnosing blocking/contention.
- **--native slows sampling** -- Native frame unwinding adds overhead. Use only when profiling C extensions.
- **No Windows subprocess support** -- `--subprocesses` is Linux/macOS only.
- **GIL contention invisible** -- py-spy samples the Python call stack, not OS thread scheduling. It shows where time is spent, not why threads are blocked on the GIL. Use `--native` for GIL-level insight.
