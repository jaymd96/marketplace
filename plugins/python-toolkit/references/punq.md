# punq v0.7.0

## Quick Start

```python
import punq

container = punq.Container()
container.register(Database)
container.register(UserService)
svc = container.resolve(UserService)  # Database auto-injected via type hints
```

## Core API

```python
import punq

container = punq.Container()

# Registration modes
container.register(ConcreteClass)                              # auto-wiring by __init__ type hints
container.register(AbstractBase, ConcreteImpl)                  # interface -> implementation
container.register(ServiceType, factory=lambda: Service(url))  # factory function
container.register(ServiceType, instance=existing_obj)          # pre-built instance (always singleton)
container.register(ServiceType, scope=punq.Scope.singleton)    # singleton lifecycle
container.register(ServiceType, scope=punq.Scope.dependent)    # transient (default, new each time)
container.register(ServiceType, kwarg1="value1")                # explicit constructor args

# Resolution
instance = container.resolve(ServiceType)                       # create or retrieve

# Scopes
punq.Scope.dependent   # new instance per resolve (transient, default)
punq.Scope.singleton   # one instance, reused forever

# Exceptions
punq.MissingDependencyError     # dependency cannot be resolved
punq.InvalidRegistrationError   # registration is invalid
```

## Examples

### Interface-based registration

```python
import abc

class MessageSender(abc.ABC):
    @abc.abstractmethod
    def send(self, msg: str) -> None: ...

class EmailSender(MessageSender):
    def send(self, msg: str) -> None:
        print(f"Email: {msg}")

container = punq.Container()
container.register(MessageSender, EmailSender)
sender = container.resolve(MessageSender)  # returns EmailSender instance
```

### Singleton vs transient

```python
container.register(Config, scope=punq.Scope.singleton)    # same instance always
container.register(RequestHandler, scope=punq.Scope.dependent)  # new each time

s1 = container.resolve(Config)
s2 = container.resolve(Config)
assert s1 is s2  # True (singleton)
```

### Factory with dependency injection

```python
class Database:
    def __init__(self, url: str): self.url = url

class DatabaseConfig:
    def __init__(self): self.url = "postgresql://localhost/mydb"

def create_db(config: DatabaseConfig) -> Database:
    return Database(url=config.url)

container.register(DatabaseConfig)
container.register(Database, factory=create_db)  # punq injects DatabaseConfig
db = container.resolve(Database)
```

## Pitfalls

- **Auto-wiring requires type annotations**: punq inspects `__init__` type hints. Missing hints = MissingDependencyError.
- **Registration order does not matter**: punq resolves the dependency tree lazily.
- **`instance=` always singleton**: regardless of `scope` parameter.
- **No scoped lifetime**: punq only has singleton and transient. No per-request scope built in.
- **~300 lines of code**: deliberately minimal. No auto-discovery, no decorators, no config files.
