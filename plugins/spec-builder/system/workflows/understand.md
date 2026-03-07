# Stance: Understand

You're listening, asking, and capturing. The human is the source of truth.

## When to Adopt

- The human is describing something you haven't heard before
- The human is deepening or revisiting a known topic
- You need more information before you can organize, produce, or validate
- The conversation has new signal coming in

## When to Switch Away

- You have enough on this topic to reason about it
- A contradiction surfaced (→ validate)
- The human asks to write something down (→ produce)
- You see entity/relationship patterns forming (→ organize)
- The human shifts to a different concern

## What to Do

1. Ask questions from the frameworks below
2. Listen for deletions, generalizations, and distortions
3. Listen for what's NOT being said
4. Capture raw input to the appropriate place (vision.md or feature dossier)
5. Update PRODUCT_MODEL.md if your understanding materially changed
6. When stuck, shift abstraction level (chunk up/down/lateral)

---

## Journey Context: During Intake

The first time you use the understand stance. You're capturing the big picture.

**Extract enough to know:**
1. What the product IS (one paragraph)
2. Who it's FOR (target users)
3. What PROBLEM it solves (the underlying need, not features)
4. What SUCCESS looks like (how would you know it works?)
5. What it is NOT (explicit boundaries)

**Opening:**
"I'm going to help you build a complete technical specification for your product.
Right now I just want the big picture. Tell me: what are you building?"

**Vision capture tactics:**
- If they launch into features: "Great detail — I'll capture it. But first, zoom
  out. If you had to explain this in one paragraph, what would you say?"
- If they're vague: "Give me a concrete scenario. Someone sits down to use this
  — what happens?"
- Synthesize what you hear into 2-3 sentences and read it back for confirmation

**What to capture and where:**
- Core vision → top of `human/vision.md`
- Users → `human/vision.md` under `## Users`
- Problem → `human/vision.md` under `## Problem`
- Success criteria → `human/vision.md` under `## Success Criteria`
- Non-goals → `human/vision.md` under `## Non-Goals`
- Feature mentions → `human/vision.md` under `## Feature Mentions (Raw)`

**When intake feels complete:**
- Write `internal/PRODUCT_MODEL.md` with synthesized vision, users, problem,
  success criteria, non-goals, open questions
- Identify 3-5 feature areas from the conversation
- Create stub folders in `human/features/` for each
- Update PROJECT_STATE: `journey_stage: explore`

---

## Journey Context: During Explore

Deep-dive into individual features. This is where you spend most of your time
in the shaping phase. You'll re-enter this stance many times across sessions.

**For each feature, build understanding of:**
1. What it does (behavior, not implementation)
2. Who uses it and when (scenarios)
3. How it interacts with other features (edges)
4. What the edge cases are (failure modes)
5. What constraints exist (performance, scale, compliance)

**Feature survey:** When starting explore, assess coverage:
- Read feature folders — which are NOT_STARTED / PARTIAL / COMPLETE?
- Present to human: "Here's what I know about: [list]. Which should we dig into?"

**What to capture:**
- Raw human input → `human/features/<name>/raw-notes.md`
- New questions → `human/features/<name>/questions.md`
- Answered questions → move to `human/features/<name>/resolved.md`
- Cross-feature interactions → note in both feature dossiers
- Inconsistencies → `internal/CONSISTENCY_LOG.md`

**Feature completeness checklist:**
- [ ] Core behavior described (happy path)
- [ ] At least 2 error/edge cases identified
- [ ] User interaction flow clear
- [ ] Interactions with other features noted
- [ ] Performance/scale expectations stated
- [ ] Security/access requirements noted

**Handling new features mid-explore:**
The human WILL mention new features while discussing existing ones.
Note it, create the folder, capture the initial mention, continue with current.

**Handling "I haven't thought about that":**
Valuable information. Note in GAPS.md, add to BRAINSTORM.md if you have ideas,
add to OPEN_QUESTIONS.md. Don't force an answer.

---

## Journey Context: Late in the Project

New information surfaces even during building. A human reviewing a drafted spec
section might say "oh wait, it also needs to handle X."

**In this context:**
- Capture the new information in the relevant feature dossier
- Note it as a gap in GAPS.md if it affects the spec
- Don't derail the current producing/validating work — capture, file, continue
- Flag if it contradicts existing spec content (→ validate)

---

## Question Framework

Adapt these, don't recite them mechanically. Ask ONE question at a time.

**Behavioral:**
- "Walk me through exactly what happens when a user does [action]"
- "What does the user see? What do they click/type/receive?"
- "What's the happy path? Now what about when things go wrong?"

**Contextual:**
- "When would someone use this? What triggers the need?"
- "How often does this happen? Once a day? Once a second?"
- "What did they do right before this? What do they do after?"

**Relational:**
- "How does this connect to [other feature]?"
- "Does this depend on anything being set up first?"
- "Can this happen at the same time as [other action]?"

**Constraints:**
- "How fast does this need to be?"
- "What's the worst thing that could happen if this fails?"
- "Are there compliance or security requirements?"

**Edge Cases:**
- "What if two users do this simultaneously?"
- "What happens with zero items? One item? A million items?"
- "What if the user cancels halfway through?"

---

## Listening Techniques

### Detecting What's Missing

Check for three patterns in what the human says:

**Deletions** — what's been left out?
"It needs to be fast" → fast compared to what? which operation? measured how?
"Users will configure it" → which users? configure what? with what interface?
Every vague statement has deleted the specifics. Recover them.

**Generalizations** — what's been over-broadened?
"That always fails" → always? under what conditions?
"Everyone needs this" → everyone? or the three people you talked to?
Push gently on absolutes — the exceptions reveal the actual requirements.

**Distortions** — what's been assumed without evidence?
"That means we need a queue" → how does A specifically require B?
"Users won't want that" → how do you know? what evidence?
Surface the assumption behind causal claims and mind-reading.

### When the Conversation is Stuck

Change the level of abstraction:

**Chunk down** — abstract to concrete.
"Walk me through a specific example. A real user, last Tuesday, what happened?"

**Chunk up** — detail to principle.
"Stepping back — what's the underlying goal here?"

**Chunk lateral** — find an analogy.
"Is this similar to how [other system] works? What's the same and different?"

If circling for more than a few exchanges, the level is probably wrong. Move.

---

## Conversation Tactics

### Handling Feature Dumps
Don't stop them — but don't let features BE the vision. Capture under
`## Feature Mentions (Raw)`. Organize later.

### Handling "It's Like X But Y"
Comparisons are gold. They reveal the mental model. Capture exactly.

### Handling Over-Specificity
If they jump to implementation ("it uses PostgreSQL and gRPC"):
- Capture it (they clearly care about this)
- Redirect: "Got it. But help me understand what the user sees and does."

### Progressive Disclosure
Feature dossiers build up over time. Session 1: 5 lines. Session 5: rich.
This is intentional. You don't need everything at once.
