# docker v7.1+

Python SDK for the Docker Engine API. Control containers, images, volumes, and networks programmatically.

```
pip install docker
```

## Quick Start

```python
import docker

client = docker.from_env()
container = client.containers.run("python:3.12-slim", "python -c 'print(42)'", remove=True)
print(container)  # b'42\n'
for c in client.containers.list():
    print(f"{c.short_id} {c.name} {c.status}")
```

## Core API

### Client

```python
import docker

# From environment (DOCKER_HOST, DOCKER_TLS_VERIFY, etc.)
client = docker.from_env()

# Explicit configuration
client = docker.DockerClient(base_url="unix:///var/run/docker.sock")
client = docker.DockerClient(base_url="tcp://192.168.1.10:2376", tls=True)

# Ping
client.ping()  # -> True

# Server info
client.info()    # -> dict (system info)
client.version() # -> dict (API version)

# Close
client.close()
```

### Containers

```python
# Run (blocking, returns output or Container depending on detach)
output = client.containers.run("alpine", "echo hello", remove=True)         # -> bytes
container = client.containers.run("nginx", detach=True, ports={"80/tcp": 8080})

# Run with full options
container = client.containers.run(
    image="myapp:latest",
    command="python app.py",
    name="my-app",
    detach=True,
    ports={"8000/tcp": 8000},
    volumes={"/host/data": {"bind": "/app/data", "mode": "rw"}},
    environment={"DB_URL": "postgres://..."},
    labels={"app": "myapp"},
    restart_policy={"Name": "unless-stopped"},
    mem_limit="512m",
    cpus=1.5,
    network="my-network",
    remove=False,
)

# List
client.containers.list()                    # running only
client.containers.list(all=True)            # include stopped
client.containers.list(filters={"label": "app=myapp"})

# Get by ID or name
container = client.containers.get("container_id_or_name")

# Container operations
container.status    # "running", "exited", etc.
container.name
container.short_id
container.logs()              # -> bytes
container.logs(stream=True)   # -> generator of bytes
container.stop(timeout=10)
container.start()
container.restart(timeout=10)
container.kill(signal="SIGTERM")
container.remove(force=True)
container.pause()
container.unpause()

# Execute command inside container
exit_code, output = container.exec_run("ls -la /app")
print(output.decode())

# Copy file into container
import tarfile, io
tar_stream = io.BytesIO()
with tarfile.open(fileobj=tar_stream, mode="w") as tar:
    data = b"hello world"
    info = tarfile.TarInfo(name="hello.txt")
    info.size = len(data)
    tar.addfile(info, io.BytesIO(data))
container.put_archive("/tmp", tar_stream.getvalue())
```

### Images

```python
# Pull
image = client.images.pull("python", tag="3.12-slim")
image = client.images.pull("myregistry.io/myapp", tag="v1.0")

# Build
image, build_logs = client.images.build(
    path="/path/to/context",
    dockerfile="Dockerfile",
    tag="myapp:latest",
    buildargs={"VERSION": "1.0"},
    rm=True,           # remove intermediate containers
    nocache=False,
)
for chunk in build_logs:
    if "stream" in chunk:
        print(chunk["stream"], end="")

# List
client.images.list()
client.images.list(filters={"dangling": True})

# Get
image = client.images.get("python:3.12-slim")
image.tags    # -> ["python:3.12-slim"]
image.id
image.short_id

# Remove
client.images.remove("myapp:old")
client.images.prune()                 # remove dangling
client.images.prune(filters={"dangling": False})  # remove all unused

# Tag and push
image.tag("myregistry.io/myapp", tag="v2.0")
client.images.push("myregistry.io/myapp", tag="v2.0")
```

### Volumes

```python
# Create
volume = client.volumes.create(
    name="my-data",
    driver="local",
    labels={"app": "myapp"},
)

# List
client.volumes.list()
client.volumes.list(filters={"label": "app=myapp"})

# Get
volume = client.volumes.get("my-data")
volume.name
volume.attrs    # -> full volume info dict

# Remove
volume.remove(force=True)
client.volumes.prune()  # remove unused volumes
```

### Networks

```python
# Create
network = client.networks.create(
    "my-network",
    driver="bridge",
    labels={"env": "dev"},
)

# List
client.networks.list()

# Connect / disconnect containers
network.connect(container)
network.disconnect(container)

# Remove
network.remove()
client.networks.prune()
```

## Examples

### Run a database for testing

```python
def start_postgres(client):
    return client.containers.run(
        "postgres:16",
        detach=True,
        name="test-db",
        ports={"5432/tcp": 5432},
        environment={"POSTGRES_PASSWORD": "test", "POSTGRES_DB": "testdb"},
        healthcheck={
            "test": ["CMD-SHELL", "pg_isready -U postgres"],
            "interval": 1_000_000_000,  # 1s in nanoseconds
            "timeout": 3_000_000_000,
            "retries": 10,
        },
        remove=True,
    )
```

### Stream container logs

```python
container = client.containers.get("my-app")
for line in container.logs(stream=True, follow=True):
    print(line.decode().strip())
```

### Cleanup old containers

```python
import datetime
for c in client.containers.list(all=True, filters={"status": "exited"}):
    finished = c.attrs["State"]["FinishedAt"]
    c.remove(force=True)
```

## Pitfalls

1. **Docker daemon required**: The SDK talks to the Docker daemon via socket. If Docker is not running, `docker.from_env()` raises `DockerException`.
2. **run() without detach blocks**: `client.containers.run(image, cmd)` blocks until the container exits and returns stdout bytes. Use `detach=True` for background containers.
3. **remove=True + detach=True**: Using both means the container auto-removes on exit, but you must stop it yourself. With `detach=False`, `remove=True` cleans up after the blocking call returns.
4. **Port mapping format**: Ports are `{"container_port/proto": host_port}`. Forgetting `/tcp` (e.g., `{80: 8080}`) causes a `TypeError`.
5. **Volume mount format**: Use dict `{"/host/path": {"bind": "/container/path", "mode": "rw"}}`, not a string. Strings work in Docker CLI but not here.
6. **Build context size**: `client.images.build(path=".")` sends the entire directory as context. Use `.dockerignore` or set a smaller `path`.
7. **Logs are bytes**: `container.logs()` returns `bytes`. Decode with `.decode("utf-8")` before string operations.
