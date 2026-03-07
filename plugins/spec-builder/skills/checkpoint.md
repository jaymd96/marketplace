# checkpoint

Serialize session state, write self-review, and git commit.

## Trigger

- End of a spec-builder session
- "Let's wrap up"
- "Save progress"
- Context is getting long and needs serializing
- Use /checkpoint <summary>

## What to do

1. **Update PROJECT_STATE.md** — phase, stage, stance, pending actions, resumption prompt (the most important field)
2. **Update SESSION_LOG.md** — append session entry (2-5 sentences)
3. **Update other files** only if they changed: OPEN_QUESTIONS, PRODUCT_MODEL, CONSISTENCY_LOG, GAPS, feature dossiers, DECISIONS, spec sections
4. **Write abbreviated self-review** to `reviews/session-<N>.md` with scores on 6 dimensions
5. **Git commit** all changes as a single atomic commit with structured message:
   ```
   session <N>: <summary>

   Phase: <shaping|building>
   Stances: <which stances were used>
   Progress: <what moved forward>
   Next: <what should happen next>
   ```
6. **Tag if milestone** (journey stage changed, spec version bumped)
