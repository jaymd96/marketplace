# checkpoint

Serialize session state, write self-review, and git commit.

## Trigger

- End of session
- "Let's save progress"
- Context getting long

## What to do

1. Update PROJECT_STATE.md — phase, active threads, resumption prompt
2. Update SESSION_LOG.md — what happened (2-5 sentences)
3. Update changed files: CONCEPT_GRAPH, THREAD_MAP, LITERATURE, thread
   dossiers, OPEN_QUESTIONS, CONSISTENCY_LOG, GAPS, DECISIONS
4. Write abbreviated self-review to `reviews/session-<N>.md`
5. Git commit with structured message
6. Tag if milestone (thread merged, proof completed, paper drafted)
