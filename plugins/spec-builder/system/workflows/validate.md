# Stance: Validate

You're checking for consistency, correctness, and completeness. Something
might be wrong, and you need to surface it.

## When to Adopt

- You notice a contradiction between what the human just said and earlier input
- You're reviewing drafted spec content
- The human asks "is this consistent?"
- You're doing a systematic quality audit of the spec
- The domain model's invariants need checking

## When to Switch Away

- The issue is resolved (→ return to previous stance)
- You need more information to resolve (→ understand)
- The human redirects to something new (→ understand)
- A resolution needs to be written into the spec (→ produce)

## What to Do

1. Surface the inconsistency clearly (see protocol below)
2. Propose resolution with reasoning
3. Get human confirmation
4. Update all affected documents
5. Verify no new issues were introduced

---

## Inconsistency Resolution

### Presenting Issues

Present ONE issue at a time:

```
"I found an inconsistency I need your help resolving.

**The issue:** [clear statement]

**Where it came from:**
- In [session/feature], you said: [quote/paraphrase A]
- In [session/feature], you said: [quote/paraphrase B]
- These conflict because: [logical explanation]

**My recommendation:** [Option A] because [reasoning]

**Alternative:** [Option B] which would mean [tradeoff]

Which fits your intent better?"
```

**Tactics:**
- Always lead with a recommendation
- If the human says "both" or "it depends" — there's a conditional rule you
  haven't captured. Dig in: "Under what conditions does A apply vs B?"
- If frustrated: "Getting these right now means no logical holes in the spec."

### Recording Resolutions

Update CONSISTENCY_LOG.md:
```
### ISSUE-<id>: <short name>
Status: resolved
Resolution: <what was decided>
Rationale: <why>
Decided by: human (confirmed) | agent (proposed, human accepted)
Date: <date>
Affected: [list of features/entities]
```

If it's a design decision, also add to DECISIONS.md:
```
### DEC-<N>: <short name>
Context: <what prompted this>
Decision: <what was decided>
Rationale: <why>
Alternatives considered: <what else was possible>
Consequences: <what this means for the design>
```

### Propagating Resolutions

After resolving, update all affected documents:
- PRODUCT_MODEL.md — entities, relationships, states, operations
- Feature dossiers — add resolution note, move questions to resolved
- OPEN_QUESTIONS.md — remove answered questions
- GAPS.md — remove filled gaps
- spec/SPEC.md — update if spec sections already drafted

Then verify the resolution didn't create new problems.

### Common Inconsistency Patterns

**"Automatic" + "needs approval":**
Usually a policy layer. "Automatic by default, optional approval gate per [scope]."

**"Real-time" + "millions of events":**
Usually different operations. "Reads are real-time. Writes are eventually consistent."

**"Simple" + "highly configurable":**
Progressive disclosure. "Sensible defaults. Advanced config available but not required."

**"Secure" + "easy onboarding":**
Layered auth. "API key for quick start. Full RBAC/SSO for production."

**Feature A assumes Entity X exists, Feature B never creates it:**
Either B needs a creation flow, X is a side effect, or it's pre-configured. Ask.

---

## Journey Context: During Reconcile

Systematic inconsistency resolution. Use when CONSISTENCY_LOG.md has accumulated
unresolved entries.

**Process:**
1. Collect all unresolved issues from CONSISTENCY_LOG.md, GAPS.md, OPEN_QUESTIONS.md
2. Classify each: contradiction | ambiguity | gap | dependency
3. Prioritize by impact:
   - Domain model contradictions first
   - State machine contradictions second
   - Feature-blocking gaps third
   - Behavior ambiguities fourth
   - Naming inconsistencies last
4. Present and resolve one at a time
5. Propagate each resolution
6. Verify no new issues created

---

## Journey Context: During Review

Systematic spec quality audit. Use when the spec has draft content.

### Five Quality Dimensions

**1. Completeness** — is everything represented?
- Every feature dossier has corresponding spec section(s)
- Every entity in PRODUCT_MODEL.md appears in the spec
- Every state machine is specified
- Every decision is reflected
- No unresolved [TBD] or [DECISION NEEDED] markers

Create a coverage matrix in `internal/REVIEW_NOTES.md`:
```
| Source | Item | Spec Section | Status |
|--------|------|-------------|--------|
| features/auth/ | Login flow | 5.1 | covered |
| DECISIONS.md | DEC-4 | 5.2 | missing |
```

**2. Consistency** — no internal contradictions?
- Terminology: same thing, same name everywhere
- State machines: transitions in features match definitions
- Operations: preconditions don't contradict other sections' guarantees
- Error handling: types used consistently
- Configuration: defaults match cross-section expectations
- Cardinality: model says 1:N, behavior section doesn't assume 1:1

**3. Correctness** — matches human's intent?
Walk through sections with the human. Don't ask "is this right?" — present
a specific scenario and ask what should happen. If their answer matches the
spec, it's correct.

**4. Clarity** — implementable by someone not in the room?
Could a competent engineer implement from this alone?
Common issues: implicit knowledge, ambiguous quantifiers, missing failure
modes, assumed context.

**5. Testability** — every requirement verifiable?
For each SHALL/MUST statement: what test? what level? what data? what outcome?

Build test matrix:
```
| Requirement | Section | Test Level | Test Description |
|-------------|---------|-----------|-----------------|
| Entity creation | 4.1 | Unit | Create entity, verify fields |
```

### Verdict

- Critical issues → back to produce or reconcile
- Minor issues → fix inline, re-verify
- Clean → ready for delivery

### Review Tactics

**Don't review everything at once.** 2-3 sections per session.

**The "explain it back" test.** Try to explain the feature in your own words
WITHOUT looking at the spec. If you can't, the spec isn't clear enough.

**Look for combinatorial explosions.** Feature A has 3 modes, Feature B has
4 modes. Does the spec account for all 12 combinations? Does it need to?
