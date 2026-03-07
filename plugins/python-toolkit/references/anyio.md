# anyio

**Async compatibility library** | v4.7+ (latest 4.12.x) | `pip install anyio`

Structured concurrency and async I/O that works on both asyncio and Trio. Drop-in replacement for asyncio primitives with cancellation-safe semantics.

## Quick Start

```python
import anyio

async def main():
    async with anyio.create_task_group() as tg:
        tg.start_soon(worker, "task-1")
        tg.start_soon(worker, "task-2")

async def worker(name: str):
    await anyio.sleep(1)
    print(f"{name} done")

anyio.run(main)  # Uses asyncio by default
```

## Core API

### Running async code

```python
import anyio

# Run the top-level coroutine
anyio.run(main)                          # Default: asyncio backend
anyio.run(main, backend="trio")          # Trio backend
anyio.run(main, backend_options={"use_uvloop": True})  # asyncio + uvloop
```

### Task Groups (Structured Concurrency)

```python
async def main():
    async with anyio.create_task_group() as tg:
        tg.start_soon(my_coroutine, arg1, arg2)  # Fire and forget
        tg.start_soon(another_task)
    # Block exits only when ALL tasks complete
    # If any task raises, all others are cancelled
```

**TaskGroup guarantees:**
- All child tasks finish before the `async with` block exits
- If a child raises an exception, all siblings are cancelled
- The exception propagates (wrapped in `ExceptionGroup` if multiple fail)

### Task startup protocol

```python
async def server(*, task_status=anyio.TASK_STATUS_IGNORED):
    listener = await setup_listener()
    task_status.started(listener.port)     # Signal "ready" and return a value
    await serve_forever(listener)

async def main():
    async with anyio.create_task_group() as tg:
        port = await tg.start(server)      # Waits until started() is called
        print(f"Server listening on {port}")
```

### Cancellation, Timeouts, and Sleep

```python
async with anyio.fail_after(5):            # Raises TimeoutError after 5s
    await long_operation()

async with anyio.move_on_after(5) as scope:
    await long_operation()
if scope.cancelled_caught:
    print("Timed out, moving on")

await anyio.sleep(1.5)             # Sleep for 1.5 seconds
await anyio.sleep_forever()        # Sleep until cancelled
await anyio.sleep(0)               # Yield to event loop (checkpoint)
```

### Synchronization Primitives

```python
# Event -- one-shot signal (cannot be reset)
event = anyio.Event()
await event.wait()                 # Blocks until set
event.set()                        # Wakes all waiters

# Lock -- mutual exclusion
lock = anyio.Lock()
async with lock:
    await modify_shared_state()

# Semaphore -- limit concurrent access
semaphore = anyio.Semaphore(10)
async with semaphore:
    await limited_resource()

# CapacityLimiter -- like Semaphore but one token per borrower
limiter = anyio.CapacityLimiter(5)
async with limiter:
    await work()
```

### Thread Integration

```python
import anyio

# Run sync function in a worker thread (from async code)
result = await anyio.to_thread.run_sync(blocking_function, arg1, arg2)

# Run with a capacity limiter
limiter = anyio.CapacityLimiter(4)
result = await anyio.to_thread.run_sync(cpu_work, limiter=limiter)

# Run async function from a sync worker thread
def sync_callback():
    # Call back into async from a worker thread
    result = anyio.from_thread.run(async_function, arg1)
    return result

# Run sync function from a worker thread in the event loop thread
def sync_callback():
    anyio.from_thread.run_sync(sync_function_needing_event_loop)
```

## Examples

### 1. Parallel HTTP requests with timeout

```python
import anyio, httpx

async def fetch(client: httpx.AsyncClient, url: str, results: dict):
    response = await client.get(url)
    results[url] = response.status_code

async def main():
    results = {}
    async with httpx.AsyncClient() as client:
        async with anyio.fail_after(10):
            async with anyio.create_task_group() as tg:
                for url in ["https://example.com", "https://httpbin.org/get"]:
                    tg.start_soon(fetch, client, url, results)
    print(results)

anyio.run(main)
```

### 2. Worker pool with capacity limiter

```python
import anyio

async def process_item(item: int, limiter: anyio.CapacityLimiter):
    async with limiter:
        await anyio.to_thread.run_sync(cpu_intensive_work, item)

async def main():
    limiter = anyio.CapacityLimiter(4)
    async with anyio.create_task_group() as tg:
        for i in range(100):
            tg.start_soon(process_item, i, limiter)

anyio.run(main)
```

### 3. Bridging sync and async

```python
import anyio

def sync_handler(query: str) -> list:
    """Called from a worker thread -- bridges back to async."""
    return anyio.from_thread.run(async_db_query, query)

async def main():
    result = await anyio.to_thread.run_sync(sync_handler, "SELECT 1")

anyio.run(main)
```

## Pitfalls

- **ExceptionGroup in Python 3.11+** -- When multiple tasks fail, anyio raises `ExceptionGroup` (or `BaseExceptionGroup`). Use `except*` syntax or the `exceptiongroup` backport to handle them.
- **Primitives are NOT thread-safe** -- `Event`, `Lock`, etc. must only be used from async tasks, not from worker threads. Use `from_thread.run()` to signal from threads.
- **No task.cancel()** -- You cannot cancel individual tasks. Cancel scopes are the mechanism. Wrap a task in its own cancel scope if you need targeted cancellation.
- **start_soon is not await** -- `tg.start_soon(coro)` schedules but does not wait. Use `tg.start(coro)` with the `task_status` protocol to wait for initialization.
- **sleep(0) is a checkpoint** -- It yields control. Without checkpoints, a CPU-bound coroutine starves others. Insert `await anyio.sleep(0)` in tight loops.
- **Backend lock-in** -- Once you call `anyio.run()`, the backend is fixed for that call tree. Don't mix asyncio and Trio primitives with anyio primitives.
- **from_thread requires a portal** -- `from_thread.run()` only works inside threads spawned by `to_thread.run_sync()`. Calling it from arbitrary threads raises `RuntimeError`.
