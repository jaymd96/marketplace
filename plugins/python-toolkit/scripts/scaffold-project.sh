#!/usr/bin/env bash
# Scaffold a new Python project following python-toolkit standards.
# Usage: scaffold-project.sh <project-path> <package-name>
#
# Creates: src layout, pyproject.toml (uv/hatch/ruff/mypy/pytest),
# domain/application/adapters/cli layers, tests/, and .github/workflows/ci.yml

set -euo pipefail

PROJECT_DIR="$1"
PACKAGE_NAME="$2"

if [ -d "$PROJECT_DIR" ]; then
  echo "Error: $PROJECT_DIR already exists" >&2
  exit 1
fi

echo "Scaffolding Python project: $PACKAGE_NAME"

# Create directory structure
mkdir -p "$PROJECT_DIR/src/$PACKAGE_NAME"/{domain,application,adapters,cli}
mkdir -p "$PROJECT_DIR/tests"/{unit,integration}
mkdir -p "$PROJECT_DIR/scripts"
mkdir -p "$PROJECT_DIR/.github/workflows"

# Package init files
for dir in "" domain application adapters cli; do
  if [ -z "$dir" ]; then
    target="$PROJECT_DIR/src/$PACKAGE_NAME/__init__.py"
  else
    target="$PROJECT_DIR/src/$PACKAGE_NAME/$dir/__init__.py"
  fi
  echo '"""'"$PACKAGE_NAME${dir:+.$dir}"'."""' > "$target"
done

# PEP 561 marker
touch "$PROJECT_DIR/src/$PACKAGE_NAME/py.typed"

# Domain models
cat > "$PROJECT_DIR/src/$PACKAGE_NAME/domain/models.py" << 'PYEOF'
"""Domain models. Pure data, no IO, no imports from adapters."""

import attrs


@attrs.frozen
class EntityId:
    value: str
PYEOF

# Domain errors
cat > "$PROJECT_DIR/src/$PACKAGE_NAME/domain/errors.py" << 'PYEOF'
"""Domain error hierarchy."""


class DomainError(Exception):
    """Base for all domain errors."""

    def __init__(self, message: str, **context: object) -> None:
        self.context = context
        super().__init__(message)


class NotFoundError(DomainError):
    """Entity not found."""


class ValidationError(DomainError):
    """Invalid input or state."""


class ConflictError(DomainError):
    """Operation conflicts with current state."""
PYEOF

# Domain ports (interfaces)
cat > "$PROJECT_DIR/src/$PACKAGE_NAME/domain/ports.py" << 'PYEOF'
"""Ports (interfaces) for adapters. Domain defines what it needs."""

from typing import Protocol
PYEOF

# Application layer
cat > "$PROJECT_DIR/src/$PACKAGE_NAME/application/services.py" << 'PYEOF'
"""Application services. Orchestration logic."""
PYEOF

# Adapters config
cat > "$PROJECT_DIR/src/$PACKAGE_NAME/adapters/config.py" << EOF
"""Configuration. The ONLY place os.environ is read."""

import os

import attrs


@attrs.frozen
class AppConfig:
    debug: bool = False


def load_config() -> AppConfig:
    return AppConfig(
        debug=os.environ.get("DEBUG", "false").lower() == "true",
    )
EOF

# CLI entrypoint
cat > "$PROJECT_DIR/src/$PACKAGE_NAME/cli/main.py" << EOF
"""CLI entrypoint. Thin shell — no business logic here."""

import click

from ${PACKAGE_NAME}.adapters.config import load_config


@click.group()
@click.pass_context
def cli(ctx: click.Context) -> None:
    """${PACKAGE_NAME} CLI."""
    config = load_config()
    ctx.ensure_object(dict)
    ctx.obj["config"] = config


@cli.command()
@click.pass_context
def hello(ctx: click.Context) -> None:
    """Hello world."""
    click.echo(f"Hello from ${PACKAGE_NAME}! Debug={ctx.obj['config'].debug}")
