# python-dateutil v2.9.0

Powerful extensions to the standard `datetime` module. Flexible date parsing,
relative deltas, recurrence rules, and timezone handling.

```
pip install python-dateutil>=2.9
```

## Quick Start

```python
from dateutil import parser, relativedelta, rrule, tz
from datetime import datetime

dt = parser.parse("March 7, 2025 3:30pm")         # Flexible parsing
next_month = dt + relativedelta.relativedelta(months=1)
eastern = tz.gettz("America/New_York")
dt_eastern = dt.replace(tzinfo=eastern)
```

## Core API

### parser.parse -- Flexible Date Parsing

```python
from dateutil.parser import parse

# Handles most human-readable formats automatically
parse("2025-03-07")                        # datetime(2025, 3, 7, 0, 0)
parse("March 7, 2025")                     # datetime(2025, 3, 7, 0, 0)
parse("Mar 7 2025 3:30pm")                 # datetime(2025, 3, 7, 15, 30)
parse("2025-03-07T15:30:00+05:00")         # datetime with tzinfo

# Key params: dayfirst (DD/MM), yearfirst (YY/MM/DD), fuzzy (ignore non-date text),
#             default (fill missing fields), ignoretz, fuzzy_with_tokens
parse("07/03/2025", dayfirst=True)         # datetime(2025, 3, 7) -- March 7
parse("Meeting on March 7 at 3pm ok", fuzzy=True)  # datetime(..., 3, 7, 15, 0)
parse("March 7", default=datetime(2025, 1, 1))     # datetime(2025, 3, 7)
```

### relativedelta -- Relative Date Arithmetic

```python
from dateutil.relativedelta import relativedelta
from datetime import datetime

dt = datetime(2025, 3, 7, 12, 0)

# Add/subtract by calendar units (handles month lengths, leap years)
dt + relativedelta(months=1)               # 2025-04-07
dt + relativedelta(years=1)                # 2026-03-07
dt + relativedelta(months=1, days=5)       # 2025-04-12
dt - relativedelta(months=2)               # 2025-01-07

# End-of-month handling
datetime(2025, 1, 31) + relativedelta(months=1)   # 2025-02-28 (clamped)
datetime(2025, 1, 31) + relativedelta(months=2)   # 2025-03-31

# Set specific fields (absolute values)
dt + relativedelta(hour=9, minute=0, second=0)     # 2025-03-07 09:00:00
dt + relativedelta(day=1)                           # 2025-03-01 (first of month)
dt + relativedelta(day=31)                          # 2025-03-31 (clamped to month end)

# Weekday targeting
from dateutil.relativedelta import MO, TU, WE, TH, FR, SA, SU

dt + relativedelta(weekday=FR)             # Next Friday (or same day if Friday)
dt + relativedelta(weekday=FR(+1))         # Next Friday (same as FR)
dt + relativedelta(weekday=FR(+2))         # Friday after next
dt + relativedelta(weekday=FR(-1))         # Last Friday (previous or same)

# Difference between dates
rd = relativedelta(datetime(2025, 6, 15), datetime(2025, 3, 7))
rd.months                                  # 3
rd.days                                    # 8
# Total: 3 months and 8 days

# Full constructor: relative args (years, months, weeks, days, hours, minutes,
# seconds) are added; absolute args (year, month, day, hour, minute, second)
# replace. Also: weekday, yearday, nlyearday, leapdays.
```

### rrule -- Recurrence Rules (RFC 2445)

