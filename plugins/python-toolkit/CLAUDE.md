# python-toolkit

Opinionated Python development toolkit for building large, maintainable codebases.

**Baseline:** Python 3.12+ | uv | ruff | mypy (strict) | pytest | hatch (build)

## The 12 Rules

These are non-negotiable. Every Python project follows these:

1. **One entrypoint.** No "run this file directly." Entrypoint creates config, logging, DI, then calls main().
2. **Pure imports.** Importing a module does no real work. No network, no disk, no env reads at import time.
3. **Types everywhere.** All public APIs typed. CI enforces mypy strict. No `Any` leaks across boundaries.
4. **Explicit boundaries.** `domain/` never imports `adapters/`. Dependencies only go inward.
5. **Illegal states unrepresentable.** Frozen dataclasses, validate at construction, Enum/Literal/NewType over dicts.
6. **No ad-hoc globals.** Config is a typed object created once and injected. No scattered `os.environ` reads.
7. **Exception taxonomy.** Domain raises domain errors. Application maps to outcomes. Edge converts to HTTP/exit codes.
8. **Side effects at edges.** Pure logic in the middle, IO in thin adapter layers.
9. **Layered testing.** Unit (fast, many) + contract (boundaries) + integration (few, real). Coverage enforced selectively.
10. **Auto-format, no debate.** ruff check + ruff format. Pre-commit + CI. No bikeshedding.
11. **Locked dependencies.** Pinned versions, uv lock, reproducible builds.
12. **No dynamic magic.** Metaprogramming, monkeypatching, runtime import hacks banned by default. Explicit registries only.

**Meta-rule:** If it's not enforced in CI, it will eventually be violated.

## When to use these skills

- **architecture** — Starting a new project, designing module structure, enforcing
  boundaries, scaffolding a repo. "How should I structure this?" "Create a new project."
- **coding-standards** — Writing Python code. The 17 decision categories: typing, data
  modeling, error handling, concurrency, logging, config, CLI, API design.
- **testing** — Writing tests, speeding up test suites, pytest patterns, fixtures,
  factories, parametrize, coverage.
- **bash** — Production shell scripting. When to use bash vs Python. Pipelines, traps,
  tool selection (jq, mlr, sqlite3).

## Preferred Libraries (version-pinned)

For any library below, read the full reference: `references/<name>.md`

### Data Modeling & Serialization
| Library | Version | Use For |
|---------|---------|---------|
| attrs | 24.3.0 | Classes without boilerplate (@define, @frozen) |
| cattrs | 24.1.2 | Composable structure/unstructure converters |
| pydantic | 2.10+ | Boundary validation (API input/output, settings) |
| pydantic-settings | 2.7+ | Typed settings from env vars, .env files, secrets |
| sqlmodel | 0.0.22+ | SQLAlchemy + Pydantic ORM (database models) |
| orjson | 3.10+ | Fast JSON (native datetime/numpy support) |
| pyyaml | 6.0.2 | YAML parsing |
| deepdiff | 8.0+ | Deep comparison and diffing |

### Web & API
| Library | Version | Use For |
|---------|---------|---------|
| fastapi | 0.115+ | Web API framework (async, OpenAPI, DI) |
| uvicorn | 0.34+ | ASGI server (runs FastAPI) |

### HTTP & Networking
| Library | Version | Use For |
|---------|---------|---------|
| httpx | 0.28.1 | Modern HTTP client (sync + async, connection pooling) |
| aiohttp | 3.11+ | Async HTTP client/server, WebSocket client |
| websockets | 14.1+ | WebSocket client and server |
| grpcio | 1.68+ | gRPC client and server |

### Observability
| Library | Version | Use For |
|---------|---------|---------|
| structlog | 24.4+ | Structured logging with processor pipelines |
| opentelemetry | 1.29+ | Distributed tracing and metrics |

### CLI
| Library | Version | Use For |
|---------|---------|---------|
| click | 8.1.8 | Composable CLI framework |
| typer | 0.15+ | CLI from type hints (built on Click) |
| rich | 13.9+ | Rich terminal output and formatting |

### Datetime & Scheduling
| Library | Version | Use For |
|---------|---------|---------|
| pendulum | 3.0+ | Timezone-aware datetime |
| python-dateutil | 2.9+ | Flexible parsing, relative deltas |
| croniter | 5.0+ | Cron expression parsing |
| datetimerange | 2.2+ | Range operations (intersection, union) |

### Architecture & Patterns
| Library | Version | Use For |
|---------|---------|---------|
| blinker | 1.9.0 | Signal/event dispatching |
| pluggy | 1.5+ | Hook-based plugin systems |
| punq | 0.7+ | Minimal dependency injection |
| transitions | 0.9.2 | Finite state machines |
| returns | 0.23+ | Typed error handling (Result, Maybe) |
| toolz | 1.0+ | Functional programming primitives |
| immutables | 0.21+ | High-performance immutable mappings |
| burr | 0.40+ | Stateful application framework (actions, state machines) |

