# Spec Quality Rubric

What a good specification looks like, distilled from analyzing OpenAI's Symphony
SPEC.md (2110 lines, 18 sections, used to produce a working implementation by AI).

This is calibration material. Read it when drafting or reviewing spec content.
It tells you what "good" looks like so you can measure your output against it.

---

## What Makes the Symphony Spec Work

Symphony is a scheduler/runner for coding agents. Its spec was written so an AI
could implement the entire service from the spec alone. That constraint forced
precision — every ambiguity would become a bug. The spec succeeds because:

1. **It specifies behavior, not implementation.** It says WHAT must happen and
   in what order, never HOW to code it. Language-agnostic pseudocode for
   critical algorithms. No framework choices. No data structure preferences.

2. **Nothing is implicit.** Every default value is stated. Every error is named.
   Every state transition has a trigger and a guard. If the spec doesn't say it,
   the implementation shouldn't assume it.

3. **It's self-contained.** A reader needs no external context. Every concept
   is defined in the spec itself. Every cross-reference is by section number.

---

## Section-by-Section Rubric

### 1. Problem Statement

**What good looks like:**
- One paragraph saying what the system IS
- Bullet list of specific problems it SOLVES (not features — problems)
- Explicit boundary: what it is NOT responsible for
- No marketing language, no aspirational claims

**Symphony example (why it works):**
> "Symphony is a long-running automation service that continuously reads work
> from an issue tracker, creates an isolated workspace for each issue, and runs
> a coding agent session for that issue inside the workspace."

One sentence. Says what it does. No adjectives.

> "Important boundary: Symphony is a scheduler/runner and tracker reader.
> Ticket writes are typically performed by the coding agent."

Explicit about where its responsibility ends.

**Anti-patterns:**
- "A next-generation platform for..." (marketing, not specification)
- "Enables teams to..." (aspirational, not behavioral)
- Problem statement that's actually a feature list
- No boundary statement (leaves scope ambiguous)

---

### 2. Goals and Non-Goals

**What good looks like:**
- Goals are TESTABLE — you could write a test for each one
- Goals use active verbs: "Poll", "Maintain", "Create", "Stop", "Recover"
- Non-goals are SPECIFIC — not "won't do everything" but "won't do X, Y, Z"
- Non-goals explain what you might expect but explicitly exclude

**Symphony example (why it works):**
Goal: "Stop active runs when issue state changes make them ineligible."
→ Testable: create a run, change the issue state, verify it stops.

Non-goal: "Rich web UI or multi-tenant control plane."
→ Specific expectation explicitly excluded.

Non-goal: "Mandating a single default approval, sandbox, or operator-confirmation
posture for all implementations."
→ Addresses a reasonable assumption and explicitly rejects it.

**Anti-patterns:**
- "Be fast" (not testable — how fast? measured how?)
- "Provide a great user experience" (subjective, not verifiable)
- Non-goals that are just "things we haven't built yet"

---

### 3. System Overview

