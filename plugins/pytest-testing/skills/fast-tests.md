# fast tests

Make a pytest suite faster. Covers the highest-impact optimizations in priority
order, from one-line config changes to architectural refactoring.

## Trigger

The user says something like:
- "My tests are slow"
- "Speed up this test suite"
- "Reduce CI time"
- "Tests take too long to run locally"
- "How do I parallelize my tests?"

## Rule zero: measure first

Change one thing at a time. Measure before and after. Only keep changes that
make a real difference.

```bash
# Benchmark full suite with statistical rigour
hyperfine "pytest"

# Find the 10 slowest individual tests
pytest --durations=10

# Measure collection time separately
pytest --collect-only

# Identify slow imports
python -X importtime -m pytest --collect-only 2> import.log
```

Visualize import times at python-importtime-graph (search for "kmichel
python-importtime-graph" on GitHub).

## Quick-start priority order

If you can only do a few things, do them in this order (highest impact first):

### 1. Parallelize with pytest-xdist

The single biggest speedup. Trail of Bits: 67% reduction on PyPI's suite.

```bash
pip install "pytest-xdist>=3.0"
```

```toml
[tool.pytest.ini_options]
addopts = ["--numprocesses=auto"]
```

That's it. `auto` uses all CPU cores. Known challenges:
- `session`-scoped fixtures run on every worker, not just once
- Database tests need per-worker isolation (suffix DB name with worker ID)
- Use `pytest-randomly>=3.15` first to expose hidden inter-test dependencies

### 2. Use sysmon coverage (Python 3.12+)

Set `COVERAGE_CORE=sysmon` for PEP 669's lightweight monitoring.
Trail of Bits: 53% reduction in test execution time.

```bash
COVERAGE_CORE=sysmon pytest --cov=my_project
```

Caveat: Coverage 7.7.0+ disables this for branch coverage on Python < 3.14.
Verify it's active.

When using xdist, add `sitecustomize.py` to collect coverage from all workers:

```python
try:
    import coverage
    coverage.process_startup()
except ImportError:
    pass
```

### 3. Set testpaths

Tell pytest exactly where tests live. Trail of Bits: 66% reduction in collection
time (7.8s to 2.6s) from this single line:

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
norecursedirs = ["docs", "*.egg-info", ".git", ".tox", "node_modules"]
```

### 4. Audit imports

```bash
python -X importtime -m pytest --collect-only 2> import.log
```

Common offenders:
- Production dependencies not needed in tests (ddtrace, sentry-sdk)
- Package `__init__.py` that eagerly imports heavy submodules (torch, django)
- conftest.py files with heavy module-level imports

Fix: lazy-import heavy libraries inside fixture functions, not at module level.
Exclude unnecessary production dependencies from the test environment.

### 5. Database rollback strategy

The highest-impact database optimization. Create schema once, wrap each test in
a transaction that rolls back:

```python
@pytest.fixture(scope="session")
def db_engine():
    engine = create_engine("postgresql://localhost/test")
    Base.metadata.create_all(engine)
    yield engine
    engine.dispose()

@pytest.fixture
def db_session(db_engine):
    connection = db_engine.connect()
    transaction = connection.begin()
    session = Session(bind=connection)
    yield session
    session.close()
    transaction.rollback()
    connection.close()
```

No data needs re-populating between tests. For xdist, isolate per worker:

```python
@pytest.fixture(scope="session")
def database(worker_id):
    db_name = f"tests-{worker_id}"
    # create/manage this database per worker
```

### 6. Use --lf for local iteration

```bash
pytest --lf    # re-run only last-failed tests
pytest --ff    # failures first, then everything else
```

## Beyond the quick start

### Test selection — be picky

```bash
pytest --lf                    # only last-failed
pytest -m "not slow"           # skip slow-marked tests locally
pytest -k "test_login"         # keyword matching
```

Install `pytest-testmon>=2.1` for coverage-based test selection — only runs tests
affected by your code changes.

Install `pytest-timeout>=2.3` to prevent rogue tests from blocking:

```toml
[tool.pytest.ini_options]
timeout = 30
```

### Network, disk, fixtures, environment

- `pytest-socket>=0.7` — disables all network access by default (hidden latency killer)
- `pyfakefs` — in-memory filesystem for disk-dependent tests
- Replace `autospec=True` on large classes with hand-written fakes (autospec is slow)
- Use `session`/`module` scope for expensive read-only fixtures
- Disable unused plugins: `addopts = ["-p no:pastebin", "-p no:nose", "-p no:doctest"]`
- Set `PYTHONDONTWRITEBYTECODE=1` on dev/CI

### CI-specific optimizations

Split tests across CI workers with `pytest-split>=0.9`:

```yaml
strategy:
  matrix:
    group: [1, 2, 3, 4]
steps:
  - run: >
      pytest --splits 4 --group ${{ matrix.group }}
      --splitting-algorithm least_duration
```

Fail fast on PR, full suite on main:

```toml
# pyproject.toml default: fast
[tool.pytest.ini_options]
addopts = ["-x", "-m", "not slow"]
```

```yaml
# CI override for main: run everything
- run: pytest --slow --timeout=300
  if: github.ref == 'refs/heads/main'
```

### Use pytest-verdict for efficient failure analysis

When tests fail, don't waste time reading 10 similar tracebacks:

```bash
pytest --cluster --verdict-output /tmp/report.jsonl --cluster-output /tmp/clusters.txt
```

pytest-verdict groups failures by root cause, so you fix one thing instead of
reading the same traceback 10 times. Especially valuable in CI where you want
structured, parseable output.

## Common mistakes

1. **Optimizing without measuring.** "I think imports are slow" is not a measurement.
   Run `python -X importtime` and `pytest --durations=10` before changing anything.

2. **Parallelizing with hidden test dependencies.** Tests that share global state fail
   randomly under xdist. Run `pytest-randomly` first to surface these dependencies.

3. **Session fixtures that mutate state.** A session-scoped fixture that caches data
   and is modified by tests causes cross-test contamination. Session scope is for
   read-only resources only.

4. **Recreating the database per test.** Use rollback, not recreate. Wrap each test
   in a transaction. This is the single highest-impact database optimization.

5. **Running the full suite locally every time.** Use `pytest --lf` for local iteration.
   Use markers to skip slow tests. Run the full suite in CI.
