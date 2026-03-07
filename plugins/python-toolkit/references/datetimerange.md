# DateTimeRange v2.3.1

Python library for datetime range operations: intersection, union, subtraction,
iteration, and containment checks.

```
pip install DateTimeRange>=2.2
```

## Quick Start

```python
from datetimerange import DateTimeRange
from datetime import datetime

r = DateTimeRange("2025-01-01T00:00:00", "2025-01-31T23:59:59")
print(datetime(2025, 1, 15) in r)        # True
print(r.timedelta)                        # 30 days, 23:59:59
print(r.is_set())                         # True
```

## Core API

### Constructor

```python
from datetimerange import DateTimeRange
from datetime import datetime

r = DateTimeRange("2025-01-01T00:00:00", "2025-01-31T23:59:59")  # From strings
r = DateTimeRange(datetime(2025, 1, 1), datetime(2025, 1, 31))   # From datetimes
r = DateTimeRange()                        # Unset; use set_start_datetime/set_end_datetime

# Properties
r.start_datetime                          # datetime object
r.end_datetime                            # datetime object
r.timedelta                               # timedelta (end - start)
r.is_set()                                # True if both start and end are set
```

### Containment and Overlap

```python
# Point-in-range check
datetime(2025, 1, 15) in r               # True
"2025-01-15T12:00:00" in r               # True (string parsed)

# Range-in-range check
inner = DateTimeRange("2025-01-10", "2025-01-20")
inner in r                                # True (fully contained)

# Overlap check
other = DateTimeRange("2025-01-20", "2025-02-10")
r.is_intersection(other)                  # True

# Validity
r.is_set()                                # True if both start and end are set
r.validate_time_inversion()               # Raises ValueError if start > end
```

### Intersection

```python
r1 = DateTimeRange("2025-01-01", "2025-01-20")
r2 = DateTimeRange("2025-01-10", "2025-01-31")

# Get intersection (overlap)
result = r1.intersection(r2)
# DateTimeRange("2025-01-10", "2025-01-20")

# Returns empty range if no overlap
r3 = DateTimeRange("2025-02-01", "2025-02-28")
result = r1.intersection(r3)              # Empty DateTimeRange
result.is_set()                           # False
```

### Encompass (Union / Merge)

```python
r1 = DateTimeRange("2025-01-01", "2025-01-15")
r2 = DateTimeRange("2025-01-10", "2025-01-31")

# Smallest range that contains both
result = r1.encompass(r2)
# DateTimeRange("2025-01-01", "2025-01-31")
```

### Subtract (Difference)

```python
r1 = DateTimeRange("2025-01-01", "2025-01-31")
r2 = DateTimeRange("2025-01-10", "2025-01-20")

# Remove r2 from r1 -- returns list of remaining ranges
result = r1.subtract(r2)
# [DateTimeRange("2025-01-01", "2025-01-10"),
#  DateTimeRange("2025-01-20", "2025-01-31")]

# No overlap: returns [original]
r3 = DateTimeRange("2025-03-01", "2025-03-31")
r1.subtract(r3)                           # [DateTimeRange("2025-01-01", "2025-01-31")]
```

### Truncate

```python
r = DateTimeRange("2025-01-01", "2025-01-31")

# Truncate to fit within a boundary
boundary = DateTimeRange("2025-01-10", "2025-02-28")
r.truncate(boundary)
# r is now DateTimeRange("2025-01-10", "2025-01-31")
```

### Iteration

```python
from datetimerange import DateTimeRange
from datetime import timedelta

r = DateTimeRange("2025-01-01", "2025-01-05")

# Iterate with step
for dt in r.range(timedelta(days=1)):
    print(dt)
# 2025-01-01 00:00:00
# 2025-01-02 00:00:00
# 2025-01-03 00:00:00
# 2025-01-04 00:00:00

# Using dateutil relativedelta for month steps
from dateutil.relativedelta import relativedelta
r = DateTimeRange("2025-01-01", "2025-06-01")
for dt in r.range(relativedelta(months=1)):
    print(dt.strftime("%Y-%m"))
```

### Timezone Support

```python
from datetimerange import DateTimeRange
from datetime import datetime
import zoneinfo

eastern = zoneinfo.ZoneInfo("America/New_York")
r = DateTimeRange(datetime(2025, 1, 1, 9, 0, tzinfo=eastern),
                  datetime(2025, 1, 1, 17, 0, tzinfo=eastern))

utc_time = datetime(2025, 1, 1, 15, 0, tzinfo=zoneinfo.ZoneInfo("UTC"))
utc_time in r                             # True (10am ET)
```

## Examples

### 1. Meeting Overlap Detection

```python
from datetimerange import DateTimeRange

meetings = [
    DateTimeRange("2025-03-10T09:00", "2025-03-10T10:00"),
    DateTimeRange("2025-03-10T09:30", "2025-03-10T11:00"),
    DateTimeRange("2025-03-10T14:00", "2025-03-10T15:00"),
]
for i, m1 in enumerate(meetings):
    for m2 in meetings[i + 1:]:
        if m1.is_intersection(m2):
            print(f"Conflict: {m1.intersection(m2).timedelta} overlap")
```

### 2. Business Hours Filtering

```python
from datetimerange import DateTimeRange

work_day = DateTimeRange("2025-03-10T09:00", "2025-03-10T17:00")
lunch = DateTimeRange("2025-03-10T12:00", "2025-03-10T13:00")
available = work_day.subtract(lunch)       # [09:00-12:00, 13:00-17:00]
```

## Pitfalls

- **String parsing depends on dateutil.** DateTimeRange uses `dateutil.parser.parse`
  internally. Ambiguous date strings (e.g., "01/02/03") may parse differently than
  expected. Use ISO 8601 format for reliability.
- **`subtract()` returns a list, not a DateTimeRange.** A single subtraction can
  produce 0, 1, or 2 ranges. Always handle the list result.
- **`encompass()` fills gaps.** It returns the smallest range containing both inputs,
  even if they don't overlap. It is not a union that preserves gaps.
- **`truncate()` modifies in place.** Unlike `intersection()` which returns a new
  range, `truncate()` mutates the original DateTimeRange object.
- **Mixing naive and timezone-aware datetimes raises TypeError.** Ensure both start
  and end (and any comparison targets) use the same timezone awareness.
- **Empty/unset ranges.** Operations on unset ranges (`is_set() == False`) may
  return unexpected results or raise errors. Always check `is_set()` first.
