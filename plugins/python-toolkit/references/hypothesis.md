# Hypothesis v6.115+

Property-based testing for Python. Instead of writing individual test cases, describe the shape of valid inputs and let Hypothesis find edge cases.

## Quick Start

```python
from hypothesis import given, strategies as st

@given(st.integers(), st.integers())
def test_addition_commutative(a, b):
    assert a + b == b + a
```

## Core API

### `@given(*args, **kwargs)`

Decorator that turns a test into a property-based test. Each argument maps a strategy to a test parameter.

```python
from hypothesis import given, settings, example, assume
from hypothesis import strategies as st

@given(x=st.integers(min_value=0, max_value=100))
def test_with_kwargs(x):
    assert 0 <= x <= 100

@given(st.text())
def test_with_positional(s):
    assert s == s[::-1][::-1]
```

### Common Strategies (`hypothesis.strategies` / `st`)

```python
# Primitives
st.integers(min_value=None, max_value=None)
st.floats(min_value=None, max_value=None, allow_nan=True, allow_infinity=True)
st.booleans()
st.none()
st.text(alphabet=None, min_size=0, max_size=None)
st.binary(min_size=0, max_size=None)

# Collections
st.lists(elements, min_size=0, max_size=None, unique=False)
st.sets(elements, min_size=0, max_size=None)
st.dictionaries(keys, values, min_size=0, max_size=None)
st.tuples(st.integers(), st.text())        # Fixed-length, heterogeneous
st.frozensets(elements)

# Temporal
st.datetimes(min_value=None, max_value=None, timezones=st.none())
st.dates()
st.times()
st.timedeltas()

# Composite / Building
st.builds(target_class, *arg_strategies, **kwarg_strategies)
st.one_of(st.integers(), st.text())         # Union of strategies
st.sampled_from(["a", "b", "c"])             # Pick from a sequence
st.just(42)                                   # Always returns 42
st.from_regex(r"[a-z]+@[a-z]+\.com")         # Matches regex
st.recursive(base, extend, max_leaves=50)     # Recursive structures

# Filtering and mapping
st.integers().filter(lambda x: x != 0)
st.text().map(str.upper)
st.integers().flatmap(lambda n: st.lists(st.integers(), min_size=n, max_size=n))
```

### `@example(*args, **kwargs)`

Force a specific input to always be tested:

```python
@given(st.text())
@example("")
@example("special\x00chars")
def test_always_includes(s):
    assert isinstance(s, str)
```

### `assume(condition)`

Skip the current example if condition is `False`. Use sparingly -- prefer `.filter()` on strategies.

```python
@given(st.integers(), st.integers())
def test_division(a, b):
    assume(b != 0)
    assert (a * b) / b == a
```

### `@settings(...)`

Configure test behavior:

```python
from hypothesis import settings, HealthCheck, Phase

@settings(
    max_examples=500,                          # Default: 100
    deadline=None,                             # Disable slow-test deadline (default: 200ms)
    suppress_health_check=[HealthCheck.too_slow],
    deriving_strategies_allowed=True,
    database=None,                             # Disable example database
)
@given(st.text())
def test_heavy(s): ...

# Set project-wide defaults
settings.register_profile("ci", max_examples=1000)
settings.register_profile("dev", max_examples=10)
settings.load_profile("dev")  # or set HYPOTHESIS_PROFILE=ci
```

## Examples

### Testing a Data Class with `st.builds`

```python
from dataclasses import dataclass
from hypothesis import given, strategies as st

@dataclass
class User:
    name: str
    age: int
    email: str

@given(st.builds(
    User,
    name=st.text(min_size=1, max_size=50),
    age=st.integers(min_value=0, max_value=150),
    email=st.from_regex(r"[a-z]+@[a-z]+\.com", fullmatch=True),
))
def test_user_serialization(user):
    data = {"name": user.name, "age": user.age, "email": user.email}
    restored = User(**data)
    assert restored == user
```

### Stateful Testing with RuleBasedStateMachine

```python
from hypothesis.stateful import RuleBasedStateMachine, rule, initialize, precondition, Bundle
from hypothesis import strategies as st

class SetMachine(RuleBasedStateMachine):
    items = Bundle("items")

    @initialize()
    def setup(self):
        self.model = set()

    @rule(target=items, value=st.integers())
    def add(self, value):
        self.model.add(value)
        return value

    @rule(value=items)
    @precondition(lambda self: len(self.model) > 0)
    def remove(self, value):
        self.model.discard(value)

    @rule()
    def check_length(self):
        assert len(self.model) >= 0

TestSetMachine = SetMachine.TestCase
```

### Composite Strategy

```python
from hypothesis import strategies as st

@st.composite
def sorted_lists(draw, min_size=0):
    xs = draw(st.lists(st.integers(), min_size=min_size))
    return sorted(xs)

@given(sorted_lists(min_size=2))
def test_sorted(xs):
    for a, b in zip(xs, xs[1:]):
        assert a <= b
```

## Pitfalls

- **Tests must be deterministic for a given input.** Hypothesis replays failing examples from its database. Non-determinism (random, time, network) breaks shrinking and replay.
- **`deadline` default is 200ms per example.** Set `deadline=None` for slow tests or you get `DeadlineExceeded` flakes.
- **`assume()` is expensive.** If more than ~10% of examples are rejected, Hypothesis raises `HealthCheck.too_slow`. Prefer constrained strategies or `.filter()`.
- **`@example()` runs in addition to random examples**, not instead of. It does not reduce `max_examples`.
- **`st.floats()` generates `nan`, `inf`, `-inf` by default.** Pass `allow_nan=False, allow_infinity=False` if your code does not handle them.
- **`st.text()` generates the full Unicode range** including null bytes, surrogates, and RTL characters. Pass `alphabet=st.characters(whitelist_categories=("L", "N"))` to restrict.
- **Stateful tests require the class to end with `TestCase = Machine.TestCase`** (or inherit from `unittest.TestCase`). Without this, pytest will not discover the test.
