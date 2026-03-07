# Kopf v1.37+

Kubernetes Operator Pythonic Framework. Write Kubernetes operators in Python with
decorators for CRD lifecycle events, timers, daemons, and in-memory indexing.

**Install:** `pip install kopf`

---

## Quick Start

```python
import kopf

@kopf.on.create("example.com", "v1", "myresources")
def create_fn(spec, name, namespace, logger, **kwargs):
    logger.info(f"Created: {name} in {namespace}")
    return {"message": f"Handled {name}"}

# Run: kopf run my_operator.py --verbose
```

---

## Core API

### Resource Event Handlers

```python
import kopf

# Full form: (group, version, plural)
@kopf.on.create("example.com", "v1", "myresources")
@kopf.on.update("example.com", "v1", "myresources")
@kopf.on.delete("example.com", "v1", "myresources")
@kopf.on.resume("example.com", "v1", "myresources")  # On operator restart

# Short form for core resources
@kopf.on.create("pods")
@kopf.on.create("deployments.v1.apps")

# Handler signature (all kwargs are optional, take what you need)
def handler(
    body: dict,         # Full resource body
    spec: dict,         # body["spec"]
    meta: dict,         # body["metadata"]
    status: dict,       # body["status"]
    name: str,          # metadata.name
    namespace: str,     # metadata.namespace
    uid: str,           # metadata.uid
    labels: dict,       # metadata.labels
    annotations: dict,  # metadata.annotations
    logger: logging.Logger,
    patch: dict,        # Accumulates JSON Patch operations
    retry: int,         # Current retry attempt number
    started: datetime,  # When this handler first started
    runtime: timedelta, # How long since first attempt
    memo: kopf.Memo,    # Per-object in-memory storage
    param: Any,         # Custom param passed via decorator
    **kwargs,           # Future-proofing
):
    ...
```

### Field Change Handlers

```python
@kopf.on.field("example.com", "v1", "myresources", field="spec.replicas")
def replicas_changed(old, new, diff, body, **kwargs):
    """Triggered only when spec.replicas changes."""
    print(f"Replicas changed from {old} to {new}")

# diff is a list of (op, path, old, new) tuples
# op: "add" | "change" | "remove"
```

### Filters

```python
# Label filters
@kopf.on.create("pods", labels={"app": "myapp"})
@kopf.on.create("pods", labels={"app": kopf.PRESENT})
@kopf.on.create("pods", labels={"app": kopf.ABSENT})

# Annotation filters
@kopf.on.create("pods", annotations={"managed": "true"})

# When filter (arbitrary condition)
@kopf.on.create("pods", when=lambda spec, **_: spec.get("priority", 0) > 5)

# Field filter (for update handlers)
@kopf.on.update("myresources", field="status.phase", new="Running")
```

### Timers

```python
@kopf.timer("example.com", "v1", "myresources", interval=60.0)
def reconcile(spec, name, logger, **kwargs):
    """Runs every 60 seconds for each existing resource."""
    logger.info(f"Reconciling {name}")

@kopf.timer("example.com", "v1", "myresources",
            interval=30.0,
            initial_delay=10.0,     # Wait before first execution
            idle=60.0,              # Min seconds between runs
            sharp=False,            # True = fixed schedule, False = interval after completion
)
def periodic_check(spec, **kwargs):
    ...
```

### Daemons

```python
@kopf.daemon("example.com", "v1", "myresources")
async def monitor(spec, name, stopped: kopf.DaemonStopped, logger, **kwargs):
    """Long-running background task per resource. Runs while resource exists."""
    while not stopped:
        logger.info(f"Monitoring {name}")
        await asyncio.sleep(10)

# Cancellation options
@kopf.daemon("example.com", "v1", "myresources",
             cancellation_timeout=30.0,    # Grace period before forced stop
             cancellation_backoff=1.0,     # Check interval during shutdown
)
async def worker(stopped, **kwargs):
    try:
        while not stopped:
            await do_work()
            await stopped.wait(timeout=5)  # Sleep but wake on stop signal
    finally:
        await cleanup()
```

### In-Memory Indexing

```python
@kopf.index("example.com", "v1", "myresources")
def my_index(name, namespace, spec, **kwargs):
    """Builds an in-memory index of all resources."""
    return {(namespace, name): spec.get("config")}

# Use the index in handlers
@kopf.on.create("example.com", "v1", "dependents")
def handle_dependent(spec, my_index: kopf.Index, **kwargs):
    # my_index is automatically injected by name
    config = my_index.get((spec["target_ns"], spec["target_name"]))
    ...
```

