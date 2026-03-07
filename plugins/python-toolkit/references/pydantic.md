# Pydantic v2.10+

Data validation library using Python type hints. Rust-powered core (pydantic-core)
provides 5-50x speedup over v1. Defines schemas as classes, validates on instantiation.

**Install:** `pip install pydantic`

---

## Quick Start

```python
from pydantic import BaseModel, Field

class User(BaseModel):
    name: str
    age: int = Field(ge=0, le=150)
    email: str | None = None

user = User(name="Alice", age=30)
print(user.model_dump())  # {"name": "Alice", "age": 30, "email": None}
```

---

## Core API

### BaseModel

```python
class MyModel(BaseModel):
    field: type = default

# Instance methods
model.model_dump()                  # -> dict (replaces v1 .dict())
model.model_dump(exclude_unset=True, exclude_none=True, by_alias=True)
model.model_dump_json()             # -> JSON string
model.model_copy(update={"field": new_value})   # Shallow copy with overrides
model.model_json_schema()           # -> JSON Schema dict

# Class methods
MyModel.model_validate(data: dict)           # dict -> model (replaces parse_obj)
MyModel.model_validate_json(json_str: str)   # JSON string -> model
MyModel.model_json_schema()                  # JSON Schema for the class
MyModel.model_rebuild()                      # Rebuild validators (forward refs)
```

### Field

```python
from pydantic import Field

Field(
    default=...,            # Default value (... = required)
    default_factory=None,   # Callable for mutable defaults
    alias=None,             # Alternate key for parsing
    validation_alias=None,  # Alias for validation only (not serialization)
    serialization_alias=None,  # Alias for serialization only
    title=None,             # JSON Schema title
    description=None,       # JSON Schema description
    gt=None, ge=None,       # Numeric: greater than / greater or equal
    lt=None, le=None,       # Numeric: less than / less or equal
    min_length=None,        # String/list minimum length
    max_length=None,        # String/list maximum length
    pattern=None,           # Regex pattern for strings
    frozen=False,           # Make field immutable after creation
    exclude=False,          # Exclude from model_dump/model_dump_json
    deprecated=None,        # Mark field as deprecated in schema
    examples=None,          # JSON Schema examples
)
```

### ConfigDict (model_config)

```python
from pydantic import ConfigDict

class MyModel(BaseModel):
    model_config = ConfigDict(
        strict=False,               # True = no type coercion
        frozen=False,               # True = immutable instances
        populate_by_name=True,      # Allow field name AND alias
        use_enum_values=True,       # Store enum .value, not enum member
        str_strip_whitespace=False, # Strip whitespace from strings
        str_max_length=None,        # Global string max length
        validate_default=False,     # Validate default values
        validate_assignment=False,  # Validate on attribute assignment
        extra="ignore",             # "ignore" | "allow" | "forbid"
        from_attributes=False,      # True = read from ORM objects (obj.field)
        json_schema_extra=None,     # Extra fields in JSON Schema
        arbitrary_types_allowed=False,  # Allow non-pydantic types
        title=None,                 # Schema title
    )
```

### Validators

```python
from pydantic import field_validator, model_validator

class Order(BaseModel):
    price: float
    quantity: int
    total: float | None = None

    @field_validator("price")
    @classmethod
    def price_must_be_positive(cls, v: float) -> float:
        if v <= 0:
            raise ValueError("price must be positive")
        return v

    @field_validator("price", mode="before")      # Runs before type coercion
    @classmethod
    def parse_price_string(cls, v):
        if isinstance(v, str):
            return float(v.replace("$", ""))
        return v

    @model_validator(mode="after")                 # Access all fields
    def compute_total(self) -> "Order":
        if self.total is None:
            self.total = self.price * self.quantity
        return self

    @model_validator(mode="before")                # Raw input dict
    @classmethod
    def check_raw(cls, data: dict) -> dict:
        # Modify or validate raw input before field parsing
        return data
```

