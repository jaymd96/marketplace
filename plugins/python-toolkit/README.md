# Python Toolkit

Opinionated Python development plugin for Claude Code. Enforces architecture
rules for large codebases, provides 48 pinned library references, and scaffolds
projects with correct structure.

## Baseline

- **Python:** 3.12+
- **Package manager:** uv (lockfiles, fast resolver)
- **Build:** hatch (pyproject.toml native)
- **Lint + format:** ruff (replaces black, isort, flake8)
- **Type checking:** mypy (strict mode)
- **Testing:** pytest (strict markers, xdist parallel)

## The 12 Rules

Non-negotiable architecture rules for every project:

1. One entrypoint (no scattered `if __name__`)
2. Pure imports (no side effects at module level)
3. Types everywhere (mypy strict, no Any leaks)
4. Explicit boundaries (domain never imports adapters)
5. Illegal states unrepresentable (frozen dataclasses, enums)
6. No ad-hoc globals (typed config, injected)
7. Exception taxonomy (domain → application → edge)
8. Side effects at edges (pure logic in the middle)
9. Layered testing (unit 70%, contract 10%, integration 15%, e2e 5%)
10. Auto-format (ruff, non-negotiable)
11. Locked dependencies (uv lock, pinned versions)
12. No dynamic magic (no metaprogramming without written reason)

## Components

### Skills (4)
| Skill | Triggers On |
|-------|------------|
| architecture | Project structure, module layout, boundaries, scaffolding |
| coding-standards | Writing code, design decisions, typing, error handling |
| testing | pytest patterns, fixtures, speed optimization |
| bash | Shell scripting, deployment scripts, pipelines |

### Agents (3)
| Agent | Purpose |
|-------|---------|
| architecture-reviewer | Audits code against the 12 rules |
| test-writer | Generates tests following the testing standards |
| library-lookup | Finds API docs in the reference files |

### Scripts (1)
| Script | Purpose |
|--------|---------|
| scaffold-project.sh | Creates a new project with correct layout + config |

### Hooks (1)
| Event | Action |
|-------|--------|
| PostToolUse (Edit/Write) | Auto-format Python files with ruff |

### References (48 libraries)
On-demand library documentation in `references/<name>.md`. Each file has:
quick-start, core API, examples, and pitfalls. Read only when needed.

## Usage

```bash
# Install the plugin
claude --plugin-dir /path/to/python-toolkit

# Scaffold a new project
/bash scripts/scaffold-project.sh ./my-project my_package

# Architecture review
"Review this code against the architecture rules"

# Library lookup
"How do I use attrs frozen classes?"
"Show me httpx connection pooling"

# Test generation
"Write tests for this service"
```

## Context Management Strategy

- **CLAUDE.md** (~150 lines) — always loaded. Contains the 12 rules and library
  index with versions. Enough to code correctly without loading anything else.
- **Skills** — loaded on trigger. Deep reference for architecture, coding
  standards, testing, and bash patterns.
- **References** — loaded on demand, one at a time. Full API docs per library.
- **Agents** — isolated context. Architecture review reads the whole codebase.
  Library lookup reads one reference file. Neither consumes main context.
- **Hooks** — automatic. ruff formats Python files after every edit.
