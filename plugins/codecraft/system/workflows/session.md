# Session State Machine

The session state machine governs the lifecycle of an autonomous agent session.
It is orthogonal to the mode system (Analysis, Planning, Construction, Validation,
Delivery) -- modes describe *what kind of work* you're doing; session states
describe *where you are in the session lifecycle*.

```
ORIENT --> SELECT --> EXECUTE --> HANDOFF --> EXIT
  |          |          |            |
  |          |          +---(loop)---+  (partial: re-enter EXECUTE or HANDOFF)
  |          |          |
  |          +----------+  (no eligible tasks: skip to HANDOFF)
  |
  +--- (context recovery failed: ask user, retry)
```

## States

### ORIENT

**Purpose:** Recover context. Understand where the project is and what needs
doing.

**When to enter:** Session start. Always. No exceptions.

**What happens:**
- Read `.codecraft.local.md` for project configuration
- Read the tracker to understand project state
- Check for in-progress locks and stuck notes
- Read recent git history
- Produce a session briefing

**Entry guard:** None -- this is always the first state.

**Exit guard:** You have a session briefing with: tracker location, task
counts, current/next task identification, and any blockers or notes from
previous sessions.

**Skill:** `/orient`

---

### SELECT

**Purpose:** Claim a task and prepare to work on it.

**When to enter:** After ORIENT, when you know the project state.

**What happens:**
- Identify the highest-priority eligible task: status is `todo`, all
  dependencies have status `done`
- If multiple tasks are eligible, pick the one with the highest priority
  (lowest ID, or explicit priority field if the tracker has one)
- Validate no conflicting locks exist
- Create a lock file at `current_tasks/<TASK_ID>.lock` with task ID, timestamp,
  and session identifier
- Read the task's spec file completely

**Entry guard:** ORIENT completed. Session briefing produced.

**Exit guard:** Lock file created. Spec file read. You can state the task's
goal in one sentence.

**Edge cases:**
- No eligible tasks: all remaining tasks are blocked or have unmet
  dependencies. Transition directly to HANDOFF with a note explaining
  the blocker.
- Stale lock from previous session: if a lock file is older than 2 hours
  and there is no evidence of active work (no recent commits referencing
  the task), force-remove the stale lock and reclaim the task.
- In-progress task from previous session: resume it rather than selecting
  a new one. Read any progress notes.

**Skill:** `/select`

---

### EXECUTE

**Purpose:** Do the work. This is where the mode system operates.

**When to enter:** After SELECT, when you have a locked task with a loaded
spec.

**What happens:**
This state contains the full mode cycle:
1. Analysis mode (`/understand`) -- read and comprehend
2. Planning mode (`/design`) -- decompose into units
3. Construction mode -- build one unit at a time
4. Validation mode (`/verify`) -- three-pass quality gate

The EXECUTE state loops internally through these modes. Recovery paths
(REFINE, RETHINK) also happen within EXECUTE.

**Entry guard:** Task is locked. Spec is loaded.

**Exit guard:** Either:
- All three validation passes succeeded (transition to HANDOFF for delivery)
- Budget threshold crossed (transition to HANDOFF for partial handoff)
- STUCK state reached (transition to HANDOFF with stuck note)

**Budget-driven exits:** See Budget Awareness below. Budget checks happen
continuously during EXECUTE, not just at mode transitions.

---

### HANDOFF

**Purpose:** Package work for delivery or continuation. This state handles
both successful completion and partial-progress handoff.

**When to enter:**
- After EXECUTE, when validation passes (successful delivery)
- During EXECUTE, when budget drops below 30% (partial handoff)
- During EXECUTE, when STUCK (handoff with stuck note)
- After SELECT, when no eligible tasks exist (empty handoff)

**What happens:**
1. **Commit work.** Stage specific files with `git add <file>`. Commit with
   a descriptive message referencing the task ID.
2. **Update tracker.** Set status to `done` (if complete) or `in-progress`
   with notes (if partial).
