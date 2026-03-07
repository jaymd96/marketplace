# Codecraft — Entry Point

**Read this document when starting execution work. It routes you to the right
state and the right workflow.**

## Two Models, One System

This system uses two complementary models — the same architecture as spec-builder
but for execution instead of specification:

**The Arc** — the high-level progression of a task. It tells you what kind of
work needs to happen and in roughly what order. It's the map.

**The Modes** — what you actually do moment-to-moment. You switch between them
as the work demands.

The arc guides. The modes operate. Neither works without the other.

## The Arc (the map)

Every task follows a natural progression:

```
Orient → Understand → Design → Build → Verify → Ship
```

| Stage | What happens | You're mostly in... |
|-------|-------------|---------------------|
| **Orient** | Context recovery: tracker, git log, stuck notes | Session mode |
| **Understand** | Read spec, read code, identify scope | Analysis mode |
| **Design** | Plan changes, order them, define tests | Planning mode |
| **Build** | Implement one unit at a time with checks | Construction mode |
| **Verify** | Three-pass quality gate | Validation mode |
| **Ship** | Commit, push, update tracker | Delivery mode |

**The progression is real.** You can't design before you understand. You can't
verify before you build. The information dependencies are genuine.

**But the arc is not a gate.** While building, you'll discover you misunderstood
something (→ back to understand). While verifying, you'll find issues (→ refine
or rethink). The arc describes the center of gravity, not a rigid sequence.

## Autonomous Invocation

Codecraft works in both **interactive** (human present) and **autonomous**
(`claude -p`) modes. The arc and modes are identical in both cases -- only
the invocation mechanism differs.

**Interactive mode:** The user invokes skills directly via `/orient`,
`/design`, `/verify`, etc. The human decides when to transition between
stages and can skip or reorder as judgment dictates.

**Autonomous mode:** The agent reads this ENTRYPOINT.md and follows the arc
naturally from ORIENT through to HANDOFF/EXIT. The session state machine
(see `system/workflows/session.md`) governs the lifecycle:
`ORIENT -> SELECT -> EXECUTE -> HANDOFF -> EXIT`. No human intervention
is expected or required.

**Project-specific configuration** comes from `.codecraft.local.md` in the
project root. This file uses YAML frontmatter for structured config followed
by markdown prose for project context:

```yaml
---
tracker: docs/engineering/tracker.md
test_command: python3 -m pytest tests/ -x -q
enforce_commands:
  - ruff check apollo
  - ruff format --check apollo
conventions:
  line_length: 100
  target_python: "3.11"
---

# Project Context

Additional prose context about the project, its architecture, conventions,
and anything the agent should know when working autonomously.
```

The `/orient` skill searches for this file automatically during context
recovery.

## The Modes (how you operate)

Each mode maps to a skill that can be invoked interactively:

| Mode | Skill | Workflow |
|------|-------|----------|
| Analysis | `/understand` | `system/workflows/analysis.md` |
| Planning | `/design` | `system/workflows/planning.md` |
| Construction | *(direct -- follow the build loop)* | `system/workflows/construction.md` |
| Validation | `/verify` | `system/workflows/validation.md` |
| Delivery | `/handoff` | `system/workflows/delivery.md` |

Construction mode has no dedicated skill because it is the core build loop
described in the construction workflow. The agent executes it directly using
the change list produced by `/design`.

### Analysis Mode
You're reading and comprehending. No code changes.

**When to adopt:** Starting a task. Encountering unfamiliar code. After a
RETHINK. When the spec references modules you haven't read.

**What to do:**
- Read the spec file completely
- Read every module the spec mentions
- Read existing tests for affected areas
- Identify patterns to follow
- Build a mental model of what needs to change

**Exit guard:** You can answer: What is the goal? Which files change? What
patterns should I follow? What tests exist?

### Planning Mode
You're designing the approach. Writing a plan, not code.

**When to adopt:** After analysis, when you understand the task well enough
to decompose it into units.

**What to do:**
- List every change needed (file + what changes)
- Order changes by dependency (foundations first)
- For each change, note how to verify it independently
- Identify risks and unknowns

**Exit guard:** You have a numbered list of changes, ordered, with verification
strategy for each.

### Construction Mode
You're writing code. One unit at a time with checks.

**When to adopt:** After planning, when you have a concrete change list.

