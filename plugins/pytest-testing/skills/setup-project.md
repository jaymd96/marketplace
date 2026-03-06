# setup project

Set up pytest in a Python project with speed-first, LLM-friendly defaults. Covers
installation, configuration, directory layout, and conftest architecture.

## Trigger

The user says something like:
- "Set up testing in this project"
- "Configure pytest for this repo"
- "Organize my test directory structure"
- "Add pytest to this project"
- A project has tests but no pyproject.toml configuration for pytest

## Step 1: Install dependencies

Start with the essentials. Add to your project's test dependencies:

```bash
pip install "pytest>=8.0" "pytest-xdist>=3.0" "jaymd96-pytest-verdict>=0.2"
```

Or in pyproject.toml:

```toml
[project.optional-dependencies]
test = [
    "pytest>=8.0",
    "pytest-xdist>=3.0",            # parallel execution
    "jaymd96-pytest-verdict>=0.2.0", # structured LLM output + failure clustering
]
```

pytest-verdict gives you `pytest --cluster` for structured, token-efficient test
output with automatic failure clustering. Install it from day one.

## Step 2: Configure pyproject.toml

This is the minimum viable configuration. Every option here earns its place:

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]             # 66% faster collection (don't scan the whole project)
addopts = [
    "-ra",                        # show summary of all non-passing tests
    "--strict-markers",           # typo in marker name = error, not silent new marker
    "--strict-config",            # catch config mistakes early
    "-x",                         # stop on first failure (fast local feedback)
]
markers = [
    "slow: marks tests as slow (deselect with '-m \"not slow\"')",
    "integration: requires external services",
]
filterwarnings = [
    "error",                      # treat warnings as errors — catch deprecations early
]
norecursedirs = [
    "docs", "*.egg-info", ".git", ".tox", "node_modules",
]
```

For CI, override `-x` to run the full suite:

```yaml
- run: pytest --no-header -rN --tb=short
```

## Step 3: Create the directory layout

Mirror your source tree inside `tests/`. When someone is working on
`src/my_project/billing/services.py`, the tests should be at
`tests/unit/billing/test_services.py`. Don't make people hunt.

```
my_project/
├── src/
│   └── my_project/
│       ├── __init__.py
│       ├── auth/
│       │   ├── models.py
│       │   └── services.py
│       └── billing/
│           ├── models.py
│           └── services.py
├── tests/
│   ├── conftest.py              # root: universal fixtures
│   ├── unit/
│   │   ├── conftest.py          # unit: lightweight fakes, mock factories
│   │   ├── auth/
│   │   │   ├── test_models.py
│   │   │   └── test_services.py
│   │   └── billing/
│   │       └── test_services.py
│   ├── integration/
│   │   ├── conftest.py          # integration: DB sessions, HTTP clients
│   │   └── test_auth_flow.py
│   └── helpers/
│       ├── __init__.py
│       ├── factories.py         # test data factories
│       └── fakes.py             # lightweight fake implementations
├── pyproject.toml
└── ...
```

Separate test tiers (unit/integration/e2e) into directories so you can run fast
tests constantly and defer slow tests to CI:

```bash
pytest tests/unit/            # fast, run constantly during development
pytest tests/integration/     # slower, run on every PR
pytest -m "not slow"          # skip slow-marked tests locally
```

## Step 4: Set up conftest.py layering

conftest.py files are loaded automatically by pytest. Layer them deliberately so
unit tests never pay the import cost of integration infrastructure.

```python
# tests/conftest.py — universal fixtures only
# Keep this lightweight. No heavy imports at module level.

import pytest

@pytest.fixture
def sample_config(tmp_path):
    """Minimal config file for tests that need one."""
    config = tmp_path / "config.yaml"
    config.write_text("debug: true\nlog_level: INFO\n")
    return config
```

```python
# tests/unit/conftest.py — unit test fixtures
# Lightweight fakes and factories. No database, no network.

import pytest

@pytest.fixture
def make_user():
    """Factory fixture: create users with sensible defaults."""
    def _make(name="Alice", role="member", **kwargs):
        return User(name=name, role=role, **kwargs)
    return _make
```

```python
# tests/integration/conftest.py — integration fixtures
# Database sessions, HTTP clients. Only loaded for integration tests.
# Import heavy libraries INSIDE fixtures, not at module level.

import pytest

@pytest.fixture(scope="session")
def db_engine():
    from sqlalchemy import create_engine
    engine = create_engine("postgresql://localhost/test")
    yield engine
    engine.dispose()

@pytest.fixture
def db_session(db_engine):
    from sqlalchemy.orm import Session
    connection = db_engine.connect()
    transaction = connection.begin()
    session = Session(bind=connection)
    yield session
    session.close()
    transaction.rollback()
    connection.close()
```

**Rules for conftest.py:**
- Fixtures only. Put helper functions in `tests/helpers/`.
- No test classes or functions. conftest is not a test file.
- Import heavy libraries inside fixtures, not at module level. Every conftest
  runs during collection — a conftest importing pandas just to define one fixture
  slows down every test run.

## Step 5: Add pytest-verdict to your workflow

Add to the project's CLAUDE.md so Claude Code always uses structured output:

```markdown
## Running tests

Always run tests with structured output:
  pytest --cluster --verdict-output /tmp/test-report.jsonl --cluster-output /tmp/clusters.txt
Read /tmp/clusters.txt for failure analysis. Fall back to /tmp/test-report.jsonl directly.
```

Add other plugins as needed: `pytest-cov>=5.0` (coverage), `pytest-randomly>=3.15`
(expose hidden dependencies), `pytest-timeout>=2.3` (prevent hangs),
`pytest-socket>=0.7` (block network), `pytest-asyncio>=0.24` (async support).

## Common mistakes

1. **No `testpaths` in config.** pytest scans everything — docs, node_modules, ML models.
   Collection takes 5x longer than necessary. Always set `testpaths = ["tests"]`.

2. **Heavy imports in conftest.py module level.** `import torch` at the top of conftest
   means every single test run pays that cost, even when running one unit test. Import
   inside the fixture function.

3. **Flat test directory.** 200 test files in a single `tests/` folder with no structure.
   Mirror the source tree. Separate unit from integration.

4. **Missing `--strict-markers`.** `@pytest.mark.sloow` silently creates a new marker
   instead of catching the typo. Always enable `--strict-markers`.

5. **Not installing pytest-verdict.** LLM agents waste tokens parsing pytest's decorative
   terminal output. Install pytest-verdict and use `--cluster` for structured, actionable
   failure reports from day one.
