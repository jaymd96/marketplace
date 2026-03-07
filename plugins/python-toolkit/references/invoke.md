# Invoke v2.2+

Python task execution framework. Define CLI-invokable tasks in Python. The local-execution foundation that Fabric builds on.

## Quick Start

```python
# tasks.py
from invoke import task

@task
def build(c):
    """Build the project."""
    c.run("python -m build")

@task
def test(c):
    """Run tests."""
    c.run("pytest tests/ -v")
```

```bash
inv build
inv test
inv --list    # Show all tasks
```

## Core API

### `@task` Decorator

```python
from invoke import task

# Basic task
@task
def clean(c):
    c.run("rm -rf dist/ build/")

# With help text for arguments
@task(help={"name": "Package name to install"})
def install(c, name):
    c.run(f"pip install {name}")

# Pre-tasks (run before this task)
@task(pre=[clean])
def build(c):
    c.run("python -m build")

# Post-tasks (run after this task)
@task(post=[clean])
def deploy(c):
    c.run("./deploy.sh")

# Pre and post combined
@task(pre=[clean], post=[notify])
def release(c):
    c.run("python -m build && twine upload dist/*")

# Shorthand: positional args become pre-tasks
@task(clean)
def build(c):
    c.run("python -m build")

# Optional arguments (flag-like, value is optional)
@task(optional=["verbose"])
def test(c, verbose=False):
    cmd = "pytest"
    if verbose:
        cmd += " -v"
    c.run(cmd)

# Iterable arguments (collect multiple values)
@task(iterable=["targets"])
def lint(c, targets):
    for t in targets:
        c.run(f"ruff check {t}")
# inv lint --targets src --targets tests

# Aliased task names
@task(aliases=["nb"])
def notebook(c):
    c.run("jupyter lab")
```

### `Context.run(command, **kwargs)`

Execute a local shell command. Returns a `Result` object.

```python
@task
def info(c):
    result = c.run("python --version", hide=True)
    print(result.stdout.strip())   # "Python 3.12.0"
    print(result.return_code)      # 0
    print(result.ok)               # True

    # Warn on failure instead of raising
    result = c.run("false", warn=True)
    if result.failed:
        print("Command failed")

    # Hide stdout/stderr from terminal
    c.run("make build", hide=True)        # Hide both
    c.run("make build", hide="stdout")    # Hide only stdout

    # Pipe input
    c.run("grep pattern", in_stream=open("data.txt"))

    # Dry run (just print the command)
    c.run("rm -rf /important", dry=True)

    # Environment variables
    c.run("echo $APP_ENV", env={"APP_ENV": "production"})

    # With pseudo-terminal
    c.run("vim config.yml", pty=True)

    # Change working directory for one command
    c.run("ls", wd="/tmp")
```

### Collections & Namespaces

Organize tasks into named groups.

```python
# tasks.py
from invoke import task, Collection

@task
def build(c):
    c.run("docker build -t myapp .")

@task
def push(c):
    c.run("docker push myapp")

@task
def run(c):
    c.run("docker run myapp")

# Create a namespace
docker_ns = Collection("docker")
docker_ns.add_task(build)
docker_ns.add_task(push)
docker_ns.add_task(run)

# Root namespace
ns = Collection()
ns.add_collection(docker_ns)

# CLI usage: inv docker.build, inv docker.push
```

**Module-based namespaces:**

```
tasks/
  __init__.py
  docker.py
  deploy.py
```

```python
# tasks/__init__.py
from invoke import Collection
from . import docker, deploy

ns = Collection()
ns.add_collection(Collection.from_module(docker))
ns.add_collection(Collection.from_module(deploy))
```

```bash
inv docker.build
inv deploy.staging
```

### Configuration

Invoke reads config from multiple sources (lowest to highest priority):
1. `/etc/invoke.yaml` (system)
2. `~/.invoke.yaml` (user)
3. `invoke.yaml` in the project directory
4. Environment variables (`INVOKE_*`)
5. CLI flags
6. Runtime `c.config` modifications

```python
# invoke.yaml
run:
  warn: true
  hide: true

tasks:
  search_root: src

# Access in tasks
@task
def show_config(c):
    print(c.config.run.warn)
```

## Examples

### Build Pipeline with Dependencies

```python
from invoke import task

@task
def clean(c):
    """Remove build artifacts."""
    c.run("rm -rf dist/ build/ *.egg-info")

@task
def lint(c):
    """Run linters."""
    c.run("ruff check src/")
    c.run("mypy src/")

@task
def test(c, coverage=False):
    """Run test suite."""
    cmd = "pytest tests/"
    if coverage:
        cmd += " --cov=src"
    c.run(cmd)

@task(pre=[clean, lint, test])
def build(c):
    """Build distribution packages."""
    c.run("python -m build")

@task(pre=[build])
def publish(c, repo="pypi"):
    """Publish to PyPI."""
    c.run(f"twine upload --repository {repo} dist/*")
```

```bash
inv build              # Runs clean -> lint -> test -> build
inv publish            # Runs clean -> lint -> test -> build -> publish
inv test --coverage    # Just tests with coverage
```

### Multi-Environment Deploy

```python
from invoke import task

@task
def deploy(c, env="staging", version="latest"):
    """Deploy application to target environment."""
    c.run(f"echo 'Deploying {version} to {env}'")
    c.run(f"ssh deploy@{env}.example.com 'deploy.sh {version}'")

@task
def staging(c, version="latest"):
    deploy(c, env="staging", version=version)

@task
def production(c, version="latest"):
    if input("Deploy to production? [y/N] ").lower() != "y":
        return
    deploy(c, env="production", version=version)
```

## Pitfalls

- **The first argument to every task is always `c` (Context).** Forgetting it causes confusing argument-count errors.
- **`c.run()` raises `UnexpectedExit` on non-zero exit codes by default.** Use `warn=True` to suppress, then check `result.ok`.
- **Task names use hyphens on the CLI but underscores in Python.** `def my_task(c)` becomes `inv my-task`.
- **Pre/post tasks run every time**, even if already run in the same invocation chain. There is no deduplication. If `build` depends on `clean` and `test` also depends on `clean`, `clean` runs twice with `inv build test`.
- **`@task` must be the outermost decorator.** Stacking other decorators outside `@task` breaks task discovery.
- **Boolean flags are auto-detected.** A parameter `def mytask(c, verbose=False)` becomes `--verbose` (flag, no value). If you want `--verbose=true`, use `optional=["verbose"]`.
- **`invoke.yaml` must be in the directory where you run `inv`**, not necessarily where `tasks.py` lives. Use `Config` explicitly for custom paths.
- **Invoke is local-only.** For remote execution over SSH, use Fabric (which extends Invoke with `Connection`).