### Serialization

```python
from pydantic import field_serializer, model_serializer

class Event(BaseModel):
    timestamp: datetime

    @field_serializer("timestamp")
    def serialize_ts(self, v: datetime, _info) -> str:
        return v.isoformat()

# Computed fields (not stored, computed on serialization)
from pydantic import computed_field

class Rectangle(BaseModel):
    width: float
    height: float

    @computed_field
    @property
    def area(self) -> float:
        return self.width * self.height
```

### Discriminated Unions

```python
from typing import Literal, Union, Annotated
from pydantic import BaseModel, Discriminator, Tag

class Cat(BaseModel):
    pet_type: Literal["cat"]
    meows: int

class Dog(BaseModel):
    pet_type: Literal["dog"]
    barks: float

class Model(BaseModel):
    pet: Cat | Dog = Field(discriminator="pet_type")

# Or with Annotated syntax
Pet = Annotated[Union[
    Annotated[Cat, Tag("cat")],
    Annotated[Dog, Tag("dog")],
], Discriminator("pet_type")]
```

### Custom Types

```python
from typing import Annotated
from pydantic import AfterValidator, BeforeValidator, PlainValidator

PositiveInt = Annotated[int, AfterValidator(lambda v: v if v > 0 else (_ for _ in ()).throw(ValueError("must be positive")))]

# Simpler: use conint, constr, etc.
from pydantic import conint, constr, confloat
PositiveInt = conint(gt=0)
ShortStr = constr(max_length=50)
```

---

## Examples

### Nested Models with Validation

```python
class Address(BaseModel):
    street: str
    city: str
    zip_code: str = Field(pattern=r"^\d{5}(-\d{4})?$")

class User(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)
    name: str = Field(min_length=1, max_length=100)
    addresses: list[Address] = Field(default_factory=list, max_length=5)

user = User.model_validate({
    "name": " Alice ",
    "addresses": [{"street": "123 Main", "city": "NYC", "zip_code": "10001"}],
})
assert user.name == "Alice"  # whitespace stripped
```

### ORM Integration

```python
class UserORM:
    def __init__(self, id, name, email):
        self.id = id; self.name = name; self.email = email

class UserSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    email: str

orm_user = UserORM(1, "Alice", "alice@example.com")
schema_user = UserSchema.model_from(orm_user)  # or model_validate(orm_user)
```

### JSON Schema Generation

```python
schema = User.model_json_schema()
# Returns valid JSON Schema dict, usable with OpenAPI, docs, etc.
import json
print(json.dumps(schema, indent=2))
```

---

## Pitfalls

1. **V1 methods removed.** `.dict()`, `.json()`, `.parse_obj()`, `.schema()` are gone.
   Use `.model_dump()`, `.model_dump_json()`, `.model_validate()`, `.model_json_schema()`.

2. **`@field_validator` requires `@classmethod`.** Omitting `@classmethod` causes a
   hard-to-debug `TypeError`.

3. **`mode="before"` vs `mode="after"`.** `before` receives raw input (any type);
   `after` receives the already-coerced Python type. Default is `"after"`.

4. **`from __future__ import annotations` breaks validators.** Pydantic v2 evaluates
   annotations at class creation time. PEP 563 deferred annotations interfere with this.

5. **`extra="forbid"` rejects unknown fields.** Default is `"ignore"`. Use `"forbid"`
   for strict APIs, `"allow"` to keep unknown fields as-is.

6. **Mutable defaults.** Use `Field(default_factory=list)` not `Field(default=[])`.
   Mutable defaults are shared across instances.

7. **Strict mode changes coercion.** `strict=True` rejects `"123"` for `int` fields.
   Default (`strict=False`) coerces `"123"` -> `123`.

8. **`model_copy()` is shallow.** Nested models are not deep-copied. Modify nested
   objects and you affect the original.
