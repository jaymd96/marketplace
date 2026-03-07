# Fabric v3.2+

Remote command execution over SSH. Built on Invoke (task runner) and Paramiko (SSH).

## Quick Start

```python
from fabric import Connection

c = Connection("web1.example.com", user="deploy", connect_kwargs={"password": "secret"})
result = c.run("uname -a", hide=True)
print(result.stdout.strip())

c.put("app.tar.gz", remote="/tmp/app.tar.gz")
c.run("cd /opt/app && tar xzf /tmp/app.tar.gz")
```

## Core API

### `Connection(host, user=None, port=None, config=None, gateway=None, forward_agent=False, connect_timeout=None, connect_kwargs=None)`

Represents a single SSH connection.

```python
from fabric import Connection

# Basic
c = Connection("hostname")

# With user and port
c = Connection("hostname", user="deploy", port=2222)

# With SSH key
c = Connection("hostname", connect_kwargs={"key_filename": "/path/to/key.pem"})

# With password
c = Connection("hostname", connect_kwargs={"password": "secret"})

# Shorthand string (user@host:port)
c = Connection("deploy@web1.example.com:2222")

# Via jump host / bastion
gateway = Connection("bastion.example.com")
c = Connection("internal-host", gateway=gateway)
```

### `Connection.run(command, **kwargs)`

Execute a shell command on the remote host. Returns a `Result` object.

```python
result = c.run("ls -la /var/log")
print(result.stdout)         # Captured stdout
print(result.stderr)         # Captured stderr
print(result.return_code)    # Exit code (0 = success)
print(result.ok)             # True if return_code == 0
print(result.failed)         # True if return_code != 0

# Hide output from terminal
result = c.run("whoami", hide=True)

# Warn instead of raising on failure
result = c.run("false", warn=True)
assert result.failed

# With environment variables
c.run("echo $APP_ENV", env={"APP_ENV": "production"})

# Pseudo-terminal allocation (needed for sudo prompts, interactive commands)
c.run("sudo systemctl restart nginx", pty=True)
```

### `Connection.sudo(command, **kwargs)`

Run a command via sudo. Handles password prompts automatically.

```python
c = Connection("host", connect_kwargs={"password": "userpass"})
c.config.sudo.password = "sudopass"
c.sudo("systemctl restart nginx")
```

### `Connection.put(local, remote=None, preserve_mode=True)`

Upload a file to the remote host.

```python
c.put("local/config.yml", remote="/etc/app/config.yml")
c.put("deploy.tar.gz", remote="/tmp/")

# From file-like object
from io import StringIO
c.put(StringIO("key=value\n"), remote="/etc/app/settings.env")
```

### `Connection.get(remote, local=None, preserve_mode=True)`

Download a file from the remote host.

```python
c.get("/var/log/app.log", local="logs/app.log")
c.get("/etc/app/config.yml")  # Downloads to current directory
```

### `Connection.local(command, **kwargs)`

Run a command on the local machine (delegates to Invoke).

```python
c.local("tar czf deploy.tar.gz ./dist/")
```

### Groups: Execute on Multiple Hosts

```python
from fabric import SerialGroup, ThreadingGroup

# Serial execution (one host at a time)
group = SerialGroup("web1", "web2", "web3", user="deploy")
results = group.run("uptime")
for conn, result in results.items():
    print(f"{conn.host}: {result.stdout.strip()}")

# Parallel execution (threaded)
group = ThreadingGroup("web1", "web2", "web3", user="deploy")
results = group.run("free -m", hide=True)

# With connect kwargs
group = SerialGroup(
    "web1", "web2",
    user="deploy",
    connect_kwargs={"key_filename": "~/.ssh/deploy_key"},
)

# File transfer to all hosts
group.put("app.tar.gz", remote="/tmp/app.tar.gz")
```

### Task Decorator

```python
# fabfile.py
from fabric import task, Connection

@task
def deploy(c, branch="main"):
    """Deploy the application."""
    c.run(f"cd /opt/app && git pull origin {branch}")
    c.run("cd /opt/app && pip install -r requirements.txt")
    c.sudo("systemctl restart app")

@task
def rollback(c):
    """Rollback to previous release."""
    c.run("cd /opt/app && git checkout HEAD~1")
    c.sudo("systemctl restart app")
```

```bash
# CLI usage
fab -H web1.example.com deploy --branch=release/v2
fab -H web1,web2,web3 deploy
```

## Examples

### Deployment Script

```python
from fabric import Connection, SerialGroup

def deploy(hosts, version):
    group = SerialGroup(*hosts, user="deploy")

    # Upload artifact
    for conn in group:
        conn.put(f"dist/app-{version}.tar.gz", remote="/tmp/")

    # Stop, deploy, start
    group.run("sudo systemctl stop app", warn=True)
    group.run(f"cd /opt/app && tar xzf /tmp/app-{version}.tar.gz")
    group.run("sudo systemctl start app")

    # Health check
    for conn in group:
        result = conn.run("curl -sf http://localhost:8000/health", warn=True)
        print(f"{conn.host}: {'OK' if result.ok else 'FAILED'}")
```

### Bastion / Jump Host

```python
bastion = Connection("bastion.example.com", user="ops")
internal = Connection("10.0.1.50", user="deploy", gateway=bastion)

internal.run("hostname")
internal.put("config.yml", remote="/etc/app/config.yml")
```

## Pitfalls

- **Fabric 3.x is a complete rewrite from Fabric 1.x / 2.x.** Legacy `env.hosts`, `env.roledefs`, and `@roles` do not exist. Use `Connection` and `Group` instead.
- **`Connection.run()` raises `UnexpectedExit` on non-zero exit codes by default.** Pass `warn=True` to suppress and check `result.failed` manually.
- **Group operations raise `GroupException` if any host fails**, wrapping individual exceptions. Handle it to avoid aborting the entire batch.
- **SSH agent forwarding requires `forward_agent=True`** on the Connection. It is off by default.
- **`sudo()` needs the password in `c.config.sudo.password`.** Without it, the sudo prompt hangs unless you use `pty=True` and provide input interactively.
- **`put()` and `get()` do not create intermediate directories.** The remote (or local) parent directory must already exist.
- **ThreadingGroup is not truly parallel** -- it uses Python threads, subject to the GIL. For CPU-bound local work, use subprocesses.
