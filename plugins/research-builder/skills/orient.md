---
name: orient
description: "Quick briefing on current research project state. Use for standalone orientation when returning to a project, or when the user says 'where are we', 'what were we working on', 'catch me up', 'brief me', 'where did we leave off', 'recap', or 'what's the status'."
---

# orient

Use the orient subagent to read project state files and produce a 20-30
line briefing. If no subagent available, read PROJECT_STATE.md (resumption
prompt) and `git log --oneline -5`.
