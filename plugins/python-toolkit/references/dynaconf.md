# dynaconf v3.3.0

## Quick Start

```python
from dynaconf import Dynaconf

settings = Dynaconf(settings_files=["settings.toml", ".secrets.toml"])
settings.DATABASE_URL   # reads from file or env var
```

## Core API

```python
from dynaconf import Dynaconf, Validator

settings = Dynaconf(
    settings_files=["settings.toml", ".secrets.toml"],
    environments=True,              # enable [development]/[production] sections
    envvar_prefix="MYAPP",          # MYAPP_DATABASE_URL overrides DATABASE_URL
    env_switcher="MYAPP_ENV",       # switch env via MYAPP_ENV=production
    load_dotenv=True,               # load .env file
    merge_enabled=False,            # global deep-merge mode
    validators=[                    # startup validation
        Validator("DATABASE_URL", must_exist=True),
        Validator("DEBUG", is_type_of=bool, default=False),
        Validator("PORT", gte=1024, lte=65535, default=8000),
    ],
)

# Access
settings.DATABASE_URL              # attribute (case-insensitive)
settings["DATABASE_URL"]           # dict-style
settings.get("MISSING", "default") # with default
settings.exists("KEY")             # check existence
settings.as_int("PORT")            # type coercion
settings.as_dict()                 # export all as dict
settings.from_env("production")    # locked to specific env

# Validators
Validator("KEY", must_exist=True, is_type_of=str, eq=..., ne=...,
          gt=..., gte=..., lt=..., lte=..., is_in=[...], condition=lambda v: ...,
          when=Validator("OTHER", eq=True), env="production")
```

## Examples

### TOML with environments

```toml
# settings.toml
[default]
debug = false
database_url = "sqlite:///default.db"

[development]
debug = true
database_url = "sqlite:///dev.db"

[production]
debug = false
database_url = "postgresql://user:pass@db-host/prod"
```

### Environment variables with type casting

```bash
export MYAPP_PORT="@int 8000"
export MYAPP_DEBUG="@bool true"
export MYAPP_HOSTS='@json ["host1", "host2"]'
export MYAPP_DATABASE__HOST="localhost"   # nested: settings.DATABASE.HOST
```

### Precedence order (lowest to highest)

1. `[default]` section
2. Active environment section (e.g., `[production]`)
3. `[global]` section
4. Environment variables (with prefix)
5. `.secrets.*` files
6. Vault/Redis (if configured)

## Pitfalls

- **Case-insensitive**: `settings.database_url` and `settings.DATABASE_URL` are the same.
- **Default override behavior**: later sources replace earlier ones entirely. Use `merge_enabled=True` or `dynaconf_merge = true` per-key for deep merge.
- **List merge**: use `["@merge", "new_item"]` in TOML to append instead of replace.
- **`.secrets.*` in `.gitignore`**: always exclude secrets files from version control.
- **`envvar_prefix`**: defaults to `"DYNACONF"`. Change to your app name to avoid collisions.
- **Validators run at startup**: invalid config fails fast. Call `settings.validators.validate()` explicitly if needed.
