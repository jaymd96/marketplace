# blinker v1.9.0

## Quick Start

```python
from blinker import Signal

order_placed = Signal()

@order_placed.connect
def handle_order(sender, **kwargs):
    print(f"Order {kwargs['order_id']} from {sender}")

order_placed.send("checkout", order_id=123, total=49.99)
```

## Core API

```python
from blinker import Signal, signal, Namespace, ANY

# Creating signals
my_signal = Signal()                    # anonymous (class/module-scoped)
my_signal = signal("event-name")       # named (global registry, same name = same signal)

# Connecting receivers
sig.connect(receiver)                   # receiver(sender, **kwargs)
sig.connect(receiver, sender=obj)       # only when sender is obj
sig.connect(receiver, weak=False)       # strong ref (needed for lambdas)

@sig.connect                            # decorator syntax
def handler(sender, **kwargs): ...

@sig.connect_via(specific_sender)       # sender-filtered decorator
def handler(sender, **kwargs): ...

# Sending
results = sig.send(sender, key="value") # returns [(receiver, return_value), ...]
results = await sig.send_async(sender)  # async version

# Disconnecting
sig.disconnect(receiver)

# Introspection
if sig.receivers:                       # any receivers connected?
    sig.send(self, data=expensive())
sig.has_receivers_for(sender)           # check for specific sender

# Context managers
with sig.connected_to(handler):         # temporary connection (great for tests)
    sig.send("test")
with sig.muted():                       # suppress all receivers
    sig.send("ignored")

# Namespaces (isolated registries)
ns = Namespace()
event = ns.signal("my-event")
```

## Examples

### Class-level signals with sender filtering

```python
class TaskQueue:
    task_completed = Signal()
    task_failed = Signal()

    def submit(self, task_name):
        try:
            result = self._execute(task_name)
            self.task_completed.send(self, task_name=task_name, result=result)
        except Exception as e:
            self.task_failed.send(self, task_name=task_name, error=str(e))
            raise

@TaskQueue.task_completed.connect
def on_complete(sender, **kwargs):
    print(f"Done: {kwargs['task_name']}")
```

### Testing with connected_to

```python
def test_signal_emitted():
    captured = []
    with order_placed.connected_to(lambda s, **kw: captured.append(kw)):
        service.place_order(data)
    assert len(captured) == 1
    assert captured[0]["order_id"] == "ORD-123"
```

## Pitfalls

- **Weak reference GC**: lambdas and local functions are garbage collected immediately. Use `weak=False` or module-level functions.
- **Always accept `**kwargs`**: receivers without it break when signal payload changes.
- **Sender uses `is` not `==`**: identity comparison. Use object instances, not constructed strings.
- **Signals at class level, not `__init__`**: instance-level signals defeat shared signaling.
- **Exception in receiver**: propagates to sender and prevents subsequent receivers from running. Catch inside handlers.
- **`send()` with async receivers**: async handlers return coroutines, not results. Use `send_async()`.
- **Memory leaks with `weak=False`**: explicitly disconnect or use `connected_to()` for temporary connections.