3. **Write progress note.** For partial handoff, write a progress note
   documenting: completed units, current unit state, remaining work, context
   for next session, failed approaches.
4. **Remove lock.** Delete `current_tasks/<TASK_ID>.lock` (if task is done).
   Keep the lock if work is partial and the task should be resumed.
5. **Signal completion.** Print `AGENT_DONE: <TASK_ID> -- <outcome>`.

**Entry guard:** You are in a state where work should be preserved (completed,
partially completed, or explicitly stuck).

**Exit guard:** Work is committed. Tracker is updated. Lock is handled
appropriately. Completion signal printed.

**Skill:** `/handoff`

---

### EXIT

**Purpose:** Session is over. No more work.

**When to enter:** After HANDOFF completes.

**What happens:** Nothing. The session terminates. The harness or user
decides whether to start a new session.

**Entry guard:** HANDOFF completed successfully.

**Exit guard:** N/A -- terminal state.

---

## Budget Awareness

"Budget" is the session's token/cost budget set by the execution profile
(e.g., `$5/session`, `$10/session`). The agent should monitor its own budget
usage and adjust behavior accordingly. Budget is not a state -- it is a
continuous modifier on behavior within the EXECUTE state.

| Budget Remaining | Behavior | Session Impact |
|------------------|----------|----------------|
| > 70% | **Normal.** Full iteration through all modes. No restrictions. | Stay in EXECUTE. |
| 30-70% | **Wind down.** Finish the current unit, then validate and ship what you have. Skip polish, skip non-critical improvements. | Complete current unit, then transition to HANDOFF. |
| < 30% | **Handoff.** Stop building. Commit what you have. Write a detailed progress note for the next session. | Transition to HANDOFF immediately. |
| < 10% | **Emergency.** Absolute minimum: `git add` changed files, commit, write a minimal stuck note. Don't spend budget on formatting or cleanup. | Transition to HANDOFF (emergency variant), then EXIT. |

**Monitoring:** There is no precise budget meter available to the agent.
Estimate based on:
- How many tool calls / LLM turns have been used
- Complexity of remaining work vs. work completed
- The execution profile's stated budget cap
- Whether the runtime environment provides usage signals

When in doubt, err on the side of handing off earlier. A clean partial
handoff is far more valuable than an incomplete session that runs out of
budget mid-commit.

---

## Lock Lifecycle

Locks prevent multiple agents (or sessions) from claiming the same task.

| Event | Action |
|-------|--------|
| SELECT succeeds | Create lock: `current_tasks/<TASK_ID>.lock` with task ID, timestamp, session ID |
| HANDOFF (task done) | Remove lock: delete `current_tasks/<TASK_ID>.lock` |
| HANDOFF (partial) | Keep lock: task is still claimed, next session resumes it |
| Stale lock detected | If lock is > 2 hours old and no recent commits reference the task, force-remove and reclaim |
| Session crash | Lock persists. Next session's ORIENT detects it, reads progress notes, and decides whether to resume or abandon |

**Lock file format:**
```
task: <TASK_ID>
locked_at: <ISO 8601 timestamp>
session: <session identifier or "interactive">
```

---

## Task Selection Criteria

When multiple tasks are eligible (status `todo`, all dependencies `done`),
select using these criteria in order:

1. **Explicit priority:** If the tracker has a priority column, pick the
   highest priority task.
2. **Dependency chain:** Prefer tasks that unblock the most downstream
   tasks.
3. **ID order:** If all else is equal, pick the lowest-numbered task ID
   (earliest defined).

---

## State Transition Summary

```
ORIENT --[briefing produced]--> SELECT
SELECT --[task locked, spec loaded]--> EXECUTE
SELECT --[no eligible tasks]--> HANDOFF (empty)
EXECUTE --[validation passed]--> HANDOFF (complete)
EXECUTE --[budget < 30%]--> HANDOFF (partial)
EXECUTE --[stuck]--> HANDOFF (stuck)
HANDOFF --[work committed, tracker updated]--> EXIT
```
