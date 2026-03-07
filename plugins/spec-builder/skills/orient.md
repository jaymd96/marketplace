# orient

Get a quick briefing on the current spec project state.

## Trigger

- Start of a spec-builder session
- "Where are we?"
- "What's the current state?"
- "Remind me what we discussed"

## What to do

Use the orient subagent (defined in `agents/orient.md`) to read all project
state files and produce a compact 20-30 line briefing. This protects your main
context from reading 8+ files at session start.

The briefing covers: resumption prompt, last session summary, feature coverage,
open questions/gaps/contradictions, recent git history, and pending actions.

If no subagent is available, read PROJECT_STATE.md (specifically the resumption
prompt) and `git log --oneline -5` in the project directory. Only read additional
files if the resumption prompt isn't sufficient.
