# burr v0.40+

Stateful application framework for building decision-making applications (agents, chatbots,
simulations) as state machines. Part of the Apache Burr (incubating) project.

```
pip install burr>=0.40
```

## Quick Start

```python
from burr.core import action, State, ApplicationBuilder

@action(reads=["count"], writes=["count"])
def increment(state: State) -> State:
    return state.update(count=state["count"] + 1)

app = (
    ApplicationBuilder()
    .with_actions(increment=increment)
    .with_transitions(("increment", "increment"))
    .with_state(count=0)
    .with_entrypoint("increment")
    .build()
)
action_name, result, state = app.step()
```

## Core API

### @action Decorator

```python
from burr.core import action, State

@action(reads=["key"], writes=["key"])     # Declare state keys read/written
def my_action(state: State) -> State:
    return state.update(key=state["key"] + 1)

# Return (result_dict, state) to expose result via step() return value
@action(reads=["query"], writes=["response"])
def generate(state: State) -> tuple[dict, State]:
    response = call_llm(state["query"])
    return {"text": response}, state.update(response=response)

# Extra params are runtime inputs (passed via step()/run())
@action(reads=["history"], writes=["history", "response"])
def chat(state: State, user_input: str) -> State:
    return state.update(response=call_llm(user_input)).append(
        history={"role": "user", "content": user_input})
```

### State (Immutable)

```python
from burr.core import State

state = State({"count": 0, "items": []})

# All mutations return new State instances
state.update(count=1)                            # Set/overwrite keys
state.update(count=state["count"] + 1)           # Increment pattern
state.append(items="new_item")                   # Append to list
state.delete("temp_key")                         # Remove key

# Access
state["count"]                                   # Get value (raises KeyError)
state.get("count", default=0)                    # Get with default

# Subset (useful for serialization)
state.subset("count", "items")                   # State with only these keys
```

### ApplicationBuilder

```python
from burr.core import ApplicationBuilder

app = (
    ApplicationBuilder()
    .with_actions(action_a=action_a, action_b=action_b)  # Register actions
    .with_transitions(                            # Define edges
        ("action_a", "action_b", default),
        ("action_b", "action_a", when(count=0)),
        ("action_b", "done", default),
    )
    .with_entrypoint("action_a")                  # Starting action
    .with_state(count=0, items=[])                # Initial state
    .with_tracker("local", project="my-project")  # Optional: UI tracker
    .build()
)
```

### Transitions and Conditions

```python
from burr.core import default, when, expr

("action_a", "action_b", default)          # Unconditional
("check", "proceed", when(approved=True))  # Condition on state value
("evaluate", "pass", expr("score > 0.8")) # Expression-based
# Default fallback must be last for a given source action
```

### Running the Application

```python
action_name, result, state = app.step()                        # Single step
action_name, result, state = app.step(user_input="hello")     # With inputs
action_name, result, state = app.run(halt_after=["done"])     # Run until halt
# halt_before=["x"] stops before x; halt_after=["x"] stops after x

for action_name, result, state in app.iterate(halt_after=["done"]):
    print(f"{action_name}: {result}")

# Async: await app.astep(), await app.arun(), async for ... in app.aiterate()
```

### Persistence and Hooks

```python
from burr.core.persistence import SQLLitePersister

# Built-in: SQLLitePersister, PostgreSQLPersister, RedisPersister
persister = SQLLitePersister(db_path="./state.db", table_name="app_state")
persister.initialize()

# Chain on ApplicationBuilder:
#   .with_persister(persister)
#   .with_identifiers(app_id="session-123", partition_key="user-1")
#   .initialize_from(persister, resume_at_next_action=True,
#                    default_entrypoint="start", default_state={...})

# Hooks: implement PreRunStepHook / PostRunStepHook, register via .with_hooks()
```

## Examples

### 1. Simple Counter with Halt

```python
from burr.core import action, State, ApplicationBuilder, default, when

@action(reads=["count"], writes=["count"])
def increment(state: State) -> State:
    return state.update(count=state["count"] + 1)

@action(reads=["count"], writes=[])
def done(state: State) -> State:
    return state

app = (
    ApplicationBuilder()
    .with_actions(increment=increment, done=done)
    .with_transitions(
        ("increment", "done", when(count=5)),
        ("increment", "increment", default),
    )
    .with_state(count=0)
    .with_entrypoint("increment")
    .build()
)

_, _, final_state = app.run(halt_after=["done"])
assert final_state["count"] == 5
```

### 2. Chatbot with State Append

```python
@action(reads=[], writes=["query", "history"])
def user_input(state: State, user_message: str) -> State:
    return state.update(query=user_message).append(
        history={"role": "user", "content": user_message})

@action(reads=["query", "history"], writes=["response", "history"])
def bot_respond(state: State) -> State:
    resp = call_llm(state["history"])
    return state.update(response=resp).append(history={"role": "assistant", "content": resp})

# Build with .with_actions(...).with_transitions(...).with_state(history=[])
```

## Pitfalls

- **State is immutable.** `state.update()` returns a new State; it does not modify
  in place. Forgetting to return the result silently drops the mutation.
- **reads/writes must be declared honestly.** Accessing a state key not listed in
  `reads` raises `KeyError`. Writing a key not listed in `writes` is silently ignored.
  These declarations enable caching and parallelism.
- **Transitions are evaluated in order.** The first matching condition wins. Always
  place `default` transitions last for a given source action.
- **`app.step()` returns 3 values.** `(action_name, result, state)`. The `result` is
  `None` unless the action returns a `(result, state)` tuple.
- **Runtime inputs must match action signatures.** Extra params like `user_input`
  must be passed to `step()`/`run()`. Missing inputs raise `TypeError`.
- **`halt_before` vs `halt_after`.** Before = state unchanged. After = state updated.
- **Async/sync cannot mix.** Use `astep()`/`arun()` for async actions.
