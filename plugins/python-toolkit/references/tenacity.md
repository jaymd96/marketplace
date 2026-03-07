# tenacity v9.1.2

## Quick Start

```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, max=10))
def fetch_data():
    response = httpx.get("https://api.example.com/data")
    response.raise_for_status()
    return response.json()
```

## Core API

```python
from tenacity import (
    retry, stop_after_attempt, stop_after_delay,
    wait_fixed, wait_exponential, wait_exponential_jitter, wait_random,
    wait_chain, wait_combine,
    retry_if_exception_type, retry_if_result, retry_if_exception_message,
    before_sleep_log, RetryError, Retrying,
)

@retry(
    stop=stop_after_attempt(5) | stop_after_delay(30),        # OR combinator
    wait=wait_exponential(multiplier=1, min=1, max=60),
    retry=retry_if_exception_type((ConnectionError, TimeoutError)),
    before_sleep=before_sleep_log(logger, logging.WARNING),
    reraise=True,           # raise original exception, not RetryError
)
def my_func(): ...

# Stop strategies (combine with | for OR, & for AND)
stop_after_attempt(5)       # max 5 total attempts
stop_after_delay(30)        # max 30s total elapsed

# Wait strategies (combine with + for sum)
wait_fixed(2)                                          # 2s between retries
wait_exponential(multiplier=1, min=1, max=60)          # 1, 2, 4, 8... capped at 60
wait_exponential_jitter(initial=1, max=60, jitter=1)   # exponential + random jitter
wait_random(min=1, max=5)                              # uniform random
wait_chain(wait_fixed(1), wait_fixed(2), wait_exponential())  # sequential strategies
wait_fixed(1) + wait_random(0, 2)                      # 1-3s (sum)

# Retry conditions (combine with | for OR, & for AND)
retry_if_exception_type(IOError)
retry_if_exception_type((ConnectionError, TimeoutError))
retry_if_result(lambda r: r is None)                   # retry on return value
retry_if_exception_message(match=r".*timeout.*")

# Modify retry params on existing function
fast_fetch = fetch_data.retry_with(stop=stop_after_attempt(1), wait=wait_fixed(0))

# Context manager usage
for attempt in Retrying(stop=stop_after_attempt(3), wait=wait_fixed(1)):
    with attempt:
        result = some_operation()
```

## Examples

### HTTP with exponential backoff + jitter

```python
@retry(
    stop=stop_after_attempt(5) | stop_after_delay(120),
    wait=wait_exponential(multiplier=1, min=1, max=30) + wait_random(0, 2),
    retry=(retry_if_exception_type((ConnectionError, TimeoutError))
           | retry_if_result(lambda r: r.status_code >= 500)),
    before_sleep=before_sleep_log(logger, logging.WARNING),
    reraise=True,
)
def resilient_api_call(url): ...
```

### Polling until complete

```python
@retry(stop=stop_after_attempt(60), wait=wait_fixed(5),
       retry=retry_if_result(lambda r: r.get("status") not in ("completed", "failed")))
def poll_job(job_id: str) -> dict:
    return httpx.get(f"/jobs/{job_id}").json()
```

### Async retry

```python
@retry(stop=stop_after_attempt(5), wait=wait_exponential_jitter(initial=0.5, max=15),
       retry=retry_if_exception_type((ConnectionError, TimeoutError)), reraise=True)
async def async_fetch(url: str) -> dict:
    async with httpx.AsyncClient() as client:
        r = await client.get(url)
        r.raise_for_status()
        return r.json()
```

## Pitfalls

- **Bare `@retry` retries forever**: always specify `stop`. No stop + no wait = infinite CPU-burning loop.
- **`retry_if_result` does not retry exceptions**: combine with `retry_if_exception_type` using `|`.
- **`RetryError` wraps original**: use `reraise=True` to get the original exception, or access `e.last_attempt.exception()`.
- **`wait_chain` last strategy repeats**: the final wait strategy repeats for all remaining attempts.
- **Statistics are per-invocation**: reset on each call to the decorated function.
- **`retry_with()` creates a new function**: does not share state with the original.
