# SQLModel v0.0.22+

SQLAlchemy + Pydantic ORM for Python. Combines SQLAlchemy's database engine with
Pydantic's data validation into a single model class.

**Install:** `pip install sqlmodel`

---

## Quick Start

```python
from sqlmodel import Field, SQLModel, Session, create_engine, select

class Hero(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    name: str = Field(index=True)
    age: int | None = None

engine = create_engine("sqlite:///database.db")
SQLModel.metadata.create_all(engine)

with Session(engine) as session:
    session.add(Hero(name="Spider-Boy", age=18))
    session.commit()
```

---

## Core API

### Model Definition

```python
class SQLModel(table=True):
    """Set table=True for database tables, omit for pure data models."""

Field(
    default=None,           # Default value
    primary_key=False,      # Mark as PK
    index=False,            # Create DB index
    unique=False,           # Unique constraint
    nullable=True,          # Allow NULL
    foreign_key=None,       # FK reference ("table.column")
    sa_column=None,         # Raw SQLAlchemy Column override
    max_length=None,        # String max length (VARCHAR)
    regex=None,             # Pydantic validation pattern
    ge=None, le=None,       # Numeric bounds (Pydantic)
    gt=None, lt=None,       # Strict numeric bounds (Pydantic)
)
```

### Engine & Metadata

```python
from sqlmodel import create_engine, SQLModel

engine = create_engine(
    url: str,               # "sqlite:///db.sqlite3" | "postgresql://user:pass@host/db"
    echo: bool = False,     # Log SQL statements
    connect_args: dict = {} # e.g. {"check_same_thread": False} for SQLite
)

SQLModel.metadata.create_all(engine)   # Create all tables
SQLModel.metadata.drop_all(engine)     # Drop all tables
```

### Session (CRUD)

```python
from sqlmodel import Session

with Session(engine) as session:
    # CREATE
    session.add(instance)
    session.add_all([instance1, instance2])
    session.commit()
    session.refresh(instance)       # Reload from DB after commit

    # READ
    statement = select(Hero)
    results = session.exec(statement).all()
    hero = session.get(Hero, 1)     # Get by primary key (returns None if missing)

    # UPDATE
    hero.name = "New Name"
    session.add(hero)
    session.commit()

    # DELETE
    session.delete(hero)
    session.commit()
```

### select() Queries

```python
from sqlmodel import select, col, or_

# Basic
select(Hero)
select(Hero).where(Hero.name == "Spider-Boy")
select(Hero).where(Hero.age >= 18)

# Multiple conditions (AND)
select(Hero).where(Hero.age >= 18, Hero.name != "Deadpool")
select(Hero).where(Hero.age >= 18).where(Hero.name != "Deadpool")

# OR
select(Hero).where(or_(Hero.age < 18, Hero.age > 60))

# Ordering, offset, limit
select(Hero).order_by(Hero.name).offset(10).limit(5)
select(Hero).order_by(col(Hero.age).desc())

# Execution
session.exec(statement).all()       # List[Hero]
session.exec(statement).first()     # Hero | None
session.exec(statement).one()       # Hero (raises if != 1 result)
```

### Relationships

```python
from sqlmodel import Relationship

class Team(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    name: str
    heroes: list["Hero"] = Relationship(back_populates="team")

class Hero(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    name: str
    team_id: int | None = Field(default=None, foreign_key="team.id")
    team: Team | None = Relationship(back_populates="heroes")

# Usage: eager loading via selectinload
from sqlmodel import selectinload
statement = select(Team).options(selectinload(Team.heroes))
```

### Read/Write Model Separation (Common Pattern)

```python
class HeroBase(SQLModel):
    name: str
    age: int | None = None

class Hero(HeroBase, table=True):
    id: int | None = Field(default=None, primary_key=True)

class HeroCreate(HeroBase):
    pass

class HeroRead(HeroBase):
    id: int

class HeroUpdate(SQLModel):
    name: str | None = None
    age: int | None = None
```

---

## Examples

### FastAPI Integration

```python
from fastapi import FastAPI, Depends, HTTPException
from sqlmodel import Session, select

app = FastAPI()

def get_session():
    with Session(engine) as session:
        yield session

@app.post("/heroes/", response_model=HeroRead)
def create_hero(hero: HeroCreate, session: Session = Depends(get_session)):
    db_hero = Hero.model_validate(hero)
    session.add(db_hero)
    session.commit()
    session.refresh(db_hero)
    return db_hero

@app.get("/heroes/", response_model=list[HeroRead])
def read_heroes(offset: int = 0, limit: int = 100,
                session: Session = Depends(get_session)):
    return session.exec(select(Hero).offset(offset).limit(limit)).all()
```

### Alembic Migration Setup

```python
# alembic/env.py
from sqlmodel import SQLModel
from your_app.models import *  # Import all models so metadata is populated

target_metadata = SQLModel.metadata

# Generate migration:  alembic revision --autogenerate -m "add heroes"
# Apply:               alembic upgrade head
# Rollback:            alembic downgrade -1
```

### Partial Update

```python
def update_hero(hero_id: int, hero_update: HeroUpdate, session: Session):
    db_hero = session.get(Hero, hero_id)
    if not db_hero:
        raise HTTPException(status_code=404, detail="Hero not found")
    hero_data = hero_update.model_dump(exclude_unset=True)
    db_hero.sqlmodel_update(hero_data)
    session.add(db_hero)
    session.commit()
    session.refresh(db_hero)
    return db_hero
```

---

## Pitfalls

1. **table=True is required for DB tables.** Without it, the class is a pure Pydantic
   model with no corresponding table. Forgetting this causes silent failures.

2. **Refresh after commit.** After `session.commit()`, attributes are expired. Always
   call `session.refresh(obj)` if you need to access fields post-commit.

3. **Relationship fields are not in `.model_dump()`.** Relationship attributes are
   excluded from serialization by default. Use `response_model` with explicit fields
   or configure `model_config` to include them.

4. **SQLite check_same_thread.** When using SQLite with FastAPI, pass
   `connect_args={"check_same_thread": False}` to `create_engine`.

5. **Alembic doesn't auto-detect all changes.** Column type changes, index additions,
   and constraint modifications often need manual migration edits.

6. **`select()` returns model instances, not rows.** Unlike raw SQLAlchemy,
   `session.exec(select(Hero))` yields `Hero` objects directly.

7. **`id: int | None = Field(default=None, primary_key=True)` pattern.** The `None`
   default is required so you can create instances without specifying an ID (the DB
   auto-generates it), but the type annotation should include `None`.
