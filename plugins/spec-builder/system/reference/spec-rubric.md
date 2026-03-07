# Spec Quality Rubric

How to judge whether a specification is good enough to implement from.

This is calibration material — not a template. Read it to develop judgment
about what precision means, when detail matters, and where to stop. The
spec you're building may look nothing like the reference material below,
and that's fine. What matters is whether an engineer could implement the
product correctly from your spec alone.

---

## The Single Test

**Could two competent engineers, working independently, read this spec and
produce implementations that are compatible where they need to be?**

If yes, the spec is precise enough. If no, find the ambiguity and resolve it.

Everything in this rubric serves this test. Precision isn't about volume —
it's about eliminating the ambiguities that would cause two implementations
to diverge.

---

## The Core Principles (from Symphony)

OpenAI's Symphony SPEC.md was written so an AI could implement the entire
service from the spec alone. That constraint forced a discipline worth
learning from:

**1. Specify behavior, not implementation.**
Say WHAT must happen and in what order. Never say HOW to code it. No
framework choices. No data structure preferences. Language-agnostic
pseudocode for critical algorithms. The moment you specify implementation,
you've reduced the spec's audience to one technology stack.

**2. Nothing is implicit.**
Every default value is stated. Every error is named. Every state transition
has a trigger and a guard. If the spec doesn't say it, the implementation
shouldn't assume it. Implicit knowledge is the #1 source of implementation
bugs.

**3. The spec is self-contained.**
A reader needs no external context. Every concept is defined in the spec.
Every cross-reference is by section number. If you need to have been in
the room to understand a section, that section isn't done.

---

## Precision Proportional to Consequence

This is the calibration principle the rubric is built on.

**Not every part of a spec needs the same level of detail.** The right
question is: "how many implementation decisions does this precision level
disambiguate?" If a section is so vague that an implementer would make
10 guesses, it needs more precision. If it's already unambiguous, adding
more detail is waste.

### High-consequence areas (need maximum precision):

- **Domain model** — entity field types, nullability, constraints, normalization
  rules. Two implementations must produce compatible data models or they can't
  interoperate. Every field needs a type and every constraint needs stating.
- **State machines** — states, transitions, triggers, guards. A missing
  transition or ambiguous guard becomes a bug. Enumerate exhaustively.
- **External contracts** — APIs, protocols, wire formats. Anything that crosses
  a system boundary must be precise enough for independent implementation.
- **Safety invariants** — security rules, data validation, access control.
  Ambiguity here becomes a vulnerability. State as mechanical rules, not guidelines.
- **Error handling at boundaries** — what happens when external calls fail?
  Each failure mode needs a specified recovery behavior.

### Medium-consequence areas (need clarity but less exhaustive detail):

- **Configuration** — every knob the operator can turn, with type and default.
  But you don't need to specify the config file format or parsing library.
- **Behavior sequences** — the order of operations matters and should be stated,
  but the exact pseudocode might not be needed if the sequence is simple.
- **Observability** — what must be logged/measured. But not how to render dashboards.

### Low-consequence areas (need direction, not exhaustive specification):

- **System overview** — shape and components, not internals.
- **Non-goals** — clear exclusions, not lengthy justifications.
- **Implementation hints** — suggestions that help but don't constrain.

### What NOT to specify:

- Programming language or runtime
- Internal data structures (specify the interface, not the implementation)
- Specific third-party libraries (specify the capability needed)
- UI layout details (specify the interaction flow and information architecture)
- Performance implementation (specify the SLA, not the caching strategy)

**The line:** if two different choices would both satisfy the requirement and
the user wouldn't notice the difference, it belongs in implementation, not spec.

---

## Section Standards

### Problem Statement

**Purpose:** Orient the reader. One paragraph to understand what this is.

**Must include:**
- What the system IS (one sentence, no adjectives)
- What problems it SOLVES (bullet list, problem-focused not feature-focused)
- Where its responsibility ENDS (explicit boundary)

**Symphony example:**
> "Symphony is a long-running automation service that continuously reads work
> from an issue tracker, creates an isolated workspace for each issue, and runs
> a coding agent session for that issue inside the workspace."

> "Important boundary: Symphony is a scheduler/runner and tracker reader."

**Anti-patterns:**
- "A next-generation platform for..." (marketing)
- Problem statement that's actually a feature list
- No boundary (scope is ambiguous)

---

### Goals and Non-Goals

**Purpose:** Define what success looks like and what's explicitly excluded.

**Must include:**
- Goals that are TESTABLE — you could verify each one mechanically
- Goals using active verbs (poll, maintain, create, stop, recover)
- Non-goals that are SPECIFIC expectations being explicitly rejected

**Test for a good goal:** Can you write a test that passes when the goal is
met and fails when it's not? If no, the goal is too vague.

**Anti-patterns:**
- "Be fast" (how fast? measured how?)
- "Great user experience" (subjective)
- Non-goals that are just "things we'll do later"

---