**What good looks like:**
- Component list with 1-2 sentence descriptions each (the map)
- Abstraction levels showing how components layer (which depends on which)
- External dependencies listed (what's outside the system boundary)
- A reader should understand the system's shape WITHOUT reading the details

**Symphony example (why it works):**
8 components, each with a clear single responsibility:
> "Orchestrator: Owns the poll tick. Owns the in-memory runtime state. Decides
> which issues to dispatch, retry, stop, or release."

6 abstraction levels showing the layering:
> Policy → Configuration → Coordination → Execution → Integration → Observability

This is the table of contents for the rest of the spec. After reading Section 3,
you know WHERE every detail will live before you read it.

**Anti-patterns:**
- Jumping into details without the overview
- Architecture diagram without prose explanation
- Missing external dependencies (reader discovers them later)
- Components described by technology instead of responsibility

---

### 4. Core Domain Model

**What good looks like:**
- Every entity has: name, purpose, fields with types and descriptions
- Every field has constraints (nullable?, default?, valid range?)
- Relationships between entities are explicit (not left for the reader to infer)
- Stable identifiers and normalization rules documented
- Entities correspond to concepts the reader already met in the overview

**Symphony example (why it works):**
Every entity field is documented like this:
```
- `priority` (integer or null)
  - Lower numbers are higher priority in dispatch sorting.
```
Type, nullability, AND behavioral semantics in two lines.

Normalization rules are explicit:
> "Workspace Key: Derive from issue.identifier by replacing any character not
> in [A-Za-z0-9._-] with _."

No ambiguity about how identifiers are formed.

**The precision test:** Could two independent implementations read this section
and produce compatible data models? If yes, the domain model is precise enough.

**Anti-patterns:**
- Entity with fields but no types
- Fields without nullability specified
- "Properties: various attributes" (not a specification)
- Missing normalization rules (how are IDs generated? compared? stored?)
- Entities referenced later that aren't defined here

---

### 5-N. Feature/Behavior Specifications

**What good looks like:**
- Each feature section follows a consistent internal structure
- Behavior specified as sequences: "first X, then Y, then Z"
- Preconditions stated: "this only happens when A is true"
- Error conditions for each operation: "if X fails, then Y"
- Configuration options with types, defaults, and validation rules
- State machines with states, transitions, triggers, and guards
- Cross-references to domain model entities by section number

**Symphony example (why it works):**
The Orchestration section (Section 7) defines a state machine:
```
1. Unclaimed — not running, no retry scheduled
2. Claimed — reserved to prevent duplicate dispatch
3. Running — worker task exists
4. RetryQueued — retry timer exists
5. Released — claim removed
```
Then every transition between these states is documented with its trigger.

The Workspace section (Section 9) has safety invariants:
> "Invariant 1: Run the coding agent only in the per-issue workspace path."
> "Invariant 2: Workspace path must stay inside workspace root."

These are testable, mechanical rules — not guidelines.

**Anti-patterns:**
- "The system handles errors gracefully" (not a specification)
- Behavior described without sequence ("it does A, B, and C" — in what order?)
- Missing error paths (only the happy path is specified)
- Configuration options without defaults
- State machines without transition triggers

---

### 6. Cross-Cutting Concerns

**What good looks like:**
- Security: trust boundaries stated, filesystem safety invariants, secret handling
- Observability: required log fields, structured format, what operators must see
- Configuration: source precedence, dynamic reload semantics, validation rules
- Error handling philosophy: error classes enumerated, recovery behavior per class

**Symphony example (why it works):**
Error handling isn't vague — it's a taxonomy:
```
1. Workflow/Config Failures (missing file, invalid YAML, missing credentials)
2. Workspace Failures (creation, population, hooks)
3. Agent Session Failures (handshake, turn, timeout, stall)
4. Tracker Failures (transport, status, GraphQL, payload)
5. Observability Failures (snapshot, dashboard, log sink)
```
Each class has a specific recovery behavior. Nothing is "handle appropriately."

**Anti-patterns:**
- "The system should be secure" (not actionable)
- "Errors are logged" (which errors? what format? where?)
- No dynamic reload semantics (does the system need restarting to apply changes?)

---

### 7. Test Matrix

**What good looks like:**
- Every behavioral requirement from the spec has a corresponding test bullet
- Tests organized by subsystem (matching spec sections)
- Test profiles: core (required), extension (if feature shipped), integration (env-dependent)
- Each test bullet is specific enough to implement without reading the spec again

**Symphony example (why it works):**
Section 17 has 80+ specific test bullets, organized by subsystem:
> "Dispatch sort order is priority then oldest creation time"
> "Todo issue with non-terminal blockers is not eligible"
> "Normal worker exit schedules a short continuation retry (attempt 1)"

Each bullet is ONE testable assertion. Not "test the dispatch logic" but
a specific scenario with expected outcome.

**Anti-patterns:**
- "Tests should cover all functionality" (not a matrix)
- Test descriptions that restate the spec without adding scenarios
- Missing negative tests (what should NOT happen)
- No distinction between required and optional tests

---

### 8. Implementation Checklist

**What good looks like:**
- Ordered by dependency (what must exist before what)
- References spec sections for each item
- Distinguishes required vs recommended
- Acts as a "definition of done" — when all items checked, the system is complete

**Symphony example (why it works):**
Section 18 mirrors Section 17 exactly: each required behavior is a checklist item.
It adds extension items marked as "recommended" and operational validation.

**Anti-patterns:**
- Unordered list (no dependency information)
- Items too vague to verify ("implement the API")
- Missing reference to spec sections (where's the detail?)

---

### Reference Algorithms

**What good looks like:**
- Language-agnostic pseudocode for critical paths
- Not prescribing data structures — prescribing behavior sequences
- Error handling inline (not deferred to "see error handling section")
- Each algorithm is self-contained and readable without surrounding context

**Symphony example (why it works):**
Section 16 has 6 reference algorithms: startup, tick, reconciliation, dispatch,
worker attempt, worker exit. Each one is ~20-30 lines of pseudocode that
specifies the exact behavioral sequence.

**Anti-patterns:**
- Pseudocode that's actually Python/Java/etc. (language-specific)
- Algorithms that skip error handling
- Missing algorithms for critical paths (reader must infer the sequence)

---

## The Calibration Questions

When reviewing a spec section, ask:

1. **Could two people implement this independently and get compatible results?**
   If no → the spec is ambiguous. Find the ambiguity and resolve it.

2. **Could you write a test for every behavioral statement?**
   If no → the statement is too vague. Make it testable.

3. **Is every default value, constraint, and error path stated?**
   If no → something is implicit. Make it explicit.

4. **Can a reader understand this section without reading any other section?**
   If no → add cross-references or inline the needed context.

5. **Is this describing WHAT the system does, or HOW it's built?**
   If how → rewrite to describe behavior, not implementation.

---

## Spec Sizing Guide

Based on Symphony (a moderately complex service):

| Aspect | Symphony | Guideline |
|--------|----------|-----------|
| Total length | 2110 lines | Scale with complexity. 500-3000 lines typical. |
| Sections | 18 | 8-20 depending on feature count |
| Entities | 8 | 1 per core domain concept |
| State machines | 2 (orchestration + run attempt) | 1 per stateful entity |
| Config fields | ~25 | Every knob the operator can turn |
| Error classes | 5 categories, ~20 specific | Enumerate, don't generalize |
| Test bullets | ~80 | 1 per behavioral requirement |
| Reference algorithms | 6 | 1 per critical path |
| Checklist items | ~30 | Maps 1:1 to test matrix |

A spec that's 200 lines is almost certainly too shallow.
A spec that's 5000 lines might be over-specified or need splitting.
The right length is: every behavioral requirement is stated, no more.
