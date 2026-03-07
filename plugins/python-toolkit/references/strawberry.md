# strawberry

**GraphQL library for Python** | v0.254+ (latest 0.288.x) | `pip install strawberry-graphql`

Type-annotation-driven GraphQL schema definition. Generates schema from Python dataclasses. Integrates with FastAPI, Django, Flask, and ASGI.

## Quick Start

```python
import strawberry

@strawberry.type
class Query:
    @strawberry.field
    def hello(self, name: str = "world") -> str:
        return f"Hello, {name}!"

schema = strawberry.Schema(query=Query)
result = schema.execute_sync("{ hello(name: \"Strawberry\") }")
print(result.data)  # {"hello": "Hello, Strawberry!"}
```

## Core API

### Types and Fields

```python
import strawberry
from typing import Optional

@strawberry.type
class User:
    name: str                          # Simple field (auto-resolved)
    email: str
    age: Optional[int] = None

    @strawberry.field
    def full_name(self) -> str:        # Computed field
        return f"{self.name} <{self.email}>"

@strawberry.input                      # Input type for mutations
class CreateUserInput:
    name: str
    email: str

@strawberry.enum                       # Enum type
class Role(enum.Enum):
    ADMIN = "admin"
    USER = "user"

@strawberry.interface                  # Interface
class Node:
    id: strawberry.ID
```

### Resolvers

```python
# Inline method resolver (preferred)
@strawberry.type
class Query:
    @strawberry.field
    def users(self, info: strawberry.types.Info, limit: int = 10) -> list[User]:
        return get_users(limit=limit)

# External function resolver
def get_books(root, info: strawberry.types.Info) -> list[Book]:
    return db.fetch_books()

@strawberry.type
class Query:
    books: list[Book] = strawberry.field(resolver=get_books)
```

`info.context` provides request context (custom dict/object from integration).

### Mutations and Subscriptions

```python
@strawberry.type
class Mutation:
    @strawberry.mutation
    def create_user(self, input: CreateUserInput) -> User:
        return User(name=input.name, email=input.email)

@strawberry.type
class Subscription:
    @strawberry.subscription
    async def notifications(self) -> AsyncGenerator[str, None]:
        while True:
            yield await get_next_notification()

schema = strawberry.Schema(query=Query, mutation=Mutation, subscription=Subscription)
```

### DataLoaders

Solve N+1 queries by batching lookups. Create per-request via `context_getter`.

```python
from strawberry.dataloader import DataLoader

async def load_users(keys: list[int]) -> list[User]:
    users = await db.get_users_by_ids(keys)
    user_map = {u.id: u for u in users}
    return [user_map[k] for k in keys]   # MUST match key order

@strawberry.type
class Post:
    author_id: int

    @strawberry.field
    async def author(self, info: strawberry.types.Info) -> User:
        return await info.context["user_loader"].load(self.author_id)
```

## Framework Integration

### FastAPI

```python
from fastapi import FastAPI
from strawberry.fastapi import GraphQLRouter

schema = strawberry.Schema(query=Query, mutation=Mutation)

async def get_context():
    return {"user_loader": DataLoader(load_fn=load_users)}

graphql_app = GraphQLRouter(schema, context_getter=get_context)
app = FastAPI()
app.include_router(graphql_app, prefix="/graphql")
```

### Django

```python
# urls.py
from strawberry.django.views import GraphQLView
from .schema import schema

urlpatterns = [
    path("graphql", GraphQLView.as_view(schema=schema)),
]
```

For async Django: use `strawberry.django.views.AsyncGraphQLView`.

## Examples

### 1. Full app with FastAPI

```python
@strawberry.type
class Book:
    id: strawberry.ID
    title: str

@strawberry.input
class BookInput:
    title: str

@strawberry.type
class Query:
    @strawberry.field
    def books(self) -> list[Book]:
        return [Book(id="1", title="Dune")]

@strawberry.type
class Mutation:
    @strawberry.mutation
    def add_book(self, input: BookInput) -> Book:
        return Book(id="2", title=input.title)

app = FastAPI()
app.include_router(GraphQLRouter(strawberry.Schema(query=Query, mutation=Mutation)), prefix="/graphql")
```

### 2. Subscription (WebSocket handled automatically by GraphQLRouter)

```python
@strawberry.type
class Subscription:
    @strawberry.subscription
    async def count(self, target: int = 10) -> AsyncGenerator[int, None]:
        for i in range(target):
            yield i
            await asyncio.sleep(1)
```

## Pitfalls

- **Async in FastAPI** -- Strawberry runs all resolvers on the event loop (unlike FastAPI endpoints). Use `async def` for all resolvers to avoid blocking the loop. Sync resolvers block.
- **DataLoader per-request** -- Create a new `DataLoader` per request (via `context_getter`), not as a global. Global loaders cache across requests.
- **DataLoader return order** -- The batch function MUST return results in the exact same order as the input keys. Missing keys need explicit `None` or an error.
- **Circular types** -- Use `strawberry.lazy()` for forward references: `author: Annotated["User", strawberry.lazy("..users")]`.
- **info.context type** -- By default `info.context` is a dict. Use `@strawberry.type` with a custom `Info` type for type safety.
- **Django sync vs async** -- Use `AsyncGraphQLView` for async resolvers in Django. The default `GraphQLView` is synchronous.
- **Schema is validated at import** -- Type errors (wrong annotations, missing resolvers) raise at schema creation, not at query time. This is a feature.
