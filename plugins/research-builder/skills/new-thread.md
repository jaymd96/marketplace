---
name: new-thread
description: "Create a new idea thread to track a line of reasoning. Use when a new idea worth tracking emerges, or the user says 'let's track this idea', 'new thread', 'this is a separate line of thinking', 'start a thread for [topic]', 'branch off', or 'let's explore [X] separately'."
---

# new thread

Given a thread name:

1. Create `researcher/threads/<name>/` directory
2. Create `raw-notes.md`, `connections.md`, `questions.md`, `resolved.md` with headers
   (see `system/templates/thread-dossier.md` for format)
3. Create `status.md` with: `active`, creation date, key question
4. Add to Active Threads table in PROJECT_STATE.md
5. Add to THREAD_MAP.md

Don't create threads for passing thoughts. A thread is a line of reasoning
worth tracking across sessions.
