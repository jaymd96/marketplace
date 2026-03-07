# FastAPI v0.115+

High-performance async web framework built on Starlette and Pydantic.
Automatic OpenAPI docs, dependency injection, type-driven validation.

**Install:** `pip install "fastapi[standard]"`

---

## Quick Start

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "hello"}

# Run: uvicorn main:app --reload
```

---

## Core API

### Application

```python
FastAPI(
    title: str = "FastAPI",
    version: str = "0.1.0",
    description: str = "",
    docs_url: str | None = "/docs",
    redoc_url: str | None = "/redoc",
    openapi_url: str | None = "/openapi.json",
    lifespan: Callable | None = None,
    dependencies: list[Depends] | None = None,
    middleware: list | None = None,
)
```

### Route Decorators

```python
@app.get(path, response_model=None, status_code=200, tags=[], summary="", deprecated=False)
@app.post(path, response_model=None, status_code=201)
@app.put(path, ...)
@app.delete(path, status_code=204)
@app.patch(path, ...)
```

### Path, Query, Body Parameters

```python
from fastapi import Path, Query, Body, Header, Cookie

@app.get("/items/{item_id}")
async def read_item(
    item_id: int = Path(..., ge=1, description="Item ID"),
    q: str | None = Query(None, max_length=50),
    x_token: str = Header(...),
):
    ...

@app.post("/items/")
async def create_item(
    item: Item,                                    # Pydantic model = JSON body
    importance: int = Body(..., gt=0),             # Extra body field
):
    ...
```

### Dependency Injection

```python
from fastapi import Depends

def get_db():
    db = SessionLocal()
    try:
        yield db             # yield-based = cleanup after response
    finally:
        db.close()

async def get_current_user(token: str = Header(...)):
    user = decode_token(token)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid token")
    return user

@app.get("/users/me")
async def read_me(user: User = Depends(get_current_user)):
    return user
```

### HTTPException

```python
from fastapi import HTTPException

raise HTTPException(
    status_code=404,
    detail="Item not found",                       # str or dict or list
    headers={"X-Error": "custom header"},          # Optional extra headers
)
```

### Response Models

```python
from pydantic import BaseModel

class ItemOut(BaseModel):
    id: int
    name: str

@app.get("/items/{id}", response_model=ItemOut)
async def get_item(id: int): ...

# Exclude unset fields
@app.get("/items/{id}", response_model=ItemOut, response_model_exclude_unset=True)
```

### APIRouter

```python
from fastapi import APIRouter

router = APIRouter(
    prefix="/items",
    tags=["items"],
    dependencies=[Depends(verify_token)],
)

@router.get("/")
async def list_items(): ...

@router.get("/{item_id}")
async def get_item(item_id: int): ...

# In main app
app.include_router(router)
app.include_router(router, prefix="/api/v2")       # Override prefix
```

### Middleware

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.middleware("http")
async def add_timing_header(request, call_next):
    import time
    start = time.perf_counter()
    response = await call_next(request)
    response.headers["X-Process-Time"] = str(time.perf_counter() - start)
    return response
```

### Lifespan

```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: runs before accepting requests
    pool = await create_pool()
    app.state.pool = pool
    yield
    # Shutdown: runs after all requests complete
    await pool.close()

app = FastAPI(lifespan=lifespan)
```

### Background Tasks

```python
from fastapi import BackgroundTasks

def send_email(email: str, message: str):
    ...  # slow I/O

@app.post("/send/")
async def send(background_tasks: BackgroundTasks):
    background_tasks.add_task(send_email, "user@example.com", "Hello")
    return {"status": "queued"}
```

---

## Examples

### CRUD Router with DI

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

router = APIRouter(prefix="/heroes", tags=["heroes"])

@router.post("/", response_model=HeroRead, status_code=201)
def create(hero: HeroCreate, db: Session = Depends(get_session)):
    obj = Hero.model_validate(hero)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj

@router.get("/{hero_id}", response_model=HeroRead)
def read(hero_id: int, db: Session = Depends(get_session)):
    hero = db.get(Hero, hero_id)
    if not hero:
        raise HTTPException(404, detail="Not found")
    return hero
```

### Custom Exception Handler

```python
from fastapi import Request
from fastapi.responses import JSONResponse

class DomainError(Exception):
    def __init__(self, message: str, code: str):
        self.message = message
        self.code = code

@app.exception_handler(DomainError)
async def domain_error_handler(request: Request, exc: DomainError):
    return JSONResponse(
        status_code=400,
        content={"error": exc.code, "message": exc.message},
    )
```

### TestClient

```python
from fastapi.testclient import TestClient

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "hello"}
```

---

## Pitfalls

1. **Order of routes matters.** `/items/me` must be declared before `/items/{item_id}`,
   otherwise `"me"` gets captured as a path parameter.

2. **`response_model` filters output.** If your endpoint returns an ORM object with
   extra fields, only `response_model` fields are serialized. Forgetting `response_model`
   may leak internal fields.

3. **Sync vs async.** Sync `def` handlers run in a threadpool; `async def` handlers
   run on the event loop. Do not call blocking I/O inside `async def` -- use `def` or
   `run_in_executor`.

4. **Depends() caching.** Within a single request, the same `Depends(fn)` is called
   once and reused. Use `Depends(fn, use_cache=False)` to disable.

5. **`HTTPException` is not a Pydantic `ValidationError`.** Validation errors from
   Pydantic (malformed request body) return 422, not the status you set on HTTPException.

6. **Middleware order.** Middleware executes in reverse declaration order (last added
   runs first on the way in).

7. **Lifespan replaces on_event.** The `@app.on_event("startup")` / `"shutdown"`
   decorators are deprecated in favor of the `lifespan` context manager.