```python
from dateutil.rrule import rrule, rruleset, YEARLY, MONTHLY, WEEKLY, DAILY, HOURLY, MINUTELY
from dateutil.rrule import MO, TU, WE, TH, FR, SA, SU
from datetime import datetime

start = datetime(2025, 1, 1)

# Basic recurrence
list(rrule(DAILY, count=5, dtstart=start))
# [Jan 1, Jan 2, Jan 3, Jan 4, Jan 5]

list(rrule(WEEKLY, count=4, dtstart=start, byweekday=MO))
# [Jan 6, Jan 13, Jan 20, Jan 27]  -- Mondays

list(rrule(MONTHLY, count=6, dtstart=start, bymonthday=15))
# [Jan 15, Feb 15, Mar 15, Apr 15, May 15, Jun 15]

# Key params: freq, dtstart, interval, count, until,
# bymonth, bymonthday, byweekday, bysetpos, byhour, byminute, bysecond

# Complex: 2nd Tuesday of every month
list(rrule(MONTHLY, count=6, dtstart=start, byweekday=TU(+2)))

# Every other Wednesday
list(rrule(WEEKLY, count=4, interval=2, dtstart=start, byweekday=WE))

# Last day of each month
list(rrule(MONTHLY, count=3, dtstart=start, bymonthday=-1))
# [Jan 31, Feb 28, Mar 31]

# rruleset: combine rules with inclusions/exclusions
rs = rruleset()
rs.rrule(rrule(DAILY, count=10, dtstart=start))
rs.exdate(datetime(2025, 1, 5))            # Exclude Jan 5
rs.rdate(datetime(2025, 2, 14))            # Include Valentine's Day
list(rs)                                   # All dates minus exclusions plus additions

# Parse from iCalendar string
from dateutil.rrule import rrulestr
rule = rrulestr("RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR;COUNT=10", dtstart=start)
```

### tz -- Timezone Utilities

```python
from dateutil import tz
from datetime import datetime

eastern = tz.gettz("America/New_York")     # By IANA name
utc = tz.UTC                               # UTC constant
local = tz.tzlocal()                        # System local timezone
plus_5 = tz.tzoffset("IST", 5 * 3600)     # Fixed offset

dt = datetime(2025, 3, 7, 12, 0, tzinfo=eastern)
dt_utc = dt.astimezone(utc)                # Convert timezone

# Resolve ambiguous/nonexistent times during DST transitions
from dateutil.tz import resolve_imaginary
dt = resolve_imaginary(datetime(2025, 11, 2, 1, 30, tzinfo=eastern))
```

### easter

```python
from dateutil.easter import easter, EASTER_WESTERN, EASTER_ORTHODOX
easter(2025)                               # datetime.date(2025, 4, 20) -- Western default
easter(2025, EASTER_ORTHODOX)              # Orthodox calendar
```

## Examples

### 1. Business Day Calculator

```python
from dateutil.rrule import rrule, DAILY, MO, TU, WE, TH, FR
from dateutil.relativedelta import relativedelta
from datetime import datetime

start = datetime(2025, 3, 7)

# Next 10 business days
business_days = list(rrule(
    DAILY, count=10, dtstart=start,
    byweekday=(MO, TU, WE, TH, FR),
))

# Business days between two dates
end = datetime(2025, 3, 31)
count = len(list(rrule(DAILY, dtstart=start, until=end, byweekday=(MO, TU, WE, TH, FR))))
```

### 2. Monthly Report Dates

```python
from dateutil.relativedelta import relativedelta, FR
from datetime import datetime

start = datetime(2025, 1, 1)
first_of_months = [start + relativedelta(months=i) for i in range(12)]
last_fridays = [start + relativedelta(months=i, day=31, weekday=FR(-1)) for i in range(12)]
```

## Pitfalls

- **`parse()` guesses on ambiguous input.** `parse("01/02/03")` returns
  `datetime(2003, 1, 2)`. Use `dayfirst`/`yearfirst` to control interpretation.
- **`parse()` does not understand relative terms.** `parse("yesterday")` raises
  `ParserError`. Use `relativedelta` for relative dates.
- **`relativedelta(months=1)` != `timedelta(days=30)`.** Former handles variable months.
- **`rrule` without `count` or `until` is infinite.** `list()` will hang.
- **`tz.gettz()` returns `None` for unknown timezones** (no error). Always check.
- **DST transitions create ambiguous/nonexistent times.** Use `resolve_imaginary()`.
- **`relativedelta` between dates gives decomposed fields, not totals.** Use
  `(dt2 - dt1).days` for total days.
