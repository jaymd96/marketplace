# spec-builder

Build complete, consistent product specifications through extended multi-session
human conversation. A harness for turning noisy, non-linear human input into
coherent, implementable specs (modeled on OpenAI's Symphony SPEC.md format).

## When to use these skills

- **spec-session** — The user wants to define a new product, scope out a system,
  or build a technical specification through conversation. This is the main entry
  point that loads the full spec-builder system.
- **orient** — Quick briefing on current spec project state. Use at session start
  to orient without reading every file manually.
- **new-feature** — Create a new feature dossier folder with template files when
  a new feature area is identified during conversation.
- **checkpoint** — Serialize session state, write self-review, and git commit.
  Use at session end or when context is getting long.
- **coverage** — Show feature exploration coverage status across all features.
- **consistency** — Cross-reference all project documents to find contradictions,
  terminology drift, and gaps.
- **review** — Audit the specification for quality across 5 dimensions
  (completeness, consistency, clarity, testability, organization).

## Architecture

The system uses two complementary models:

- **The Journey** (linear arc): Intake -> Explore -> Model -> Reconcile -> Structure -> Draft -> Review -> Deliver. This guides overall progress.
- **The Stances** (operating modes): Understand, Organize, Produce, Validate. These are what you actually do moment-to-moment, switching as the conversation demands.

The journey guides. The stances operate. The agent follows the conversation,
adopts the right stance, and uses the journey to track overall progress.

## Key principles

1. **Human input is noisy.** Expect tangents, contradictions, and gaps. Navigate
   them, not fight them.
2. **Separate raw from processed.** Human's words in `human/`, agent understanding
   in `internal/`, spec output in `spec/`. Never mix.
3. **Detect inconsistencies actively.** Surface contradictions immediately with a
   proposed resolution.
4. **Serialize aggressively.** Context will be lost between sessions. Write
   everything needed to resume.
5. **Git is your memory.** Every session is committed. Use `git log` and `git diff`
   to understand evolution.
6. **The workflows are not the work.** The work is thinking deeply about the
   product. The workflows exist for resumability.

## Subagents

Three subagents run in isolated context windows to protect the main conversation:

- **orient** — Reads all state files, produces a 20-30 line briefing
- **consistency-checker** — Cross-references all documents for contradictions
- **spec-reviewer** — 5-dimension quality audit of the spec

## Entry point

Always start by reading `system/ENTRYPOINT.md`. It routes the session.

## Constraints

- Don't read every file at session start. Use /orient or the resumption prompt.
- Don't let process overhead displace thinking. If you're spending more time on
  files than on the product, you've inverted the priority.
- Don't gate the conversation. The journey is guidance, not a sequence to enforce.
