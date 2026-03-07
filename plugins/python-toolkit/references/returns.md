# returns v0.23.0

## Quick Start

```python
from returns.result import Result, Success, Failure

def parse_int(s: str) -> Result[int, str]:
    try:
        return Success(int(s))
    except ValueError:
        return Failure(f"Cannot parse: {s}")

parse_int("42")   # Success(42)
parse_int("abc")  # Failure("Cannot parse: abc")
```

## Core API

```python
# Result -- typed error handling (replaces exceptions)
from returns.result import Result, Success, Failure, safe

Success(42)                                # happy path
Failure("error")                           # sad path

result.map(lambda x: x * 2)               # transform Success value
result.bind(validate_positive)             # chain Result-returning functions
result.alt(lambda e: f"Error: {e}")        # transform Failure value
result.lash(recover_func)                  # recover from Failure
result.value_or(0)                         # extract with default
result.unwrap()                            # unsafe: raises on Failure

@safe                                      # exceptions -> Result
def divide(a, b): return a / b
divide(10, 0)  # Failure(ZeroDivisionError(...))

# Maybe -- optional values without None
from returns.maybe import Maybe, Some, Nothing
Some(42) / Nothing
maybe.map(f).bind(g).value_or(default)

# IO / IOResult -- marking impure operations
from returns.io import IO, IOResult, IOSuccess, IOFailure, impure_safe

@impure_safe
def read_file(path): return open(path).read()
read_file("x.txt")  # IOSuccess("...") or IOFailure(FileNotFoundError)

# Future / FutureResult -- async containers
from returns.future import FutureResultE, future_safe

@future_safe
async def fetch(url): ...   # returns FutureResultE[str]

# Pipeline composition
from returns.pipeline import flow
from returns.pointfree import bind, map_

result = flow(
    Success("42"),
    bind(parse_int),
    map_(lambda x: x * 2),
)  # Success(84)

# Do notation (imperative monadic style)
result = Result.do(
    f"Port: {port}"
    for port in parse_int("8080")
    for port in check_range(port, 1, 65535)
)  # Success("Port: 8080")
```

## Examples

### Railway-oriented processing pipeline

```python
from returns.pipeline import flow
from returns.pointfree import bind, map_

def validate(data: dict) -> Result[dict, str]:
    if "name" not in data:
        return Failure("missing name")
    return Success(data)

def process(data: dict) -> Result[str, str]:
    return Success(f"Processed {data['name']}")

result = flow(
    Success({"name": "Alice"}),
    bind(validate),
    bind(process),
)  # Success("Processed Alice")
```

### @safe decorator

```python
from returns.result import safe
import json

@safe
def parse_json(raw: str) -> dict:
    return json.loads(raw)

parse_json('{"a": 1}')   # Success({'a': 1})
parse_json('invalid')     # Failure(JSONDecodeError(...))
```

### Pattern matching (Python 3.10+)

```python
match result:
    case Success(value): print(f"Got: {value}")
    case Failure(error): print(f"Error: {error}")
```

## Pitfalls

- **mypy plugin required**: add `returns.contrib.mypy.returns_plugin` to mypy plugins for proper type inference.
- **`@safe` catches ALL exceptions**: including KeyboardInterrupt. Use specific exception handling if needed.
- **`.unwrap()` raises `UnwrapFailedError`**: only use at program boundaries, not in business logic.
- **`.map()` vs `.bind()`**: `.map(f)` takes `T -> U`. `.bind(f)` takes `T -> Result[U, E]`. Mixing them is the most common mistake.
- **`flow()` is not lazy**: all functions execute eagerly. Short-circuits on Failure via bind semantics.
- **Performance overhead**: containers add allocation cost. Fine for I/O-bound code, avoid in tight numeric loops.
