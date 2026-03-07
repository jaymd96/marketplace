---
name: design
description: "Plan changes before writing code. Produces an ordered change list with verification strategy for each unit. Use after /understand, before any implementation."
---

# design

Convert understanding into a concrete, ordered plan. This is the blueprint
for the BUILD phase. No code changes yet — only planning.

## Steps

1. **List every change.** For each modification needed, specify:
   - File path (absolute)
   - What changes (new function, modified class, new test, etc.)
   - Why this change is needed (trace back to spec requirement)

2. **Order by dependency.** Arrange changes so each unit can be verified
   independently:
   - Models and data structures first
   - Utility functions before their consumers
   - Core logic before API routes
   - Implementation before tests (unless TDD is specified)
   - Tests alongside or after each implementation unit

3. **Define verification for each unit.** Every change must have a quick
   check that confirms it works in isolation:
   - New module: `python3 -c "from package.module import NewClass"`
   - New function: `python3 -c "from package.module import func; print(func(test_input))"`
   - Modified code: `python3 -m pytest tests/specific_test.py -x -q`
   - New test file: `python3 -m pytest tests/new_test.py -x -q`
   - Config change: `python3 -c "from package.config import Settings; print(Settings())"`

4. **Identify risks.** For each unit, note:
   - What could go wrong
   - What's uncertain
   - What depends on external state (database, filesystem, network)

5. **Group into phases** if the task is large (>5 units). Each phase should
   produce a verifiable milestone.

## Exit Guard

You cannot proceed to BUILD until you have:
- A numbered, ordered list of change units
- A verification command for each unit
- Risks identified (even if the list is "none apparent")

## Output Format

```
CHANGE PLAN
===========
Task: <ID>

Phase 1: <description>
  1. <file> — <what changes>
     Verify: <command>
  2. <file> — <what changes>
     Verify: <command>

Phase 2: <description>
  3. <file> — <what changes>
     Verify: <command>

Risks:
  - <risk 1>
  - <risk 2>
```

This plan becomes the BUILD roadmap. Execute units in order, checking each
one before proceeding to the next.
