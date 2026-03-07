# dramatiq v1.17+

Background task queue for Python. Simple, reliable, and performant. Supports Redis and RabbitMQ brokers.

```
pip install dramatiq[redis]    # Redis broker
pip install dramatiq[rabbitmq] # RabbitMQ broker
pip install dramatiq[watch]    # Auto-reload in dev
```

## Quick Start

```python
import dramatiq
from dramatiq.brokers.redis import RedisBroker

broker = RedisBroker(host="localhost", port=6379)
dramatiq.set_broker(broker)

@dramatiq.actor
def send_email(to, subject, body):
    # runs in a worker process
    print(f"Sending email to {to}")

send_email.send("user@example.com", "Hello", "World")
```

Run workers: `dramatiq my_module`

## Core API

### Actors

```python
@dramatiq.actor(
    queue_name="default",       # queue to enqueue on
    priority=0,                 # lower = higher priority (0-255)
    max_retries=3,              # retry count on failure
    min_backoff=1000,           # ms before first retry
    max_backoff=600000,         # ms max backoff
    max_age=3600000,            # ms max message age before discard
    time_limit=600000,          # ms max execution time
    store_results=False,        # enable result storage
)
def my_task(arg1, arg2):
    return arg1 + arg2

# Enqueue
my_task.send(1, 2)                          # fire and forget
my_task.send_with_options(args=(1, 2), delay=5000)  # delay in ms
```

### Broker Setup

```python
# Redis broker
from dramatiq.brokers.redis import RedisBroker
broker = RedisBroker(host="localhost", port=6379, db=0)
dramatiq.set_broker(broker)

# RabbitMQ broker
from dramatiq.brokers.rabbitmq import RabbitmqBroker
broker = RabbitmqBroker(host="localhost", port=5672)
dramatiq.set_broker(broker)
```

### Middleware

```python
# Built-in middleware (all on by default):
# - AgeLimit: drops messages that exceed max_age
# - TimeLimit: interrupts actors that exceed time_limit
# - Retries: retries failed actors with exponential backoff
# - ShutdownNotifications: notifies actors on worker shutdown
# - Callbacks: enables success/failure callbacks

# Add custom middleware
from dramatiq import Middleware

class LoggingMiddleware(Middleware):
    def before_process_message(self, broker, message):
        print(f"Processing: {message.actor_name}({message.args})")

    def after_process_message(self, broker, message, *, result=None, exception=None):
        if exception:
            print(f"Failed: {message.actor_name}: {exception}")
        else:
            print(f"Done: {message.actor_name}")

    def after_skip_message(self, broker, message):
        print(f"Skipped: {message.actor_name}")

broker.add_middleware(LoggingMiddleware())
```

### Results Backend

```python
from dramatiq.results import Results
from dramatiq.results.backends import RedisBackend

backend = RedisBackend(host="localhost", port=6379)
broker.add_middleware(Results(backend=backend))

@dramatiq.actor(store_results=True)
def add(x, y):
    return x + y

msg = add.send(3, 4)
result = msg.get_result(block=True, timeout=5000)  # -> 7
```

### Composition (Pipelines and Groups)

```python
import dramatiq

# Pipeline: chain actors sequentially
pipe = dramatiq.pipeline([
    add.message(1, 2),
    add.message(3),      # receives result of prior step as first arg
])
pipe.run()
result = pipe.get_result(block=True, timeout=10000)

# Group: run actors in parallel
group = dramatiq.group([
    add.message(1, 2),
    add.message(3, 4),
])
group.run()
results = group.get_results(block=True, timeout=10000)  # -> [3, 7]
```

### Error Handling

```python
@dramatiq.actor(max_retries=5, min_backoff=1000, max_backoff=60000)
def unreliable_task():
    raise ConnectionError("retry me")

# Custom retry logic
@dramatiq.actor(max_retries=3, throws=(ValueError,))  # don't retry ValueError
def picky_task(data):
    if not data:
        raise ValueError("bad data")  # will NOT be retried
    raise RuntimeError("oops")        # WILL be retried
```

## Examples

### Periodic scheduling with APScheduler

```python
import dramatiq
from apscheduler.schedulers.blocking import BlockingScheduler

@dramatiq.actor
def daily_report():
    print("Generating daily report...")

scheduler = BlockingScheduler()
scheduler.add_job(daily_report.send, "cron", hour=8, minute=0)
scheduler.start()
```

### Worker with multiple queues

```python
@dramatiq.actor(queue_name="high-priority")
def urgent_task(data):
    pass

@dramatiq.actor(queue_name="low-priority")
def batch_task(data):
    pass
```

Run: `dramatiq my_module --queues high-priority low-priority --processes 4 --threads 25`

### Rate-limited actor

```python
@dramatiq.actor(max_retries=10, min_backoff=2000)
def call_api(url):
    resp = requests.get(url)
    if resp.status_code == 429:
        raise dramatiq.RateLimitExceeded("rate limited")
    return resp.json()
```

## Pitfalls

1. **Broker must be set before actor decoration**: `dramatiq.set_broker(broker)` must run before any `@dramatiq.actor` decorators are evaluated. Put broker setup at module top level.
2. **Results require middleware**: `store_results=True` does nothing without `Results` middleware added to the broker. You will silently get `None`.
3. **Messages are not results**: `send()` returns a `Message`, not the return value. Use `.get_result(block=True)` with the results backend.
4. **Worker must import the module**: The worker CLI `dramatiq my_module` must be able to import all actors. Missing imports = actors silently not registered.
5. **Default retries are generous**: `max_retries=20` by default in v1.x. Set explicitly to avoid thundering herd on persistent failures.
6. **Serialization**: Arguments must be JSON-serializable by default. No `datetime`, no objects. Use primitive types or configure a custom encoder.
7. **No built-in scheduler**: Dramatiq does not include periodic task scheduling. Use APScheduler, cron, or `dramatiq-crontab` for recurring tasks.
