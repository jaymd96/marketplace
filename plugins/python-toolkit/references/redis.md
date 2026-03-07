# redis v5.2+

Python client for Redis. Supports sync and async APIs, connection pooling, pipelines, pub/sub, and all Redis commands.

```
pip install redis
```

## Quick Start

```python
import redis

r = redis.Redis(host="localhost", port=6379, db=0, decode_responses=True)
r.set("key", "value", ex=60)  # SET with 60s TTL
val = r.get("key")            # "value"
r.hset("user:1", mapping={"name": "alice", "age": "30"})
r.hget("user:1", "name")      # "alice"
```

## Core API

### Connection

```python
# Basic connection
r = redis.Redis(host="localhost", port=6379, db=0, decode_responses=True)

# From URL
r = redis.from_url("redis://localhost:6379/0", decode_responses=True)

# Connection pool (explicit)
pool = redis.ConnectionPool(host="localhost", port=6379, db=0, max_connections=10)
r = redis.Redis(connection_pool=pool)

# With auth and SSL
r = redis.Redis(host="redis.example.com", port=6380, password="secret", ssl=True)
```

### Strings

```python
r.set(name, value, ex=None, px=None, nx=False, xx=False)  # ex=seconds, px=ms
r.get(name)                    # -> str | None
r.mset({"k1": "v1", "k2": "v2"})
r.mget("k1", "k2")            # -> ["v1", "v2"]
r.incr("counter")             # atomic increment
r.decr("counter")
r.setex("key", 300, "value")  # SET + EXPIRE in one call
```

### Hashes

```python
r.hset("hash", key="field", value="val")
r.hset("hash", mapping={"f1": "v1", "f2": "v2"})
r.hget("hash", "field")       # -> str | None
r.hgetall("hash")             # -> {"f1": "v1", "f2": "v2"}
r.hdel("hash", "field")
r.hexists("hash", "field")    # -> bool
r.hincrby("hash", "count", 1)
```

### TTL / Expiry

```python
r.expire("key", 60)           # set TTL in seconds
r.pexpire("key", 5000)        # TTL in milliseconds
r.ttl("key")                  # -> int (seconds remaining, -1 = no TTL, -2 = missing)
r.persist("key")              # remove TTL
r.expireat("key", unix_ts)    # expire at absolute time
```

### Lists, Sets, Sorted Sets

```python
r.lpush("list", "a", "b")     # push left
r.rpop("list")                 # pop right
r.sadd("set", "member")
r.smembers("set")
r.zadd("zset", {"alice": 1.0, "bob": 2.0})
r.zrange("zset", 0, -1, withscores=True)
```

### Pipelines

```python
pipe = r.pipeline(transaction=True)  # MULTI/EXEC by default
pipe.set("a", "1")
pipe.set("b", "2")
pipe.incr("counter")
results = pipe.execute()  # -> [True, True, 3]
```

### Pub/Sub

```python
# Subscriber
pubsub = r.pubsub()
pubsub.subscribe("channel")
for msg in pubsub.listen():
    if msg["type"] == "message":
        print(msg["data"])

# Publisher
r.publish("channel", "hello")

# Pattern subscribe
pubsub.psubscribe("events.*")
```

### Async (asyncio)

```python
import redis.asyncio as aioredis

async def main():
    r = aioredis.from_url("redis://localhost", decode_responses=True)
    await r.set("key", "value")
    val = await r.get("key")

    # Async pipeline
    async with r.pipeline(transaction=True) as pipe:
        pipe.set("a", "1")
        pipe.set("b", "2")
        await pipe.execute()

    # Async pub/sub
    async with r.pubsub() as pubsub:
        await pubsub.subscribe("channel")
        async for msg in pubsub.listen():
            if msg["type"] == "message":
                break

    await r.aclose()  # explicit close required for async
```

## Examples

### Cache with TTL fallback

```python
def cached_fetch(r, key, fetch_fn, ttl=300):
    val = r.get(key)
    if val is None:
        val = fetch_fn()
        r.setex(key, ttl, val)
    return val
```

### Atomic counter with pipeline

```python
def transfer(r, src, dst, amount):
    with r.pipeline(transaction=True) as pipe:
        pipe.decrby(src, amount)
        pipe.incrby(dst, amount)
        pipe.execute()
```

### Distributed lock

```python
lock = r.lock("my-lock", timeout=10, blocking_timeout=5)
if lock.acquire():
    try:
        # critical section
        pass
    finally:
        lock.release()
```

## Pitfalls

1. **decode_responses**: Without `decode_responses=True`, all values return as `bytes`, not `str`. Set it on the client, not per-call.
2. **Async cleanup**: `redis.asyncio` requires explicit `await r.aclose()`. There is no async destructor -- failing to close leaks connections.
3. **Pipeline vs transaction**: `pipeline(transaction=False)` batches commands but does NOT wrap in MULTI/EXEC. Use `transaction=True` (default) for atomicity.
4. **Connection pool exhaustion**: Default `max_connections` is `2**31`. In high-concurrency apps, set an explicit limit and handle `ConnectionError`.
5. **Pub/sub blocks**: `pubsub.listen()` is blocking. In async code, use `async for`. In sync code, use `pubsub.get_message(timeout=1.0)` for non-blocking polling.
6. **Key expiry race**: `GET` then `SET` with TTL is not atomic. Use `SET ... EX` or Lua scripts for atomic get-or-set.
