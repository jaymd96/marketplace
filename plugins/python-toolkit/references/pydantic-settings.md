# pydantic-settings v2.7+

Settings management for Pydantic v2. Loads configuration from environment variables,
dotenv files, secrets directories, and custom sources with full validation.

**Install:** `pip install pydantic-settings`

---

## Quick Start

```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_prefix="APP_")
    debug: bool = False
    database_url: str
    secret_key: str

settings = Settings()  # reads APP_DEBUG, APP_DATABASE_URL, APP_SECRET_KEY
```

---

## Core API

### BaseSettings

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """Inherits from Pydantic BaseModel. All BaseModel features work.
    Values resolved in priority order (highest first):
      1. __init__ keyword arguments
      2. Environment variables
      3. dotenv file (.env)
      4. Secrets directory files
      5. Field defaults
    """
    field_name: type = default
```

### SettingsConfigDict

```python
from pydantic_settings import SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        # --- Environment Variables ---
        env_prefix="",                  # Prefix for all env vars (e.g. "APP_")
        env_prefix_len=None,            # Strip prefix from env var names
        env_nested_delimiter=None,      # Delimiter for nested models (e.g. "__")

        # --- Dotenv Files ---
        env_file=None,                  # Path or tuple of paths (".env",)
        env_file_encoding="utf-8",      # Encoding for .env files

        # --- Secrets ---
        secrets_dir=None,               # Path or list of paths to secrets dirs

        # --- Behavior ---
        env_ignore_empty=False,         # Treat empty env vars as unset
        env_parse_none_str=None,        # String that maps to None (e.g. "null")
        env_parse_enums=None,           # Parse enum values from env vars
        case_sensitive=False,           # Case-sensitive env var matching
        extra="ignore",                 # "ignore" | "allow" | "forbid"
        validate_default=True,          # Validate default values

        # --- JSON ---
        json_file=None,                 # Path to JSON config file
        json_file_encoding="utf-8",     # Encoding for JSON files

        # --- TOML ---
        toml_file=None,                 # Path to TOML config file

        # --- YAML ---
        yaml_file=None,                 # Path to YAML config file
        yaml_file_encoding="utf-8",     # Encoding for YAML files
    )
```

### env_prefix

```python
class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="MYAPP_")
    db_host: str    # reads MYAPP_DB_HOST
    db_port: int    # reads MYAPP_DB_PORT

# Note: env_prefix does NOT apply to fields with explicit alias
```

### env_file (dotenv)

```python
class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",                    # Single file
        # env_file=(".env", ".env.prod"),   # Multiple files (later overrides earlier)
    )

# Override at instantiation:
settings = Settings(_env_file=".env.local")
```

### env_nested_delimiter

```python
class DatabaseSettings(BaseModel):
    host: str = "localhost"
    port: int = 5432

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_nested_delimiter="__")
    db: DatabaseSettings = DatabaseSettings()

# Set via: DB__HOST=myhost DB__PORT=5433
```

### secrets_dir

```python
class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        secrets_dir="/run/secrets",         # Docker secrets directory
        # secrets_dir=["/run/secrets", "/etc/app/secrets"],  # Multiple dirs
    )
    db_password: str    # reads from /run/secrets/db_password

# File content becomes the field value (stripped of trailing newline)
```

### Custom Sources

```python
from pydantic_settings import (
    BaseSettings,
    PydanticBaseSettingsSource,
    SettingsConfigDict,
)

class VaultSettingsSource(PydanticBaseSettingsSource):
    def get_field_value(self, field, field_name):
        # Return (value, field_key, is_complex)
        vault_value = fetch_from_vault(field_name)
        return vault_value, field_name, False

    def __call__(self):
        d = {}
        for field_name, field_info in self.settings_cls.model_fields.items():
            val, key, is_complex = self.get_field_value(field_info, field_name)
            if val is not None:
                d[key] = val
        return d

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env")
    secret_key: str

    @classmethod
    def settings_customise_sources(
        cls,
        settings_cls: type[BaseSettings],
        init_settings: PydanticBaseSettingsSource,
        env_settings: PydanticBaseSettingsSource,
        dotenv_settings: PydanticBaseSettingsSource,
        file_secret_settings: PydanticBaseSettingsSource,
    ):
        # Return sources in priority order (first = highest priority)
        return (
            init_settings,
            env_settings,
            VaultSettingsSource(settings_cls),
            dotenv_settings,
            file_secret_settings,
        )
```

---

## Examples

### Full Application Config

```python
from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_prefix="APP_",
        env_nested_delimiter="__",
        case_sensitive=False,
    )

    # App
    debug: bool = False
    host: str = "0.0.0.0"
    port: int = 8000

    # Database
    database_url: str = "sqlite:///app.db"

    # Secrets (SecretStr hides value in repr/logs)
    secret_key: SecretStr
    api_token: SecretStr | None = None

# .env file:
# APP_DEBUG=true
# APP_DATABASE_URL=postgresql://user:pass@db:5432/mydb
# APP_SECRET_KEY=super-secret
```

### Testing with Override

```python
def test_settings():
    settings = Settings(
        _env_file=None,          # Ignore .env in tests
        debug=True,
        database_url="sqlite:///:memory:",
        secret_key="test-key",
    )
    assert settings.debug is True
```

### TOML Config Source

```python
class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        toml_file="config.toml",
    )
    app_name: str
    port: int

# config.toml:
# app_name = "myapp"
# port = 8080
```

---

## Pitfalls

1. **env_prefix applies globally.** If `env_prefix="APP_"`, then field `db_host`
   reads `APP_DB_HOST`. Forgetting the prefix in `.env` files is a common mistake.

2. **Dotenv loads ALL values.** pydantic-settings loads all key-value pairs from the
   dotenv file regardless of `env_prefix`. With `extra="forbid"` (default is
   `"ignore"`), unrelated vars in `.env` cause `ValidationError`.

3. **env_prefix does NOT apply to aliased fields.** If a field has `alias="DB_URL"`,
   the env var is `DB_URL`, not `APP_DB_URL`.

4. **Case sensitivity default is False.** Env vars are matched case-insensitively by
   default. Set `case_sensitive=True` if you need exact matching.

5. **Secrets files contain raw values.** The entire file content (minus trailing
   newline) becomes the value. Multi-line secrets need careful handling.

6. **Source priority can surprise you.** Init args beat env vars beat dotenv beat
   secrets beat defaults. If a value appears in multiple sources, the highest-priority
   source wins silently.

7. **`_env_file` override at instantiation.** Pass `_env_file=None` to disable dotenv
   loading in tests. The underscore prefix is required to avoid collision with field
   names.
