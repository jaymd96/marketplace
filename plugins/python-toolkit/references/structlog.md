# structlog v24.4.0

## Quick Start

```python
import structlog
log = structlog.get_logger()
log.info("user_logged_in", user_id=42, ip="10.0.0.1")
# {"user_id": 42, "ip": "10.0.0.1", "event": "user_logged_in", "level": "info"}
```

## Core API

```python
import logging, structlog

# Configure once at startup
structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,       # request-scoped context
        structlog.processors.add_log_level,            # add "level" key
        structlog.processors.TimeStamper(fmt="iso"),   # add timestamp
        structlog.dev.ConsoleRenderer(),               # dev: pretty, prod: JSONRenderer()
    ],
    wrapper_class=structlog.make_filtering_bound_logger(logging.INFO),  # filter below INFO
    context_class=dict,
    logger_factory=structlog.PrintLoggerFactory(),
    cache_logger_on_first_use=True,
)

# Logging
log = structlog.get_logger()
log.info("event_name", key="value")
log = log.bind(request_id="abc-123")        # returns new logger with context
log.info("processing")                       # includes request_id
log = log.unbind("request_id")              # remove key

# Request-scoped context (async-safe)
structlog.contextvars.clear_contextvars()
structlog.contextvars.bind_contextvars(request_id="abc-123")

# Custom processor signature: (logger, method_name, event_dict) -> event_dict
def add_hostname(logger, method_name, event_dict):
    event_dict["hostname"] = "server-01"
    return event_dict

# Drop events
def drop_health_checks(logger, method_name, event_dict):
    if event_dict.get("event") == "health_check":
        raise structlog.DropEvent
    return event_dict
```

## Examples

### Dev/prod configuration

```python
def configure_logging(env: str = "development"):
    shared = [
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.stdlib.add_logger_name,
        structlog.processors.format_exc_info,
        structlog.stdlib.ProcessorFormatter.wrap_for_formatter,
    ]
    structlog.configure(
        processors=shared,
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )
    renderer = (structlog.processors.JSONRenderer() if env == "production"
                else structlog.dev.ConsoleRenderer())
    formatter = structlog.stdlib.ProcessorFormatter(processors=[
        structlog.stdlib.ProcessorFormatter.remove_processors_meta, renderer,
    ])
    handler = logging.StreamHandler()
    handler.setFormatter(formatter)
    root = logging.getLogger()
    root.handlers.clear()
    root.addHandler(handler)
    root.setLevel(logging.INFO if env == "production" else logging.DEBUG)
```

### FastAPI middleware

```python
class StructlogMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        structlog.contextvars.clear_contextvars()
        structlog.contextvars.bind_contextvars(
            request_id=request.headers.get("x-request-id", str(uuid.uuid4())),
            method=request.method, path=request.url.path,
        )
        response = await call_next(request)
        structlog.get_logger().info("request_completed", status=response.status_code)
        return response
```

## Pitfalls

- **Processor order matters**: renderer must be last. TimeStamper after JSONRenderer = no timestamp.
- **Forgetting `merge_contextvars`**: bound contextvars won't appear without it in the chain.
- **configure() before get_logger()**: with `cache_logger_on_first_use=True`, loggers cached with defaults won't update.
- **`make_filtering_bound_logger` takes int**: use `logging.INFO`, not the string `"INFO"`.
- **JSONRenderer + non-serializable objects**: add a serialization processor before the renderer.
- **Testing**: set `cache_logger_on_first_use=False` so config changes between tests take effect.
- **Don't mix threadlocal and contextvars**: pick one. Prefer contextvars for modern Python.
