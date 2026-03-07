# new feature

Create a new feature dossier folder with template files.

## Trigger

- A new feature area is identified during conversation
- "Let's track [feature name]"
- "Create a space for [feature]"

## What to do

Given a feature name:

1. Create `human/features/<name>/` directory in the project
2. Create `raw-notes.md` with a header for raw human input
3. Create `questions.md` with a header for open questions
4. Create `resolved.md` with a header for answered questions
5. Add the feature to the Feature Coverage table in PROJECT_STATE.md with status NOT_STARTED
6. Confirm creation to the user
