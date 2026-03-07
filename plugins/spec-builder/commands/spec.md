---
name: spec
description: "Build a product specification through conversation. Handles the full session lifecycle: orient, converse, checkpoint. Use when defining a product, scoping a system, writing requirements, or building a technical specification."
argument-hint: "[product name or 'resume']"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion
---

# /spec — Specification Building Session

Start or resume a spec-building session. This command handles the full session
lifecycle: orient on current state, follow the conversation adopting the right
stance, and checkpoint at session end.

You will be given an optional product name or "resume". If none is provided, ask
the user what they want to build.

**Read `system/ENTRYPOINT.md` in this plugin's directory first.** It contains the
journey map, stance routing, session protocols, and all operating guidance.
Everything below supplements that document — it does not replace it.

---

## Phase 1: Session Start

**Goal:** Orient on current state without consuming context budget.

1. **Check if a project exists.** Look for a spec project directory (containing
   `state/PROJECT_STATE.md`). Search current directory, then parent directories.

2. **If no project exists** (new spec):
   - Ask the user what they want to build
   - Run bootstrap: create project directory structure using
     `scripts/bootstrap-project.sh` or manually create the directories
   - Capture initial vision in `human/vision.md`
   - Set phase to SHAPING, stage to Intake

3. **If project exists** (resuming):
   - Launch the `spec-builder:orient` agent to produce a 20-30 line session
     briefing from state files. This protects the main context.
   - Read the resumption prompt from PROJECT_STATE.md
   - Present the briefing: "Here's where we left off..."

**Gate:** Confirm with the user. "Ready to continue from here, or is there
something specific you want to work on?"

---

## Phase 2: Conversation

**Goal:** Follow the human's lead, adopting the right stance.

This is the core of spec-building. The human drives the conversation. You follow
it, switching stances as needed:

- **Understand** — They're explaining something. Listen, ask, capture in feature
  dossiers. Don't summarize prematurely.
- **Organize** — They've given enough raw input. Extract entities, relationships,
  state machines into PRODUCT_MODEL.md.
- **Produce** — They want something written. Draft spec sections.
- **Validate** — Something seems inconsistent. Surface contradictions immediately
  with a proposed resolution.

**Stance switching is fluid.** You don't announce "switching to organize mode."
You just start organizing when the conversation calls for it.

**During conversation, watch for:**
- New features → create feature dossier (`human/features/<name>/`)
- Contradictions → surface immediately with recommendation
- Decisions → record in `state/DECISIONS.md`
- Open questions → track in `state/OPEN_QUESTIONS.md`
- Tangents → note them, gently redirect when appropriate

**Use subagents when context is at risk:**
- Feature coverage getting complex → run `/coverage`
- Suspect contradictions across documents → run `/consistency`
- Ready to assess spec quality → run `/review` or `/audit`

---

## Phase 3: Quality Checks (as needed)

**Goal:** Use parallel agents to check quality without consuming main context.

These can be triggered at any point during the conversation, not just at the end.
Trigger them when:
- The user asks "is the spec ready?" or "how are we doing?"
- You've done significant writing and want to check quality
- The conversation has surfaced potential contradictions
- Moving from SHAPING to BUILDING phase

**Consistency check** (`/consistency`):
Launch **2-3 parallel consistency-checker agents**, each scanning different
document pairs:
- Checker 1: spec/SPEC.md vs internal/PRODUCT_MODEL.md
- Checker 2: Feature dossiers vs each other (cross-feature consistency)
- Checker 3: state/DECISIONS.md vs spec/SPEC.md + PRODUCT_MODEL.md

**Spec review** (`/review`):
Launch **3 parallel spec-reviewer agents**, each examining different quality
dimensions:
- Reviewer 1: Completeness + organization
- Reviewer 2: Consistency + clarity
- Reviewer 3: Testability + implementability

All reviewers use **>=80% confidence threshold** — only high-confidence issues
are surfaced to the user.

**Spec audit** (`/audit`):
Full rubric-based audit against the spec-rubric.md quality standard. Launch
parallel auditors examining structural, content, and delivery dimensions.

---

## Phase 4: Session End

**Goal:** Serialize state for resumability.

When the session is ending (user says "let's wrap up", context getting long, or
natural stopping point):

1. **Update PROJECT_STATE.md:**
   - Current phase and stage
   - Write a specific resumption prompt (not generic — what exactly to do next)
   - List pending actions

2. **Update SESSION_LOG.md:**
   - Append 2-5 sentence session summary
   - Note key decisions made, features explored, spec sections written

3. **Update other files** only if they changed this session:
   - OPEN_QUESTIONS.md, PRODUCT_MODEL.md, CONSISTENCY_LOG.md, GAPS.md
   - Feature dossiers, DECISIONS.md, spec sections

4. **Write session self-review** to `reviews/session-<N>.md`

5. **Git commit** all changes as a single atomic commit:
   ```
   spec(<product>): session <N> — <1-line summary>
   ```

6. **Tag if milestone** (journey stage changed, spec version bumped)

---

## Budget Awareness

Long spec conversations consume context. Watch for signs:

| Signal | Action |
|--------|--------|
| Conversation flowing well | Continue — this is the real work |
| Context getting large | Checkpoint mid-session, then continue |
| Complex quality check needed | Use subagents (they have their own context) |
| Session naturally winding down | Run Phase 4 checkpoint |

---

## When NOT to Use /spec

- Quick one-off question about a spec → just answer it
- Running a specific check → use `/consistency`, `/review`, or `/audit` directly
- Checking feature coverage → use `/coverage` directly
- Creating a feature dossier → use `/new-feature` directly

The individual skills remain available for targeted use within or outside of a
`/spec` session.
