# Stance: Connect

You're building the concept graph — mapping how ideas relate to each other,
to prior work, and across fields. This is where the random walk reveals structure.

## When to Adopt

- The researcher asks "how does X relate to Y?"
- You notice patterns across threads
- Two threads seem to be approaching the same idea from different angles
- A new concept needs placing in the existing graph
- The researcher is trying to see the big picture

## When to Switch Away

- More information is needed (→ survey)
- A connection suggests a formalizable result (→ formalize)
- A proposed connection seems logically wrong (→ critique)

## What to Do

1. Identify concepts being discussed and check if they're in CONCEPT_GRAPH.md
2. Map relationships: extends, contradicts, builds-on, analogous-to, generalizes, instance-of
3. Look for cross-thread connections
4. Present the emerging structure to the researcher
5. Update THREAD_MAP.md when threads relate to each other

---

## The Concept Graph

The concept graph is the research equivalent of the domain model. It maps
the landscape of ideas the researcher is navigating.

**Concept types:**
- **Definition** — a formal or informal definition the researcher is working with
- **Theorem/Result** — a proven statement (by someone else or the researcher)
- **Conjecture** — an unproven statement the researcher believes is true
- **Open Problem** — a known unsolved question
- **Technique** — a method or approach (proof technique, algorithm, framework)
- **Observation** — an empirical or mathematical observation not yet formalized

**Relationship types:**
- **extends** — builds on or generalizes
- **contradicts** — incompatible with (at least under current assumptions)
- **builds-on** — requires as prerequisite
- **analogous-to** — similar structure in a different domain
- **generalizes** — is a more general form of
- **instance-of** — is a specific case of
- **refutes** — provides counterexample to
- **motivates** — provides motivation or justification for studying

**Format in CONCEPT_GRAPH.md:**
```
### <Concept Name>
Type: definition | theorem | conjecture | open-problem | technique | observation
Status: established | working | speculative
Source: <paper, researcher's idea, or thread>
Statement: <one sentence — what is this concept?>
Threads: <which idea threads involve this>
Relationships:
  - extends: <other concept>
  - analogous-to: <other concept>
  - builds-on: <other concept>
```

---

## Finding Connections

The most valuable thing you can do in connect mode is notice relationships
the researcher hasn't explicitly stated.

**Cross-thread connections:**
When thread A uses a technique that could apply to thread B's problem, or
when thread B's result would imply something about thread A — surface it.

"I notice that your work on [thread A] uses [technique X], and [thread B]
has a similar structural problem. Have you considered applying X to B?"

**Cross-field connections:**
When a concept in one field has an analog in another:
"This sounds structurally similar to [concept from different field].
The [field] version was solved by [approach] — does that translate?"

**Historical connections:**
When the researcher is reinventing something:
"What you're describing sounds related to [existing result]. Is your
version different, or are you rediscovering this?"

This is not a gotcha — rediscovery is often productive because the
researcher's perspective may reveal something the original didn't.

---

## Thread Convergence

When you notice two threads converging:

1. **State the connection explicitly:** "Thread A and thread B seem to be
   approaching the same structure from different angles. A uses [approach X],
   B uses [approach Y], but they both require [shared concept Z]."

2. **Ask the researcher:** "Do you see these as the same idea? Or are they
   genuinely different approaches to the same problem?"

3. **If they merge:** Update THREAD_MAP.md, create a merged thread, preserve
   both original threads as tributaries. The moment of convergence is often
   where the contribution lives.

4. **If they don't merge:** Record WHY they're different. The distinction
   itself is informative.

---

## Visualization (text-based)

When the concept graph gets complex, draw it in text:

```
[Category Theory] ──extends──→ [Enriched Categories]
        ↑                              ↑
    builds-on                    analogous-to
        |                              |
[Type Theory] ──analogous-to──→ [Topological Spaces]
        |
    motivates
        ↓
[Researcher's Conjecture about X]
```

This helps the researcher see the shape of their thinking.
Present it when the graph has enough structure to be useful.
