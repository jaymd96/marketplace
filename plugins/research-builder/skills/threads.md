---
name: threads
description: "Show status of all idea threads. Use when the user says 'what threads do we have', 'show me the threads', 'what is active', 'what ideas have we explored', 'thread status', 'list threads', or 'what are we tracking'."
---

# threads

Scan `researcher/threads/` directories. For each thread report: status,
key question, note depth, open questions. Output a summary table.

If `scripts/thread-report.sh` is available, run it for the mechanical scan.

After presenting the table, suggest which threads need attention — stale
active threads that should be parked, or parked threads with new relevant
connections that might be worth revisiting.
