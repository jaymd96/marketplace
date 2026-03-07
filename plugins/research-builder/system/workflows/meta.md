# Stance: Meta

Self-review and self-evolution. Same as spec-builder, adapted for research.

## Self-Review (Every Session)

### Abbreviated (normal sessions)

```markdown
# Session <N> Review — <date>

## What Happened
<2-3 sentences>

## Scores
Survey: /5 | Connect: /5 | Formalize: /5 | Critique: /5 | Depth: /5 | Progress: /5
```

### Full Review (at milestones — thread merged, proof completed, paper drafted)

**Dimensions:**

1. **Survey quality** — Did I capture the researcher's ideas faithfully?
   Did I track references properly? Did I notice what wasn't being said?

2. **Connection finding** — Did I spot relationships the researcher hadn't
   stated? Did I link new ideas to the concept graph effectively?

3. **Formalization support** — When we tightened arguments, did I help move
   from intuition to precision without killing the intuition?

4. **Critique quality** — Did I find real logical issues? Or was I pedantic
   about irrelevant details? Did I distinguish fixable from fatal?

5. **Depth** — Was I genuinely engaging with the ideas, or performing the
   appearance of intellectual engagement?

6. **Research progress** — Did the researcher's understanding actually
   advance? Did threads move forward? Did the concept graph grow
   meaningfully?

**Full review format:**
```markdown
# Session <N> Review — <date>

## What Happened
<2-3 sentences>

## What Went Well
- <specific intellectual contribution>

## What Could Improve
- <missed connection, weak critique, etc.>

## Patterns Noticed

## Observations for System Evolution

## Scores
Survey: /5 | Connect: /5 | Formalize: /5 | Critique: /5 | Depth: /5 | Progress: /5
```

## Self-Evolution (Rare)

Modify the research-builder system itself based on accumulated evidence.
Invoke rarely — only for changes backed by evidence from actual sessions.

Changes affect every future session. A bad change silently degrades
every conversation. The asymmetry demands caution.

### Process

```
EVIDENCE → PROPOSE → TRIAL → SOAK → EVALUATE → COMMIT or REVERT
```

**EVIDENCE:** Gather observations supported by 3+ session reviews (or explicit
human request). Articulate: what's happening, what should happen, why the
current design causes this, how strong the evidence is.

**PROPOSE:** Write `evolution/proposals/EP-<N>-<name>.md` with: problem,
proposed change, rationale, risk assessment, before/after, alternatives.

**TRIAL:** Create modified file in `evolution/trials/`. Follow the trial
version for 2-3 sessions. Original files stay unchanged as fallback.

**SOAK:** Record observations per session in the proposal:
```
## Soak Log
- Session <N>: <observation>
```

**EVALUATE:**
- Clear improvement → COMMIT
- Neutral → REVERT (complexity without benefit)
- Regression → REVERT
- Mixed → refine and restart TRIAL

**COMMIT:** Update original files. Add to `evolution/CHANGELOG.md`. Remove
trial. Git commit: `evolve: EP-<N> — <description>`

**REVERT:** Remove trial. Update proposal status. Add to CHANGELOG.

### What NOT to Evolve

- ENTRYPOINT.md session protocol (it's the anchor)
- File structure (breaks in-progress projects)
- Anything based on one session (not a pattern)

### What IS Safe to Evolve

- Conversation tactics, question frameworks
- Template formats
- Self-review dimensions
- Adding new stance guidance
