# cachetools v5.5+

In-memory caching collections and decorators. Drop-in replacements for `functools.lru_cache` with more eviction policies.

## Quick Start

```python
from cachetools import TTLCache, cached

cache = TTLCache(maxsize=100, ttl=300)  # 100 items, 5-minute TTL

@cached(cache)
def get_user(user_id):
    return db.query(f"SELECT * FROM users WHERE id = {user_id}")
```

## Core API

### Cache Classes

All caches are `MutableMapping` subclasses (dict-like interface).

```python
from cachetools import LRUCache, TTLCache, LFUCache, FIFOCache, TLRUCache

# LRU -- evicts least recently used
cache = LRUCache(maxsize=256)

# TTL -- evicts expired items first, then LRU
cache = TTLCache(maxsize=256, ttl=60)          # 60-second TTL
cache = TTLCache(maxsize=256, ttl=60, timer=time.monotonic)  # Custom timer

# LFU -- evicts least frequently used
cache = LFUCache(maxsize=256)

# FIFO -- evicts oldest inserted
cache = FIFOCache(maxsize=256)

# TLRU -- per-item TTL via user function
cache = TLRUCache(maxsize=256, ttu=lambda key, value, now: now + 60, timer=time.monotonic)
```

**Common cache interface:**

```python
cache[key] = value            # Set
value = cache[key]            # Get (raises KeyError)
value = cache.get(key, None)  # Get with default
del cache[key]                # Delete
len(cache)                    # Current size
key in cache                  # Membership
cache.clear()                 # Remove all items

# TTLCache-specific
cache.currsize                # Current number of items
cache.maxsize                 # Maximum capacity
cache.timer()                 # Current time value
```

### `@cached(cache, key=hashkey, lock=None, info=False)`

Decorator that memoizes function return values.

```python
from cachetools import cached, TTLCache, LRUCache
from cachetools.keys import hashkey
import threading

# Basic usage
@cached(cache=LRUCache(maxsize=128))
def expensive(x, y):
    return x ** y

# Thread-safe with lock
@cached(cache=TTLCache(maxsize=100, ttl=300), lock=threading.Lock())
def fetch_config(key):
    return db.get_config(key)

# Custom cache key (ignore certain args)
def my_key(request, use_cache=True):
    return hashkey(request.url)

@cached(cache=LRUCache(maxsize=64), key=my_key)
def handle(request, use_cache=True):
    return process(request)

# info=True adds .cache_info() like functools.lru_cache
@cached(cache=LRUCache(maxsize=64), info=True)
def compute(n):
    return sum(range(n))

print(compute.cache_info())  # CacheInfo(hits=..., misses=..., maxsize=64, currsize=...)
```

### `@cachedmethod(cache, key=methodkey, lock=None)`

Decorator for instance methods. `cache` and `lock` are callables that receive `self`.

```python
from cachetools import cachedmethod, TTLCache
from cachetools.keys import methodkey   # Ignores self in the key
import threading

class UserService:
    def __init__(self):
        self._cache = TTLCache(maxsize=100, ttl=60)
        self._lock = threading.Lock()

    @cachedmethod(lambda self: self._cache, lock=lambda self: self._lock)
    def get_user(self, user_id):
        return db.query_user(user_id)
```

### Key Functions (`cachetools.keys`)

```python
from cachetools.keys import hashkey, methodkey, typedkey

hashkey(1, 2, a=3)      # Returns a hashable tuple-like key
methodkey(self, 1, 2)   # Same as hashkey but ignores first arg (self)
typedkey(1, 2)           # Like hashkey but treats int(1) != float(1.0)
```

## Examples

### API Rate Limiter Cache

```python
from cachetools import TTLCache, cached
import threading

# Cache API responses for 30 seconds, max 500 entries
_api_cache = TTLCache(maxsize=500, ttl=30)
_api_lock = threading.Lock()

@cached(cache=_api_cache, lock=_api_lock)
def call_external_api(endpoint, params_hash):
    resp = httpx.get(f"https://api.example.com/{endpoint}")
    return resp.json()
```

### Per-Instance Cache with TTL

```python
from cachetools import TTLCache, cachedmethod
from cachetools.keys import methodkey

class ConfigManager:
    def __init__(self, ttl=300):
        self._cache = TTLCache(maxsize=50, ttl=ttl)

    @cachedmethod(lambda self: self._cache)
    def get_setting(self, key):
        return self._load_from_db(key)

    def invalidate(self, key=None):
        if key:
            self._cache.pop(methodkey(key), None)
        else:
            self._cache.clear()
```

### Manual Cache Usage (No Decorator)

```python
from cachetools import LRUCache

cache = LRUCache(maxsize=1000)

def get_or_compute(key):
    if key in cache:
        return cache[key]
    result = expensive_computation(key)
    cache[key] = result
    return result
```

## Pitfalls

- **Caches are NOT thread-safe by default.** Always pass a `lock=threading.Lock()` when using `@cached` in multi-threaded code. Without it, concurrent access can corrupt the cache.
- **`@cachedmethod` takes callables, not objects.** Write `cache=lambda self: self._cache`, not `cache=self._cache`. The latter fails because `self` is not available at decoration time.
- **`TTLCache` does not actively expire items.** Expired items are removed lazily on access. The cache may hold stale data in memory until the next read or write triggers cleanup.
- **`maxsize` is the item count, not memory.** A cache of 100 large objects uses more memory than 100 small ones. There is no built-in memory-based eviction.
- **Unhashable arguments break the default key functions.** If your function takes dicts or lists, write a custom key function that converts them to hashable form.
- **`@cached(cache={})` with a plain dict means unbounded caching** with no eviction. This is a memory leak in long-running processes.
- **The `lock` only guards cache access**, not the underlying function execution. Two threads can still call the wrapped function simultaneously if both miss the cache.
