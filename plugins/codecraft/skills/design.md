---
name: design
description: "Plan changes before writing code using parallel architect agents to explore alternatives. Produces an ordered change list with verification strategy. Use after /understand, before any implementation."
---

# design

Convert understanding into a concrete, ordered plan. This is the blueprint
for the BUILD phase. No code changes yet — only planning.

## Steps

1. **Launch 2-3 parallel architect agents.** Each explores a different
   implementation approach simultaneously:

   - **Architect 1 — Minimal changes:** Least-invasive approach. Smallest
     set of changes that satisfies the spec. Use the `codecraft:architect`
     agent with directive "minimal changes".

   - **Architect 2 — Clean architecture:** Principles-first approach. Right
     abstractions even if it means more files. Use the `codecraft:architect`
     agent with directive "clean architecture".

   - **Architect 3 — Pragmatic balance:** Hybrid approach balancing minimal
     changes with good structure. Use the `codecraft:architect` agent with
     directive "pragmatic balance".

   For simple tasks (< 3 files), skip parallel agents and design directly.

2. **Synthesize and recommend.** After agents return, compare approaches:
   - Present each option with scope (files created/modified), pros, and cons
   - Make a specific recommendation with rationale
   - Ask the user which approach they prefer

3. **Produce the change plan** from the selected approach:

   For each modification, specify:
   - File path
   - What changes (new function, modified class, new test, etc.)
   - Why this change is needed (trace back to spec requirement)

4. **Order by dependency.** Arrange changes so each unit can be verified
   independently:
   - Models and data structures first
   - Utility functions before their consumers
   - Core logic before API routes
   - Tests alongside or after each implementation unit

5. **Define verification for each unit.** Every change must have a quick
   check that confirms it works in isolation:
   - New module: `python3 -c "from package.module import NewClass"`
   - Modified code: `python3 -m pytest tests/specific_test.py -x -q`
   - New test file: `python3 -m pytest tests/new_test.py -x -q`

6. **Identify risks.** For each unit, note:
   - What could go wrong
   - What's uncertain
   - What depends on external state

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
Approach: <selected option and rationale>

Phase 1: <description>
  1. <file> — <what changes>
     Verify: <command>
  2. <file> — <what changes>
     Verify: <command>

Risks:
  - <risk 1>
  - <risk 2>
```

This plan becomes the BUILD roadmap. Execute units in order, checking each
one before proceeding to the next.
