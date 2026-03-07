---
name: checkpoint
description: "Save progress and wrap up a research session. Use at session end, when the user says 'save progress', 'let's wrap up', 'commit progress', 'let's stop here', 'end session', or when the conversation context is becoming long."
---

# checkpoint

1. Update PROJECT_STATE.md — phase, active threads, resumption prompt
2. Update SESSION_LOG.md — what happened (2-5 sentences)
3. Update changed files: CONCEPT_GRAPH, THREAD_MAP, LITERATURE, thread
   dossiers, OPEN_QUESTIONS, CONSISTENCY_LOG, GAPS, DECISIONS
4. Write abbreviated self-review to `reviews/session-<N>.md`
   (see `system/workflows/meta.md` for format, `system/templates/session-review.md` for template)
5. Git commit with structured message
6. Tag if milestone (thread merged, proof completed, paper drafted)