### Startup/Cleanup/Login

```python
@kopf.on.startup()
def configure(settings: kopf.OperatorSettings, **kwargs):
    settings.posting.level = logging.WARNING
    settings.watching.server_timeout = 270
    settings.persistence.finalizer = "example.com/my-finalizer"
    settings.persistence.progress_storage = kopf.AnnotationsProgressStorage()
    settings.batching.idle_timeout = 1.0

@kopf.on.cleanup()
def cleanup_fn(**kwargs):
    """Runs when operator is shutting down."""
    ...

@kopf.on.login()
def login_fn(**kwargs):
    """Custom authentication. Return credentials or ConnectionInfo."""
    return kopf.login_via_client(**kwargs)       # Use kubernetes client config
    # or: return kopf.login_via_pykube(**kwargs)
    # or: return kopf.ConnectionInfo(server="...", token="...")
```

### Sub-Handlers

```python
@kopf.on.create("example.com", "v1", "myresources")
def create_fn(spec, patch, **kwargs):
    # Register sub-handlers for step-by-step processing
    @kopf.register(id="step-1")
    def step_one(**kwargs):
        return {"step1": "done"}

    @kopf.register(id="step-2")
    def step_two(**kwargs):
        return {"step2": "done"}
```

---

## Examples

### Full Operator with Timer and Daemon

```python
import kopf
import kubernetes

@kopf.on.startup()
def configure(settings: kopf.OperatorSettings, **kwargs):
    settings.posting.level = logging.WARNING

@kopf.on.create("example.com", "v1", "widgets")
def on_create(spec, name, namespace, logger, **kwargs):
    api = kubernetes.client.AppsV1Api()
    deployment = build_deployment(name, namespace, spec)
    api.create_namespaced_deployment(namespace, deployment)
    logger.info(f"Deployment created for widget {name}")
    return {"deployment": f"{namespace}/{name}"}

@kopf.on.delete("example.com", "v1", "widgets")
def on_delete(name, namespace, logger, **kwargs):
    api = kubernetes.client.AppsV1Api()
    api.delete_namespaced_deployment(name, namespace)
    logger.info(f"Deployment deleted for widget {name}")

@kopf.timer("example.com", "v1", "widgets", interval=30.0)
def health_check(name, namespace, logger, **kwargs):
    api = kubernetes.client.AppsV1Api()
    dep = api.read_namespaced_deployment(name, namespace)
    if dep.status.ready_replicas != dep.spec.replicas:
        logger.warning(f"Widget {name} not fully ready")
```

### Testing Operators

```python
import kopf.testing
import subprocess

def test_operator():
    with kopf.testing.KopfRunner(
        ["run", "--verbose", "my_operator.py"],
        timeout=60,
    ) as runner:
        subprocess.run(["kubectl", "apply", "-f", "test-resource.yaml"], check=True)
        import time; time.sleep(5)
        subprocess.run(["kubectl", "delete", "-f", "test-resource.yaml"], check=True)

    assert runner.exit_code == 0
    assert runner.exception is None
    assert "Created" in runner.stdout
```

---

## Pitfalls

1. **Handlers must be idempotent.** Kopf retries failed handlers automatically.
   Ensure create/update handlers can run multiple times safely.

2. **`**kwargs` is mandatory.** Always include `**kwargs` in handler signatures.
   Kopf passes many keyword arguments; missing kwargs causes TypeErrors on upgrades.

3. **Finalizers block deletion.** Kopf adds a finalizer to managed resources. If the
   operator is down, resources cannot be deleted. Set a custom finalizer name in
   settings or use `kopf.on.delete(optional=True)` to allow deletion without the operator.

4. **Timer drift.** With `sharp=False` (default), the interval starts after handler
   completion. Long-running handlers cause the actual period to exceed the interval.

5. **Daemon lifecycle.** Daemons start when the resource is created OR when the operator
   starts (for existing resources). Always check the `stopped` flag to exit cleanly.

6. **Index name matching.** The index is injected into handlers by matching the function
   name of the `@kopf.index` decorator. Rename the function = break the injection.

7. **Namespace scoping.** By default, Kopf watches all namespaces. Use
   `kopf run --namespace=my-ns` or `settings.watching.namespaces = {"my-ns"}` to scope.
