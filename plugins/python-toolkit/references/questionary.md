# questionary v2.1.1

Interactive CLI prompts built on prompt_toolkit. Pretty select lists, confirmations, text input with validation.

```
pip install questionary>=2.1
```

## Quick Start

```python
import questionary

name = questionary.text("What is your name?").ask()
proceed = questionary.confirm("Continue?").ask()
color = questionary.select("Pick a color:", choices=["Red", "Green", "Blue"]).ask()
features = questionary.checkbox("Select features:", choices=["Auth", "Logs", "Cache"]).ask()
```

## Core API

All prompt functions return a `Question` object. Call `.ask()` for synchronous or
`await .ask_async()` for async. Returns `None` if the user cancels (Ctrl+C/Ctrl+D).

### text()

```python
questionary.text(
    message: str,                    # Prompt message
    default: str = "",               # Pre-filled value
    validate: Validator = None,      # Callable(str)->bool or Validator subclass
    qmark: str = "?",               # Question mark prefix
    style: Style = None,            # prompt_toolkit Style
    multiline: bool = False,        # Enable multi-line input
    instruction: str = None,        # Hint text after the question
    lexer: Lexer = None,            # Syntax highlighting
) -> Question
```

### password()

Same params as `text()` (without `multiline`, `lexer`). Input is masked.

### confirm()

```python
questionary.confirm(
    message: str,
    default: bool = True,           # Default yes (True) or no (False)
    auto_enter: bool = True,        # Accept on single keypress
    qmark: str = "?", style: Style = None, instruction: str = None,
) -> Question
```

### select()

```python
questionary.select(
    message: str,
    choices: Sequence[str | Choice],  # Items to choose from
    default: str = None,              # Pre-selected value
    qmark: str = "?",
    style: Style = None,
    use_shortcuts: bool = False,      # Number shortcuts (1-9)
    use_arrow_keys: bool = True,
    use_jk_keys: bool = True,        # Vim-style j/k navigation
    use_emacs_keys: bool = True,
    use_indicator: bool = True,
    use_search_filter: bool = True,   # Type to filter
    instruction: str = None,
    pointer: str = ">",              # Selection pointer character
    show_selected: bool = True,
) -> Question
```

### checkbox()

```python
questionary.checkbox(
    message: str,
    choices: Sequence[str | Choice],
    default: str = None,              # Initial pointer position
    validate: Validator = None,       # Validate final selection
    qmark: str = "?",
    style: Style = None,
    pointer: str = ">",
    use_arrow_keys: bool = True,
    use_jk_keys: bool = True,
    use_emacs_keys: bool = True,
    initial_choice: str | Choice = None,
    instruction: str = None,
) -> Question
```

### autocomplete()

```python
questionary.autocomplete(
    message: str, choices: Sequence[str], default: str = "",
    completer: Completer = None,      # Custom completer (overrides choices)
    meta_information: dict = None,    # {choice: description} tooltips
    ignore_case: bool = True, match_middle: bool = True,
    validate: Validator = None, style: Style = None,
) -> Question
```

### path()

```python
questionary.path(
    message: str, default: str = "", validate: Validator = None,
    only_directories: bool = False, file_filter: Callable = None,
    style: Style = None,
) -> Question
```

### Choice Object

```python
from questionary import Choice

Choice(
    title: str,                       # Display text
    value: Any = None,                # Returned value (defaults to title)
    disabled: str = None,             # Disable with reason text
    checked: bool = False,            # Pre-checked (checkbox only)
    shortcut_key: str = None,         # Keyboard shortcut
)

# Separator for visual grouping
from questionary import Separator
choices = ["Option A", Separator("--- Advanced ---"), "Option B"]
```

### Validation

```python
# Function-based (return True or error string)
def validate_email(text):
    if "@" not in text:
        return "Please enter a valid email"
    return True

questionary.text("Email:", validate=validate_email).ask()

# Class-based (prompt_toolkit Validator)
from prompt_toolkit.validation import Validator, ValidationError

class EmailValidator(Validator):
    def validate(self, document):
        if "@" not in document.text:
            raise ValidationError(message="Invalid email", cursor_position=0)

questionary.text("Email:", validate=EmailValidator).ask()
```

### Style Customization

Pass a `prompt_toolkit.styles.Style` to the `style` parameter. Supported keys:
`qmark`, `question`, `answer`, `pointer`, `highlighted`, `selected`, `separator`,
`instruction`, `text`. Example: `Style([("qmark", "fg:yellow bold"), ...])`.

## Examples

### 1. Multi-Step Form

```python
import questionary
from questionary import Choice

name = questionary.text("Your name:", validate=lambda t: len(t) > 0 or "Required").ask()
role = questionary.select("Role:", choices=["Admin", "Editor", "Viewer"]).ask()
features = questionary.checkbox("Enable:", choices=[
    Choice("Auth", checked=True), Choice("Logs", checked=True), Choice("Cache"),
]).ask()
questionary.confirm(f"Create user {name}?").ask()
```

### 2. Conditional Flow and Async

```python
import questionary

db = questionary.select("Database:", choices=["PostgreSQL", "SQLite"]).ask()
if db == "PostgreSQL":
    host = questionary.text("Host:", default="localhost").ask()
elif db == "SQLite":
    path = questionary.path("DB file:", default="./app.db").ask()

# Async: await questionary.text("Name:").ask_async()
```

## Pitfalls

- **`.ask()` returns `None` on cancel.** Use `if answer is not None:` not `if answer:`.
- **`checkbox` validate receives a list**, not a string.
- **`select`/`checkbox` require non-empty choices.** Empty list raises at prompt time.
- **Not testable interactively.** Use `.unsafe_ask()` or mock the prompt in tests.
- **`use_shortcuts` limits to 9 choices.** Requires real TTY; piped input hangs.
