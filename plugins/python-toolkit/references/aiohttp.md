# aiohttp v3.11+

Async HTTP client/server framework for Python. Supports HTTP client sessions with
connection pooling, WebSocket client/server, and a full web server with middleware.

**Install:** `pip install aiohttp`

---

## Quick Start

```python
import aiohttp, asyncio

async def main():
    async with aiohttp.ClientSession() as session:
        async with session.get("https://httpbin.org/get") as resp:
            print(resp.status)
            print(await resp.json())

asyncio.run(main())
```

---

## Core API

### ClientSession

```python
aiohttp.ClientSession(
    base_url: str | URL | None = None,
    connector: BaseConnector | None = None,    # TCPConnector by default
    timeout: ClientTimeout | None = None,
    headers: dict | None = None,               # Default headers for all requests
    cookies: dict | None = None,
    auth: BasicAuth | None = None,             # Default auth
    json_serialize: Callable = json.dumps,
    cookie_jar: AbstractCookieJar | None = None,
    raise_for_status: bool | Callable = False, # Auto-raise on 4xx/5xx
    trust_env: bool = False,                   # Read proxy from env
    trace_configs: list[TraceConfig] | None = None,
)

# HTTP methods (all return ClientResponse context manager)
session.get(url, *, params=None, headers=None, **kwargs)
session.post(url, *, data=None, json=None, headers=None, **kwargs)
session.put(url, *, data=None, json=None, **kwargs)
session.patch(url, *, data=None, json=None, **kwargs)
session.delete(url, **kwargs)
session.head(url, **kwargs)
session.options(url, **kwargs)
session.ws_connect(url, **kwargs)   # WebSocket client
```

### ClientResponse

```python
async with session.get(url) as resp:
    resp.status                     # int (200, 404, etc.)
    resp.headers                    # CIMultiDictProxy
    resp.content_type               # str ("application/json")
    resp.url                        # URL object

    await resp.text()               # str (decoded body)
    await resp.json()               # parsed JSON
    await resp.read()               # bytes (raw body)
    await resp.content.read(1024)   # streaming read

    resp.raise_for_status()         # Raise ClientResponseError on 4xx/5xx
    resp.ok                         # True if status < 400
```

### Timeouts

```python
from aiohttp import ClientTimeout

timeout = ClientTimeout(
    total=300,          # Total timeout for the whole operation (default: 300s)
    connect=None,       # Timeout for connection establishment
    sock_connect=None,  # Timeout for connecting to peer (socket level)
    sock_read=None,     # Timeout between reading data chunks
    ceil_threshold=5,   # Ceil small timeouts to next second
)

# Per-session
session = aiohttp.ClientSession(timeout=ClientTimeout(total=60))

# Per-request (overrides session timeout)
await session.get(url, timeout=ClientTimeout(total=10))
```

### Connection Pooling (TCPConnector)

```python
from aiohttp import TCPConnector

connector = TCPConnector(
    limit=100,              # Total connection pool size (default: 100, 0=unlimited)
    limit_per_host=0,       # Per-host limit (default: 0 = unlimited)
    keepalive_timeout=15,   # Seconds to keep idle connections alive
    enable_cleanup_closed=False,  # Abort stale connections
    ssl=None,               # SSLContext or False to disable verification
    ttl_dns_cache=10,       # DNS cache TTL in seconds (None = forever)
    force_close=False,      # Close connection after each request
)

session = aiohttp.ClientSession(connector=connector)
```

### WebSocket Client

```python
async with session.ws_connect("ws://example.com/ws") as ws:
    await ws.send_str("hello")
    await ws.send_json({"type": "ping"})
    await ws.send_bytes(b"\x00\x01")

    async for msg in ws:
        if msg.type == aiohttp.WSMsgType.TEXT:
            print(msg.data)
        elif msg.type == aiohttp.WSMsgType.BINARY:
            process(msg.data)
        elif msg.type in (aiohttp.WSMsgType.CLOSE,
                          aiohttp.WSMsgType.ERROR,
                          aiohttp.WSMsgType.CLOSING):
            break

    await ws.close()
```

### Web Server (web.Application)

```python
from aiohttp import web

async def handle_get(request: web.Request) -> web.Response:
    name = request.match_info.get("name", "World")
    return web.json_response({"hello": name})

async def handle_post(request: web.Request) -> web.Response:
    data = await request.json()
    return web.json_response(data, status=201)

app = web.Application()
app.router.add_get("/", handle_get)
app.router.add_get("/{name}", handle_get)
app.router.add_post("/items", handle_post)

# Or with RouteTableDef (Flask-like)
routes = web.RouteTableDef()

@routes.get("/health")
async def health(request):
    return web.json_response({"status": "ok"})

app.router.add_routes(routes)

# Run
web.run_app(app, host="0.0.0.0", port=8080)
```

### Server Middleware

```python
from aiohttp import web

@web.middleware
async def error_middleware(request: web.Request, handler):
    try:
        response = await handler(request)
        return response
    except web.HTTPException:
        raise
    except Exception as e:
        return web.json_response({"error": str(e)}, status=500)

@web.middleware
async def timing_middleware(request, handler):
    import time
    start = time.perf_counter()
    response = await handler(request)
    elapsed = time.perf_counter() - start
    response.headers["X-Elapsed"] = f"{elapsed:.4f}"
    return response

app = web.Application(middlewares=[error_middleware, timing_middleware])
```

---

## Examples

### Concurrent Requests with Semaphore

```python
async def fetch_all(urls: list[str], max_concurrent: int = 10):
    sem = asyncio.Semaphore(max_concurrent)
    async with aiohttp.ClientSession() as session:
        async def fetch(url):
            async with sem:
                async with session.get(url) as resp:
                    return await resp.json()
        return await asyncio.gather(*(fetch(u) for u in urls))
```

### Streaming Large Response

```python
async with session.get(url) as resp:
    with open("output.bin", "wb") as f:
        async for chunk in resp.content.iter_chunked(8192):
            f.write(chunk)
```

### Server with Startup/Shutdown

```python
async def init_db(app: web.Application):
    app["pool"] = await asyncpg.create_pool(dsn="postgresql://...")
    yield
    await app["pool"].close()

app = web.Application()
app.cleanup_ctx.append(init_db)
```

---

## Pitfalls

1. **Create one ClientSession per application.** Do NOT create a session per request.
   Sessions manage connection pooling internally; creating many sessions defeats this.

2. **Always use `async with` for responses.** Without the context manager, the response
   body is not read and the connection is not returned to the pool.

3. **Timeout includes pool wait time.** `ClientTimeout.total` starts from when the
   request call is made, including time waiting for a free connection from the pool.

4. **`raise_for_status` is off by default.** Unlike `requests`, aiohttp does NOT raise
   on 4xx/5xx. Set `raise_for_status=True` on the session or call `resp.raise_for_status()`.

5. **Session must close.** Use `async with ClientSession()` or call `await session.close()`
   explicitly. Unclosed sessions leak connections and produce warnings.

6. **`resp.json()` does not check Content-Type.** It attempts JSON parsing regardless.
   Check `resp.content_type` if the server might return non-JSON.

7. **Server middleware order.** Middleware runs in declaration order (first declared
   wraps outermost). The last middleware in the list is closest to the handler.