EOF

# pyproject.toml
cat > "$PROJECT_DIR/pyproject.toml" << EOF
[project]
name = "${PACKAGE_NAME}"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "attrs>=24.3.0",
    "click>=8.1.8",
    "structlog>=24.4.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.3.0",
    "pytest-xdist>=3.5.0",
    "mypy>=1.13.0",
    "ruff>=0.8.0",
]

[project.scripts]
${PACKAGE_NAME} = "${PACKAGE_NAME}.cli.main:cli"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/${PACKAGE_NAME}"]

[tool.ruff]
target-version = "py312"
line-length = 100
src = ["src"]

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP", "B", "SIM", "TCH", "RUF"]

[tool.ruff.lint.isort]
known-first-party = ["${PACKAGE_NAME}"]

[tool.mypy]
python_version = "3.12"
strict = true
packages = ["${PACKAGE_NAME}"]
mypy_path = "src"

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--strict-markers --strict-config -x -q"
asyncio_mode = "auto"
markers = [
    "unit: fast, no IO",
    "integration: real dependencies",
    "slow: takes >1 second",
]
EOF

# Test conftest
cat > "$PROJECT_DIR/tests/conftest.py" << EOF
"""Shared test fixtures and factories."""

import pytest

from ${PACKAGE_NAME}.adapters.config import AppConfig


@pytest.fixture
def config() -> AppConfig:
    return AppConfig(debug=True)
EOF

cat > "$PROJECT_DIR/tests/unit/conftest.py" << 'PYEOF'
"""Unit test configuration. No IO, no network."""
PYEOF

cat > "$PROJECT_DIR/tests/integration/conftest.py" << 'PYEOF'
"""Integration test configuration. Real dependencies."""
PYEOF

# Sample test
cat > "$PROJECT_DIR/tests/unit/test_models.py" << EOF
"""Unit tests for domain models."""

import pytest

from ${PACKAGE_NAME}.domain.models import EntityId


@pytest.mark.unit
class TestEntityId:
    def test_equality(self) -> None:
        assert EntityId("a") == EntityId("a")

    def test_inequality(self) -> None:
        assert EntityId("a") != EntityId("b")

    def test_is_frozen(self) -> None:
        entity_id = EntityId("a")
        with pytest.raises(attrs.exceptions.FrozenInstanceError):
            entity_id.value = "b"  # type: ignore[misc]
EOF

# .gitignore
cat > "$PROJECT_DIR/.gitignore" << 'EOF'
__pycache__/
*.pyc
.mypy_cache/
.ruff_cache/
.pytest_cache/
*.egg-info/
dist/
build/
.venv/
.DS_Store
EOF

# CI workflow
cat > "$PROJECT_DIR/.github/workflows/ci.yml" << 'EOF'
name: CI
on: [push, pull_request]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - run: uv sync --dev
      - run: uv run ruff check src/ tests/
      - run: uv run ruff format --check src/ tests/
      - run: uv run mypy
      - run: uv run pytest
EOF

# Initialize
cd "$PROJECT_DIR"
git init -q
uv init --no-readme 2>/dev/null || true
uv sync 2>/dev/null || echo "Note: run 'uv sync' to install dependencies"
git add -A
git commit -q -m "scaffold: initial project structure

Python 3.12+ / uv / ruff / mypy (strict) / pytest
Architecture: domain → application → adapters → cli
Standards: python-toolkit rules of the road"

echo ""
echo "Project '$PACKAGE_NAME' created at $PROJECT_DIR"
echo ""
echo "Next steps:"
echo "  cd $PROJECT_DIR"
echo "  uv sync              # install dependencies"
echo "  uv run pytest        # run tests"
echo "  uv run ruff check .  # lint"
echo "  uv run mypy          # type check"
echo "  uv run $PACKAGE_NAME hello  # run CLI"