### System Overview

**Purpose:** Give the reader a map before the territory.

**Must include:**
- Component list with single-responsibility descriptions
- How components relate (dependency direction, data flow)
- External dependencies (what's outside the system boundary)

**Test:** After reading this section, can the reader predict which section
contains the details for any given question? If yes, the overview works.

---

### Domain Model

**Purpose:** Define the nouns of the system precisely enough for independent
implementation.

**For each entity:**
- Name and purpose (one sentence)
- Fields with types, nullability, and constraints
- Behavioral semantics where the field affects logic (not just "stores data")

**For relationships:**
- Cardinality (1:1, 1:N, N:M)
- Lifecycle coupling (cascade-delete? orphan? prevent-delete?)
- Direction (who owns whom)

**For identifiers:**
- How generated, how compared, normalization rules
- Which identifiers are stable (never change) vs mutable

**The precision test:** Could two implementations read this section and produce
data models that can exchange data without loss? Every field type mismatch or
missing constraint is a compatibility bug.

**Anti-patterns:**
- Fields without types ("properties: various attributes")
- Missing nullability (is this field optional or required?)
- Entities referenced in later sections but not defined here
- Relationships left implicit

---

### Behavior Specifications

**Purpose:** Define what the system does in each feature area.

**For each operation or interaction:**
- Preconditions (what must be true before this can happen)
- Sequence (what happens, in order)
- Postconditions (what is guaranteed after)
- Error conditions (what can go wrong, and what happens when it does)

**For state machines:**
- All states listed (including terminal states)
- All transitions with: trigger, guard condition, effect
- Verification: every state is reachable, every non-terminal state has an exit
- No "the system may be in other states" — enumerate exhaustively

**For configuration in this area:**
- Every option with: type, default value, validation rules
- What happens when the option changes at runtime (restart required? live reload?)

**The sequence test:** Could an implementer trace through a scenario step-by-step
using only this section? If they'd need to guess any step, add it.

**Anti-patterns:**
- "The system handles errors gracefully" (not a specification)
- Behavior without sequence ("it does A, B, and C" — in what order?)
- Happy path only (no error paths)
- State machines with unlabeled transitions

---

### Cross-Cutting Concerns

**Purpose:** Address things that span multiple features.

**Error handling:** Don't say "errors are handled." Enumerate error CLASSES
and specify recovery behavior for each class. Symphony has 5 error categories,
each with specific recovery rules.

**Security:** State trust boundaries, safety invariants (as mechanical rules),
and secret handling. Not "be secure" but "workspace path must stay inside
workspace root."

**Observability:** What must be logged, with what fields. Not how to build
dashboards.

**Configuration management:** Source precedence, reload semantics, validation.

---

### Test Matrix

**Purpose:** Every behavioral requirement should be testable, and this section
proves it.

**For each requirement in the spec:**
- One test bullet stating the scenario and expected outcome
- Organized by subsystem (matching spec sections)

**Profile classification:**
- Core: required for any conforming implementation
- Extension: required only if that feature is shipped
- Integration: requires real external dependencies

**The test:** Every SHALL/MUST statement in the spec has a corresponding
bullet here. If a requirement has no test, it's either untestable (rewrite it)
or the test is missing (add it).

**Anti-patterns:**
- "Tests should cover all functionality" (not a matrix)
- Test descriptions that just restate requirements without adding scenarios
- Missing negative tests ("this should NOT happen when...")

---

### Implementation Checklist

**Purpose:** Ordered definition of done.

**Must include:**
- Items ordered by dependency (what must exist before what)
- Each item references a spec section
- Required items separated from recommended items
- Granularity: each item is independently verifiable

---

### Reference Algorithms (when needed)

**Include these when:** The behavioral sequence is complex enough that prose
description alone would be ambiguous. If the sequence has conditional branches,
loops, or error recovery, pseudocode clarifies better than prose.

**Don't include these when:** The behavior is simple and the prose specification
is unambiguous. Not every operation needs pseudocode.

**Properties of good pseudocode:**
- Language-agnostic (no language-specific syntax)
- Error handling inline (not deferred)
- Self-contained (readable without other sections)
- Specifies behavior sequence, not data structures

---

## Iterative Quality: v0.1 Is Not v1.0

A spec evolves through drafts. Don't aim for Symphony quality on the first pass.

### v0.1 — Structural Draft
- Problem statement exists and is honest
- Major entities identified with rough descriptions
- Feature areas listed with behavioral summaries
- State machines sketched (states and major transitions)
- Obvious non-goals stated
- `[TBD]` markers where detail is needed

### v0.5 — Working Draft
- All entities have typed fields
- State machines are complete (all transitions, triggers, guards)
- Behavior sequences specified for major operations
- Error handling enumerated for boundary interactions
- Configuration options listed with defaults
- Cross-references working between sections
- Test bullets exist for critical paths

### v1.0 — Implementation-Ready
- Every section passes the "two independent implementations" test
- Every `[TBD]` resolved or explicitly deferred with rationale
- Test matrix complete (every SHALL/MUST has a test)
- Implementation checklist ordered by dependency
- Reference algorithms for complex sequences
- Self-contained: no external context needed

**The agent should know which version it's producing** and calibrate detail
accordingly. Asking v0.1-level questions ("what entities exist?") while
writing v1.0-level prose is a mismatch.

---

## Section Dependency DAG

Sections aren't independent. They form a dependency graph:

```
Problem Statement
  └→ Goals / Non-Goals
       └→ System Overview
            └→ Domain Model ←──────────────────┐
                 ├→ Behavior Specifications ────┤
                 │    └→ Cross-Cutting Concerns  │
                 │         └→ Test Matrix ───────┘
                 │              └→ Implementation Checklist
                 └→ Reference Algorithms (draws from Behavior + Domain Model)
```

**What this means:**
- The domain model CONSTRAINS the behavior specs (you can't specify operations
  on entities that don't exist in the model)
- The behavior specs GENERATE the test matrix (every behavioral requirement
  becomes a test bullet)
- The test matrix VALIDATES the behavior specs (if you can't test it, it's
  either too vague or not a real requirement)
- The implementation checklist SEQUENCES from all of the above

**Don't write sections out of dependency order.** You can sketch later sections
early, but don't finalize a behavior spec before the domain model is solid —
you'll be editing it when the model changes.

---

## Adapting to Different Product Types

Not every product is a backend daemon like Symphony. Adjust emphasis:

### API / Platform
- Domain model and external contracts need maximum precision
- Version strategy and backward compatibility become critical sections
- Security (auth, rate limiting, data access) gets its own detailed section
- Error responses need schema-level precision (every error code, every field)

### CLI Tool
- Simpler domain model, fewer entities
- Command structure and flag semantics need precision
- Input/output formats specified exhaustively
- State machines may not apply (most CLIs are stateless)
- Exit codes and error messages become the "external contract"

### Data Pipeline
- Schema definitions need field-level precision
- Transformation semantics (what changes, what's preserved)
- Lineage and provenance (where does data come from, where does it go)
- Failure and retry semantics for each stage
- State machines for pipeline stage lifecycle

### UI-Heavy Product
- Interaction flows need step-by-step sequences
- Information architecture (what the user sees, in what order)
- State machines for UI state (loading, error, empty, populated)
- Accessibility requirements as testable statements
- Less emphasis on wire protocols, more on user-facing behavior

### Real-Time / Event-Driven
- Event schemas need field-level precision
- Ordering guarantees (exactly-once? at-least-once? ordering?)
- Latency requirements as quantified SLAs
- Backpressure and flow control behavior
- Failure modes for producers and consumers independently

**The principle:** precision goes where divergence would be visible to users
or operators. For an API, that's the contract. For a CLI, that's the command
interface. For a pipeline, that's the schema. Identify YOUR product's equivalent
and specify it to Symphony-level precision. Everything else can be lighter.

---

## The Calibration Questions

### Per-section:
1. Could two engineers implement this independently with compatible results?
2. Could you write a test for every behavioral statement?
3. Is every default, constraint, and error path stated?
4. Can a reader understand this without reading other sections?
5. Is this describing WHAT (behavior) or HOW (implementation)?

### Per-entity:
1. Are all fields typed with nullability stated?
2. Are normalization rules explicit?
3. Is the lifecycle clear (created when? destroyed when?)
4. Are relationships to other entities documented?

### Per-operation:
1. Are preconditions stated?
2. Is the sequence of steps specified?
3. Are error conditions enumerated with recovery behavior?
4. Are postconditions (what's guaranteed after) stated?

### Per-state-machine:
1. Are all states listed, including terminal states?
2. Does every transition have a trigger and guard?
3. Is every state reachable from the initial state?
4. Can every non-terminal state be exited?

### Per-configuration-option:
1. Type, default value, and validation rules stated?
2. Behavior on change specified (restart required? live reload?)
3. Environment variable or override mechanism documented?

---

## What Symphony Does NOT Specify (Equally Important)

Symphony deliberately leaves these to the implementer:
- Programming language and runtime
- Database or persistence technology
- Internal data structures
- Web framework for the optional HTTP server
- Logging library or format beyond required fields
- Test framework or runner
- CI/CD pipeline
- Deployment method

Each of these is a decision the spec COULD have made but chose not to —
because any reasonable choice would satisfy the behavioral requirements.
If the spec specified "use PostgreSQL," it would exclude equally valid
implementations using SQLite or in-memory state.

**Your spec should do the same.** When you're tempted to specify an
implementation choice, ask: "would a different choice still satisfy the
behavioral requirements?" If yes, leave it out. You're over-specifying.

The only exception: when the human has explicitly stated a technology
constraint ("we're building this in Python" or "it must use PostgreSQL").
Then it's a requirement, not an implementation choice, and belongs in the spec.
