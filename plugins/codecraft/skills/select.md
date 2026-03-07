---
name: select
description: "Pick a task from the tracker and lock it. Validates dependencies are met, creates a lock, reads the spec. Use after orient to claim a specific task."
---

# select

Claim a task and prepare to execute it. Runs after /orient has established
context.

## Steps

1. **Find eligible tasks.** Read the tracker. The tracker is a markdown file
   with task tables. Each row has: ID, status (`todo`/`in_progress`/`done`/
   `blocked`), spec path, and dependencies. Parse the table to find eligible
   tasks: those with status `todo` whose dependencies are all `done`. If the
   user specified a task ID, validate that task is eligible.

2. **Check for existing locks.** If a lock file exists in `current_tasks/`
   for another task, that task should be resolved first (finish it or explicitly
   abandon it). Don't claim two tasks simultaneously.

3. **Create the lock.** Write a lock file at `current_tasks/<TASK_ID>.lock`
   containing: task ID, timestamp, session context. This signals to other
   agents that this task is claimed.

4. **Read the spec.** Open the spec file referenced by the tracker for this
   task. Read it completely.

5. **Read referenced source files.** Identify every module, file, or directory
   the spec mentions. Read them now — don't wait until build time.

6. **Transition to UNDERSTAND.** The task is locked and spec is loaded.
   Proceed to /understand for deep analysis.

## Output

```
TASK SELECTED
=============
Task:        <ID>
Spec:        <path to spec file>
Summary:     <1-2 sentence description>
Files:       <list of files that will change>
Deps met:    <list of completed dependency tasks>
Lock:        <path to lock file>

Ready for /understand
```

## Edge Cases

- **No eligible tasks:** All remaining tasks have unmet dependencies or are
  blocked. Report this and suggest reviewing blockers.
- **User picks a blocked task:** Explain which dependencies are unmet. Suggest
  working on those first.
- **Stale lock exists:** If a lock file exists from a previous session with no
  progress, remove it and reclaim.
