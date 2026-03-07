# Spec Builder

Build complete, consistent product specifications through extended human conversation.

## When to Use

Trigger when the user wants to:
- Define a new product or service from scratch
- Build a technical specification through conversation
- Scope out requirements for a system that doesn't exist yet
- Turn vague ideas into structured, implementable specifications

## What This Is

This is a harness — an operational environment that makes an AI agent effective at
a specific kind of knowledge work: extracting coherent product specifications from
extended, noisy human conversation.

The agent's effectiveness here is bounded not by its reasoning ability but by the
environment it operates in. This system provides what the environment must supply:

- **Context** — progressive disclosure from a stable entry point (ENTRYPOINT.md)
  through layered state files, feature dossiers, and the evolving spec
- **Capabilities** — conversation tools (question frameworks, listening patterns,
  abstraction shifting), verification tools (consistency checks, self-review),
  and generation tools (templates for all document types)
- **Constraints** — session protocols that prevent context drift, evolution
  protocols that prevent impulsive self-modification, depth checks that prevent
  mechanical process theater
- **Maintenance** — self-review scoring across sessions, evidence-based
  self-evolution, git history as immutable record

Read the parent `README.md` for the full harness architecture.

## Entry Point

**Always start by reading `ENTRYPOINT.md` in this directory.** It will tell you:
1. Whether a project exists or needs bootstrapping
2. What workflow state you're in
3. What to do next

Do not skip ENTRYPOINT.md. Do not guess the state. Read it every time.

## Core Principles

1. **Human input is noisy.** Expect tangents, contradictions, and gaps. Your job is to
   navigate them, not fight them.
2. **Separate raw from processed.** Human's words go in `human/`. Your understanding goes
   in `internal/`. The spec goes in `spec/`. Never mix these.
3. **Detect inconsistencies actively.** When the human says something that contradicts an
   earlier statement, raise it immediately with a proposed resolution.
4. **Serialize aggressively.** Before ending any interaction, write everything you'll need
   to resume. You WILL lose your memory.
5. **The spec is the product.** Every conversation should move the spec forward. If it
   doesn't, you've lost the thread.
6. **Git is your memory.** Every session is committed. Use `git log` and `git diff` to
   understand evolution over time. The commit history IS the project timeline.
7. **Review yourself honestly.** After every session, assess what worked and what didn't.
   This compounds — patterns become visible over time.
8. **Evolve cautiously.** The system can modify its own workflows, but only with repeated
   evidence, a soak period, and explicit evaluation. Never change on impulse.

## Directory Layout

```
spec-builder/                         # Landing zone
  README.md                           # Harness architecture and design rationale
  plugin.toml                         # Plugin manifest

  agents/                             # Subagents (isolated context)
    orient.md                         # Session-start briefing
    consistency-checker.md            # Cross-document contradiction finder
    spec-reviewer.md                  # 5-dimension spec quality auditor

  skills/                             # Invocable commands
    spec-session.md                   # Main entry point
    orient.md                         # Quick briefing via subagent
    new-feature.md                    # Create feature tracking directory
    checkpoint.md                     # Session-end protocol
    coverage.md                       # Feature status table
    consistency.md                    # Find contradictions
    review.md                         # Spec quality audit

  scripts/                            # Mechanical operations
    bootstrap-project.sh              # Create project directory
    coverage-report.sh                # Scan feature status
    validate-state.sh                 # Sanity check state files

  system/                             # The harness (you are here)
    SKILL.md                          # Trigger conditions, principles, layout
    ENTRYPOINT.md                     # Session router (read every time)
    workflows/                        # Stance reference files
      bootstrap.md                    # One-time project setup
      understand.md                   # Stance: listening, asking, capturing
      organize.md                     # Stance: modeling, structuring, relating
      produce.md                      # Stance: drafting, delivering spec content
      validate.md                     # Stance: checking consistency, reviewing
      meta.md                         # Stance: self-review + self-evolution
    templates/                        # Document scaffolds
    evolution/                        # System self-modification records

<project-dir>/                        # Created per-project (git-initialized)
  state/
    PROJECT_STATE.md                  # Phase, stage, stance, resumption prompt
    SESSION_LOG.md                    # Chronological session history
    OPEN_QUESTIONS.md                 # Unanswered questions
    DECISIONS.md                      # All decisions with rationale
  human/
    vision.md                         # Initial product vision (raw)
    features/                         # One folder per feature area
      <feature-name>/
        raw-notes.md                  # Verbatim human input
        questions.md                  # Open questions
        resolved.md                   # Answered questions + decisions
  internal/
    PRODUCT_MODEL.md              # Agent's current product understanding
    CONSISTENCY_LOG.md            # Contradictions found and resolved
    BRAINSTORM.md                 # Agent's own ideas and analysis
    GAPS.md                       # Known unknowns
    RISK_REGISTER.md              # Technical and logical risks
  reviews/                        # Session self-reviews (one per session)
    session-1.md                  # Review of session 1
    session-2.md                  # Review of session 2, etc.
  spec/
    SPEC.md                       # The specification (output artifact)
```
