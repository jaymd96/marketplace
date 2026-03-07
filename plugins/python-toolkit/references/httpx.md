# httpx v0.28.1

## Quick Start

```python
import httpx

r = httpx.get("https://api.example.com/users", params={"page": 1})
r.raise_for_status()
data = r.json()
```

## Core API

```python
# One-off requests
httpx.get(url, params=..., headers=..., timeout=...)
httpx.post(url, json=..., data=..., files=...)
httpx.put(url, json=...) / httpx.patch(url, json=...) / httpx.delete(url)

# Client with connection pooling (always use for multiple requests)
with httpx.Client(
    base_url="https://api.example.com",
    headers={"Authorization": "Bearer token"},
    timeout=30.0,
    follow_redirects=True,   # disabled by default (unlike requests)
) as client:
    r = client.get("/users")
    r = client.post("/users", json={"name": "Alice"})

# Async client
async with httpx.AsyncClient(base_url="https://api.example.com") as client:
    r = await client.get("/users")

# Response object
r.status_code           # 200
r.json()                # parsed JSON
r.text                  # decoded string
r.content               # raw bytes
r.headers               # case-insensitive headers
r.is_success            # True for 2xx
r.raise_for_status()    # raises HTTPStatusError on 4xx/5xx

# Timeout config
httpx.Timeout(connect=5.0, read=30.0, write=10.0, pool=5.0)

# Streaming
with httpx.stream("GET", url) as r:
    for chunk in r.iter_bytes(chunk_size=8192):
        f.write(chunk)
```

## Examples

### Concurrent async requests

```python
async with httpx.AsyncClient() as client:
    results = await asyncio.gather(
        client.get("https://api.example.com/a"),
        client.get("https://api.example.com/b"),
    )
```

### Testing with MockTransport

```python
def handler(request: httpx.Request) -> httpx.Response:
    if request.url.path == "/users":
        return httpx.Response(200, json=[{"id": 1, "name": "Alice"}])
    return httpx.Response(404)

client = httpx.Client(transport=httpx.MockTransport(handler), base_url="https://test")
r = client.get("/users")
assert r.status_code == 200
```

## Pitfalls

- **Redirects disabled by default**: set `follow_redirects=True` (unlike requests).
- **5-second default timeout**: requests has no timeout; httpx times out at 5s. Set explicitly.
- **Always close clients**: use `with` context manager to avoid leaked connections.
- **`content` vs `data` vs `json`**: only use one per request. Combining raises an error.
- **Sync/async mismatch**: never use `httpx.Client` in async code or `AsyncClient` in sync code.
- **dumps returns bytes not str**: `r.content` is bytes, `r.text` is str.
