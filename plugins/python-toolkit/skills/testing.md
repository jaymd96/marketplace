---
name: testing
description: "Python testing with pytest. Use when writing tests, designing test strategy, speeding up test suites, or when the user asks about fixtures, factories, parametrize, markers, conftest, coverage, test speed, or 'how should I test this'."
---

# testing

Pytest patterns for large Python codebases. Fast feedback, layered strategy,
production-grade infrastructure.

## Test Pyramid

```
         /  E2E  \          ~5% — critical paths only
        / Integration \      ~15% — real DB, real HTTP
       /    Contract    \    ~10% — boundary schemas, API contracts
      /      Unit        \   ~70% — pure domain logic, fast
```

## Project Layout

```
tests/
  conftest.py              # Universal fixtures (factories, config, markers)
  unit/
    conftest.py            # Unit-specific (mock adapters)
    test_models.py         # Mirror src/ structure
    test_services.py
  integration/
    conftest.py            # Real DB, real services
    test_db.py
    test_api.py
```

## Configuration (pyproject.toml)

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--strict-markers --strict-config -x -q"
asyncio_mode = "auto"
markers = [
    "unit: fast, no IO, no network",
    "integration: real dependencies",
    "slow: takes >1 second",
    "database: requires database",
]
```

`--strict-markers` catches typos. `--strict-config` catches bad config.
`-x` stops on first failure (fast feedback). `-q` reduces noise.

## Fixtures: Composition Over Inheritance

```python
# conftest.py
@pytest.fixture
def config() -> AppConfig:
    return AppConfig(db_url="sqlite:///:memory:", api_key="test")

@pytest.fixture
def db(config: AppConfig) -> Generator[Database, None, None]:
    database = Database(config.db_url)
    database.create_tables()
    yield database
    database.drop_tables()

@pytest.fixture
def service(config: AppConfig, db: Database) -> OrderService:
    return OrderService(config=config, db=db)
```

Fixtures compose. Each fixture does one thing. Use `yield` for cleanup.

## Factories: Better Than Fixtures for Data

```python
# tests/factories.py
import attrs

@attrs.define
class OrderFactory:
    _counter: ClassVar[int] = 0

    @classmethod
    def create(cls, **overrides: Any) -> Order:
        cls._counter += 1
        defaults = {
            "id": OrderId(f"order-{cls._counter}"),
            "status": OrderStatus.PENDING,
            "items": (ItemFactory.create(),),
        }
        defaults.update(overrides)
        return Order(**defaults)
```

Factories give you control. Override only what matters for each test.

## Writing Tests

```python
# One concept per test, descriptive name
def test_order_total_sums_item_prices():
    order = OrderFactory.create(items=(
        ItemFactory.create(price=10),
        ItemFactory.create(price=20),
    ))
    assert order.total == 30

def test_cancelled_order_cannot_be_shipped():
    order = OrderFactory.create(status=OrderStatus.CANCELLED)
    with pytest.raises(ConflictError, match="cannot ship"):
        order.ship()

# Parametrize for variations
@pytest.mark.parametrize("status,can_cancel", [
    (OrderStatus.PENDING, True),
    (OrderStatus.SHIPPED, False),
    (OrderStatus.CANCELLED, False),
], ids=["pending-yes", "shipped-no", "cancelled-no"])
def test_cancel_eligibility(status: OrderStatus, can_cancel: bool):
    order = OrderFactory.create(status=status)
    assert order.can_cancel == can_cancel
```

## Speed Optimization (Priority Order)

1. **Set testpaths** in pyproject.toml (66% collection speedup)
2. **Use `-x`** to stop on first failure
3. **Use `--lf`** to run last-failed tests first
4. **Use `pytest-xdist`** for parallel: `pytest -n auto`
5. **Use `PYTHONDONTWRITEBYTECODE=1`** to skip .pyc writes
6. **Scope expensive fixtures** to `session` or `module`
7. **Use `--import-mode=importlib`** for faster collection
8. **Profile with `--durations=10`** to find slow tests
9. **Use `pytest-testmon`** for affected-test-only runs

## Mocking: Last Resort, Not First

Prefer real objects over mocks. Mock only at boundaries (HTTP, DB, clock).

```python
# GOOD: real domain objects, mock only the boundary
def test_order_service_creates_order(db: Database):
    service = OrderService(db=db)  # real service, real in-memory DB
    order = service.create_order(items=[...])
    assert order.status == OrderStatus.PENDING

# BAD: mocking everything
def test_order_service_creates_order():
    mock_db = MagicMock()
    mock_db.save.return_value = None
    service = OrderService(db=mock_db)
    service.create_order(items=[...])
    mock_db.save.assert_called_once()  # tests wiring, not behavior
```

## Async Testing

```python
# pytest-asyncio with auto mode (set in pyproject.toml)
async def test_async_fetch():
    async with httpx.AsyncClient() as client:
        response = await client.get("https://example.com")
        assert response.status_code == 200
```

## CLI Quick Reference

```bash
pytest                           # run all
pytest tests/unit/               # run directory
pytest -k "order and not cancel" # keyword filter
pytest -m "not slow"             # marker filter
pytest --lf                      # last failed only
pytest -x                        # stop on first failure
pytest -n auto                   # parallel (xdist)
pytest --durations=10            # show slowest
pytest --co                      # collect only (dry run)
```
