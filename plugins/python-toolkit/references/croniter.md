# croniter v6.0.0

Cron expression parser and iterator. Computes next/previous occurrences from cron schedules.
Supports 5-field (standard), 6-field (seconds), 7-field (seconds + year), and hashed expressions.

```
pip install croniter>=5.0
```

## Quick Start

```python
from croniter import croniter
from datetime import datetime

base = datetime(2025, 1, 1)
cron = croniter("*/5 * * * *", base)     # Every 5 minutes
print(cron.get_next(datetime))           # 2025-01-01 00:05:00
print(cron.get_next(datetime))           # 2025-01-01 00:10:00
print(cron.get_prev(datetime))           # 2025-01-01 00:05:00
```

## Core API

### Constructor

```python
croniter(
    expr_format: str,                    # Cron expression string
    start_time: datetime | float = None, # Start time (default: now)
    ret_type: type = float,              # Default return type (float, datetime)
    day_or: bool = True,                 # True: day-of-month OR day-of-week
                                         # False: day-of-month AND day-of-week
    max_years_between_matches: int = 50, # Max gap to search before giving up
    hash_id: str = None,                 # Seed for hashed (H) expressions
    implement_cron_bug: bool = False,    # Match cron's DST handling quirks
    second_at_beginning: bool = False,   # If True, seconds field is first (not sixth)
)
```

### Iteration Methods

```python
# Get next/previous occurrence
cron.get_next(ret_type=float) -> float | datetime
cron.get_prev(ret_type=float) -> float | datetime
# ret_type: float (Unix timestamp) or datetime

# Get current match (without advancing)
cron.get_current(ret_type=float) -> float | datetime

# Set current time
cron.set_current(start_time: datetime | float, force: bool = True)

# Iterate all future/past occurrences (generator)
cron.all_next(ret_type=float) -> Iterator[float | datetime]
cron.all_prev(ret_type=float) -> Iterator[float | datetime]

# Example: get next 10 occurrences
from itertools import islice
next_10 = list(islice(cron.all_next(datetime), 10))
```

### Class Methods

```python
# Validate expression
croniter.is_valid(expr: str) -> bool
croniter.is_valid("*/5 * * * *")         # True
croniter.is_valid("*/5 * * *")           # False (4 fields)
croniter.is_valid("61 * * * *")          # False (minute > 59)

# Match: check if a specific time matches the expression
croniter.match(
    expr: str,                           # Cron expression
    dt: datetime,                        # Time to check
) -> bool
croniter.match("0 9 * * MON", datetime(2025, 1, 6, 9, 0))  # True (Monday 9am)

# Expand expression into value lists
croniter.expand(expr: str) -> tuple[list, ...]
# Returns tuple of lists: (minutes, hours, days, months, dow)
```

## Cron Expression Reference

```
Standard 5-field:  MIN HOUR DOM MON DOW
6-field (seconds): MIN HOUR DOM MON DOW SEC
7-field:           MIN HOUR DOM MON DOW SEC YEAR

Field    Range          Special
-----    -----          -------
MIN      0-59           * , - /
HOUR     0-23           * , - /
DOM      1-31           * , - / L W
MON      1-12 or JAN-DEC  * , - /
DOW      0-6 or SUN-SAT   * , - / L #
SEC      0-59           * , - /
YEAR     1970-2099      * , - /
```

Special chars: `*` (every), `,` (list), `-` (range), `/` (step), `L` (last),
`W` (nearest weekday), `#` (Nth weekday, e.g. `5#3` = 3rd Friday), `H` (hashed).

### Hashed Expressions (Jenkins-Style)

```python
# H distributes load by hashing the hash_id to pick a stable value
# within the field's range
cron = croniter("H * * * *", hash_id="my-job-id")
# Equivalent to a fixed minute (e.g., "37 * * * *") determined by hash

cron = croniter("H H(0-3) * * *", hash_id="nightly")
# Random hour between 0-3, random minute, stable per hash_id

croniter.is_valid("H/15 * * * *")   # True -- every 15 min, hashed offset
```

### 6-Field with Seconds

```python
# Seconds as 6th field (default position)
cron = croniter("* * * * * */15", base)      # Every 15 seconds
next_dt = cron.get_next(datetime)

# Seconds as 1st field
cron = croniter("*/15 * * * * *", base, second_at_beginning=True)
```

## Examples

### 1. Next N Occurrences of a Schedule

```python
from croniter import croniter
from datetime import datetime
from itertools import islice

now = datetime.now()
cron = croniter("0 9 * * MON-FRI", now)     # Weekdays at 9am

next_5 = list(islice(cron.all_next(datetime), 5))
for dt in next_5:
    print(dt.strftime("%Y-%m-%d %H:%M %A"))
```

### 2. Check if Current Time Matches a Schedule

```python
from croniter import croniter
from datetime import datetime

schedules = {
    "hourly":   "0 * * * *",
    "daily_9":  "0 9 * * *",
    "weekdays": "0 9 * * MON-FRI",
}

now = datetime.now()
for name, expr in schedules.items():
    if croniter.match(expr, now):
        print(f"Matched: {name}")
```

### 3. Time Until Next Occurrence

```python
from croniter import croniter
from datetime import datetime

now = datetime.now()
cron = croniter("30 2 * * *", now)          # Daily at 2:30am
next_run = cron.get_next(datetime)
delta = next_run - now
print(f"Next run in {delta.total_seconds():.0f}s ({delta})")
```

## Pitfalls

- **Iteration is stateful.** Each `get_next()` / `get_prev()` advances the internal
  pointer. To restart, create a new `croniter` or call `set_current()`.
- **`all_next()` / `all_prev()` are infinite generators.** Always use `islice()` or
  a break condition. Without it, you get an infinite loop.
- **Default return type is `float` (Unix timestamp).** Pass `datetime` explicitly:
  `cron.get_next(datetime)`. Forgetting this returns a float that looks wrong.
- **Day-of-month and day-of-week are OR by default.** `0 0 15 * FRI` means "15th of
  month OR any Friday", not "15th that is a Friday". Use `day_or=False` for AND logic.
- **DST transitions can cause skipped or repeated times.** Be aware when iterating
  through DST boundaries. Use timezone-aware datetimes with `pytz` or `zoneinfo`.
- **`is_valid()` does not catch all semantic errors.** It validates syntax but may
  accept expressions that never match (e.g., February 31st). The iterator simply
  skips impossible dates.
- **Second field position changed.** In older versions, `second_at_beginning=True`
  was the default. In current versions, seconds are the 6th field by default.
