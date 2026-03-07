# codecraft

The craft of turning specifications into working software — iterative,
verification-gated, state machine-driven development.

**Where spec-builder turns conversation into specs, codecraft turns specs
into code.** They're two halves of the same pipeline.

## Operating Model: Three Nested State Machines

This plugin embodies a development methodology — not a checklist.

### Level 1: Session (manages budget, task selection, handoff)
```
ORIENT → SELECT → EXECUTE → HANDOFF → EXIT
```

### Level 2: Task (manages approach, iteration, shipping)
```
UNDERSTAND → DESIGN → BUILD → VERIFY → SHIP
                ▲                 │
                └── RETHINK ◄─ REFINE
```

### Level 3: Build Unit (manages each individual change)
```
READ → CHANGE → CHECK → next unit
  ↑              │
  └── FIX ◄──────┘
```

Every state has **entry guards** (conditions to enter) and **exit guards**
(conditions to leave). You iterate until guards are met, never skip states,
and escalate when stuck.

## When to Use These Skills

### Session lifecycle
- **/orient** — Start of any session. Read tracker, understand context, identify
  what to work on. Use FIRST before any other skill.
- **/select** — Pick a task from the tracker. Validates dependencies, creates lock,
  reads the spec. Use after orient.
- **/handoff** — End of session or task. Commits, updates tracker, writes progress.
  Use when done or when budget is running low.

### Task execution
- **/understand** — Deep-read a spec and the code it references. Produces a
  structured understanding document. Use before designing a solution.
- **/design** — Plan changes before writing code. Produces an ordered change list
  with verification strategy. Use after understand, before any implementation.
- **/verify** — Run the full three-pass quality gate (correctness, compliance,
  quality). Use after build is complete.

### Recovery
- **/rethink** — Step back from a failing approach. Diagnose why it failed,
  propose an alternative. Use when REFINE has looped 3+ times.
- **/status** — Quick snapshot of current state: which state machine you're in,
  what's done, what's next, budget remaining.

## Key Principles

1. **Never one-shot.** Build one unit, check it, build the next. The BUILD state
   machine enforces this — READ → CHANGE → CHECK for each unit.

2. **Verify before shipping.** Three passes: correctness (tests), compliance
   (ratchets), quality (self-review). All three must pass.

3. **Escalate, don't thrash.** If the same issue fails → gets fixed → fails again
   3 times, stop fixing and RETHINK the approach.

4. **Budget awareness is constant.** Every state checks remaining budget and
   adjusts behavior: full iteration (>70%), wind down (30-70%), emergency
   handoff (<30%).

5. **Design before build.** The DESIGN state produces a concrete change list. You
   can't enter BUILD without one. This prevents "let me just start coding."

6. **The state machine is the methodology.** It's not a suggestion — it's the
   operating model. Skip a state and you'll pay for it later.

## Subagents

- **verifier** — Runs all three verification passes in isolated context. Keeps
  verbose linter/test output out of the main conversation.
- **reviewer** — Self-reviews the diff against the spec and codebase conventions.
  Catches scope creep, dead code, and naming inconsistencies.
- **diagnoser** — When tests fail, analyzes the failure in isolation. Returns
  root cause and suggested fix, not raw stack traces.

## Hooks

- **PostToolUse (Edit/Write)** — Auto-formats Python files with ruff after every edit.
- **PreToolUse (Bash: git commit)** — Runs quick enforcement checks before any commit.

## Project Configuration

The plugin reads a `.codecraft.local.md` file (if present) for project-specific
configuration:

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
  id_type: RID
---

## Project Context

- Hub/Spoke architecture. Hub is FastAPI, Spoke is Burr.
- Always use RIDs, never integer IDs.
- State machines via `transitions` library.
```

All fields are optional. If `lock_dir` or `stuck_notes_dir` are omitted,
codecraft defaults to `current_tasks/` and `stuck_notes/` in the project root.

## Relationship to Other Plugins

| Plugin | Level | What it does | How codecraft relates |
|--------|-------|-------------|----------------------|
| spec-builder | Process | Conversation → specs | codecraft consumes specs |
| pytest-testing | Tool | Write/run tests | codecraft invokes in VERIFY |
| python-toolkit | Tool | Coding standards + libs | codecraft follows its rules |

codecraft is the **orchestrator** — it knows _when_ to test, _when_ to lint,
_when_ to review. The tool-level plugins know _how_.
