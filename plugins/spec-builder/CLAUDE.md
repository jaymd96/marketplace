# spec-builder

Build complete, consistent product specifications through extended multi-session
human conversation. A harness for turning noisy, non-linear human input into
coherent, implementable specs (modeled on OpenAI's Symphony SPEC.md format).

## Quick Start

**`/spec [product name or 'resume']`** — Full session lifecycle: orient on current
state, follow the conversation adopting the right stance, checkpoint at session end.
Handles both new projects and resuming existing ones.

For targeted checks during or outside a session:
- `/review` — Parallel spec quality review (3 agents, 5 dimensions, confidence-scored)
- `/consistency` — Parallel cross-document consistency check (2-3 agents, different doc pairs)
- `/audit` — Full rubric-based readiness assessment (3 agents, 9 criteria)
- `/coverage` — Feature exploration status report
- `/new-feature` — Create a feature dossier when new feature area identified
- `/checkpoint` — Serialize state, self-review, git commit

## Architecture

The system uses two complementary models:

- **The Journey** (linear arc): Intake -> Explore -> Model -> Reconcile -> Structure -> Draft -> Review -> Deliver. This guides overall progress.
- **The Stances** (operating modes): Understand, Organize, Produce, Validate. These are what you actually do moment-to-moment, switching as the conversation demands.

The journey guides. The stances operate. The agent follows the conversation,
adopts the right stance, and uses the journey to track overall progress.

## Agents

| Agent | Purpose | Model |
|-------|---------|-------|
| **orient** | Read state files, produce 20-30 line session briefing | sonnet |
| **consistency-checker** | **Parallel** cross-document contradiction detection (>=80% confidence) | sonnet |
| **spec-reviewer** | **Parallel** quality review across dimensions (>=80% confidence) | opus |
| **spec-auditor** | **Parallel** rubric-based readiness audit (3 groups, 9 criteria) | opus |

Agents are designed for **parallel execution**: `/review` launches 3 reviewers
examining different dimensions, `/consistency` launches 2-3 checkers scanning
different document pairs, `/audit` launches 3 auditors covering structure,
consistency, and delivery readiness.

All review/consistency/audit agents use **>=80% confidence threshold** — only
high-confidence issues are surfaced. This eliminates nitpicks and false positives.

## Key Principles

1. **Human input is noisy.** Expect tangents, contradictions, and gaps. Navigate
   them, not fight them.
2. **Separate raw from processed.** Human's words in `human/`, agent understanding
   in `internal/`, spec output in `spec/`. Never mix.
3. **Detect inconsistencies actively.** Surface contradictions immediately with a
   proposed resolution.
4. **Review with confidence.** Only surface issues >=80% confidence. No nitpicks.
5. **Serialize aggressively.** Context will be lost between sessions. Write
   everything needed to resume.
6. **Git is your memory.** Every session is committed. Use `git log` and `git diff`
   to understand evolution.
7. **The workflows are not the work.** The work is thinking deeply about the
   product. The workflows exist for resumability.

## Entry Point

The `/spec` command handles session lifecycle automatically. For the full
operating model, read `system/ENTRYPOINT.md` — it contains the journey map,
stance routing, session protocols, and all operating guidance.

## Constraints

- Don't read every file at session start. Use `/spec` (which runs the orient agent).
- Don't let process overhead displace thinking. If you're spending more time on
  files than on the product, you've inverted the priority.
- Don't gate the conversation. The journey is guidance, not a sequence to enforce.
