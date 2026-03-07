# casbin v1.36.3

## Quick Start

```python
import casbin

e = casbin.Enforcer("model.conf", "policy.csv")
allowed = e.enforce("alice", "data1", "read")  # True or False
```

## Core API

```python
# Create enforcer
e = casbin.Enforcer("model.conf", "policy.csv")
e = casbin.Enforcer("model.conf", adapter)      # with database adapter

# Authorization check
e.enforce("subject", "object", "action")         # -> bool
e.enforce("alice", "tenant1", "data1", "read")   # with domain (multi-tenant)

# Policy management
e.add_policy("bob", "data1", "read")
e.remove_policy("bob", "data1", "read")
e.has_policy("bob", "data1", "read")
e.get_policy()                                   # all rules
e.get_filtered_policy(0, "alice")                # filter by field index

# RBAC role management
e.add_role_for_user("alice", "admin")
e.delete_role_for_user("alice", "admin")
e.get_roles_for_user("alice")                    # ["admin"]
e.get_users_for_role("admin")                    # ["alice"]
e.has_role_for_user("alice", "admin")            # True
e.get_implicit_permissions_for_user("alice")     # all permissions via roles

# Role grouping
e.add_grouping_policy("alice", "admin")          # assign role
e.add_grouping_policy("alice", "admin", "tenant1")  # with domain
```

### Model patterns

```ini
# ACL (simplest)
[request_definition]
r = sub, obj, act
[policy_definition]
p = sub, obj, act
[policy_effect]
e = some(where (p.eft == allow))
[matchers]
m = r.sub == p.sub && r.obj == p.obj && r.act == p.act

# RBAC (add role_definition + g() in matcher)
[role_definition]
g = _, _
[matchers]
m = g(r.sub, p.sub) && r.obj == p.obj && r.act == p.act

# RBAC with domains (multi-tenant)
[request_definition]
r = sub, dom, obj, act
[role_definition]
g = _, _, _
[matchers]
m = g(r.sub, p.sub, r.dom) && r.dom == p.dom && r.obj == p.obj && r.act == p.act
```

## Examples

### RBAC with roles

```csv
# policy.csv
p, admin, data1, read
p, admin, data1, write
p, viewer, data1, read
g, alice, admin
g, bob, viewer
```

```python
e.enforce("alice", "data1", "write")  # True (admin)
e.enforce("bob", "data1", "write")    # False (viewer)
```

### SQLAlchemy adapter

```python
from casbin_sqlalchemy_adapter import Adapter
adapter = Adapter("postgresql://user:pass@localhost/db")
e = casbin.Enforcer("model.conf", adapter)
e.add_policy("alice", "data1", "read")  # persisted to DB
```

### FastAPI middleware

```python
from fastapi_authz import CasbinMiddleware
enforcer = casbin.Enforcer("model.conf", "policy.csv")
app.add_middleware(CasbinMiddleware, enforcer=enforcer)
```

## Pitfalls

- **Argument order matters**: `enforce(sub, obj, act)` must match `r = sub, obj, act` in the model exactly.
- **In-memory policies are lost on restart**: use a database adapter for persistence.
- **g() in matchers**: required for RBAC. Without it, role assignments are ignored.
- **Policy effect**: `some(where (p.eft == allow))` means "allow if any rule matches". Use `!some(where (p.eft == deny))` for deny-override.
- **ABAC with eval()**: `eval(p.sub_rule)` in matchers enables attribute-based checks but requires careful input sanitization.
- **Multi-instance sync**: use a Watcher (Redis, etc.) to synchronize policy changes across enforcer instances.
