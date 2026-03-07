# protobuf v5.29+

Python runtime for Protocol Buffers. Serialize structured data efficiently. Used with gRPC and standalone.

```
pip install protobuf
```

## Quick Start

Define a `.proto` file, compile it, use the generated classes.

```protobuf
// person.proto
syntax = "proto3";
package example;

message Person {
  string name = 1;
  int32 age = 2;
  repeated string emails = 3;
}
```

```bash
protoc --python_out=. person.proto
# generates person_pb2.py
```

```python
from person_pb2 import Person

p = Person(name="Alice", age=30, emails=["alice@example.com"])
data = p.SerializeToString()      # -> bytes
p2 = Person()
p2.ParseFromString(data)
print(p2.name)  # "Alice"
```

## Core API

### Message Construction

```python
from person_pb2 import Person, Address

# Keyword arguments
p = Person(name="Alice", age=30)

# Field assignment
p = Person()
p.name = "Alice"
p.age = 30

# Nested messages
p.address.CopyFrom(Address(city="NYC", zip="10001"))

# Repeated fields (list-like)
p.emails.append("alice@example.com")
p.emails.extend(["a@b.com", "c@d.com"])

# Map fields (dict-like)
# proto: map<string, int32> scores = 5;
p.scores["math"] = 95
p.scores["english"] = 88
```

### Scalar Field Types

| Proto Type | Python Type | Default | Notes |
|------------|------------|---------|-------|
| `double` / `float` | `float` | 0.0 | |
| `int32` / `int64` | `int` | 0 | |
| `uint32` / `uint64` | `int` | 0 | unsigned |
| `sint32` / `sint64` | `int` | 0 | more efficient for negative |
| `bool` | `bool` | False | |
| `string` | `str` | "" | UTF-8 |
| `bytes` | `bytes` | b"" | |
| `fixed32` / `fixed64` | `int` | 0 | fixed-width encoding |

### Serialization

```python
# Binary (compact, fast)
data = message.SerializeToString()          # -> bytes
message.ParseFromString(data)               # in-place parse

# Deterministic serialization (stable byte order for maps)
data = message.SerializeToString(deterministic=True)

# JSON (human-readable)
from google.protobuf.json_format import MessageToJson, Parse

json_str = MessageToJson(message)           # -> str
Parse(json_str, Person())                   # -> Person

# Dict
from google.protobuf.json_format import MessageToDict, ParseDict

d = MessageToDict(message)                  # -> dict
ParseDict(d, Person())                      # -> Person

# Text format (debug)
from google.protobuf.text_format import MessageToString
text = MessageToString(message)             # -> str
```

### Common Message Methods

```python
# Check if field is set (proto3: only for message fields and oneof)
message.HasField("address")     # -> bool (message/oneof fields only)

# Check if repeated field has elements
len(message.emails)             # -> int

# Clear a field (reset to default)
message.ClearField("name")

# Clear all fields
message.Clear()

# Copy from another message
msg2.CopyFrom(msg1)

# Merge (non-default fields overwrite)
msg2.MergeFrom(msg1)

# Size in bytes
message.ByteSize()             # -> int

# Equality
msg1 == msg2                   # structural equality

# Descriptor (reflection)
message.DESCRIPTOR.name        # -> "Person"
message.DESCRIPTOR.fields_by_name["name"]  # -> FieldDescriptor
```

### Oneof

```protobuf
message Event {
  string id = 1;
  oneof payload {
    LoginEvent login = 2;
    PurchaseEvent purchase = 3;
  }
}
```

```python
event = Event(id="1", login=LoginEvent(user="alice"))
event.WhichOneof("payload")    # -> "login"
event.HasField("login")        # -> True
event.HasField("purchase")     # -> False

# Setting one clears the other
event.purchase.CopyFrom(PurchaseEvent(item="book"))
event.WhichOneof("payload")    # -> "purchase"
event.HasField("login")        # -> False
```

### Repeated and Map Fields

