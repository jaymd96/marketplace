---
name: audit
description: "Audit a Python codebase against 12 architecture and governance rules using parallel auditor agents. Use when evaluating codebase health, before starting work on unfamiliar code, checking architecture compliance, or reviewing overall code quality."
---

# audit

Evaluate a Python codebase against 12 governance rules that make large codebases
maintainable. Launches **3 parallel auditor agents**, each examining a different
rule group, then synthesizes findings into a scored health report.

## The 12 Rules

### Group A — Architecture & Boundaries
1. **One way to run the code** — Single entrypoint per program, same in dev/CI/prod
2. **Imports must be pure** — No side effects on import (no network, disk, env reads)
4. **Define boundaries** — Explicit layers, dependencies only go inward
6. **No ad-hoc globals** — Config is a typed object, no scattered `os.environ`
8. **Side effects at edges** — Pure logic in the middle, IO at boundaries

### Group B — Type Safety & Data Modeling
3. **Types are not optional** — Public APIs typed, CI enforces it
5. **Make illegal states unrepresentable** — Frozen dataclasses, validate at construction
7. **Exceptions are policy** — Documented error taxonomy, no bare `except`

### Group C — Tooling & Process
9. **Testing is layered** — Unit + contract + integration, coverage enforced
10. **Format/lint is non-negotiable** — Auto-format, pre-commit, CI enforcement
11. **Dependency management locked** — Pinned versions, reproducible builds
12. **No dynamic magic** — No metaprogramming, monkeypatching, or import hacks

**Meta-rule:** Everything important is enforced by tools, not people.

## Steps

1. **Identify the project.** If not specified, use the current working directory.
   Read `pyproject.toml` or `setup.py` to understand project structure.

2. **Launch 3 parallel auditor agents** (`codecraft:auditor`):

   - **Auditor 1 — Group A (Architecture & Boundaries):** Rules 1, 2, 4, 6, 8.
     "Audit this project against Group A rules: entrypoints, pure imports,
     boundaries, globals, side effects at edges."

   - **Auditor 2 — Group B (Type Safety & Modeling):** Rules 3, 5, 7.
     "Audit this project against Group B rules: type annotations, data modeling
     with invariants, exception taxonomy."

   - **Auditor 3 — Group C (Tooling & Process):** Rules 9, 10, 11, 12.
     "Audit this project against Group C rules: test structure, lint/format
     config, dependency locking, dynamic magic."

3. **Synthesize findings.** After all agents return, combine into a unified
   health report:

```
CODEBASE HEALTH REPORT
======================
Project: <name>
Date: <date>

SCORECARD
  Rule  1 — One entrypoint:       PASS | PARTIAL | FAIL  (<score>/100)
  Rule  2 — Pure imports:         PASS | PARTIAL | FAIL  (<score>/100)
  Rule  3 — Types enforced:       PASS | PARTIAL | FAIL  (<score>/100)
  Rule  4 — Boundaries defined:   PASS | PARTIAL | FAIL  (<score>/100)
  Rule  5 — Illegal states:       PASS | PARTIAL | FAIL  (<score>/100)
  Rule  6 — No ad-hoc globals:    PASS | PARTIAL | FAIL  (<score>/100)
  Rule  7 — Exception taxonomy:   PASS | PARTIAL | FAIL  (<score>/100)
  Rule  8 — Side effects edged:   PASS | PARTIAL | FAIL  (<score>/100)
  Rule  9 — Layered testing:      PASS | PARTIAL | FAIL  (<score>/100)
  Rule 10 — Format/lint:          PASS | PARTIAL | FAIL  (<score>/100)
  Rule 11 — Deps locked:          PASS | PARTIAL | FAIL  (<score>/100)
  Rule 12 — No dynamic magic:     PASS | PARTIAL | FAIL  (<score>/100)

  OVERALL: <average>/100

CRITICAL VIOLATIONS (must fix)
  - <rule> — <file:line> — <issue>

TOP 5 IMPROVEMENTS (highest impact)
  1. <what to do and why>
  2. ...

EXEMPLARS (things done well)
  - <rule> — <file:line> — <what's good>
```

4. **Present findings to the user.** Group by severity:
   - Critical violations that need immediate attention
   - Partial compliance that could be improved
   - Rules that are well-followed (reinforcement)

5. **Offer next steps:**
   - "Want me to fix the critical violations?"
   - "Want a detailed breakdown of any specific rule?"
   - "Want me to create tasks in the tracker for each improvement?"

## Integration with /codecraft

The audit can be used at several points in the codecraft workflow:

- **Before /orient:** Audit an unfamiliar codebase before starting work
- **During /understand:** As part of codebase exploration (Phase 2 of /codecraft)
- **During /verify Pass 3:** Check that new code follows the rules
- **Standalone:** Run anytime to assess codebase health

## The 80/20 Starter Policy

If the full 12-rule audit is overwhelming, focus on the 5 rules that give
80% of the benefit:

1. Pure imports (no side effects) — Rule 2
2. Single entrypoint bootstraps config/logging/DI — Rule 1
3. Strict typing on public APIs + CI gate — Rule 3
4. ruff/format + pre-commit + CI gate — Rule 10
5. Explicit package boundaries + side effects at edges — Rules 4 + 8

Report these 5 separately as the "starter policy score" alongside the full audit.
