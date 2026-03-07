# time-machine v2.16+

Fast time-mocking for Python tests. Replaces C-level time functions (not just Python imports), so it catches `datetime.now()`, `time.time()`, `time.monotonic()`, etc.

## Quick Start

```python
import datetime as dt
import time_machine

@time_machine.travel("2024-01-15 12:00:00")
def test_frozen_time():
    assert dt.date.today() == dt.date(2024, 1, 15)
```

## Core API

### `time_machine.travel(destination, *, tick=True)`

Creates a time travel context. Can be used as decorator, context manager, or started/stopped manually.

**Parameters:**
- `destination` -- Where to travel. Accepts:
  - `datetime.datetime` (naive treated as local, aware respected)
  - `datetime.date` (midnight)
  - `str` (ISO format, e.g. `"2024-01-15"` or `"2024-01-15 09:30:00+00:00"`)
  - `float` / `int` (Unix timestamp)
  - `callable` returning any of the above (called at start)
- `tick` -- If `True` (default), time advances in real-time from destination. If `False`, time is frozen until explicitly moved.

**Returns a `Coordinates` object** (when used as context manager) with:
- `coordinates.move_to(destination)` -- Jump to a new point in time.
- `coordinates.shift(delta)` -- Move relative to current time. Accepts `timedelta` or numeric seconds (positive or negative).

### Usage Patterns

```python
import datetime as dt
import time
import time_machine

# As decorator
@time_machine.travel(dt.datetime(2024, 6, 1, tzinfo=dt.timezone.utc))
def test_decorated():
    assert dt.datetime.now(dt.timezone.utc).year == 2024

# As context manager
with time_machine.travel("2024-01-01", tick=False) as traveller:
    assert time.time() == dt.datetime(2024, 1, 1).timestamp()
    traveller.shift(dt.timedelta(hours=2))
    # Now 2 hours later
    traveller.move_to("2024-06-01")
    # Now June 1st

# Manual start/stop
traveller = time_machine.travel("2024-01-01")
traveller.start()
# ... do work ...
traveller.stop()

# Async context manager
async with time_machine.travel("2024-01-01") as traveller:
    ...
```

### pytest Fixture

time-machine ships a built-in pytest fixture called `time_machine`. No extra install needed.

```python
def test_with_fixture(time_machine):
    time_machine.move_to(dt.datetime(2024, 3, 15, tzinfo=dt.timezone.utc))
    assert dt.date.today() == dt.date(2024, 3, 15)

    time_machine.shift(dt.timedelta(days=7))
    assert dt.date.today() == dt.date(2024, 3, 22)
```

## Examples

### Frozen Time with Explicit Steps

```python
@time_machine.travel("2024-01-01 00:00:00", tick=False)
def test_token_expiry():
    token = create_token(expires_in=3600)
    assert not token.is_expired()

    # Manually advance past expiry
    with time_machine.travel("2024-01-01 01:00:01", tick=False):
        assert token.is_expired()
```

### UTC-Aware Testing

```python
import datetime as dt
import time_machine

@time_machine.travel(dt.datetime(2024, 7, 4, 12, 0, tzinfo=dt.timezone.utc))
def test_utc():
    now = dt.datetime.now(dt.timezone.utc)
    assert now == dt.datetime(2024, 7, 4, 12, 0, tzinfo=dt.timezone.utc)
```

### Autouse Fixture for Test Classes

```python
import pytest
import datetime as dt

class TestScheduler:
    @pytest.fixture(autouse=True)
    def freeze(self, time_machine):
        time_machine.move_to(dt.datetime(2024, 1, 1, 9, 0))

    def test_morning_schedule(self):
        assert get_schedule_period() == "morning"

    def test_advance_to_afternoon(self, time_machine):
        time_machine.move_to(dt.datetime(2024, 1, 1, 14, 0))
        assert get_schedule_period() == "afternoon"
```

## Pitfalls

- **`tick=True` is the default.** Time keeps advancing in real-time after the jump. Use `tick=False` when you need deterministic timestamps (e.g., comparing exact values in assertions).
- **Naive datetimes are treated as local time**, not UTC. Always pass timezone-aware datetimes (e.g., `datetime(2024, 1, 1, tzinfo=timezone.utc)`) to avoid surprises on CI servers in different timezones.
- **Nesting `travel()` calls works** -- inner travel overrides outer. When the inner exits, the outer destination resumes.
- **`time.monotonic()` is also mocked.** This can affect timeouts, retries, and asyncio internals. If a test hangs, check whether frozen time is blocking a timeout check.
- **The pytest fixture is function-scoped.** You cannot use it as a session or module fixture. For broader scope, use `travel().start()` / `.stop()` in a conftest fixture.
- **Fixture ordering matters.** If combining with other fixtures that read time, ensure `time_machine` is applied first (list it earlier in the function signature or use `autouse`).
- **`shift()` with negative values works** but can cause confusing results if other code assumes monotonic time progression.
