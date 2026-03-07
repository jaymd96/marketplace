# attrs v24.3.0

## Quick Start

```python
import attrs

@attrs.define      # mutable, slots=True by default
class User:
    name: str
    email: str
    age: int = 0

@attrs.frozen      # immutable + hashable
class Point:
    x: float
    y: float

u = User("Alice", "alice@ex.com", 30)
p = attrs.evolve(Point(1.0, 2.0), x=3.0)  # Point(x=3.0, y=2.0)
```

## Core API

```python
@attrs.define           # mutable, slots=True, eq=True
@attrs.frozen           # immutable + hashable (frozen=True, slots=True)
@attrs.mutable          # explicit alias for @attrs.define

attrs.field(            # field config
    default=...,        # static default (NO mutable objects -- use factory)
    factory=list,       # callable for mutable defaults
    validator=...,      # validator or list of validators
    converter=...,      # callable to convert value before setting
    repr=True,          # include in __repr__
    eq=True,            # include in __eq__
    hash=None,          # include in __hash__
    init=True,          # include in __init__
    alias="name",       # alternative __init__ parameter name
    kw_only=False,      # keyword-only in __init__
    on_setattr=...,     # per-field setattr hook
)

attrs.Factory(fn, takes_self=False)  # lazy default; takes_self for self-referential
attrs.evolve(inst, **changes)        # create modified copy (runs validators)
attrs.asdict(inst)                   # recursive dict conversion
attrs.astuple(inst)                  # recursive tuple conversion
attrs.fields(cls)                    # tuple of Attribute objects
attrs.has(cls)                       # True if cls is an attrs class
attrs.resolve_types(cls)             # resolve string annotations to real types
```

### Built-in Validators

```python
attrs.validators.instance_of(type)          # isinstance check
attrs.validators.in_(options)               # membership check
attrs.validators.matches_re(pattern)        # regex match
attrs.validators.gt(val) / ge(val) / lt(val) / le(val)  # numeric bounds
attrs.validators.min_len(n) / max_len(n)    # length validation
attrs.validators.and_(*v) / or_(*v)         # compose validators
attrs.validators.optional(v)               # allow None
attrs.validators.deep_iterable(member, iterable)  # validate collection items
```

### Converters

```python
attrs.converters.optional(converter)   # pass None, otherwise convert
attrs.converters.pipe(*converters)     # chain converters
attrs.converters.to_bool              # "yes"/"no"/"true"/"false" -> bool
```

## Examples

### Validators and Converters

```python
@attrs.define
class Config:
    port: int = attrs.field(converter=int, validator=[attrs.validators.ge(1024), attrs.validators.le(65535)])
    tags: list[str] = attrs.Factory(list)
    host: str = attrs.field(default="localhost", converter=str.lower)
```

### Frozen with evolve

```python
@attrs.frozen
class AppConfig:
    host: str = "0.0.0.0"
    port: int = 8080
    debug: bool = False

prod = AppConfig()
dev = attrs.evolve(prod, debug=True, port=3000)
```

### Post-init and derived fields

```python
@attrs.frozen
class Circle:
    radius: float
    _area: float = attrs.field(init=False)

    def __attrs_post_init__(self):
        object.__setattr__(self, "_area", 3.14159 * self.radius ** 2)
```

## Pitfalls

- **Mutable defaults**: `members: list = []` raises ValueError. Use `attrs.Factory(list)`.
- **evolve() runs validators**: both old and new values are validated via `__init__`.
- **Slots + multiple inheritance**: only one class in MRO should define non-empty `__slots__`.
- **`from __future__ import annotations`**: call `attrs.resolve_types(cls)` if you need runtime type access.
- **Non-value fields** (loggers, caches): set `eq=False, hash=False, repr=False`.
- **Frozen post-init**: must use `object.__setattr__()` in `__attrs_post_init__`.
