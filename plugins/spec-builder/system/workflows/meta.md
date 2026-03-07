# Stance: Meta

Self-review and self-evolution. Reflecting on how you're performing and
whether the system itself should change.

## Self-Review (Every Session)

Run at session end, AFTER serializing state but BEFORE git commit.

### Abbreviated Review (normal sessions, 2-3 minutes)

Quick gut assessment. Write to `reviews/session-<N>.md`:

```markdown
# Session <N> Review — <date>

## What Happened
<2-3 sentence summary>

## Scores
Signal: /5 | Steering: /5 | Consistency: /5 | Hygiene: /5 | Progress: /5 | Depth: /5
```

### Full Review (at milestones)

Thorough assessment after intake complete, model complete, spec delivered, etc.

**Reflect on:**

**Conversation Dynamics:**
- Did I maintain focus, or did we drift?
- Did I capture the signal in tangents and redirect well?
- Did I ask the right questions?
- Did I detect inconsistencies early?

**Information Extraction:**
- How much new, useful information was captured?
- Were there moments the human was trying to say something I didn't get?
- Did I over-ask or under-ask?

**Depth and Focus:**
- Did I actually THINK about the product, or just follow process?
- Was I context-switching without finishing anything?
- Was my file I/O productive (genuine insight) or mechanical (shuffling paper)?
- If I removed all file reads/writes, what reasoning actually happened?

**State Management:**
- If I lost context right now, could my future self resume?
- Are the files I wrote useful or bureaucratic noise?

**Score on 6 dimensions (1-5):**

1. **Signal extraction** — useful product information captured
2. **Conversation steering** — dialogue management quality
3. **Inconsistency detection** — contradictions caught
4. **State hygiene** — serialized state quality
5. **Spec progress** — did the spec move forward
6. **Depth quality** — thinking vs. performing the appearance of work

**Full review format:**
```markdown
# Session <N> Review — <date>

## What Happened
<2-3 sentence summary>

## What Went Well
- <specific thing>

## What Could Improve
- <issue> — <what to do differently>

## Patterns Noticed
<!-- Only add if genuinely repeated across sessions -->

## Observations for System Evolution
<!-- Only note if evidence is strong — reference specific session moments -->

## Scores
Signal: /5 | Steering: /5 | Consistency: /5 | Hygiene: /5 | Progress: /5 | Depth: /5
```

### Flag for Evolution

After recording, check: does any observation warrant system change?

**Criteria:**
- Same issue in 3+ session reviews
- A workflow element consistently skipped or feels wrong
- A template never used as designed
- A conversation tactic consistently fails
- The human says "this isn't working" about the process

If flagged: add to `evolution/observations.md`. Do NOT change the system yet.

---

## Self-Evolution (Rare)

Modify the spec-builder system itself based on accumulated evidence.

**THIS SHOULD BE INVOKED RARELY.** Only for changes backed by evidence from
actual sessions. Not for aesthetic preferences or theoretical improvements.

### Gravity of Changes

Changes affect every future session for every future project.
- A bad change silently degrades every conversation.
- A good change compounds across all future work.

The asymmetry demands caution.

### Process

```
EVIDENCE → PROPOSE → TRIAL → SOAK → EVALUATE → COMMIT or REVERT
```

**EVIDENCE:** Gather observations supported by 3+ sessions (or human request).
Articulate: what's happening, what should happen, why the current design
causes this, how many sessions show the pattern.

**PROPOSE:** Write `evolution/proposals/EP-<N>-<name>.md`:
```markdown
# EP-<N>: <Title>
**Status:** proposed
**Date:** <date>
**Affects:** <files>
**Evidence:** <session references>

## Problem
## Proposed Change
## Rationale
## Risk Assessment
## Before / After
## Alternatives Considered
```

**TRIAL:** Create modified version in `evolution/trials/`. Follow the trial
version for 2-3 sessions. Original files stay unchanged (fallback if context
is lost).

**SOAK:** Record observations per session in the proposal file:
```
## Soak Log
- Session <N>: <observation>
- Session <N+1>: <observation>
```

**EVALUATE:**
- Clear improvement → COMMIT
- Neutral → REVERT (complexity without benefit)
- Regression → REVERT
- Mixed → refine and restart TRIAL

**COMMIT:** Update original files. Add to `evolution/CHANGELOG.md`. Remove
trial file. Git commit: `evolve: EP-<N> — <description>`

**REVERT:** Remove trial file. Update proposal status. Add to CHANGELOG.

### What NOT to Evolve

- ENTRYPOINT.md session protocol (it's the anchor)
- File structure (breaks in-progress projects)
- Anything based on one session (not a pattern)
- Edge case optimizations (if it works 90%, the 10% needs a workaround)

### What IS Safe to Evolve

- Conversation tactics (questions, scripts, redirects)
- Template formats (add fields, clarify)
- Checklist items
- Self-review dimensions
- Adding new templates or stance guidance
