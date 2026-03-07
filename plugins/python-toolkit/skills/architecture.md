---
name: architecture
description: "Python project architecture and structure. Use when starting a new project, designing module layout, enforcing boundaries, scaffolding a repo, or when the user asks 'how should I structure this', 'create a new project', 'scaffold a Python project', 'module layout', or 'project structure'."
---

# architecture

Design and enforce architecture for large Python codebases. This skill covers
project scaffolding, boundary enforcement, and the 12 rules in depth.

## Standard Project Layout (src layout)

```
<project>/
  pyproject.toml              # Single source of truth for project metadata
  uv.lock                    # Locked dependencies
  src/
    <package>/
      __init__.py             # Public API exports only
      _internal.py            # Private implementation (underscore prefix)
      py.typed                # PEP 561 marker
      domain/                 # Pure business logic, no imports from adapters/
        __init__.py
        models.py             # @frozen dataclasses, value objects
        errors.py             # Domain exception hierarchy
        services.py           # Domain services (pure functions/classes)
        ports.py              # Protocols (interfaces) for adapters
      application/            # Orchestration, use cases
        __init__.py
        use_cases.py          # Application logic calling domain + ports
      adapters/               # External integrations
        __init__.py
        db.py                 # Database adapter (implements domain.ports)
        http.py               # HTTP adapter
        config.py             # Configuration loading (typed)
      cli/                    # CLI layer (thin shell)
        __init__.py
        main.py               # Click/typer commands
  tests/
    conftest.py               # Shared fixtures, factories
    unit/                     # Fast, no IO, mirror src/ structure
    integration/              # Real dependencies, marked slow
  scripts/                    # Development scripts
```

## The Entrypoint Pattern (Rule 1)

Every program has exactly ONE supported entrypoint:

```python
# src/<package>/cli/main.py
import click
from <package>.adapters.config import load_config
from <package>.application.use_cases import MyService

@click.group()
@click.pass_context
def cli(ctx: click.Context) -> None:
    config = load_config()           # Config created once
    ctx.ensure_object(dict)
    ctx.obj["config"] = config
    ctx.obj["service"] = MyService(config)  # DI wired here

@cli.command()
@click.pass_context
def run(ctx: click.Context) -> None:
    ctx.obj["service"].execute()

# pyproject.toml
# [project.scripts]
# myapp = "<package>.cli.main:cli"
```

No `if __name__ == "__main__"` scattered across modules. No implicit
side effects on import. Config/logging/DI created at boot, not at import.

## Import Purity (Rule 2)

Module top-level can only contain:
- Constants, type aliases, type definitions
- Function/class definitions
- Import statements

Module top-level CANNOT contain:
- `os.environ[...]` reads
- Network calls (`requests.get(...)`)
- File reads (`open(...)`)
- Database connections
- Global mutable state (`clients = {}`)
- `logging.getLogger(__name__)` (use structlog injection instead)

## Boundary Enforcement (Rule 4)

```
Layer 0: domain/     (types, models, errors, ports — pure)
Layer 1: application/ (use cases — imports domain only)
Layer 2: adapters/   (implementations — imports domain + application)
Layer 3: cli/        (entrypoint — imports everything)
```

**Rule:** Higher layers import lower layers. Never the reverse.
Domain NEVER imports from adapters. Application NEVER imports from cli.

Check with: `scripts/check-boundaries.py` (see scripts/)

## Error Taxonomy (Rule 7)

```python
# domain/errors.py
class DomainError(Exception):
    """Base for all domain errors."""

class NotFoundError(DomainError):
    """Entity not found."""
    def __init__(self, entity_type: str, entity_id: str) -> None:
        self.entity_type = entity_type
        self.entity_id = entity_id
        super().__init__(f"{entity_type} '{entity_id}' not found")

class ValidationError(DomainError):
    """Invalid input or state."""

class ConflictError(DomainError):
    """Operation conflicts with current state."""
```

Application maps domain errors to outcomes. CLI/API converts to exit codes
or HTTP status codes. No bare `except Exception`.

## pyproject.toml Template

```toml
[project]
name = "<package>"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = []

[project.scripts]
<package> = "<package>.cli.main:cli"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/<package>"]

[tool.ruff]
target-version = "py312"
line-length = 100
src = ["src"]

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP", "B", "SIM", "TCH", "RUF"]

[tool.mypy]
python_version = "3.12"
strict = true
packages = ["<package>"]
mypy_path = "src"

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--strict-markers --strict-config -x"
asyncio_mode = "auto"
markers = [
    "unit: fast, no IO",
    "integration: real dependencies",
    "slow: takes >1s",
]
```

## Scaffolding

Run `scripts/scaffold-project.sh <path> <name>` to create a new project
with this layout, pre-configured pyproject.toml, and CI templates.
