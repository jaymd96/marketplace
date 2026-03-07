# codecraft

The craft of turning specifications into working software — iterative,
verification-gated, state machine-driven development.

**Where spec-builder turns conversation into specs, codecraft turns specs
into code.** They're two halves of the same pipeline.

## Quick Start

**`/codecraft [task description or ID]`** — Full-lifecycle command that orchestrates
everything: explore codebase with parallel agents, design with architectural
alternatives, build incrementally, verify with confidence-scored reviewers, and ship.

For manual control, use individual skills in order:
`/orient` → `/select` → `/understand` → `/design` → (build) → `/verify` → `/handoff`

## Operating Model

### The Arc

Every task follows a natural progression with gates between phases:

```
Orient → Explore → Design → Build → Verify → Ship
           ↑                   ↑         │
           └─── RETHINK ◄──── └── REFINE ┘
```

**The /codecraft command runs this entire arc** with explicit user confirmation
at key decision points. Individual skills let you run any phase manually.

### The Build Loop

Construction is the inner loop — one unit at a time with verification:

```
READ → CHANGE → CHECK → next unit
  ↑              │
  └── FIX ◄──────┘ (3 failures → RETHINK)
```

### Recovery Paths

- **REFINE:** Verification failed. Targeted fix, then re-verify all passes.
- **RETHINK:** Same failure 3+ times. Stop fixing symptoms, diagnose the
  approach, redesign or re-explore.
- **STUCK:** Rethinking didn't help. Write stuck note, commit what you have,
  handoff to next session.

## Skills

| Skill | Phase | Purpose |
|-------|-------|---------|
| `/orient` | Session start | Read tracker, recover context, identify next work |
| `/select` | Task claim | Pick task, create lock, read spec |
| `/understand` | Exploration | **Parallel explorer agents** trace code paths, map patterns |
| `/design` | Architecture | **Parallel architect agents** propose alternatives, user picks |
| `/verify` | Validation | 4-pass gate: correctness, compliance, review, **governance audit on new code** |
| `/handoff` | Delivery | Commit, update tracker, clean up |
| `/rethink` | Recovery | Diagnose failing approach, propose alternative |
| `/audit` | Health check | **Parallel auditor agents** score codebase against 12 governance rules |
| `/status` | Diagnostic | Quick state snapshot (no changes) |

## Agents

| Agent | Purpose | Model |
|-------|---------|-------|
| **explorer** | Trace execution paths, map architecture, extract patterns | sonnet |
| **architect** | Design implementation blueprints with specific files and sequences | opus |
| **auditor** | Score codebase against 12 governance rules (3 parallel groups) | opus |
| **reviewer** | Confidence-scored code review (>=80% threshold, no nitpicks) | opus |
| **verifier** | Run correctness + compliance passes in isolated context | sonnet |
| **diagnoser** | Root cause analysis for test failures | sonnet |

Agents are designed for **parallel execution**: /understand launches 2-3
explorers simultaneously, /design launches 2-3 architects with different
approaches, /verify launches 3 reviewers examining different dimensions.

## Hooks

- **PostToolUse (Edit/Write)** — Auto-formats Python files with ruff after every edit.
- **PreToolUse (Bash)** — Guards git commits: checks validation passed, specific
  files staged, commit message references task ID.

## Key Principles

1. **Never one-shot.** Build one unit, check it, build the next.
2. **Explore before designing.** Parallel agents trace the codebase first.
3. **Present alternatives.** Architect agents propose different approaches.
4. **Verify with confidence.** Only surface review issues >=80% confidence.
5. **Audit every change.** New code is checked against 12 governance rules in Pass 4.
6. **Escalate, don't thrash.** 3 failures on same issue → RETHINK.
7. **Budget awareness.** Behavior changes at 70%, 30%, and 10% thresholds.
8. **Design before build.** Can't enter BUILD without a change plan.
9. **User gates.** Confirm scope, approve architecture, review findings.

## Project Configuration

The plugin reads `.codecraft.local.md` (if present) for project-specific config:

```yaml
---
tracker: docs/engineering/tracker.md
test_command: "python3 -m pytest tests/ -x -q"
enforce_commands:
  - "ruff check ."
  - "ruff format --check ."
lock_dir: current_tasks
stuck_notes_dir: stuck_notes
conventions:
  line_length: 100
  python_target: "3.11+"
---

## Project Context

Additional prose context about the project architecture and conventions.
```

## Relationship to Other Plugins

| Plugin | Role | How codecraft relates |
|--------|------|----------------------|
| spec-builder | Conversation → specs | codecraft consumes specs |
| pytest-testing | Write/run tests | codecraft invokes in VERIFY |
| python-toolkit | Coding standards + libs | codecraft follows its rules |

codecraft is the **orchestrator** — it knows _when_ to test, _when_ to lint,
_when_ to review. The tool-level plugins know _how_.
