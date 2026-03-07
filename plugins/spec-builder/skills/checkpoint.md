---
name: checkpoint
description: "Save progress and wrap up a spec-builder session. Use at session end, when the user says 'let us wrap up', 'save progress', 'commit progress', or when context is getting long. Writes state, self-review, and creates a git commit."
---

# checkpoint

1. Update PROJECT_STATE.md — phase, stage, stance, pending actions, resumption prompt
2. Update SESSION_LOG.md — append session entry (2-5 sentences)
3. Update other files only if they changed this session (OPEN_QUESTIONS, PRODUCT_MODEL, CONSISTENCY_LOG, GAPS, feature dossiers, DECISIONS, spec sections)
4. Write abbreviated self-review to `reviews/session-<N>.md` with 6-dimension scores
5. Git commit all changes as a single atomic commit with structured message
6. Tag if milestone (journey stage changed, spec version bumped)
