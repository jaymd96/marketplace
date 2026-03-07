# Alembic v1.14+

SQLAlchemy database migration tool. Generates and runs migration scripts that ALTER database schema.

## Quick Start

```bash
# Initialize alembic in your project
alembic init alembic

# Edit alembic.ini: set sqlalchemy.url
# Edit alembic/env.py: set target_metadata = Base.metadata

# Generate a migration from model changes
alembic revision --autogenerate -m "add users table"

# Apply all pending migrations
alembic upgrade head

# Rollback one migration
alembic downgrade -1
```

## Core API

### CLI Commands

```bash
alembic init <directory>                    # Create migration environment
alembic revision -m "msg"                   # Create empty migration
alembic revision --autogenerate -m "msg"    # Auto-detect model changes
alembic upgrade head                        # Apply all migrations
alembic upgrade +1                          # Apply next migration
alembic downgrade -1                        # Rollback one migration
alembic downgrade base                      # Rollback all migrations
alembic current                             # Show current revision
alembic history                             # Show migration history
alembic heads                               # Show latest revisions
alembic stamp head                          # Mark DB as up-to-date without running
```

### Programmatic Commands (`alembic.command`)

```python
from alembic.config import Config
from alembic import command

cfg = Config("alembic.ini")
command.revision(cfg, message="add table", autogenerate=True)
command.upgrade(cfg, "head")
command.downgrade(cfg, "-1")
command.current(cfg)
command.history(cfg)
command.stamp(cfg, "head")
```

### Migration Script Operations (`alembic.op`)

```python
from alembic import op
import sqlalchemy as sa

# Tables
op.create_table("users",
    sa.Column("id", sa.Integer, primary_key=True),
    sa.Column("name", sa.String(100), nullable=False),
    sa.Column("email", sa.String(200), unique=True),
)
op.drop_table("users")
op.rename_table("old_name", "new_name")

# Columns
op.add_column("users", sa.Column("age", sa.Integer))
op.drop_column("users", "age")
op.alter_column("users", "name", new_column_name="full_name")
op.alter_column("users", "name", type_=sa.Text, nullable=True)

# Indexes and constraints
op.create_index("ix_users_email", "users", ["email"], unique=True)
op.drop_index("ix_users_email", table_name="users")
op.create_foreign_key("fk_orders_user", "orders", "users", ["user_id"], ["id"])
op.drop_constraint("fk_orders_user", "orders", type_="foreignkey")
op.create_unique_constraint("uq_users_email", "users", ["email"])
op.create_check_constraint("ck_users_age", "users", "age > 0")
```

## Examples

### env.py Configuration (Online Mode)

```python
from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context
from myapp.models import Base  # Your declarative base

config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata

def run_migrations_online():
    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
        )
        with context.begin_transaction():
            context.run_migrations()

run_migrations_online()
```

### Migration Script with Data Migration

```python
"""add status column and backfill

Revision ID: abc123
Revises: def456
"""
from alembic import op
import sqlalchemy as sa

revision = "abc123"
down_revision = "def456"

def upgrade():
    op.add_column("orders", sa.Column("status", sa.String(20), server_default="pending"))
    # Data migration
    orders = sa.table("orders", sa.column("status", sa.String))
    op.execute(orders.update().values(status="pending"))
    op.alter_column("orders", "status", server_default=None, nullable=False)

def downgrade():
    op.drop_column("orders", "status")
```

### Programmatic URL Override (e.g., from env vars)

```python
# In env.py
import os
config = context.config
config.set_main_option("sqlalchemy.url", os.environ["DATABASE_URL"])
```

## Pitfalls

- **Autogenerate does not detect everything.** Renames are detected as drop + create. Table/column name changes, changes to constraints without explicit names, and data-type changes on some backends are missed. Always review generated scripts.
- **Always name your constraints explicitly** (`sa.UniqueConstraint(..., name="uq_...")`). Unnamed constraints cannot be reliably dropped across databases.
- **`op.execute()` runs raw SQL or SQLAlchemy core expressions.** Do not use ORM models in migrations -- the model may change after the migration is written, breaking it.
- **Multiple heads cause errors.** If two branches diverge, run `alembic merge heads -m "merge"` to create a merge migration.
- **`stamp` does not run migrations.** It only updates the `alembic_version` table. Use it to mark an already-migrated DB, not to skip migrations.
- **Offline mode** (`alembic upgrade head --sql`) generates SQL without connecting. Requires `run_migrations_offline()` in env.py and `context.configure(url=..., target_metadata=..., literal_binds=True)`.
