# orjson v3.10.15

## Quick Start

```python
import orjson

encoded = orjson.dumps({"name": "Alice", "scores": [95, 87]})  # returns bytes
decoded = orjson.loads(encoded)                                  # accepts bytes or str
```

## Core API

```python
# Serialize (returns bytes, NOT str)
orjson.dumps(obj, default=None, option=None) -> bytes
result_str = orjson.dumps(data).decode("utf-8")  # if you need str

# Deserialize (accepts bytes, bytearray, memoryview, or str)
orjson.loads(data) -> object

# Option flags (combine with |)
orjson.OPT_INDENT_2             # pretty-print 2-space indent
orjson.OPT_SORT_KEYS            # sort dict keys
orjson.OPT_NON_STR_KEYS         # allow int/float/bool/None/date/uuid/enum as keys
orjson.OPT_NAIVE_UTC             # serialize naive datetime as UTC (+00:00)
orjson.OPT_UTC_Z                 # use "Z" instead of "+00:00"
orjson.OPT_OMIT_MICROSECONDS    # drop microseconds from datetime/time
orjson.OPT_STRICT_INTEGER        # error on integers outside 53-bit range
orjson.OPT_SERIALIZE_NUMPY       # serialize numpy arrays/scalars
orjson.OPT_PASSTHROUGH_DATETIME  # pass datetime to default function
orjson.OPT_PASSTHROUGH_DATACLASS # pass dataclasses to default function
orjson.OPT_APPEND_NEWLINE        # append \n

orjson.dumps(data, option=orjson.OPT_INDENT_2 | orjson.OPT_SORT_KEYS)

# Custom serializer for unsupported types
def default(obj):
    if isinstance(obj, Decimal): return float(obj)
    if isinstance(obj, set): return sorted(obj)
    raise TypeError

orjson.dumps(data, default=default)
```

### Natively supported types (no default needed)

| Type | JSON Output |
|------|-------------|
| `str`, `int`, `float`, `bool`, `None` | standard JSON |
| `list`, `tuple` | array |
| `dict` | object (string keys by default) |
| `datetime.datetime` | ISO 8601 string |
| `datetime.date` | `"2025-03-15"` |
| `datetime.time` | `"12:00:00"` |
| `uuid.UUID` | canonical lowercase string |
| `dataclasses.dataclass` | dict of fields |
| `enum.Enum` | `.value` |
| `numpy.ndarray` | array (requires `OPT_SERIALIZE_NUMPY`) |

## Examples

### Dataclass serialization

```python
from dataclasses import dataclass
from datetime import datetime
from uuid import UUID

@dataclass
class User:
    id: UUID
    name: str
    created: datetime

orjson.dumps(User(UUID("12345678-..."), "Alice", datetime.now()))
# dataclass, datetime, UUID all handled automatically
```

### FastAPI integration

```python
from fastapi.responses import ORJSONResponse
app = FastAPI(default_response_class=ORJSONResponse)
```

## Pitfalls

- **Returns `bytes`, not `str`**: call `.decode("utf-8")` if you need a string.
- **No `cls` parameter**: unlike `json.dumps(cls=...)`. Use the `default` function instead.
- **Non-string dict keys**: require `OPT_NON_STR_KEYS` or you get `JSONEncodeError`.
- **Integer precision**: integers > 2^53 lose precision in JavaScript. Use `OPT_STRICT_INTEGER` to catch this.
- **No `ensure_ascii`**: orjson always outputs UTF-8. Non-ASCII characters are not escaped.
- **Naive datetimes**: serialized without timezone. Use `OPT_NAIVE_UTC` to force UTC.
- **5-10x faster than stdlib json**: the performance gap is real and consistent.
