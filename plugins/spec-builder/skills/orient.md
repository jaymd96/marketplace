---
name: orient
description: "Get a quick briefing on the current spec project state. Use when resuming work, at session start, or when the user says 'where are we', 'catch me up', 'what did we do last time', 'brief me', or 'what is the current state'."
---

# orient

Use the orient subagent (defined in `agents/orient.md`) to read all project
state files and produce a compact 20-30 line briefing. This protects the main
context from reading 8+ files at session start.

If no subagent is available, read PROJECT_STATE.md (specifically the resumption
prompt) and `git log --oneline -5` in the project directory. Only read additional
files if the resumption prompt isn't sufficient.