### Resilience & Configuration
| Library | Version | Use For |
|---------|---------|---------|
| tenacity | 9.0+ | Retry logic with backoff |
| dynaconf | 3.2+ | Layered configuration management |
| python-dotenv | 1.0+ | Load .env files for local dev |
| cachetools | 5.5+ | In-memory caches (TTL, LRU, LFU) |
| limits | 3.13+ | Rate limiting strategies |

### Database
| Library | Version | Use For |
|---------|---------|---------|
| sqlalchemy | 2.0.40 | ORM and SQL toolkit |
| alembic | 1.14+ | Database migrations (for SQLAlchemy) |
| redis | 5.2+ | Distributed cache, pub/sub, rate limiting |

### Security & Auth
| Library | Version | Use For |
|---------|---------|---------|
| casbin | 1.36+ | Policy-based authorization (RBAC, ABAC) |
| pyjwt | 2.9+ | JWT token creation and verification |
| jwcrypto | 1.5+ | JWT/JWE/JWS cryptography (advanced) |
| cryptography | 44.0+ | Encryption, signing, certificates |
| pyotp | 2.9+ | TOTP/HOTP one-time passwords (MFA) |

### Background Jobs
| Library | Version | Use For |
|---------|---------|---------|
| dramatiq | 1.17+ | Background task queue (Redis/RabbitMQ) |

### Parsing & Templating
| Library | Version | Use For |
|---------|---------|---------|
| lark | 1.2+ | Grammar-based parsing (DSLs) |
| jinja2 | 3.1+ | Template engine |
| rule-engine | 4.5+ | Safe business rule evaluation |
| markdown-it-py | 3.0+ | Markdown parsing and rendering |
| protobuf | 5.29+ | Protocol Buffers serialization |

### Data Structures & Processing
| Library | Version | Use For |
|---------|---------|---------|
| networkx | 3.4+ | Graph and network analysis |
| semantic-version | 2.10+ | SemVer parsing and comparison |
| polars | 1.14+ | Fast DataFrames (modern pandas alternative) |
| zstandard | 0.23+ | Fast compression (Zstandard algorithm) |

### Task Execution & DevOps
| Library | Version | Use For |
|---------|---------|---------|
| fabric | 3.2+ | Remote execution over SSH |
| invoke | 2.2+ | Local task runner |
| docker | 7.1+ | Docker client (build, run, manage) |
| kubernetes | 31.0+ | Kubernetes API client |
| kopf | 1.37+ | Kubernetes operator framework |
| gitpython | 3.1+ | Programmatic git operations |
| watchdog | 6.0+ | File system event monitoring |
| boto3 | 1.35+ | AWS SDK (S3, SQS, DynamoDB, etc.) |

### Notifications & Integrations
| Library | Version | Use For |
|---------|---------|---------|
| slack-sdk | 3.33+ | Slack API (messages, Block Kit, events) |
| questionary | 2.1+ | Interactive CLI prompts (select, confirm, text) |

### GraphQL
| Library | Version | Use For |
|---------|---------|---------|
| strawberry | 0.254+ | GraphQL server (type-safe, Python-first) |

### Async
| Library | Version | Use For |
|---------|---------|---------|
| anyio | 4.7+ | Async abstraction (structured concurrency) |

### Build & Tooling
| Tool | Version | Use For |
|------|---------|---------|
| uv | 0.5+ | Package management, venv, lockfiles |
| ruff | 0.8+ | Linting + formatting (replaces black, isort, flake8) |
| mypy | 1.13+ | Static type checking (strict mode) |
| pytest | 8.3+ | Testing framework |
| hatch | 1.13+ | Build system (pyproject.toml) |

### Testing Utilities
| Library | Version | Use For |
|---------|---------|---------|
| respx | 0.22+ | Mock httpx calls in tests |
| time-machine | 2.16+ | Freeze/travel time in tests |
| hypothesis | 6.115+ | Property-based testing |
| faker | 33.0+ | Fake data generation for tests |

### Profiling & Debugging
| Tool | Version | Use For |
|------|---------|---------|
| py-spy | 0.4+ | Sampling CPU profiler (attach to running process) |
| memray | 1.14+ | Memory allocation profiler |

## Constraints

- Always use the pinned library version. If a newer version exists, check the
  reference file for migration notes before upgrading.
- Never use `from __future__ import annotations` in codebases using attrs or
  Pants — it breaks runtime type inspection.
- Never use asyncio unless the project is explicitly async-first. Default to
  threading for concurrency.
- Never read `os.environ` directly. Use a typed config object.
- Never catch bare `Exception`. Use the project's error taxonomy.
