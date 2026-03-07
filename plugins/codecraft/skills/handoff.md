---
name: handoff
description: "End of session or task. Commits work, updates tracker, writes progress notes. Use when done with a task, when budget is running low, or at session end."
---

# handoff

This skill implements **Delivery Mode** (see `system/workflows/delivery.md`).

Package completed work for delivery or continuation. Handles both successful
completion and partial-progress handoff.

## Complete Task (all verification passed)

1. **Stage specific files.** Use `git add <file1> <file2> ...` for each changed
   file. Never use `git add -A` or `git add .` — these catch unintended files.

2. **Commit with task reference.** Write a descriptive commit message that
   references the task ID:
   ```
   feat(<area>): <what was done>

   Implements <TASK_ID>. <1-2 sentences of context if needed.>
   ```

3. **Update tracker.** Change the task's status from `in-progress` to `done`.
   Add completion timestamp if the tracker format supports it.

4. **Pull and resolve conflicts.** Run `git pull origin main --no-edit` to incorporate any
   upstream changes. Resolve conflicts if they arise; re-run /verify after
   conflict resolution.

5. **Push** if operating in a multi-agent or remote setup.

6. **Remove lock file.** Delete `current_tasks/<TASK_ID>.lock`.

7. **Print completion marker:**
   ```
   AGENT_DONE: <TASK_ID> -- completed
   ```

## Partial Handoff (budget low or session ending)

When you can't finish the task, preserve maximum context for the next session:

1. **Commit what you have.** Stage and commit completed units, even if the
   task isn't fully done. Use a message like:
   ```
   wip(<area>): partial progress on <TASK_ID>

   Completed units 1-3 of 7. See progress note for details.
   ```

2. **Write a progress note.** Create or update a note file explaining:
   - Which units from the /design plan are complete
   - Which unit is in progress and its current state
   - What remains to be done
   - Any blockers, insights, or gotchas discovered
   - Failed approaches (so the next session doesn't repeat them)

3. **Update tracker.** Set status to `in-progress` with a note about partial
   completion.

4. **Keep the lock file.** The task is still claimed.

5. **Print handoff marker:**
   ```
   AGENT_DONE: <TASK_ID> -- partial (units 1-3/7 complete)
   ```

## Emergency Handoff (budget critical, <10%)

When budget is nearly exhausted:

1. `git add` all changed files
2. `git commit -m "wip: emergency handoff <TASK_ID>"`
3. Write a minimal stuck note with current state
4. Print: `AGENT_DONE: <TASK_ID> -- emergency handoff`

Don't spend remaining budget on polish. Save it for the commit.

## Progress Note Template

When writing a progress note for incomplete work, include:

```
# <TASK_ID> -- Progress Note
**Session:** <date/time>
**Status:** partial | blocked | stuck

## Completed
- <list of completed units from the change list>

## In Progress
- <current unit and its state>

## Remaining
- <list of uncompleted units>

## Context for Next Session
- <key insights, failed approaches, important findings>
- <any gotchas the next session should know about>
```
