# websockets v14.1+

WebSocket client and server library for Python, built on asyncio.

```
pip install websockets
```

## Quick Start

```python
# Server
import asyncio
from websockets.asyncio.server import serve

async def echo(websocket):
    async for message in websocket:
        await websocket.send(f"echo: {message}")

async def main():
    async with serve(echo, "localhost", 8765):
        await asyncio.Future()  # run forever

asyncio.run(main())
```

```python
# Client
import asyncio
from websockets.asyncio.client import connect

async def main():
    async with connect("ws://localhost:8765") as ws:
        await ws.send("hello")
        response = await ws.recv()
        print(response)

asyncio.run(main())
```

## Core API

### Server

```python
from websockets.asyncio.server import serve, ServerConnection

# Basic server
async with serve(handler, host="localhost", port=8765) as server:
    await asyncio.Future()  # block forever

# Handler signature
async def handler(websocket: ServerConnection):
    # websocket.path       -> request path (e.g., "/chat")
    # websocket.request    -> HTTP request object
    # websocket.remote_address -> (host, port)
    async for message in websocket:
        await websocket.send(message)

# Server options
async with serve(
    handler,
    host="0.0.0.0",
    port=8765,
    ping_interval=20,        # seconds between pings (default: 20)
    ping_timeout=20,         # seconds to wait for pong (default: 20)
    close_timeout=10,        # seconds to wait for close (default: 10)
    max_size=2**20,          # max message size in bytes (default: 1 MiB)
    origins=["https://example.com"],  # allowed origins
    ssl=ssl_context,         # for wss://
) as server:
    await asyncio.Future()
```

### Client

```python
from websockets.asyncio.client import connect, ClientConnection

# Context manager (auto-close)
async with connect("ws://localhost:8765") as ws:
    await ws.send("hello")
    msg = await ws.recv()

# With options
async with connect(
    "wss://example.com/ws",
    additional_headers={"Authorization": "Bearer token"},
    ping_interval=20,
    ping_timeout=20,
    max_size=2**20,
    ssl=ssl_context,
    open_timeout=10,
) as ws:
    pass
```

### Send and Receive

```python
# Text messages
await ws.send("hello")
msg = await ws.recv()        # -> str

# Binary messages
await ws.send(b"\x00\x01\x02")
data = await ws.recv()       # -> bytes

# Iteration (receive until close)
async for message in ws:
    process(message)

# Recv with timeout
import asyncio
try:
    msg = await asyncio.wait_for(ws.recv(), timeout=5.0)
except asyncio.TimeoutError:
    print("No message in 5 seconds")
```

### Ping / Pong

```python
# Ping is sent automatically by default (ping_interval=20)
# Manual ping
pong = await ws.ping()
await pong  # wait for pong response

# Disable automatic ping
async with serve(handler, "localhost", 8765, ping_interval=None):
    pass
```

### Close Handling

```python
from websockets.exceptions import ConnectionClosed, ConnectionClosedOK, ConnectionClosedError

async def handler(websocket):
    try:
        async for message in websocket:
            await websocket.send(message)
    except ConnectionClosedError as e:
        print(f"Connection lost: {e.code} {e.reason}")
    except ConnectionClosedOK:
        print("Client closed normally")

# Explicit close
await ws.close(code=1000, reason="goodbye")

# Check state
ws.close_code    # -> int | None
ws.close_reason  # -> str | None
```

### Subprotocols and Headers

```python
# Server: select subprotocol
async with serve(
    handler,
    "localhost", 8765,
    subprotocols=["graphql-ws", "graphql-transport-ws"],
) as server:
    pass

# In handler, check which was selected
async def handler(ws):
    print(ws.subprotocol)  # -> selected subprotocol or None

# Client: request subprotocol
async with connect(uri, subprotocols=["graphql-ws"]) as ws:
    print(ws.subprotocol)
```

## Examples

### Broadcast server

```python
from websockets.asyncio.server import serve

CLIENTS = set()

async def handler(websocket):
    CLIENTS.add(websocket)
    try:
        async for message in websocket:
            # Broadcast to all other clients
            for client in CLIENTS - {websocket}:
                try:
                    await client.send(message)
                except Exception:
                    pass
    finally:
        CLIENTS.discard(websocket)

async def main():
    async with serve(handler, "localhost", 8765):
        await asyncio.Future()
```

### Reconnecting client

```python
from websockets.asyncio.client import connect
from websockets.exceptions import ConnectionClosed
import asyncio

async def resilient_client(uri):
    while True:
        try:
            async with connect(uri) as ws:
                async for msg in ws:
                    print(f"Received: {msg}")
        except ConnectionClosed:
            print("Disconnected, reconnecting in 3s...")
            await asyncio.sleep(3)
        except OSError:
            print("Connection failed, retrying in 5s...")
            await asyncio.sleep(5)
```

### JSON protocol

```python
import json
from websockets.asyncio.server import serve

async def handler(websocket):
    async for raw in websocket:
        request = json.loads(raw)
        response = {"type": "reply", "data": process(request)}
        await websocket.send(json.dumps(response))
```

## Pitfalls

1. **Legacy API deprecated in v14**: `websockets.serve()` and `websockets.connect()` from the top-level module use the legacy asyncio implementation. Use `websockets.asyncio.server.serve` and `websockets.asyncio.client.connect` instead.
2. **async for consumes until close**: `async for message in ws` runs until the connection closes. Do not try to receive more messages after the loop ends.
3. **Ping/pong keeps connections alive**: Default `ping_interval=20` sends automatic pings. If the server or a proxy has a shorter idle timeout, reduce this value.
4. **max_size limits**: Default 1 MiB per message. Large messages (file uploads, big JSON) will raise `ConnectionClosedError` with code 1009. Increase `max_size` or chunk data.
5. **ConnectionClosed is normal**: Iteration over `async for message in ws` already handles `ConnectionClosedOK`. Only catch `ConnectionClosedError` for abnormal disconnects.
6. **No built-in reconnect**: The client does not auto-reconnect. Build a retry loop (see example above).
7. **Thread safety**: WebSocket objects are not thread-safe. Use `asyncio.run_coroutine_threadsafe()` to send from other threads.
