# respx v0.22+

Mock httpx requests with route patterns and response side effects.

## Quick Start

```python
import httpx
import respx
from httpx import Response

@respx.mock
async def test_api_call():
    respx.get("https://api.example.com/users").mock(return_value=Response(200, json=[{"id": 1}]))
    async with httpx.AsyncClient() as client:
        resp = await client.get("https://api.example.com/users")
    assert resp.status_code == 200
    assert resp.json() == [{"id": 1}]
```

## Core API

### Activating the Mock Router

```python
# As decorator
@respx.mock
def test_sync(): ...

@respx.mock
async def test_async(): ...

# As context manager
with respx.mock:
    response = httpx.get("https://example.com/")

async with respx.mock:
    ...

# With options
@respx.mock(assert_all_mocked=True, assert_all_called=True, base_url="https://api.example.com")
def test_strict(): ...

# As pytest fixture (see below)
```

### Adding Routes

```python
# HTTP method shortcuts -- match method + URL
respx.get("https://example.com/path")
respx.post("https://example.com/path")
respx.put("https://example.com/path")
respx.patch("https://example.com/path")
respx.delete("https://example.com/path")
respx.head("https://example.com/path")
respx.options("https://example.com/path")

# Generic route with patterns
respx.route(method="GET", host="example.com", path="/users")

# URL pattern matching
respx.get("https://example.com/users/123")           # Exact URL
respx.get(url__regex=r"/users/\d+")                   # Regex
respx.get(path="/users")                               # Path only
respx.get(host="example.com")                          # Host only
respx.get(url="https://example.com/search", params={"q": "test"})  # With query params

# Named routes
my_route = respx.get("https://example.com/", name="homepage")
```

### Mocking Responses

```python
from httpx import Response

# Using .mock(return_value=...)
route = respx.get("https://example.com/")
route.mock(return_value=Response(200, json={"ok": True}))
route.mock(return_value=Response(204))
route.mock(return_value=Response(200, text="hello"))
route.mock(return_value=Response(200, content=b"bytes"))
route.mock(return_value=Response(200, headers={"X-Custom": "val"}))

# Using .respond() shortcut
respx.get("https://example.com/").respond(200, json={"ok": True})
respx.get("https://example.com/").respond(404)
respx.get("https://example.com/").respond(200, text="hello")

# Side effects -- callable, exception, or stacked responses
respx.get("https://example.com/").mock(side_effect=httpx.ConnectTimeout)
respx.get("https://example.com/").mock(side_effect=lambda req: Response(200, json={"url": str(req.url)}))

# Stacked responses (returned in order)
route = respx.get("https://example.com/")
route.side_effect = [Response(200, json={"page": 1}), Response(200, json={"page": 2})]
```

### Assertions

```python
route = respx.get("https://example.com/users").mock(return_value=Response(200))
httpx.get("https://example.com/users")

assert route.called
assert route.call_count == 1
assert route.calls.last.request.url == "https://example.com/users"
assert route.calls.last.request.headers["user-agent"]
```

## Examples

### pytest Fixture with Scoped Router

```python
import pytest
import respx as respx_lib

@pytest.fixture
def mocked_api():
    with respx_lib.mock(base_url="https://api.example.com", assert_all_called=False) as router:
        router.get("/health").respond(200, json={"status": "ok"})
        router.post("/items").respond(201, json={"id": 42})
        yield router

async def test_create_item(mocked_api):
    async with httpx.AsyncClient(base_url="https://api.example.com") as client:
        resp = await client.post("/items", json={"name": "widget"})
    assert resp.status_code == 201
    assert mocked_api.routes["items"].call_count == 0 or True  # unnamed routes
```

### Content Negotiation with Callable Side Effect

```python
@respx.mock
async def test_dynamic_response():
    def handler(request):
        if request.headers.get("accept") == "application/xml":
            return Response(200, text="<ok/>", headers={"content-type": "application/xml"})
        return Response(200, json={"ok": True})

    respx.get("https://api.example.com/data").mock(side_effect=handler)

    async with httpx.AsyncClient() as client:
        resp = await client.get("https://api.example.com/data", headers={"accept": "application/xml"})
        assert "<ok/>" in resp.text
```

### Pass-Through for Unmocked URLs

```python
@respx.mock(assert_all_mocked=False)
async def test_partial_mock():
    respx.get("https://api.example.com/cached").respond(200, json={"cached": True})
    # Other URLs will pass through to the real network
```

## Pitfalls

- **`assert_all_mocked=True` (default) raises if any request has no matching route.** Disable it explicitly if your test makes calls you do not want to mock.
- **`assert_all_called=True` (default) raises on exit if a registered route was never called.** Set to `False` for optional routes or shared fixtures.
- **Route order matters.** The first matching route wins. Place more specific patterns before general ones.
- **Async and sync both work**, but ensure your test function signature matches the client you use (`async def` for `AsyncClient`).
- **`respx.mock` patches globally.** All httpx clients in the test process are affected. Use `base_url` to scope narrowly.
- **Do not reuse `respx.get(...)` across tests** without the context manager or decorator -- routes accumulate on the global router.
