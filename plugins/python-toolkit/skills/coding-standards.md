---
name: coding-standards
description: "Python coding standards and decision categories. Use when writing Python code, making design decisions, choosing patterns, or when the user asks about typing, data modeling, error handling, concurrency, logging, configuration, API design, or naming conventions."
---

# coding standards

17 opinionated decisions for writing Python that scales. Each decision has a
"default" and a "when to deviate." Follow the default unless you have a
specific reason not to.

## 1. Organisation: Vertical Slicing

Organise by domain, not by technical layer. `orders/` not `models/`.
Exception: shared infrastructure (`adapters/`, `domain/`).

## 2. Dependency Direction: Inward Only

Domain depends on nothing. Application depends on domain. Adapters depend on
domain + application. CLI depends on everything. Never the reverse.

## 3. Abstraction: Concrete First

Start with concrete implementations. Extract interfaces (Protocols) only when
you have 2+ implementations or need test doubles. Premature abstraction is
worse than duplication.

## 4. State: Immutable by Default

```python
@attrs.frozen           # immutable + hashable
class UserId:
    value: str

@attrs.frozen
class Order:
    id: OrderId
    items: tuple[Item, ...]    # tuple, not list
    status: OrderStatus        # Enum, not str
```

Use `attrs.evolve()` for immutable updates. Mutable state only in adapters.

## 5. Objects: Useful Dunders

Implement `__eq__`, `__hash__`, `__repr__`, `__str__` where meaningful.
`@attrs.frozen` gives you these for free. Don't implement `__getattr__`
or `__missing__` — that's dynamic magic.

## 6. Data Modeling: Boundary vs Internal

- **Boundary** (API input/output): Pydantic `BaseModel` — validation, serialization
- **Internal** (domain, application): `@attrs.frozen` — lightweight, hashable, no schema

Never use raw dicts for structured data. `TypedDict` only for compatibility
with external APIs that return dicts.

## 7. Error Strategy: Hierarchies with Context

```python
class AppError(Exception):
    """Base. Carry structured context."""
    def __init__(self, message: str, **context: object) -> None:
        self.context = context
        super().__init__(message)

class NotFoundError(AppError): ...
class AuthorizationError(AppError): ...
class ValidationError(AppError): ...
```

Catch specific exceptions. Never `except Exception: pass`. Log at the boundary.

## 8. Typing: Strict from Day One

```toml
[tool.mypy]
strict = true
```

- `def f(x: int) -> str:` — all public functions typed
- `Sequence[T]` for read-only, `list[T]` for mutable
- `Protocol` for structural subtyping (duck typing with types)
- `TypeAlias` for complex types: `UserId: TypeAlias = str`
- `NewType` for type-safe wrappers: `UserId = NewType("UserId", str)`

## 9. Concurrency: Threading, Not Asyncio

Default to `concurrent.futures.ThreadPoolExecutor` for IO-bound work.
Asyncio only if the project is explicitly async-first (web server, event loop).
Never mix sync and async in the same codebase without a clear boundary.

## 10. Testing: Public API is the Unit

Test through the public interface, not internal implementation. Use factories
for test data. One assertion per concept (not per test function).

```python
def test_order_cannot_be_cancelled_after_shipping():
    order = OrderFactory.create(status=OrderStatus.SHIPPED)
    with pytest.raises(ConflictError):
        order.cancel()
```

## 11. Logging: structlog with Injection

```python
import structlog

def process_order(order: Order, log: structlog.BoundLogger) -> None:
    log = log.bind(order_id=order.id)
    log.info("processing_order")
```

No `logging.getLogger(__name__)`. Inject the logger. Bind context progressively.

## 12. Configuration: Typed Object, Created Once

```python
@attrs.frozen
class AppConfig:
    db_url: str
    api_key: str
    max_retries: int = 3

def load_config() -> AppConfig:
    return AppConfig(
        db_url=os.environ["DB_URL"],      # Only place os.environ is read
        api_key=os.environ["API_KEY"],
        max_retries=int(os.environ.get("MAX_RETRIES", "3")),
    )
```

Config loaded once at entrypoint, passed to everything that needs it.

## 13. CLI: Click as Thin Shell

```python
@click.command()
@click.option("--dry-run", is_flag=True)
def deploy(dry_run: bool) -> None:
    config = load_config()
    service = DeployService(config)
    service.run(dry_run=dry_run)
```

No business logic in CLI layer. Click commands call application services.

## 14. Build & Tooling

- **Package manager:** uv (fast, lockfile, resolver)
- **Build:** hatch (pyproject.toml native)
- **Lint + format:** ruff (replaces black + isort + flake8)
- **Type check:** mypy strict
- **Test:** pytest with strict markers

## 15. API Design: Public via __init__.py

```python
# src/<package>/__init__.py
from <package>.domain.models import Order, OrderId
from <package>.domain.errors import NotFoundError
from <package>.application.use_cases import OrderService

__all__ = ["Order", "OrderId", "NotFoundError", "OrderService"]
```

Users import from the package, not from internal modules.

## 16. Documentation: Types + Docstrings

Types are the primary documentation. Docstrings for non-obvious behavior:

```python
def retry_with_backoff(
    fn: Callable[[], T],
    *,
    max_attempts: int = 3,
    base_delay: float = 1.0,
) -> T:
    """Retry fn with exponential backoff.

    Raises the last exception if all attempts fail.
    Delay doubles each attempt: 1s, 2s, 4s, ...
    """
```

Don't docstring obvious getters/setters. Don't repeat the type signature.

## 17. When to Deviate

- **Single-file scripts:** relax structure rules, keep typing
- **Library code consumed by others:** may need to support asyncio, may need
  wider Python version support
- **Performance-critical hot paths:** may need mutable state, may skip type checks
- **Prototyping:** relax everything except the entrypoint rule

Document deviations with a comment explaining why.
