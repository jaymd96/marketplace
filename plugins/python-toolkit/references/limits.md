# limits v3.13+

Rate limiting library with multiple strategies and storage backends (Redis, Memcached, MongoDB, in-memory). Identical sync and async APIs.

```
pip install limits
pip install limits[redis]       # Redis backend
pip install limits[memcached]   # Memcached backend
pip install limits[mongodb]     # MongoDB backend
```

## Quick Start

```python
from limits import parse, parse_many
from limits.storage import MemoryStorage
from limits.strategies import FixedWindowRateLimiter

storage = MemoryStorage()
limiter = FixedWindowRateLimiter(storage)
rate = parse("10/minute")

if limiter.hit(rate, "user:123"):
    print("Request allowed")
else:
    print("Rate limited!")
```

## Core API

### Parsing Rate Limits

```python
from limits import parse, parse_many

# Single limit
rate = parse("100/hour")
rate = parse("10/minute")
rate = parse("1/second")
rate = parse("5000/day")

# Shorthand notation
rate = parse("100/h")    # hour
rate = parse("10/m")     # minute
rate = parse("1/s")      # second
rate = parse("5000/d")   # day

# Custom amounts
rate = parse("10/5minute")    # 10 per 5 minutes
rate = parse("100/15second")  # 100 per 15 seconds

# Multiple limits (returns tuple)
rates = parse_many("100/hour;10/minute;1/second")
# -> (RateLimitItem(100, 3600), RateLimitItem(10, 60), RateLimitItem(1, 1))

# RateLimitItem attributes
rate = parse("10/minute")
rate.amount     # -> 10
rate.multiples  # -> 1
rate.get_expiry()  # -> 60 (seconds)
```

### Strategies

```python
from limits.strategies import (
    FixedWindowRateLimiter,
    FixedWindowElasticExpiryRateLimiter,
    MovingWindowRateLimiter,
)

# Fixed Window: resets at end of each window
limiter = FixedWindowRateLimiter(storage)

# Fixed Window with Elastic Expiry: window extends on each hit
limiter = FixedWindowElasticExpiryRateLimiter(storage)

# Moving Window: sliding window (most accurate, higher memory)
limiter = MovingWindowRateLimiter(storage)
```

### Strategy Methods

```python
# Check and increment counter (returns True if allowed)
allowed = limiter.hit(rate_limit, *identifiers, cost=1)

# Check without incrementing
allowed = limiter.test(rate_limit, *identifiers)

# Get remaining hits
remaining = limiter.get_window_stats(rate_limit, *identifiers)
# -> WindowStats(reset_time: int, remaining: int)

# Clear rate limit for an identifier
limiter.clear(rate_limit, *identifiers)
```

### Storage Backends

```python
from limits.storage import (
    MemoryStorage,
    RedisStorage,
    RedisSentinelStorage,
    RedisClusterStorage,
    MemcachedStorage,
    MongoDBStorage,
)

# In-memory (single process only)
storage = MemoryStorage()

# Redis
storage = RedisStorage("redis://localhost:6379")
storage = RedisStorage("redis://:password@host:6379/0")
storage = RedisStorage("rediss://host:6380")  # TLS

# Redis Sentinel
storage = RedisSentinelStorage("redis+sentinel://host1:26379,host2:26379/mymaster")

# Redis Cluster
storage = RedisClusterStorage("redis+cluster://host1:7000,host2:7001")

# Memcached
storage = MemcachedStorage("memcached://localhost:11211")

# MongoDB
storage = MongoDBStorage("mongodb://localhost:27017")

# Factory from URI string
from limits.storage import storage_from_string
storage = storage_from_string("redis://localhost:6379")
storage = storage_from_string("memory://")
```

### Async Support

```python
from limits.aio.storage import MemoryStorage, RedisStorage
from limits.aio.strategies import (
    FixedWindowRateLimiter,
    MovingWindowRateLimiter,
)

storage = RedisStorage("redis://localhost:6379")
limiter = FixedWindowRateLimiter(storage)
rate = parse("10/minute")

# All methods are async
allowed = await limiter.hit(rate, "user:123")
stats = await limiter.get_window_stats(rate, "user:123")
await limiter.clear(rate, "user:123")
```

### Multiple Identifiers

```python
# Identifiers are joined to form the key
# Useful for per-user, per-endpoint, per-IP limits
rate = parse("100/hour")

limiter.hit(rate, "user:123")                           # key: "user:123"
limiter.hit(rate, "user:123", "/api/orders")            # key: "user:123//api/orders"
limiter.hit(rate, "ip:10.0.0.1", "POST", "/api/login") # key: "ip:10.0.0.1/POST//api/login"
```

## Examples

### Multi-tier rate limiting

```python
from limits import parse_many
from limits.storage import RedisStorage
from limits.strategies import MovingWindowRateLimiter

storage = RedisStorage("redis://localhost:6379")
limiter = MovingWindowRateLimiter(storage)
rates = parse_many("1000/hour;50/minute;5/second")

def check_rate_limit(user_id: str) -> bool:
    """Returns True if all rate limits pass."""
    return all(limiter.hit(rate, user_id) for rate in rates)
```

### API middleware pattern

```python
from limits import parse
from limits.storage import RedisStorage
from limits.strategies import FixedWindowRateLimiter

storage = RedisStorage("redis://localhost:6379")
limiter = FixedWindowRateLimiter(storage)
RATE = parse("100/minute")

def rate_limit_middleware(request):
    client_ip = request.remote_addr
    if not limiter.test(RATE, client_ip):
        stats = limiter.get_window_stats(RATE, client_ip)
        return Response(
            status=429,
            headers={
                "Retry-After": str(stats.reset_time - time.time()),
                "X-RateLimit-Remaining": str(stats.remaining),
            },
        )
    limiter.hit(RATE, client_ip)
    return handle_request(request)
```

### Cost-based limiting (weighted requests)

```python
rate = parse("1000/hour")

# Expensive operation costs 10 units
limiter.hit(rate, "user:123", cost=10)

# Cheap operation costs 1 unit (default)
limiter.hit(rate, "user:123", cost=1)
```

## Pitfalls

1. **hit() both checks AND increments**: `hit()` consumes a token even when checking. Use `test()` to peek without consuming.
2. **MemoryStorage is per-process**: In multi-worker deployments (gunicorn, uvicorn), each worker has its own counter. Use Redis or Memcached for distributed limiting.
3. **parse_many delimiter**: Use semicolons, not commas: `parse_many("100/hour;10/minute")`. Commas will cause parse errors.
4. **MovingWindowRateLimiter memory**: Stores individual timestamps for each request. At high rates, this uses significantly more memory than fixed window. Use FixedWindow for high-volume scenarios.
5. **Async storage is separate**: `limits.storage.RedisStorage` is sync-only. For async, use `limits.aio.storage.RedisStorage`. They are different classes.
6. **Window stats timing**: `get_window_stats().reset_time` is a Unix timestamp, not seconds-until-reset. Subtract `time.time()` for a countdown.
7. **Identifier ordering matters**: `limiter.hit(rate, "a", "b")` and `limiter.hit(rate, "b", "a")` produce different keys. Be consistent.
