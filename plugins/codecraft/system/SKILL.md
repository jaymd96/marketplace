# Codecraft

Turn specifications into working software through iterative, verification-gated
development.

## When to Use

Trigger when the user wants to:
- Implement a feature from a specification
- Execute tasks from an engineering tracker
- Build code iteratively with verification at each step
- Run autonomous agent sessions against a work plan

## What This Is

This is a harness — an operational environment that makes an AI agent effective
at a specific kind of knowledge work: turning specifications into correct,
tested, shippable code through disciplined iteration.

Where spec-builder extracts specifications from conversation, codecraft
executes those specifications as working software. They are two halves of the
same pipeline.

The agent's effectiveness is bounded by the environment it operates in. This
system provides:

- **Context** — progressive disclosure from ENTRYPOINT.md through mode-specific
  workflows, with project configuration via `.codecraft.local.md`
- **Capabilities** — analysis tools (spec reading, codebase exploration),
  construction tools (unit-by-unit building with verification), quality tools
  (three-pass validation gate)
- **Constraints** — state machine transitions that prevent skipping steps,
  budget awareness that prevents overcommitment, anti-patterns that prevent
  common failure modes
- **Recovery** — REFINE for targeted fixes, RETHINK for approach changes,
  STUCK for graceful handoff when blocked

## Entry Point

**Always start by reading `ENTRYPOINT.md` in this directory.** It will tell you:
1. Where you are in the execution arc
2. What mode to operate in
3. What to do next

Do not skip ENTRYPOINT.md. Do not guess the state. Read it every time.

## Core Principles

1. **Never one-shot.** Build one unit, check it, build the next. The build loop
   enforces this — READ → CHANGE → CHECK for each unit.
2. **Verify before shipping.** Three passes: correctness (tests), compliance
   (ratchets), quality (self-review). All three must pass.
3. **Escalate, don't thrash.** If the same issue fails 3+ times, RETHINK the
   approach instead of fixing symptoms.
4. **Design before build.** A numbered change list with verification strategy
   per unit. No change list, no building.
5. **Budget awareness is constant.** Every mode checks remaining budget. Wind
   down at 30%, emergency handoff at 10%.
6. **The state machine is the methodology.** Skip a state and you'll pay for it
   later.

## Directory Layout

```
codecraft/
  plugin.toml                    # Plugin manifest
  CLAUDE.md                      # Plugin documentation

  agents/                        # Subagents (isolated context)
    verifier.md                  # Three-pass verification gate
    reviewer.md                  # Diff-vs-spec code review
    diagnoser.md                 # Test failure root cause analysis

  skills/                        # Invocable commands
    orient.md                    # Session start — context recovery
    select.md                    # Pick and lock a task
    understand.md                # Deep-read spec and code
    design.md                    # Plan changes before coding
    verify.md                    # Three-pass quality gate
    handoff.md                   # Session end — commit, update, exit
    rethink.md                   # Approach recovery
    status.md                    # Quick state snapshot

  hooks/                         # Automated checks
    hooks.json                   # PostToolUse (format), PreToolUse (commit guard)

  scripts/                       # Mechanical validation
    validate-state.sh            # Project structure sanity check

  system/                        # The harness
    SKILL.md                     # Trigger conditions, principles, layout
    ENTRYPOINT.md                # Session router (read every time)
    workflows/                   # Mode reference files
      analysis.md                # Mode: reading, comprehending
      planning.md                # Mode: designing the approach
      construction.md            # Mode: building one unit at a time
      validation.md              # Mode: three-pass quality gate
      delivery.md                # Mode: commit, push, update
```

## Relationship to Other Plugins

| Plugin | Role | How codecraft relates |
|--------|------|------------------------|
| spec-builder | Specs from conversation | codecraft consumes specs |
| pytest-testing | Write and run tests | codecraft invokes in VERIFY |
| python-toolkit | Coding standards | codecraft follows its rules |

codecraft is the **orchestrator** — it knows _when_ to test, _when_ to lint,
_when_ to review. The tool-level plugins know _how_.
