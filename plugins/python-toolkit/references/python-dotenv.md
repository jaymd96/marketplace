# python-dotenv v1.0+

Load environment variables from `.env` files. Follows the 12-factor app methodology.

## Quick Start

```python
# .env file:
# DATABASE_URL=postgresql://localhost/mydb
# SECRET_KEY=hunter2
# DEBUG=true

from dotenv import load_dotenv
import os

load_dotenv()  # Loads .env from current directory
print(os.environ["DATABASE_URL"])  # "postgresql://localhost/mydb"
```

## Core API

### `load_dotenv(dotenv_path=None, stream=None, verbose=False, interpolate=True, override=False, encoding="utf-8")`

Reads a `.env` file and sets environment variables via `os.environ`.

**Parameters:**
- `dotenv_path` -- Path to `.env` file. Defaults to `.env` in the current working directory.
- `stream` -- File-like object to read from instead of a file path.
- `verbose` -- If `True`, warn when `.env` file is missing.
- `interpolate` -- If `True` (default), expand `${VAR}` references in values.
- `override` -- If `False` (default), existing environment variables are NOT overwritten. If `True`, `.env` values take precedence.
- `encoding` -- File encoding. Default is `"utf-8"`.

**Returns:** `True` if a file was found and loaded, `False` otherwise.

```python
from dotenv import load_dotenv

# Basic
load_dotenv()

# Explicit path
load_dotenv("/path/to/.env")

# Override existing env vars
load_dotenv(override=True)

# Verbose warnings
load_dotenv(verbose=True)
```

### `find_dotenv(filename=".env", raise_error_if_not_found=False, usecwd=False)`

Walks up the directory tree from the calling file to find a `.env` file.

**Parameters:**
- `filename` -- Name of the file to find. Default: `".env"`.
- `raise_error_if_not_found` -- If `True`, raises `IOError` when file not found.
- `usecwd` -- If `True`, starts search from `os.getcwd()` instead of the calling file's directory.

```python
from dotenv import load_dotenv, find_dotenv

# Auto-find .env walking up from this file's directory
load_dotenv(find_dotenv())

# Find a specific file, raise if missing
load_dotenv(find_dotenv(".env.production", raise_error_if_not_found=True))
```

### `dotenv_values(dotenv_path=None, stream=None, verbose=False, interpolate=True, encoding="utf-8")`

Same as `load_dotenv` but returns a `dict` instead of modifying `os.environ`.

```python
from dotenv import dotenv_values

config = dotenv_values(".env")
print(config["DATABASE_URL"])  # "postgresql://localhost/mydb"
print(config.get("MISSING", "default"))

# Merge multiple env files
config = {
    **dotenv_values(".env.shared"),
    **dotenv_values(".env.local"),
    **os.environ,  # OS env takes highest priority
}
```

### `set_key(dotenv_path, key, value, quote_mode="always", export=False, encoding="utf-8")`

Write or update a key-value pair in a `.env` file.

```python
from dotenv import set_key
set_key(".env", "NEW_VAR", "new_value")
```

### `unset_key(dotenv_path, key, quote_mode="always", encoding="utf-8")`

Remove a key from a `.env` file.

```python
from dotenv import unset_key
unset_key(".env", "OLD_VAR")
```

## .env File Format

```bash
# Comments start with #
SIMPLE=value
QUOTED="value with spaces"
SINGLE_QUOTED='no interpolation here'
MULTILINE="line1\nline2"
INTERPOLATED=prefix_${SIMPLE}_suffix
EXPORT_STYLE=exported_value      # 'export' prefix is optional and ignored

# Empty values
EMPTY=
EMPTY_QUOTED=""

# These are equivalent
VAR1=hello
VAR2="hello"
```

## Examples

### Application Entry Point Pattern

```python
# settings.py
import os
from dotenv import load_dotenv, find_dotenv

load_dotenv(find_dotenv())

DATABASE_URL = os.environ["DATABASE_URL"]
SECRET_KEY = os.environ["SECRET_KEY"]
DEBUG = os.environ.get("DEBUG", "false").lower() == "true"
PORT = int(os.environ.get("PORT", "8000"))
```

### Testing with Isolated Config

```python
from dotenv import dotenv_values

def test_config_loading():
    config = dotenv_values("tests/.env.test")
    assert config["DATABASE_URL"] == "sqlite:///test.db"
    # os.environ is NOT modified
```

### CLI Usage

```bash
# Run a command with .env loaded
dotenv run -- python manage.py migrate

# List values
dotenv list

# Set/unset via CLI
dotenv set MY_VAR "my_value"
dotenv unset MY_VAR
```

## Pitfalls

- **`override=False` is the default.** If a variable already exists in the environment, `load_dotenv()` will NOT overwrite it. This is intentional (real env takes priority) but surprising if you expect `.env` to always win. Pass `override=True` to force.
- **Call `load_dotenv()` early.** It must run before any code reads `os.environ`. Put it at the top of your entry point, not inside lazy-loaded modules.
- **`find_dotenv()` walks up from the calling file's directory**, not from `os.getcwd()`. In tests run from the project root, the `.env` at the repo root may not be found if the test file is nested. Use `usecwd=True` or pass an explicit path.
- **Variable interpolation** (`${VAR}`) happens by default. If your values contain literal `${}`, set `interpolate=False` or use single quotes in the `.env` file.
- **No type conversion.** All values are strings. `DEBUG=true` is the string `"true"`, not a boolean. Parse explicitly.
- **`.env` files should NOT be committed to version control.** Commit a `.env.example` with placeholder values instead.
- **`dotenv_values()` does NOT modify `os.environ`.** It only returns a dict. Use `load_dotenv()` to actually set env vars.
