# typer v0.15.x

## Quick Start

```python
import typer

def main(name: str, count: int = 1, verbose: bool = False):
    """Greet someone."""
    for _ in range(count):
        typer.echo(f"Hello {name}!")

typer.run(main)
# Usage: python app.py Alice --count 3 --verbose
```

## Core API

```python
import typer
from typing import Annotated

# Single command
typer.run(main_function)

# Multi-command app
app = typer.Typer(help="My CLI tool", rich_markup_mode="rich")

@app.command()
def create(name: str): ...

@app.command()
def delete(name: str, force: bool = False): ...

@app.callback()  # app-level options
def main(verbose: bool = typer.Option(False, "--verbose", "-v")): ...

# Annotated syntax (recommended)
@app.command()
def deploy(
    env: Annotated[str, typer.Argument(help="Target environment")],
    dry_run: Annotated[bool, typer.Option("--dry-run", "-n")] = False,
    port: Annotated[int, typer.Option(min=1, max=65535)] = 8080,
): ...

# Type mapping: str, int, float, bool (--flag/--no-flag), Path, Enum (choices),
#   datetime, Optional, List (repeatable), Tuple, UUID

# Output
typer.echo("message")
typer.secho("Error!", fg=typer.colors.RED, bold=True)
typer.confirm("Continue?", abort=True)
typer.prompt("Name", type=str)

# Flow control
raise typer.Exit(code=1)     # clean exit
raise typer.Abort()           # abort with message

# Context
@app.command()
def cmd(ctx: typer.Context):
    ctx.obj["verbose"]        # shared state from callback
```

## Examples

### Multi-command with shared state

```python
app = typer.Typer()

@app.callback(invoke_without_command=True)
def main(ctx: typer.Context, verbose: bool = False):
    ctx.ensure_object(dict)
    ctx.obj["verbose"] = verbose
    if ctx.invoked_subcommand is None:
        typer.echo("Use --help for commands")

@app.command()
def deploy(ctx: typer.Context, env: str):
    if ctx.obj.get("verbose"):
        typer.echo(f"[DEBUG] Deploying to {env}")
    typer.echo(f"Deployed to {env}")
```

### Enum choices

```python
from enum import Enum

class Color(str, Enum):
    red = "red"
    green = "green"
    blue = "blue"

@app.command()
def paint(color: Color = Color.red):
    typer.echo(f"Painting {color.value}")
```

### Testing

```python
from typer.testing import CliRunner
runner = CliRunner()
result = runner.invoke(app, ["deploy", "production", "--verbose"])
assert result.exit_code == 0
assert "Deployed" in result.output
```

## Pitfalls

- **Bool creates flag pair**: `verbose: bool = False` generates `--verbose` / `--no-verbose`.
- **snake_case to kebab-case**: function `run_server` becomes command `run-server`.
- **`typer.Argument(...)` with `...`**: Ellipsis means required. No default = also required.
- **`invoke_without_command`**: must be True on Typer() to run callback without subcommand.
- **Typer is built on Click**: `typer.Context` wraps `click.Context`. All Click patterns apply.
- **`rich_markup_mode="rich"`**: enables Rich markup in help text (`[bold]`, `[red]`, etc.).
