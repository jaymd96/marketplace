# rich v13.9.4

## Quick Start

```python
from rich.console import Console
console = Console()
console.print("[bold red]Error:[/] Something went wrong")
console.print({"key": "value"})  # auto pretty-prints dicts/lists
```

## Core API

```python
from rich.console import Console
from rich.table import Table
from rich.progress import track, Progress
from rich.panel import Panel
from rich.tree import Tree
from rich.syntax import Syntax
from rich.traceback import install as install_traceback

# Console
console = Console(stderr=False, record=False, width=None, force_terminal=None)
console.print("text", style="bold red")       # rich markup + styling
console.print("[bold]Bold [red]and red[/]")   # inline markup
console.log("msg", log_locals=True)           # with timestamp + file/line
console.rule("Section Title")                 # horizontal rule
with console.status("Working..."):            # spinner
    do_work()

# Table
table = Table(title="Users")
table.add_column("Name", style="cyan")
table.add_column("Email", style="green")
table.add_row("Alice", "alice@ex.com")
console.print(table)

# Progress
for item in track(items, description="Processing..."):
    process(item)

# Panel
console.print(Panel("Content here", title="Info"))

# Syntax highlighting
console.print(Syntax(code_string, "python", theme="monokai"))

# Pretty tracebacks (install once at startup)
install_traceback(show_locals=True)

# Markup colors: red, green, blue, yellow, cyan, magenta, white, bold, italic, underline
# Hex: [#ff8800], RGB: [rgb(100,200,50)], BG: [on red]
```

## Examples

### Custom theme

```python
from rich.theme import Theme
theme = Theme({"info": "dim cyan", "warning": "bold yellow", "error": "bold red"})
console = Console(theme=theme)
console.print("Server started", style="info")
console.print("[error]Connection failed[/error]")
```

### Progress bar with multiple tasks

```python
from rich.progress import Progress
with Progress() as progress:
    task1 = progress.add_task("Downloading...", total=100)
    task2 = progress.add_task("Processing...", total=200)
    while not progress.finished:
        progress.update(task1, advance=0.5)
        progress.update(task2, advance=1.0)
```

### Tree display

```python
from rich.tree import Tree
tree = Tree("Project")
src = tree.add("src/")
src.add("main.py")
src.add("utils.py")
tree.add("tests/").add("test_main.py")
console.print(tree)
```

## Pitfalls

- **CI environments**: use `Console(force_terminal=True)` in containers/CI where terminal detection fails.
- **Escape markup**: use `\\[text]` or `console.print(text, markup=False)` for literal brackets.
- **Thread safety**: create separate Console instances per thread, or use `console.print()` (which acquires a lock).
- **Recording for export**: `Console(record=True)` then `console.export_html()` or `console.export_svg()`.
- **Width override**: set `Console(width=120)` for consistent output in tests.
