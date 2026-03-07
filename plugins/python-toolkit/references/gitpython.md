# gitpython v3.1+

Python interface to Git repositories. Wraps the git CLI for high-level operations on repos, commits, branches, and remotes.

```
pip install gitpython
```

## Quick Start

```python
from git import Repo

repo = Repo("/path/to/repo")
print(repo.active_branch)                    # current branch
print(repo.head.commit.message)              # last commit message
for commit in repo.iter_commits("main", max_count=5):
    print(f"{commit.hexsha[:8]} {commit.summary}")
```

## Core API

### Open / Init / Clone

```python
from git import Repo

# Open existing
repo = Repo("/path/to/repo")
repo = Repo(".")                      # current directory

# Init new
repo = Repo.init("/path/to/new/repo")
repo = Repo.init("/path", bare=True)  # bare repo

# Clone
repo = Repo.clone_from(
    "https://github.com/user/repo.git",
    "/path/to/local",
    branch="main",
    depth=1,                           # shallow clone
)

# Check validity
repo.bare          # -> bool
repo.is_dirty()    # -> bool (uncommitted changes)
repo.untracked_files  # -> list[str]
```

### Commits

```python
# Latest commit
commit = repo.head.commit
commit.hexsha        # full SHA
commit.hexsha[:8]    # short SHA
commit.message       # full message
commit.summary       # first line
commit.author        # Actor(name, email)
commit.authored_date # Unix timestamp
commit.committed_date
commit.parents       # tuple of parent commits
commit.stats.total   # {"insertions": N, "deletions": N, "lines": N, "files": N}

# Iterate commits
for c in repo.iter_commits("main", max_count=20):
    print(f"{c.hexsha[:8]} {c.author.name}: {c.summary}")

# Commits on a range
for c in repo.iter_commits("v1.0..main"):
    print(c.summary)

# Commits touching a file
for c in repo.iter_commits(paths="src/app.py"):
    print(c.summary)
```

### Branches

```python
# List branches
repo.branches              # list of Head objects (local)
repo.remote().refs         # remote branches

# Current branch
repo.active_branch         # -> Head
repo.active_branch.name    # -> "main"

# Create branch
new_branch = repo.create_head("feature-x")
new_branch = repo.create_head("feature-y", commit="abc123")

# Checkout
repo.heads["feature-x"].checkout()

# Delete branch
repo.delete_head("feature-x", force=True)
```

### Tags

```python
# List
repo.tags                                 # list of TagReference

# Create
repo.create_tag("v1.0")
repo.create_tag("v1.0", message="Release 1.0")  # annotated tag
repo.create_tag("v1.0", ref="abc1234")           # tag specific commit

# Delete
repo.delete_tag("v1.0")
```

### Index (Staging)

```python
index = repo.index

# Stage files
index.add(["file1.py", "file2.py"])
index.add("*.txt")                   # glob pattern

# Remove from index
index.remove(["old_file.py"])
index.remove(["old_file.py"], working_tree=True)  # also delete from disk

# Commit
index.commit("feat: add new feature")

# Full workflow
repo.index.add(["src/new.py"])
repo.index.commit("add new module")
```

### Diff

```python
# Working tree vs index (unstaged changes)
diffs = repo.index.diff(None)

# Index vs HEAD (staged changes)
diffs = repo.index.diff("HEAD")

# Between commits
diffs = repo.commit("HEAD~3").diff("HEAD")

# Inspect diff objects
for d in diffs:
    d.a_path          # source file path
    d.b_path          # destination file path
    d.change_type     # "A" (add), "D" (delete), "M" (modify), "R" (rename)
    d.diff            # raw diff bytes
    d.new_file        # bool
    d.deleted_file    # bool
    d.renamed_file    # bool
```

### Remote Operations

```python
# List remotes
repo.remotes          # -> [Remote("origin")]

# Access a remote
origin = repo.remote("origin")
origin.url            # -> "https://github.com/..."
origin.urls           # -> iterator of URLs

# Fetch
origin.fetch()
origin.fetch("main")
origin.fetch(tags=True)

# Pull
origin.pull()
origin.pull("main")

# Push
origin.push()
origin.push("feature-x")
origin.push(tags=True)

# Add / remove remote
repo.create_remote("upstream", "https://github.com/upstream/repo.git")
repo.delete_remote("upstream")
```

### Git Command (Escape Hatch)

```python
# Run arbitrary git commands
repo.git.status()
repo.git.log("--oneline", "-10")
repo.git.stash("push", "-m", "wip")
repo.git.stash("pop")
repo.git.cherry_pick("abc1234")
```

## Examples

### Commit and push

```python
repo = Repo(".")
repo.index.add(["src/feature.py", "tests/test_feature.py"])
repo.index.commit("feat: implement feature X")
repo.remote("origin").push()
```

### Find commits by author in date range

```python
from datetime import datetime

since = datetime(2025, 1, 1).strftime("%Y-%m-%d")
for c in repo.iter_commits("main", since=since, author="alice"):
    print(f"{c.hexsha[:8]} {c.summary}")
```

### Check if branch exists

```python
def branch_exists(repo, name):
    return name in [b.name for b in repo.branches]
```

## Pitfalls

1. **Requires git CLI**: GitPython shells out to `git`. If `git` is not in `$PATH`, it fails. It is not a pure-Python Git implementation.
2. **Repo("/path") walks upward**: `Repo(".")` searches parent directories for `.git`. This can unexpectedly find a repo higher in the tree. Use `search_parent_directories=False` to prevent this.
3. **Memory with large repos**: `list(repo.iter_commits())` on a large repo loads all commit objects. Always use `max_count` or iterate lazily.
4. **Detached HEAD**: `repo.active_branch` raises `TypeError` when HEAD is detached. Check `repo.head.is_detached` first.
5. **diff bytes encoding**: `d.diff` returns `bytes`. Decode with `d.diff.decode("utf-8", errors="replace")` for display.
6. **Resource leaks**: Call `repo.close()` or use `with Repo(".") as repo:` (v3.1.30+) when opening many repos, especially in long-running processes. Open file descriptors can leak.
7. **No progress for fetch/push**: Remote operations block without progress. Use `progress=RemoteProgress()` callback for long operations.
