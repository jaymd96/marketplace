---
name: orient
description: "Start of session. Read tracker, recover context, identify what to work on. Use FIRST before any other skill, when resuming work, at session start, or when saying 'where are we'."
---

# orient

Recover full context before doing anything else. This is always the first
skill invoked in a session.

## Steps

1. **Read project config.** Find and read `.codecraft.local.md`. Search in
   this order:
   1. Current working directory
   2. Git repository root (`git rev-parse --show-toplevel`)

   If found, parse the YAML frontmatter to extract: tracker path,
   test_command, enforce_commands, conventions. Read the markdown body for
   additional project context.

   If not found, proceed with defaults and ask the user for tracker location
   and test command.

2. **Read the tracker.** Open the tracker file. Parse the task list: identify
   each task's ID, status (todo/in-progress/done/blocked), dependencies, and
   any notes from previous sessions.

3. **Check for in-progress work.** Look for lock files in `current_tasks/` or
   equivalent. If a lock exists, that task was mid-flight when the last session
   ended. Read any associated progress notes or stuck notes.

4. **Read recent git history.** Run `git log --oneline -10` to see what was
   committed recently. Cross-reference with tracker status.

5. **Check for stuck notes.** Look for files left by previous RETHINK or HANDOFF
   operations. These contain diagnosis of failed approaches — critical context
   to avoid repeating mistakes.

## Output

Produce a structured briefing (15-25 lines):

```
SESSION BRIEFING
================
Project:     <name>
Tracker:     <path>
Test cmd:    <command>

PROGRESS
  Done:      <count> / <total> tasks
  Current:   <task ID if locked, else "none">
  Next:      <task ID — first todo with deps met>

RECENT ACTIVITY
  <last 3-5 commits, one line each>

BLOCKERS / NOTES
  <any stuck notes, warnings, or context from previous sessions>

RECOMMENDATION
  <what to do next: resume locked task, or select next available>
```

After orient, transition to /select to claim a task, or resume the locked one.
