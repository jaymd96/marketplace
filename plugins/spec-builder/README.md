# Spec Builder

A harness for building product specifications through extended human conversation.

## What This Is

Spec Builder is an operational environment for an AI agent whose job is to extract,
organize, and refine product requirements from a human into a formal, implementable
specification (modeled on OpenAI's Symphony SPEC.md format).

The problem it solves: humans think about products at a high level — fragmented,
non-linear, sometimes contradictory. Converting that into a coherent spec requires
sustained, structured dialogue across many sessions. The agent doing this work faces
three environment-level challenges:

1. **Context loss.** The agent's memory resets between sessions. Everything needed
   to resume must be in files.
2. **Noisy input.** The human goes on tangents, introduces contradictions, changes
   their mind, and operates at varying levels of abstraction.
3. **Long-running coordination.** The work spans many sessions, each building on
   the last. Without structure, the accumulated understanding drifts and decays.

These are not model limitations — a smarter model in the same unstructured
environment would hit the same problems. They are environment limitations. Spec
Builder is the harness that addresses them.

## Harness Architecture

The system is designed around the four components of a well-harnessed environment.

### Context: What the Agent Can See

The agent operates on what it can access. Spec Builder organizes knowledge for
progressive disclosure through a stable entry point and layered detail:

| Layer | What It Contains | When to Read |
|-------|-----------------|-------------|
| `system/ENTRYPOINT.md` | Session router, current state, what to do next | Every session, first thing |
| `state/PROJECT_STATE.md` | Workflow position, pending actions, resumption prompt | Every session, during housekeeping |
| `state/SESSION_LOG.md` | What happened in recent sessions | Every session, last 3 entries |
| `internal/PRODUCT_MODEL.md` | Agent's synthesized understanding of the product | When reasoning about the product |
| `human/features/<name>/` | Raw human input per feature, progressive depth | When exploring or drafting a specific feature |
| `spec/SPEC.md` | The specification being built | When drafting or reviewing |

The entry point is the map — small, stable, always read first. It teaches the agent
where to look next. The detail lives in the layers beneath it, organized by concern
(human input vs. agent understanding vs. spec output) and by topic (per-feature
dossiers).

**Anti-pattern avoided:** One massive instruction file. The system separates
navigation (ENTRYPOINT.md) from content (everything else), and separates raw human
input (human/) from processed understanding (internal/) from the deliverable (spec/).

### Capabilities: What the Agent Can Do

The agent has tools for the three categories of capability that matter:

**Verification** — can the agent check its own work?
- Housekeeping checklists at the end of every workflow (completeness checks)
- Consistency auditing during the review workflow (5-dimension quality check)
- Self-review scoring after every session (honest self-assessment)
- Git diff between sessions to verify what actually changed vs. what should have

**Query** — can the agent discover what it needs to know?
- Git log/diff for reconstructing history after context loss
- Feature coverage table in PROJECT_STATE.md for knowing what's explored vs. not
- OPEN_QUESTIONS.md and GAPS.md as queryable inventories of unknowns
- CONSISTENCY_LOG.md for tracking what's been resolved vs. what's still in conflict

**Generation** — can the agent produce correct-by-construction artifacts?
- Templates for all document types (project state, feature dossiers, decisions,
  session reviews, spec outline) — the agent fills in structure, not invents it
- Spec outline template following the Symphony pattern — sections are pre-defined,
  the agent populates them

### Constraints: What the System Prevents

Constraints are encoded as workflow rules and protocols, not optional guidelines:

**The session protocol** (ENTRYPOINT.md) prevents context drift:
- Must read ENTRYPOINT.md first (no guessing state)
- Must run housekeeping before working (no stale understanding)
- Must serialize state before ending (no lost progress)
- Must commit to git after every session (no invisible changes)

**The self-evolution protocol** (`workflows/meta.md`) prevents impulsive system changes:
- Requires 3+ session reviews citing the same issue (no single-observation changes)
- Requires a formal proposal with risk assessment (no undocumented changes)
- Requires a 2-3 session trial period (no untested changes)
- Requires explicit evaluation before committing (no silent adoption)

**"The Real Work" principle** (ENTRYPOINT.md) prevents mechanical process theater:
- Names three failure modes explicitly (context-switching, recursive descent,
  process theater) so the agent can catch itself
- States that workflows are checkpoints for resumability, not the work itself

**Anti-pattern avoided:** Constraints without remediation. Every constraint in the
system tells the agent what to do instead, not just what went wrong.

### Maintenance: What Prevents Decay

Over many sessions, entropy accumulates — documents drift from each other,
terminology shifts, old decisions get forgotten. The system has three maintenance
mechanisms:

**Session self-review** (`workflows/meta.md`): After every session, the agent scores
itself on 6 dimensions (signal, steering, consistency, hygiene, progress, depth).
Patterns accumulate across reviews, making decay visible before it compounds.

**Self-evolution protocol** (`workflows/meta.md`): When observations accumulate across 3+
sessions, the system can modify its own workflows — with a soak period, trial
evaluation, and explicit commit/revert decision. This is how the harness improves
over time without decaying through impulsive changes.

**Git history**: Every session is an atomic commit. The agent can diff between any
two points in time to see how understanding evolved, catch documents that drifted
apart, or reconstruct context after a total memory loss. Milestone tags mark
workflow transitions.

## How to Use

### Starting a new spec project

Read `system/SKILL.md` for when to trigger this system, then follow
`system/ENTRYPOINT.md`. It will bootstrap a project directory and begin the intake
conversation.

### Resuming an existing project

Read `system/ENTRYPOINT.md`. It will locate the project, restore state from files
and git history, and route to the correct workflow.

### The workflow sequence

```
bootstrap → intake → explore → model → reconcile → structure → draft → review → deliver
                       ↑          |                                        |       |
                       └──────────┘                                        └───────┘
                    (gaps found)                                      (issues found)
```

Workflows are composable, not strictly sequential. The agent follows them as guides,
not rails. The human can redirect at any time — the agent captures the signal,
updates state, and adapts.

## Directory Structure

```
spec-builder/
  README.md                           # You are here
  system/                             # The harness (stable, evolves cautiously)
    SKILL.md                          # When to trigger, core principles
    ENTRYPOINT.md                     # Session router (always read first)
    workflows/                        # State machine definitions (11 workflows)
    templates/                        # Document scaffolds (5 templates)
    evolution/                        # System self-modification records
      CHANGELOG.md                    # History of harness changes
      observations.md                 # Evidence bank for proposed changes
      proposals/                      # Evolution proposals
      trials/                         # Active trial versions

  <project-dir>/                      # Created per-project (one per spec)
    state/                            # Workflow position, session history, decisions
    human/                            # Raw human input, organized by feature
    internal/                         # Agent's processed understanding
    reviews/                          # Post-session self-assessments
    spec/                             # The specification (output artifact)
```

## Design Principles

**The harness should get simpler as models improve.** Every workflow state,
every template field, every housekeeping step is a hypothesis: "the agent can't
reliably do X on its own, so the environment must handle it." When that hypothesis
becomes false, the harness element should be removed.

**Capabilities before constraints.** The system provides conversation tools
(question frameworks, listening patterns, abstraction-level shifting) before it
provides rules (housekeeping checklists, session protocols). Making the right
approach easy is more valuable than catching the wrong approach after the fact.

**Separation of concerns.** Human input, agent understanding, and spec output are
physically separated in the file system. This prevents the agent from confusing
what the human said with what it thinks the human meant, or either of those with
what the spec should say.

**Progressive disclosure.** Feature dossiers start empty and fill over sessions.
The agent doesn't need everything at once. Each session adds depth where it matters
most, and the file structure makes it obvious where coverage is thin.

**Git as the ground truth.** Files can be corrupted, state can drift, context can
be lost. The git history is the immutable record. Any point in the project's
evolution can be reconstructed from a commit hash.
