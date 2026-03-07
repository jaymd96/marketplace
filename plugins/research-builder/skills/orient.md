---
name: orient
description: "Quick briefing on current research project state. Use at session start, or when the user says 'where are we', 'what were we working on', 'catch me up', or 'brief me'."
---

# orient

Use the orient subagent to read project state files and produce a 20-30
line briefing. If no subagent available, read PROJECT_STATE.md (resumption
prompt) and `git log --oneline -5`.
