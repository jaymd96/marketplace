# SQLAlchemy v2.0.40

## Quick Start

```python
from sqlalchemy import create_engine, String, select
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, Session

class Base(DeclarativeBase):
    pass

class User(Base):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    email: Mapped[str | None]

engine = create_engine("sqlite:///app.db")
Base.metadata.create_all(engine)
```

## Core API

```python
# Models (2.0 style -- NO Column(), NO declarative_base())
class User(Base):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    email: Mapped[str | None]                              # Optional = nullable
    created_at: Mapped[datetime] = mapped_column(server_default=func.now())
    posts: Mapped[list["Post"]] = relationship(back_populates="author")

class Post(Base):
    __tablename__ = "posts"
    id: Mapped[int] = mapped_column(primary_key=True)
    author_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    author: Mapped["User"] = relationship(back_populates="posts")

# Querying (2.0 style -- NO session.query())
with Session(engine) as session:
    stmt = select(User).where(User.name == "Alice")
    user = session.scalars(stmt).first()

    # Eager loading (always use to avoid N+1)
    stmt = select(User).options(selectinload(User.posts))
    users = session.scalars(stmt).all()

# CRUD
session.add(User(name="Alice"))                            # create
user = session.get(User, 1)                                # read by PK
user.name = "Updated"; session.commit()                    # update
session.delete(user); session.commit()                     # delete

# Result processing
session.execute(stmt).scalars().all()          # list[Model]
session.execute(stmt).scalars().first()        # Model | None
session.execute(stmt).scalar_one()             # Model (raises if != 1)
session.execute(stmt).scalar_one_or_none()     # Model | None
session.execute(select(func.count()).select_from(User)).scalar()  # int
```

## Examples

### Relationships

```python
# Many-to-many
article_tags = Table("article_tags", Base.metadata,
    Column("article_id", Integer, ForeignKey("articles.id"), primary_key=True),
    Column("tag_id", Integer, ForeignKey("tags.id"), primary_key=True),
)
class Article(Base):
    tags: Mapped[list["Tag"]] = relationship(secondary=article_tags, back_populates="articles")
```

### Mixin pattern

```python
class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(default=func.now(), server_default=func.now())
    updated_at: Mapped[datetime | None] = mapped_column(default=None, onupdate=func.now())

class Article(TimestampMixin, Base):
    __tablename__ = "articles"
    id: Mapped[int] = mapped_column(primary_key=True)
```

### Filtering and joins

```python
from sqlalchemy import or_, func, select
stmt = (select(User)
    .join(User.posts)
    .where(or_(User.name == "Alice", User.name == "Bob"))
    .order_by(User.created_at.desc())
    .limit(10).offset(0))
```

## Pitfalls

- **N+1 queries**: always use `selectinload()` or `joinedload()` for relationships in loops.
- **Detached instance errors**: eager-load before closing session, or keep session open.
- **Forgetting `.scalars()`**: `session.execute(select(User)).all()` returns Row tuples, not User objects.
- **`expire_on_commit`**: after commit, accessing attributes triggers a SELECT. Set `expire_on_commit=False` if returning data to API.
- **Bulk operations**: use `insert(User).values([...])` for thousands of rows, not `session.add()` in a loop.
- **`session.query()` is deprecated**: migrate to `session.execute(select(...))`.
- **JSON column mutation**: reassign the entire dict or use `flag_modified(obj, "field")`.
- **`back_populates` over `backref`**: explicit on both sides for clarity and type checking.
