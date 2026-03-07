# transitions v0.9.2

## Quick Start

```python
from transitions import Machine

class Order:
    pass

model = Order()
machine = Machine(
    model=model,
    states=["pending", "paid", "shipped", "delivered"],
    transitions=[
        {"trigger": "pay", "source": "pending", "dest": "paid"},
        {"trigger": "ship", "source": "paid", "dest": "shipped"},
        {"trigger": "deliver", "source": "shipped", "dest": "delivered"},
    ],
    initial="pending",
)
model.pay()       # pending -> paid
model.state       # "paid"
model.may_ship()  # True
```

## Core API

```python
Machine(
    model=obj,                    # object to manage (None = Machine itself)
    states=["a", "b", "c"],      # str, State objects, dicts, or Enums
    transitions=[...],           # list of transition dicts
    initial="a",                 # starting state
    auto_transitions=True,       # generate to_<state>() methods
    send_event=False,            # wrap callback args in EventData
    queued=False,                # queue events for sequential processing
    ignore_invalid_triggers=False,
    before_state_change=None,    # global before callback
    after_state_change=None,     # global after callback
    on_exception=None,           # exception handler callback
    finalize_event=None,         # always runs after transition
    model_attribute='state',     # attribute name on model
)

# Transition dict keys
{"trigger": "pay", "source": "pending", "dest": "paid",
 "conditions": "has_valid_card",   # must return True
 "unless": "is_frozen",           # must return False
 "before": "validate_payment",    # before state change
 "after": "send_receipt",         # after state change
}

# Special values
"source": "*"        # wildcard: any state
"dest": None         # internal: no state change (no on_enter/on_exit)
"dest": "="          # reflexive: re-enter same state (on_exit + on_enter fire)

# Auto-generated model methods
model.state              # current state
model.<trigger>()        # fire trigger
model.is_<state>()       # boolean check
model.may_<trigger>()    # check if trigger is allowed
model.to_<state>()       # auto-transition (if enabled)

# Extensions
from transitions.extensions import HierarchicalMachine, LockedMachine
from transitions.extensions.asyncio import AsyncMachine
```

## Examples

### With callbacks and conditions

```python
class Order:
    def __init__(self):
        self.machine = Machine(model=self, states=["draft", "submitted", "confirmed"],
            transitions=[
                {"trigger": "submit", "source": "draft", "dest": "submitted",
                 "conditions": ["has_items"], "after": "send_notification"},
                {"trigger": "confirm", "source": "submitted", "dest": "confirmed",
                 "before": "charge_payment", "conditions": ["payment_valid"]},
            ], initial="draft", send_event=True)

    def has_items(self, event): return True
    def payment_valid(self, event): return True
    def charge_payment(self, event): print("Charged")
    def send_notification(self, event): print("Notified")
```

### Hierarchical states

```python
from transitions.extensions import HierarchicalMachine
states = ["idle", {"name": "moving", "children": ["walking", "running"], "initial": "walking"}]
machine = HierarchicalMachine(model=obj, states=states, initial="idle")
obj.is_moving()           # True when in any child of "moving"
obj.is_moving_walking()   # True when specifically walking
```

## Pitfalls

- **Model vs Machine confusion**: always use a separate model in production. `model=None` mixes concerns.
- **Callback order**: `prepare -> conditions -> before -> on_exit -> STATE CHANGES -> on_enter -> after -> finalize`.
- **Auto-transition conflicts**: `to_<state>()` overwrites model methods with same name. Use `auto_transitions=False`.
- **Thread safety**: standard Machine is NOT thread-safe. Use `LockedMachine` for concurrent access.
- **Conditions block silently**: return False = no transition, no error. Check `may_<trigger>()` first.
- **`send_event=True` is global**: all callbacks receive EventData, you cannot mix styles.
- **Multiple same-trigger transitions**: evaluated in definition order, first match wins.
- **String vs Enum states**: `model.state == "running"` (string) vs `model.state == State.RUNNING` (enum). Use `is_<state>()` for safety.
