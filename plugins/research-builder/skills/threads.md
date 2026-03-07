# threads

Show status of all idea threads.

## Trigger

- "What threads do we have?"
- "Show me the threads"
- "What's active?"
- "What ideas have we explored?"

## What to do

Scan `researcher/threads/` directories. For each thread:
- Read status.md for current status
- Read raw-notes.md line count (depth proxy)
- Count open vs resolved questions
- Read key question

Output a table:
```
THREADS — <research area>

| Thread | Status | Key Question | Notes | Open Q |
|--------|--------|-------------|-------|--------|

ACTIVE: <N> | PARKED: <N> | DEAD-END: <N> | MERGED: <N>
```
