# semantic-version v2.10.0

SemVer parsing, comparison, and range matching for Python. Supports both a simple
spec syntax and NPM-compatible range expressions.

```
pip install semantic-version>=2.10
```

## Quick Start

```python
from semantic_version import Version, NpmSpec, SimpleSpec

v = Version("1.2.3")
assert v > Version("1.2.2")
assert v in SimpleSpec(">=1.0.0,<2.0.0")
assert v in NpmSpec("^1.2.0")
next_v = v.next_minor()                   # Version("1.3.0")
```

## Core API

### Version

```python
from semantic_version import Version

# Parse
v = Version("1.2.3")
v = Version("1.2.3-alpha.1+build.42")
v = Version("1.2.3-rc.1")

# Coerce (lenient parsing -- fills missing fields with 0)
v = Version.coerce("1.2")                 # Version("1.2.0")
v = Version.coerce("1")                   # Version("1.0.0")

# Components
v.major                                   # 1
v.minor                                   # 2
v.patch                                   # 3
v.prerelease                              # ("alpha", "1") -- tuple of strings
v.build                                   # ("build", "42") -- tuple of strings

# Comparison (follows SemVer 2.0.0 precedence rules)
Version("1.2.3") < Version("1.2.4")       # True
Version("1.2.3") == Version("1.2.3")      # True
Version("1.0.0-alpha") < Version("1.0.0") # True (prerelease < release)
Version("1.0.0-alpha") < Version("1.0.0-beta")  # True (lexicographic)

# Build metadata is ignored in comparison
Version("1.2.3+build1") == Version("1.2.3+build2")  # True

# Next version helpers
v = Version("1.2.3")
v.next_major()                             # Version("2.0.0")
v.next_minor()                             # Version("1.3.0")
v.next_patch()                             # Version("1.2.4")

# Truncate (remove prerelease/build)
v = Version("1.2.3-alpha+build")
v.truncate("prerelease")                   # Version("1.2.3")
```

### SimpleSpec (Python-Friendly Range Syntax)

```python
from semantic_version import SimpleSpec, Version

# Comparison operators
SimpleSpec(">=1.0.0")                      # 1.0.0 and above
SimpleSpec("<2.0.0")                       # Below 2.0.0
SimpleSpec(">=1.0.0,<2.0.0")              # AND: both must match
SimpleSpec("!=1.2.3")                      # Not equal

# Wildcard
SimpleSpec("1.*")                          # Any 1.x.y
SimpleSpec("1.2.*")                        # Any 1.2.x

# Tilde (minor-level pinning)
SimpleSpec("~=1.2.3")                      # >=1.2.3, <1.3.0

# Caret (compatible with)
SimpleSpec("^1.2.3")                       # >=1.2.3, <2.0.0
SimpleSpec("^0.2.3")                       # >=0.2.3, <0.3.0

# Containment check
Version("1.5.0") in SimpleSpec(">=1.0.0,<2.0.0")  # True
Version("2.0.0") in SimpleSpec(">=1.0.0,<2.0.0")  # False

# Filter versions
spec = SimpleSpec(">=1.0.0,<2.0.0")
versions = [Version("0.9.0"), Version("1.2.3"), Version("1.5.0"), Version("2.0.0")]
matches = list(spec.filter(versions))      # [Version("1.2.3"), Version("1.5.0")]

# Best match (highest matching version)
best = spec.select(versions)               # Version("1.5.0")
```

### NpmSpec (NPM-Compatible Range Syntax)

```python
from semantic_version import NpmSpec, Version

NpmSpec("1.0.0 - 2.0.0")                  # Hyphen: >=1.0.0, <=2.0.0
NpmSpec("1.x")                             # X-range: >=1.0.0, <2.0.0
NpmSpec("~1.2.3")                          # Tilde: >=1.2.3, <1.3.0
NpmSpec("^1.2.3")                          # Caret: >=1.2.3, <2.0.0
NpmSpec("^0.2.3")                          # Caret 0.x: >=0.2.3, <0.3.0
NpmSpec("^0.0.3")                          # Caret 0.0.x: >=0.0.3, <0.0.4
NpmSpec(">=1.0.0 <1.5.0 || >=2.0.0")      # OR ranges
Version("1.3.0") in NpmSpec("^1.2.0")     # True

# Same filter/select API as SimpleSpec
spec = NpmSpec("^1.2.0")
list(spec.filter(versions))                # Matching versions
spec.select(versions)                      # Best (highest) match
```

## Examples

### 1. Version Constraint Resolution

```python
from semantic_version import Version, SimpleSpec

constraints = [
    SimpleSpec(">=1.0.0"),
    SimpleSpec("<2.0.0"),
    SimpleSpec("!=1.3.0"),
]

available = [Version(v) for v in ["0.9.0", "1.0.0", "1.3.0", "1.5.2", "2.0.0"]]
valid = [v for v in available if all(v in c for c in constraints)]
best = max(valid) if valid else None
print(f"Best version: {best}")             # 1.5.2
```

### 2. Release Workflow

```python
from semantic_version import Version

current = Version("1.2.3")

# Determine next version based on change type
change_type = "minor"  # or "major", "patch"
next_version = {
    "major": current.next_major,
    "minor": current.next_minor,
    "patch": current.next_patch,
}[change_type]()

# Pre-release
pre = Version(f"{next_version}-rc.1")
print(f"{current} -> {pre} -> {next_version}")
# 1.2.3 -> 1.3.0-rc.1 -> 1.3.0
```

### 3. NPM-Style Dependency Check

```python
from semantic_version import Version, NpmSpec

dependencies = {
    "framework": NpmSpec("^2.0.0"),
    "utils": NpmSpec("~1.5.0"),
    "core": NpmSpec(">=3.0.0 <4.0.0"),
}

installed = {
    "framework": Version("2.3.1"),
    "utils": Version("1.5.7"),
    "core": Version("3.2.0"),
}

for pkg, spec in dependencies.items():
    v = installed[pkg]
    status = "OK" if v in spec else "MISMATCH"
    print(f"{pkg} {v}: {status}")
```

## Pitfalls

- **`Version()` is strict by default.** `Version("1.2")` raises `ValueError`. Use
  `Version.coerce("1.2")` for lenient parsing that fills in missing fields.
- **Prerelease ordering is subtle.** `1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-beta < 1.0.0`.
  Numeric segments compare numerically; string segments compare lexicographically.
- **Build metadata is ignored in comparisons.** `Version("1.0.0+build1") == Version("1.0.0+build2")`
  is `True` per SemVer spec. Do not use build metadata for ordering.
- **`SimpleSpec` vs `NpmSpec` have different caret behavior at `0.x`.** Both treat
  `^0.2.3` as `>=0.2.3, <0.3.0`, but `NpmSpec("^0.0.3")` means `>=0.0.3, <0.0.4`
  while `SimpleSpec("^0.0.3")` matches `>=0.0.3, <0.1.0`.
- **`select()` returns `None` if no version matches.** Always check the return value.
- **`next_major()` drops prerelease and build.** `Version("1.2.3-alpha").next_major()`
  returns `Version("2.0.0")`, not `Version("2.0.0-alpha")`.
- **Immutable objects.** `Version` instances are immutable. Methods like `next_minor()`
  return new instances; they do not modify the original.
