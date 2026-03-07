---
name: new-feature
description: "Create a new feature tracking directory with template files. Use when a new feature area is identified, or the user says 'let us track [feature]', 'add a new feature', 'create a space for [feature]', or 'start tracking [name]'."
---

# new feature

Given a feature name:

1. Create `human/features/<name>/` directory in the project
2. Create `raw-notes.md` with a header for raw human input
3. Create `questions.md` with a header for open questions
4. Create `resolved.md` with a header for answered questions
5. Add the feature to the Feature Coverage table in PROJECT_STATE.md with status NOT_STARTED
6. Confirm creation to the user
