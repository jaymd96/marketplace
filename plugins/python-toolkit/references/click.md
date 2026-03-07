# click v8.1.8

## Quick Start

```python
import click

@click.command()
@click.option("--name", "-n", required=True, help="Your name")
@click.option("--count", "-c", default=1, type=int)
@click.argument("target")
def greet(name, count, target):
    """Greet TARGET."""
    for _ in range(count):
        click.echo(f"Hello, {name}! Target: {target}")

if __name__ == "__main__":
    greet()
```

## Core API

```python
@click.command()                           # define a command
@click.group()                             # define a command group
@click.option("--name", "-n", ...)         # named option (--flag)
@click.argument("name")                    # positional argument
@click.pass_context                        # pass Context as first arg
@click.pass_obj                            # pass ctx.obj as first arg
@click.version_option(version="1.0.0")     # add --version

# Option patterns
@click.option("--verbose", is_flag=True)                     # boolean flag
@click.option("--verbose/--no-verbose", default=False)       # flag pair
@click.option("-v", "--verbose", count=True)                 # counting (-vvv)
@click.option("--tag", multiple=True)                        # repeatable
@click.option("--format", type=click.Choice(["json","csv"])) # enum
@click.option("--port", type=click.IntRange(1, 65535))       # range
@click.option("--config", type=click.Path(exists=True))      # path
@click.option("--input", type=click.File("r"))               # file handle
@click.option("--key", envvar="API_KEY")                     # env fallback

# Output
click.echo("message")                     # encoding-safe print
click.secho("Error!", fg="red", bold=True) # styled output
click.confirm("Continue?", abort=True)     # yes/no prompt
click.prompt("Name", type=str)             # input prompt
```

## Examples

### Multi-command group with shared config

```python
@click.group()
@click.option("--debug/--no-debug", default=False)
@click.pass_context
def cli(ctx, debug):
    ctx.ensure_object(dict)
    ctx.obj["DEBUG"] = debug

@cli.command()
@click.argument("name")
@click.pass_obj
def create(config, name):
    if config["DEBUG"]:
        click.echo(f"[DEBUG] Creating {name}")
    click.echo(f"Created {name}")
```

### Testing with CliRunner

```python
from click.testing import CliRunner

runner = CliRunner()
result = runner.invoke(cli, ["--debug", "create", "foo"])
assert result.exit_code == 0
assert "Created foo" in result.output

# Isolated filesystem for file operations
with runner.isolated_filesystem():
    result = runner.invoke(cli, ["init", "project"])
```

## Pitfalls

- **Decorator order**: `@click.command()` must be outermost (topmost). Options/arguments below.
- **Arguments not in --help**: describe arguments in the docstring, not via `help=`.
- **Default None infers STRING**: explicitly set `type=int` when default is None.
- **standalone_mode**: commands call `sys.exit()`. Use `CliRunner` for tests or `standalone_mode=False`.
- **Resilient parsing in callbacks**: check `ctx.resilient_parsing` in eager callbacks (--version).
- **Entry points**: `[project.scripts] my-tool = "pkg.cli:cli"` in pyproject.toml.
