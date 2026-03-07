# watchdog v6.0+

File system event monitoring library. Watch directories for changes and react in real time.

```
pip install watchdog
```

## Quick Start

```python
import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class MyHandler(FileSystemEventHandler):
    def on_modified(self, event):
        print(f"Modified: {event.src_path}")

observer = Observer()
observer.schedule(MyHandler(), path=".", recursive=True)
observer.start()
try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    observer.stop()
observer.join()
```

## Core API

### Observer

```python
from watchdog.observers import Observer

observer = Observer()

# Schedule a handler for a path
watch = observer.schedule(
    event_handler,          # FileSystemEventHandler subclass
    path="/path/to/watch",
    recursive=True,         # watch subdirectories
)

# Start watching (spawns a daemon thread)
observer.start()

# Stop watching
observer.stop()
observer.join()            # wait for thread to finish

# Unschedule a specific watch
observer.unschedule(watch)

# Unschedule all watches
observer.unschedule_all()

# Schedule multiple paths
observer.schedule(handler, "/path/one", recursive=True)
observer.schedule(handler, "/path/two", recursive=False)
```

### FileSystemEventHandler

```python
from watchdog.events import (
    FileSystemEventHandler,
    FileSystemEvent,
    FileCreatedEvent,
    FileModifiedEvent,
    FileDeletedEvent,
    FileMovedEvent,
    DirCreatedEvent,
    DirModifiedEvent,
    DirDeletedEvent,
    DirMovedEvent,
)

class MyHandler(FileSystemEventHandler):
    def on_any_event(self, event: FileSystemEvent):
        """Called for any event. Override for catch-all logging."""
        pass

    def on_created(self, event):
        """Called when a file or directory is created."""
        if not event.is_directory:
            print(f"File created: {event.src_path}")

    def on_modified(self, event):
        """Called when a file or directory is modified."""
        if not event.is_directory:
            print(f"File modified: {event.src_path}")

    def on_deleted(self, event):
        """Called when a file or directory is deleted."""
        print(f"Deleted: {event.src_path}")

    def on_moved(self, event):
        """Called when a file or directory is moved/renamed."""
        print(f"Moved: {event.src_path} -> {event.dest_path}")

    def on_closed(self, event):
        """Called when a file is closed (Linux inotify only)."""
        print(f"Closed: {event.src_path}")
```

### Event Objects

```python
# Common attributes on all events
event.src_path       # -> str: absolute path of the affected file/dir
event.is_directory   # -> bool
event.event_type     # -> str: "created", "modified", "deleted", "moved", "closed"

# MovedEvent has an additional attribute
event.dest_path      # -> str: destination path (moved/renamed events only)
```

### PatternMatchingEventHandler

```python
from watchdog.events import PatternMatchingEventHandler

class PyHandler(PatternMatchingEventHandler):
    def __init__(self):
        super().__init__(
            patterns=["*.py", "*.yaml"],          # shell-style globs
            ignore_patterns=["*/__pycache__/*", "*.pyc"],
            ignore_directories=True,               # skip directory events
            case_sensitive=True,
        )

    def on_modified(self, event):
        print(f"Python file changed: {event.src_path}")
```

### RegexMatchingEventHandler

```python
from watchdog.events import RegexMatchingEventHandler

class LogHandler(RegexMatchingEventHandler):
    def __init__(self):
        super().__init__(
            regexes=[r".*\.log$", r".*/logs/.*"],
            ignore_regexes=[r".*/\.git/.*"],
            ignore_directories=True,
            case_sensitive=False,
        )

    def on_modified(self, event):
        print(f"Log changed: {event.src_path}")
```

### LoggingEventHandler (Debug)

```python
from watchdog.events import LoggingEventHandler
import logging

logging.basicConfig(level=logging.INFO)
handler = LoggingEventHandler()  # logs all events at INFO level
observer.schedule(handler, ".", recursive=True)
```

## Examples

### Auto-reload on file changes

```python
import subprocess
import time
from watchdog.observers import Observer
from watchdog.events import PatternMatchingEventHandler

class ReloadHandler(PatternMatchingEventHandler):
    def __init__(self, command):
        super().__init__(patterns=["*.py"], ignore_directories=True)
        self.command = command
        self.process = None
        self._restart()

    def _restart(self):
        if self.process:
            self.process.terminate()
            self.process.wait()
        self.process = subprocess.Popen(self.command, shell=True)

    def on_modified(self, event):
        print(f"Change detected: {event.src_path}")
        self._restart()

handler = ReloadHandler("python app.py")
observer = Observer()
observer.schedule(handler, "src/", recursive=True)
observer.start()
try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    handler.process.terminate()
    observer.stop()
observer.join()
```

### Watch for new files and process them

```python
import os
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class InboxHandler(FileSystemEventHandler):
    def on_created(self, event):
        if event.is_directory:
            return
        if event.src_path.endswith(".csv"):
            print(f"Processing new CSV: {event.src_path}")
            process_csv(event.src_path)
            os.rename(event.src_path, event.src_path + ".done")

observer = Observer()
observer.schedule(InboxHandler(), "/data/inbox", recursive=False)
observer.start()
```

### Debounced handler (avoid duplicate events)

```python
import time
from watchdog.events import FileSystemEventHandler

class DebouncedHandler(FileSystemEventHandler):
    def __init__(self, callback, delay=0.5):
        super().__init__()
        self.callback = callback
        self.delay = delay
        self._last_event = {}

    def on_modified(self, event):
        if event.is_directory:
            return
        now = time.time()
        last = self._last_event.get(event.src_path, 0)
        if now - last > self.delay:
            self._last_event[event.src_path] = now
            self.callback(event.src_path)
```

## Pitfalls

1. **Duplicate events**: Many OS file systems fire multiple events for a single save (write + modify + close). Debounce with a short delay (see example above).
2. **Platform differences**: macOS uses FSEvents (coalesces events, slight delay), Linux uses inotify (immediate, per-file), Windows uses ReadDirectoryChangesW. Behavior varies across platforms.
3. **recursive=False is default**: If you forget `recursive=True`, subdirectory changes are not reported.
4. **observer.join() is required**: After `observer.stop()`, call `observer.join()` to clean up the thread. Skipping it can leave zombie threads.
5. **Large directories**: Watching a directory with thousands of files (e.g., `node_modules`) can consume significant CPU. Use `ignore_patterns` or `ignore_directories` to filter.
6. **on_modified fires for directories too**: When a file is created inside a directory, both `on_created` (file) and `on_modified` (parent dir) fire. Check `event.is_directory` to filter.
7. **No event for content**: Events report that a file changed, not what changed. You must read and diff the file yourself.
8. **Thread safety**: Event handler methods are called from the observer thread. If you interact with shared state, use locks or a queue.