```python
# Repeated (ordered list)
# proto: repeated string tags = 4;
msg.tags.append("urgent")
msg.tags.extend(["high", "low"])
msg.tags[0]                    # "urgent"
del msg.tags[1]
list(msg.tags)                 # -> ["urgent", "low"]

# Repeated messages
# proto: repeated Address addresses = 5;
addr = msg.addresses.add()     # returns new Address to fill
addr.city = "NYC"
# or
msg.addresses.append(Address(city="LA"))  # NOT supported pre-5.x
# use add() or CopyFrom pattern

# Map fields
# proto: map<string, int32> scores = 6;
msg.scores["math"] = 100
"math" in msg.scores           # -> True
del msg.scores["math"]
dict(msg.scores)               # -> plain dict copy
```

### Well-Known Types

```protobuf
import "google/protobuf/timestamp.proto";
import "google/protobuf/duration.proto";
import "google/protobuf/any.proto";
import "google/protobuf/struct.proto";
import "google/protobuf/wrappers.proto";
import "google/protobuf/empty.proto";
```

```python
# Timestamp
from google.protobuf.timestamp_pb2 import Timestamp
from datetime import datetime

ts = Timestamp()
ts.GetCurrentTime()                # now
ts.FromDatetime(datetime(2025, 1, 1))
dt = ts.ToDatetime()               # -> datetime

# Duration
from google.protobuf.duration_pb2 import Duration
dur = Duration(seconds=300)        # 5 minutes
dur.FromTimedelta(timedelta(hours=1))
td = dur.ToTimedelta()

# Any (wrap arbitrary messages)
from google.protobuf.any_pb2 import Any
any_msg = Any()
any_msg.Pack(person)               # wrap
person2 = Person()
any_msg.Unpack(person2)            # unwrap
any_msg.Is(Person.DESCRIPTOR)      # type check

# Struct (dynamic JSON-like)
from google.protobuf.struct_pb2 import Struct
s = Struct()
s.update({"key": "value", "nested": {"a": 1}})

# Wrappers (nullable scalars)
from google.protobuf.wrappers_pb2 import Int32Value, StringValue
w = Int32Value(value=42)
```

## Examples

### Encode/decode for storage

```python
def save_to_file(message, path):
    with open(path, "wb") as f:
        f.write(message.SerializeToString())

def load_from_file(message_class, path):
    msg = message_class()
    with open(path, "rb") as f:
        msg.ParseFromString(f.read())
    return msg

save_to_file(person, "person.bin")
loaded = load_from_file(Person, "person.bin")
```

### Proto to/from JSON API

```python
from google.protobuf.json_format import MessageToDict, ParseDict

# API response -> proto
data = {"name": "Alice", "age": 30, "emails": ["a@b.com"]}
person = ParseDict(data, Person())

# Proto -> API response
response_data = MessageToDict(person, preserving_proto_field_name=True)
# preserving_proto_field_name=True keeps snake_case instead of camelCase
```

## Pitfalls

1. **Proto3 defaults are invisible**: In proto3, scalar fields set to their default (0, "", false) are indistinguishable from unset. `HasField()` only works for message fields and oneof.
2. **Repeated message append**: `msg.items.append(Item(...))` did not work before protobuf v5. Use `msg.items.add()` and assign fields, or use `CopyFrom` for older versions.
3. **Map iteration order**: Map fields have no guaranteed iteration order. Use `deterministic=True` in `SerializeToString()` for reproducible output.
4. **No in-place parse**: `ParseFromString()` clears the message first. It is not a merge -- use `MergeFromString()` to merge into existing data.
5. **JSON field name casing**: `MessageToJson` converts `snake_case` to `camelCase` by default. Use `preserving_proto_field_name=True` for snake_case.
6. **Generated code is not importable without protoc**: The `_pb2.py` files must be generated and present. They cannot be written by hand.
7. **Enum values are ints**: Proto3 enums are plain integers in Python. Use `Name()` on the enum descriptor to get string names.