**What to do:**
For each unit in the plan:
1. READ the file(s) you're about to modify
2. CHANGE — make one logical change
3. CHECK — quick-verify this unit:
   - New module: `python3 -c "from module import NewClass"`
   - Modified code: `pytest tests/module/test_file.py -x -q`
   - New test: `pytest tests/path.py::TestClass -x -q`
4. FIX if CHECK fails (targeted, not rewrite)

**When to switch away:** A unit fails CHECK repeatedly (→ rethink). You realize
the design is wrong (→ back to planning). You discover you misunderstood
something (→ back to analysis).

### Validation Mode
You're verifying the complete solution. Three passes, all must pass.

**When to adopt:** All planned units are implemented and individually checked.

**Pass 1 — Correctness:**
Run the full test suite. All tests must pass.

**Pass 2 — Compliance:**
Run all enforcement/ratchet checks. No new violations.

**Pass 3 — Quality (self-review):**
Read the complete diff. Check: matches spec? No scope creep? No debug code?
No dead code? Naming consistent? Would a reviewer approve?

**When to switch away:** Any pass fails (→ refine, which is construction mode
with a targeted fix). All passes pass (→ delivery mode).

### Delivery Mode
You're packaging and shipping. Commit, push, update tracker.

**When to adopt:** All three validation passes succeeded.

**What to do:**
- `git add` specific files (not `git add -A`)
- Commit with descriptive message
- Pull and resolve any conflicts
- Push
- Update tracker status to done
- Remove lock file
- Print AGENT_DONE

## Recovery Paths

### REFINE (validation failed)
A specific check failed. Fix it.

1. Identify the specific failure
2. Hypothesize root cause
3. Make a targeted fix
4. Re-run validation

**Escalation:** If the same failure recurs 3+ times, escalate to RETHINK.
Repeating the same fix is not progress -- it means the approach is wrong.

### RETHINK (approach isn't working)
Stop fixing symptoms. The approach is wrong.

1. Write a diagnosis: "My approach failed because ___"
2. Identify what was wrong: misunderstood spec? wrong abstraction? missing dependency?
3. Choose: redesign (→ planning mode) or re-analyze (→ analysis mode)
4. Preserve the failed attempt (don't delete — future context)

**Escalation:** If the spec itself is unclear or contradictory and you cannot
resolve the ambiguity by re-reading, flag it in a stuck note and move to the
next eligible task. Do not burn budget trying to divine intent from an
ambiguous spec.

### STUCK (can't make progress)
You've rethought and still can't solve it.

1. Write a stuck note explaining:
   - What you tried (specific approaches, not vague descriptions)
   - What failed (exact errors, test output, or logical contradictions)
   - What you think the blocker is (missing context, spec gap, architectural constraint)
2. Commit what you have
3. Update tracker with notes
4. HANDOFF to the next session

## Budget Awareness

Budget is a parallel concern — not a state, but a modifier on behavior:

| Remaining | Behavior |
|-----------|----------|
| > 70% | Normal. Full iteration through all modes. |
| 30-70% | Finish current unit, then validate → ship. Skip polish. |
| < 30% | HANDOFF now. Commit what you have. Write progress note. |
| < 10% | Emergency: `git add -A && git commit`. Stuck note. EXIT. |

## Anti-Patterns

These are the failure modes this system is designed to prevent:

| Anti-pattern | Symptom | Correct behavior |
|-------------|---------|-----------------|
| One-shotting | Write all code, then test | Build one unit, check it, build next |
| Wishful fixing | Change random things until tests pass | Identify root cause, targeted fix |
| Scope creep | Refactor unrelated code while building | Stay in scope. Note for future. |
| Skipping verification | Commit without enforcement checks | Three passes. All must pass. |
| Infinite loops | Fix → fail → fix → fail (5+ rounds) | Escalate to RETHINK after 3 |
| Shallow understanding | Skim spec, start coding | Analysis mode has exit guards |
| Design-free building | Jump from spec to code | Planning mode produces change list |

## The Real Work

Before anything else: **the state machine is not the work.**

The work is thinking clearly about the problem and writing correct code. The
state machine exists so you don't skip important steps, iterate when needed,
and escalate when stuck. If you're spending more time on process than on code,
you've inverted the priority.

The test: after all that reading and planning, did your understanding actually
improve? After verification, is the code actually better? If not, you're
performing process, not executing it.
