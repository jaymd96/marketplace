# cattrs v24.1.2

## Quick Start

```python
import attrs, cattrs

@attrs.define
class User:
    name: str
    age: int

user = cattrs.structure({"name": "Alice", "age": 30}, User)  # dict -> object
data = cattrs.unstructure(user)                                # object -> dict
```

## Core API

```python
# Module-level (global converter)
cattrs.structure(data, type)                    # dict -> typed object
cattrs.unstructure(obj)                         # typed object -> dict

# Custom converter (recommended for apps)
converter = cattrs.Converter()                  # base converter
converter = cattrs.GenConverter()               # code-generating, 2-5x faster

converter.structure(data, type)
converter.unstructure(obj)
converter.register_structure_hook(type, func)   # func(value, type) -> object
converter.register_unstructure_hook(type, func) # func(value) -> dict/primitive

# Code generation with overrides (GenConverter only)
from cattrs.gen import make_dict_structure_fn, make_dict_unstructure_fn, override
converter.register_unstructure_hook(User, make_dict_unstructure_fn(
    User, converter,
    name=override(rename="userName"),
    password=override(omit=True),
    count=override(omit_if_default=True),
))

# Preconf converters (format-specific, handle datetime/UUID/bytes)
from cattrs.preconf.json import make_converter     # stdlib json
from cattrs.preconf.orjson import make_converter    # orjson (fastest)

# Strategies
from cattrs.strategies import configure_tagged_union, include_subclasses
configure_tagged_union(Dog | Cat, converter, tag_name="type")
```

## Examples

### Custom hooks for datetime

```python
from datetime import datetime
converter = cattrs.Converter()
converter.register_structure_hook(datetime, lambda v, _: datetime.fromisoformat(v))
converter.register_unstructure_hook(datetime, lambda v: v.isoformat())
```

### Tagged unions (polymorphism)

```python
from cattrs.strategies import configure_tagged_union
configure_tagged_union(
    TextBlock | ImageBlock | CodeBlock, converter,
    tag_name="block_type",
    tag_generator=lambda t: t.__name__,
)
data = {"block_type": "TextBlock", "content": "Hello"}
block = converter.structure(data, TextBlock | ImageBlock | CodeBlock)
```

### GenConverter with rename/omit (snake_case <-> camelCase)

```python
converter.register_unstructure_hook(User, make_dict_unstructure_fn(
    User, converter,
    first_name=override(rename="firstName"),
    password_hash=override(omit=True),
))
```

## Pitfalls

- **Union disambiguation**: cattrs cannot auto-detect `Union[A, B]` for attrs classes with overlapping fields. Use `configure_tagged_union` or a custom hook.
- **Extra dict keys**: silently ignored by default (both Converter and GenConverter).
- **attrs validators run during structuring**: structuring fails if validators reject the data.
- **Converter isolation**: use separate converters for API vs DB layers to avoid hook conflicts.
- **Hook registration order**: predicate hooks checked in reverse order (last registered wins). Exact type hooks always take priority.
- **GenConverter**: slower on first call (generates code), faster on subsequent calls. Use for hot paths.
- **`ClassValidationError`**: catch `cattrs.errors.ClassValidationError` for per-field error details.
