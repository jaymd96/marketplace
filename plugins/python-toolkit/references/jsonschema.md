# jsonschema v4.23+

JSON Schema validation for Python. Supports drafts 4, 6, 7, 2019-09, and 2020-12.

```
pip install jsonschema
pip install jsonschema[format]  # format validation (email, uri, date-time, etc.)
```

## Quick Start

```python
from jsonschema import validate, ValidationError

schema = {"type": "object", "properties": {"name": {"type": "string"}, "age": {"type": "integer", "minimum": 0}}, "required": ["name"]}

validate(instance={"name": "alice", "age": 30}, schema=schema)  # OK
validate(instance={"age": -1}, schema=schema)                    # raises ValidationError
```

## Core API

### validate()

```python
from jsonschema import validate

# Raises ValidationError on failure, returns None on success
validate(instance=data, schema=schema)

# Specify draft explicitly
from jsonschema import Draft202012Validator
validate(instance=data, schema=schema, cls=Draft202012Validator)
```

### Validator Classes

```python
from jsonschema import (
    Draft4Validator,
    Draft6Validator,
    Draft7Validator,
    Draft201909Validator,
    Draft202012Validator,  # latest, recommended
)

# Create a reusable validator (preferred for multiple validations)
validator = Draft202012Validator(schema)

# Check if schema itself is valid
Draft202012Validator.check_schema(schema)  # raises SchemaError if invalid

# Validate
validator.validate(instance)           # raises ValidationError
validator.is_valid(instance)           # -> bool

# Collect all errors (don't raise on first)
errors = list(validator.iter_errors(instance))
for error in sorted(errors, key=lambda e: list(e.path)):
    print(f"{'.'.join(str(p) for p in error.absolute_path)}: {error.message}")
```

### Error Reporting

```python
from jsonschema import ValidationError, Draft202012Validator

validator = Draft202012Validator(schema)

try:
    validator.validate(instance)
except ValidationError as e:
    e.message          # human-readable error
    e.path             # deque of path elements to failing field
    e.absolute_path    # full path from root
    e.schema_path      # path within the schema that caused failure
    e.validator        # name of failing keyword ("required", "type", etc.)
    e.validator_value  # value of the failing keyword in the schema
    e.instance         # the failing piece of the instance
    e.cause            # underlying exception (for format checks)
```

### Format Checking

```python
# Requires: pip install jsonschema[format]
from jsonschema import Draft202012Validator, FormatChecker

schema = {"type": "string", "format": "email"}

# Option 1: pass format_checker to validate
validator = Draft202012Validator(schema, format_checker=FormatChecker())
validator.validate("bad-email")  # raises ValidationError

# Option 2: global format checker
from jsonschema import validate
validate("bad-email", schema, format_checker=FormatChecker())

# Supported formats: date-time, date, time, duration, email, idn-email,
# hostname, idn-hostname, ipv4, ipv6, uri, uri-reference, iri,
# iri-reference, json-pointer, relative-json-pointer, regex, uuid
```

### Custom Validators

```python
from jsonschema import Draft202012Validator, validators

# Extend a validator with custom keywords
def is_even(validator_cls, value, instance, schema):
    if value and isinstance(instance, int) and instance % 2 != 0:
        yield ValidationError(f"{instance} is not even")

CustomValidator = validators.extend(
    Draft202012Validator,
    {"is_even": is_even},
)

schema = {"type": "integer", "is_even": True}
v = CustomValidator(schema)
v.validate(3)  # raises ValidationError: 3 is not even
```

### Setting Defaults

```python
from jsonschema import Draft202012Validator, validators

def extend_with_defaults(validator_cls):
    validate_props = validator_cls.VALIDATORS["properties"]

    def set_defaults(validator, properties, instance, schema):
        for prop, subschema in properties.items():
            if "default" in subschema:
                instance.setdefault(prop, subschema["default"])
        yield from validate_props(validator, properties, instance, schema)

    return validators.extend(validator_cls, {"properties": set_defaults})

DefaultValidator = extend_with_defaults(Draft202012Validator)
```

## Examples

### Validate API request body

```python
from jsonschema import Draft202012Validator, FormatChecker

user_schema = {
    "type": "object",
    "properties": {
        "email": {"type": "string", "format": "email"},
        "age": {"type": "integer", "minimum": 13, "maximum": 150},
        "roles": {"type": "array", "items": {"enum": ["admin", "user", "viewer"]}, "minItems": 1},
    },
    "required": ["email", "roles"],
    "additionalProperties": False,
}

validator = Draft202012Validator(user_schema, format_checker=FormatChecker())

def validate_request(body: dict) -> list[str]:
    errors = list(validator.iter_errors(body))
    return [e.message for e in errors]
```

### Schema with $ref

```python
from referencing import Registry, Resource
from jsonschema import Draft202012Validator

address_schema = Resource.from_contents({
    "$id": "https://example.com/address",
    "type": "object",
    "properties": {
        "street": {"type": "string"},
        "city": {"type": "string"},
    },
    "required": ["street", "city"],
})

registry = Registry().with_resource("https://example.com/address", address_schema)

schema = {
    "type": "object",
    "properties": {
        "name": {"type": "string"},
        "address": {"$ref": "https://example.com/address"},
    },
}

validator = Draft202012Validator(schema, registry=registry)
validator.validate({"name": "Alice", "address": {"street": "123 Main", "city": "NY"}})
```

### Collect all errors with paths

```python
schema = {
    "type": "object",
    "properties": {
        "users": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {"name": {"type": "string"}, "age": {"type": "integer"}},
                "required": ["name"],
            },
        }
    },
}

instance = {"users": [{"name": "ok"}, {"age": "bad"}, {}]}
v = Draft202012Validator(schema)
for err in sorted(v.iter_errors(instance), key=lambda e: list(e.absolute_path)):
    path = ".".join(str(p) for p in err.absolute_path)
    print(f"  {path}: {err.message}")
```

## Pitfalls

1. **Format is not validated by default**: `{"format": "email"}` is an annotation only unless you pass `format_checker=FormatChecker()`. Install `jsonschema[format]` for validators.
2. **validate() raises on first error**: Use `validator.iter_errors()` to collect all errors instead of stopping at the first one.
3. **Schema validation is not automatic**: `validate()` does not check if your schema itself is valid. Call `Draft202012Validator.check_schema(schema)` during development.
4. **$ref resolution changed in v4.18+**: The old `RefResolver` is deprecated. Use `referencing.Registry` for `$ref` resolution.
5. **additionalProperties default is permissive**: Without `"additionalProperties": false`, any extra keys are accepted silently.
6. **Draft matters**: Default validator may differ across versions. Always specify `cls=Draft202012Validator` explicitly for predictable behavior.
