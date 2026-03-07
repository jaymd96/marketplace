# pendulum v3.0.0

## Quick Start

```python
import pendulum

now = pendulum.now("UTC")                    # always timezone-aware
tomorrow = now.add(days=1)                   # immutable -- returns new object
now.diff_for_humans()                        # "just now"
```

## Core API

```python
# Creation
pendulum.now(tz="UTC")
pendulum.today() / pendulum.tomorrow() / pendulum.yesterday()
pendulum.datetime(2026, 3, 15, 14, 30, tz="America/New_York")
pendulum.parse("2026-03-15T14:30:00+00:00")
pendulum.from_format("15/03/2026", "DD/MM/YYYY")
pendulum.from_timestamp(1773849600, tz="UTC")
pendulum.instance(stdlib_datetime, tz="UTC")   # convert stdlib datetime

# Arithmetic (all return NEW DateTime)
dt.add(years=1, months=2, days=3, hours=4)
dt.subtract(weeks=2, days=1)

# Differences
diff = dt1.diff(dt2)
diff.in_days() / diff.in_hours() / diff.in_months()
dt.diff_for_humans()                          # "3 hours ago" / "in 2 days"

# Boundaries
dt.start_of("day")    # also: year, month, week, hour
dt.end_of("month")    # last moment of the unit

# Formatting
dt.format("YYYY-MM-DD HH:mm:ss")             # pendulum tokens
dt.to_iso8601_string()                        # ISO 8601
dt.to_datetime_string()                       # "2026-03-15 14:30:45"

# Timezone
dt.in_timezone("Asia/Tokyo")
dt.in_tz("UTC")                               # shorthand

# Comparisons
dt.is_past() / dt.is_future() / dt.is_today() / dt.is_weekend()

# Duration and Period
dur = pendulum.duration(days=30, hours=5)
dur.in_hours() / dur.in_words()

period = pendulum.period(start, end)
period.in_days()
for dt in period.range("days"):               # iterate over each day
    print(dt)
```

## Examples

### Date arithmetic and formatting

```python
dt = pendulum.datetime(2026, 1, 15, 12, 0, tz="UTC")
next_month = dt.add(months=1)                 # 2026-02-15
start = dt.start_of("week")                   # Monday 00:00
end = dt.end_of("month")                      # Jan 31 23:59:59.999999
dt.format("dddd, MMMM D, YYYY")              # "Thursday, January 15, 2026"
```

### Timezone conversion

```python
utc = pendulum.now("UTC")
eastern = utc.in_tz("America/New_York")
tokyo = utc.in_tz("Asia/Tokyo")
assert utc == eastern == tokyo                 # same instant, different representation
```

### Iterating over a period

```python
start = pendulum.datetime(2026, 1, 1)
end = pendulum.datetime(2026, 3, 31)
for dt in pendulum.period(start, end).range("weeks"):
    print(dt.to_date_string())                # "2026-01-01", "2026-01-08", ...
```

## Pitfalls

- **Immutable**: `.add()` and `.subtract()` return new objects. The original is unchanged.
- **Mixing with stdlib timedelta**: `dt + timedelta(days=5)` returns a stdlib `datetime`, not pendulum. Use `dt.add(days=5)`.
- **pendulum 2.x vs 3.x**: `interval()` renamed to `duration()`. Check your version.
- **`parse()` strict mode**: default strict mode rejects "March 15, 2026". Use `strict=False` or `from_format()`.
- **Format tokens differ from strftime**: pendulum uses `YYYY-MM-DD`, not `%Y-%m-%d`. Use `.strftime()` for stdlib format strings.
- **Week starts Monday**: `start_of("week")` returns Monday by default.
- **JSON serialization**: pendulum DateTime is a datetime subclass -- use `.isoformat()` or `.to_iso8601_string()`.
