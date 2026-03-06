# write tests

Write effective pytest tests: fixtures, parametrize, assertions, mocking, and async.
Organized by what you need to do, from basic patterns to advanced techniques.

## Trigger

The user says something like:
- "Write tests for this function/class/module"
- "How should I test this?"
- "Add unit tests for the billing service"
- "This test is too complex, help me refactor it"
- "I need to mock an external API in my test"

## The AAA pattern

Structure every test with three phases separated by blank lines:

```python
def test_transfer_funds(make_account):
    # Arrange
    source = make_account(balance=1000)
    target = make_account(balance=0)

    # Act
    transfer(source, target, amount=250)

    # Assert
    assert source.balance == 750
    assert target.balance == 250
```

Multiple `assert` statements are fine if they verify the same logical concept.
If a test checks "user is created" AND "email is sent", split into two tests.

## Fixtures

pytest injects fixtures by matching parameter names. Define in conftest.py.

**Scopes:** `function` (default, per test), `module` (per file), `session` (entire run).
Use `session` for expensive read-only resources. Use `function` for anything tests mutate.

**Factory fixtures** — when tests need multiple variations, return a callable:

```python
@pytest.fixture
def make_user():
    def _make(name="Alice", role="member", **kwargs):
        return User(name=name, role=role, **kwargs)
    return _make

def test_admin_can_delete(make_user):
    admin = make_user(name="Admin", role="admin")
    target = make_user()
    admin.delete_user(target)
    assert target.is_deleted
```

**Yield fixtures** — everything before `yield` is setup, after is teardown (runs even
on failure). **Composition** — fixtures can depend on other fixtures. Build complex
infrastructure from small, composable pieces (`db_engine` -> `db_session` -> `user_repo`).

## Parametrize

Always use `pytest.param` with `id=` so failures are readable:

```python
@pytest.mark.parametrize("input_val,expected", [
    pytest.param("hello", "HELLO", id="basic-lowercase"),
    pytest.param("Hello World", "HELLO WORLD", id="mixed-case-with-space"),
    pytest.param("", "", id="empty-string"),
])
def test_uppercase(input_val, expected):
    assert input_val.upper() == expected
```

Stack decorators for cartesian product. Use `indirect=True` to pass params through
a fixture.

## Assertions

pytest rewrites `assert` for detailed failure messages. No need for assertEqual.
Use `pytest.raises(ExcType, match=r"regex")` for exceptions — `match` distinguishes
different errors of the same type. Use `pytest.approx` for floats.

```python
def test_overdraft():
    account = Account(balance=100)
    with pytest.raises(InsufficientFunds, match=r"balance.*100") as exc_info:
        account.withdraw(200)
    assert exc_info.value.amount == 200
```

For custom assertion helpers, set `__tracebackhide__ = True` so pytest's traceback
points at the caller, not the helper function.

## Mocking

Use `monkeypatch` for env vars and simple attribute replacement. Use `unittest.mock.patch`
when you need to verify call counts or arguments. Use hand-written fakes for complex
collaborators — they're faster and more readable than `autospec=True` on large classes.

```python
def test_api_call(monkeypatch):
    monkeypatch.setattr("my_project.auth.services.requests.get", fake_get)
    monkeypatch.setenv("API_KEY", "test-key-123")
```

If a test mocks every collaborator, it tests wiring, not behaviour. Consider an
in-memory fake repository instead of mocking every `.save()` and `.find()` call.

## Async tests

```python
import pytest

@pytest.mark.asyncio
async def test_async_fetch(httpx_mock):
    httpx_mock.add_response(json={"status": "ok"})
    result = await fetch_status("https://api.example.com")
    assert result == "ok"
```

Configure in pyproject.toml:
```toml
[tool.pytest-asyncio]
mode = "auto"  # or "strict" to require explicit @pytest.mark.asyncio
```

## Markers for test tiers

```python
@pytest.mark.slow
def test_full_reindex(): ...

@pytest.mark.integration
def test_api_roundtrip(): ...
```

Run selectively:
```bash
pytest -m "not slow"                  # skip slow locally
pytest -m "integration and not e2e"   # just integration
```

## Common mistakes

1. **Testing implementation, not behaviour.** `mock.assert_called_with(x=1, y=2)` breaks
   when internals change. Assert on the observable output instead.

2. **Fixture spaghetti.** A fixture that depends on 5 other fixtures is hard to debug.
   If setup is complex, use a factory fixture that takes explicit parameters.

3. **No parametrize IDs.** `FAILED test_parse[input0-expected0]` tells you nothing.
   Always add `id=` to parametrize cases so failures are immediately understandable.

4. **Huge test functions.** A 50-line test that does 6 things is 6 tests wearing a
   trench coat. Each test should verify one concept.

5. **Ignoring pytest-verdict.** When failures cluster, use `pytest --cluster` to get
   root-cause grouping instead of reading 10 similar tracebacks one by one.
