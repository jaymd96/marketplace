# Uvicorn v0.34+

Lightning-fast ASGI server implementation. Runs FastAPI, Starlette, and any ASGI
application. Based on uvloop and httptools for maximum performance.

**Install:** `pip install uvicorn[standard]`

---

## Quick Start

```python
# CLI
# uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Programmatic
import uvicorn
uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
```

---

## Core API

### CLI Usage

```bash
uvicorn <module>:<attribute> [OPTIONS]

# Common flags
uvicorn main:app \
    --host 0.0.0.0 \           # Bind address (default: 127.0.0.1)
    --port 8000 \              # Bind port (default: 8000)
    --reload \                 # Auto-reload on code changes
    --reload-dir src \         # Watch specific directory (repeatable)
    --reload-include "*.html" \ # Extra glob patterns to watch
    --reload-exclude "*.pyc" \ # Glob patterns to ignore
    --reload-delay 0.25 \      # Seconds between reload checks
    --workers 4 \              # Worker processes (default: $WEB_CONCURRENCY or 1)
    --loop uvloop \            # Event loop (auto|asyncio|uvloop)
    --http httptools \         # HTTP implementation (auto|h11|httptools)
    --ws websockets \          # WebSocket implementation (auto|websockets|wsproto)
    --lifespan auto \          # Lifespan protocol (auto|on|off)
    --interface asgi3 \        # ASGI version (auto|asgi3|asgi2|wsgi)
    --log-level info \         # critical|error|warning|info|debug|trace
    --access-log \             # Enable access log (default: on)
    --no-access-log \          # Disable access log
    --proxy-headers \          # Trust X-Forwarded-* headers
    --forwarded-allow-ips "*"  # IPs to trust for proxy headers
```

### uvicorn.run() — Programmatic

```python
import uvicorn

uvicorn.run(
    app: str | ASGIApplication,  # "module:attr" string or ASGI app object
    host: str = "127.0.0.1",
    port: int = 8000,
    uds: str | None = None,      # Unix domain socket path
    fd: int | None = None,       # File descriptor to bind to
    reload: bool = False,
    reload_dirs: list[str] | None = None,
    reload_delay: float = 0.25,
    reload_includes: list[str] | None = None,
    reload_excludes: list[str] | None = None,
    workers: int | None = None,
    loop: str = "auto",          # "auto" | "asyncio" | "uvloop"
    http: str = "auto",          # "auto" | "h11" | "httptools"
    ws: str = "auto",            # "auto" | "websockets" | "wsproto"
    lifespan: str = "auto",      # "auto" | "on" | "off"
    interface: str = "auto",     # "auto" | "asgi3" | "asgi2" | "wsgi"
    log_level: str | None = None,
    log_config: dict | str | None = LOGGING_CONFIG,
    access_log: bool = True,
    proxy_headers: bool = True,
    server_header: bool = True,  # Send "server: uvicorn" header
    date_header: bool = True,    # Send "date" header
    forwarded_allow_ips: str | None = None,
    root_path: str = "",         # ASGI root_path for reverse proxies
    limit_concurrency: int | None = None,
    limit_max_requests: int | None = None,
    timeout_keep_alive: int = 5,
    timeout_notify: int = 30,
    ssl_keyfile: str | None = None,
    ssl_certfile: str | None = None,
    ssl_keyfile_password: str | None = None,
    ssl_version: int | None = None,
    ssl_cert_reqs: int | None = None,
    ssl_ca_certs: str | None = None,
    ssl_ciphers: str = "TLSv1",
    headers: list[tuple[str, str]] | None = None,
    factory: bool = False,       # Treat app as factory (call to get ASGI app)
    h11_max_incomplete_event_size: int | None = None,
)
```

### SSL Configuration

```bash
# Self-signed cert for development
uvicorn main:app \
    --ssl-keyfile ./key.pem \
    --ssl-certfile ./cert.pem \
    --port 443

# With password-protected key
uvicorn main:app \
    --ssl-keyfile ./key.pem \
    --ssl-certfile ./cert.pem \
    --ssl-keyfile-password "secret"

# Mutual TLS (client cert required)
uvicorn main:app \
    --ssl-keyfile ./key.pem \
    --ssl-certfile ./cert.pem \
    --ssl-ca-certs ./ca.pem \
    --ssl-cert-reqs 2          # ssl.CERT_REQUIRED
```

### Custom Logging

```python
log_config = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "default": {
            "fmt": "%(asctime)s %(levelname)s %(message)s",
            "datefmt": "%Y-%m-%d %H:%M:%S",
        },
    },
    "handlers": {
        "default": {
            "formatter": "default",
            "class": "logging.StreamHandler",
            "stream": "ext://sys.stderr",
        },
    },
    "loggers": {
        "uvicorn": {"handlers": ["default"], "level": "INFO", "propagate": False},
        "uvicorn.error": {"level": "INFO"},
        "uvicorn.access": {"handlers": ["default"], "level": "INFO", "propagate": False},
    },
}

uvicorn.run("main:app", log_config=log_config)
```

---

## Examples

### Production Deployment (Gunicorn + Uvicorn Workers)

```bash
gunicorn main:app \
    --workers 4 \
    --worker-class uvicorn.workers.UvicornWorker \
    --bind 0.0.0.0:8000 \
    --timeout 120
```

### Programmatic Server with Lifespan

```python
import uvicorn
from contextlib import asynccontextmanager
from fastapi import FastAPI

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Starting up")
    yield
    print("Shutting down")

app = FastAPI(lifespan=lifespan)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
    # Note: pass string "main:app" if using --reload
```

### Factory Pattern

```python
# app.py
def create_app() -> FastAPI:
    app = FastAPI()
    configure_routes(app)
    return app

# Run with factory flag
# uvicorn app:create_app --factory --reload
uvicorn.run("app:create_app", factory=True, reload=True)
```

---

## Pitfalls

1. **`--reload` and `--workers` are mutually exclusive.** You cannot use both at the
   same time. Use `--reload` for development, `--workers` for production.

2. **Pass app as string for reload.** `uvicorn.run(app)` with an object reference
   disables reload. Use `uvicorn.run("module:app")` for reload to work.

3. **`$WEB_CONCURRENCY` overrides `--workers`.** The environment variable takes
   precedence. Unset it if you want the CLI flag to apply.

4. **Default host is `127.0.0.1`.** The server only listens on localhost by default.
   For Docker/remote access, bind to `0.0.0.0`.

5. **Gunicorn is recommended for production multi-process.** Uvicorn's built-in
   `--workers` is simpler but Gunicorn's process management is more battle-tested
   (graceful restarts, worker recycling).

6. **`timeout_keep_alive` default is 5 seconds.** Behind load balancers that expect
   longer keep-alive (e.g., ALB at 60s), increase this to avoid premature disconnects.

7. **Lifespan protocol.** Set `--lifespan on` if your app uses lifespan events but
   uvicorn doesn't auto-detect them (rare with FastAPI, more common with raw ASGI).
