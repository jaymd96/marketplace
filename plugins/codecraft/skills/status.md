---
name: status
description: "Quick snapshot of current state. Shows which state machine you're in, what's done, what's next, budget remaining. Use anytime to check where you are."
---

# status

Print a concise snapshot of current execution state. No file changes, no
analysis — just report where you are. Keep it under 15 lines.

## What to Report

Read current context (tracker, lock files, git status) and produce:

```
EXEC STATUS
===========
Session:  <ORIENT | SELECT | EXECUTE | HANDOFF>
Task:     <task ID or "none selected">
Phase:    <UNDERSTAND | DESIGN | BUILD | VERIFY | SHIP | RETHINK>
Unit:     <N/M — current build unit out of total, if in BUILD>

Done this session:
  - <completed item 1>
  - <completed item 2>

Next:
  <what happens next — specific action, not vague>

Issues:
  <any blockers, stuck loops, or warnings — or "none">
```

## Rules

- Read the tracker and lock files to determine state. Do not guess.
- If no task is selected, session state is ORIENT or SELECT.
- If a task is locked, report which phase of that task you're in.
- If in BUILD, report which unit number you're on from the /design plan.
- Keep it factual. No recommendations — that's /orient's job.
- If the user asks for status mid-build, don't interrupt the build flow.
  Report and continue.
