---
name: codecraft
description: "Full-lifecycle feature development: explore codebase, design architecture, build incrementally, verify, and ship. Use for multi-file tasks, complex features, or any work that benefits from structured execution."
argument-hint: "[task description or task ID]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion
---

# /codecraft — Structured Feature Development

Execute a complete development task from understanding through shipping. This command
orchestrates the full arc using parallel agents for exploration and design, with
explicit user gates between phases.

You will be given an optional task description or task ID. If none is provided, ask
the user what they want to build.

---

## Phase 1: Orient & Discover

**Goal:** Establish context and confirm scope.

1. Find and read `.codecraft.local.md` (cwd or git root) for project config:
   - `tracker`, `test_command`, `enforce_commands`, `conventions`
   - Read the markdown body for project context
2. If a tracker exists, read it. Identify the task (by ID or match description).
3. If a lock file exists in `current_tasks/`, report it — resume or abandon.
4. Read recent git history (`git log --oneline -10`).
5. Summarize what you understand about the task in 3-5 sentences.

**Gate:** Confirm scope with the user. "Here's what I understand — is this right?"
Wait for confirmation before proceeding.

---

## Phase 1.5: Codebase Audit (optional)

If this is the first time working in the codebase, or the user asks for an audit,
run `/audit` before exploration. This launches 3 parallel `codecraft:auditor`
agents scoring the codebase against 12 governance rules (architecture, type safety,
tooling). The health report informs exploration focus areas and design decisions.

Skip this phase if the codebase is already well-understood.

---

## Phase 2: Parallel Codebase Exploration

**Goal:** Understand the existing codebase deeply before designing anything.

Launch **2-3 explorer agents in parallel**, each investigating a different aspect:

- **Agent 1 — Feature trace:** Trace similar features in the codebase. Find entry
  points, execution paths, data transformations. Identify the pattern to follow.
- **Agent 2 — Test & convention scan:** Read existing tests for affected areas.
  Identify fixtures, factories, naming patterns, error handling conventions.
- **Agent 3 — Dependency mapping** (if needed): Map imports, interfaces, and
  integration points that the new code must respect.

Use the `codecraft:explorer` agent type for each.

After all agents return, **synthesize their findings** into a unified analysis:
- Key files (5-10 most relevant, with why each matters)
- Patterns to follow (naming, structure, error handling)
- Existing tests and infrastructure
- Risks and unknowns

**Gate:** Present the analysis. "Here's what I found in the codebase. Any areas
I should look deeper into, or shall I proceed to design?"

---

## Phase 3: Clarifying Questions

**Goal:** Eliminate specification gaps before designing.

Based on the exploration, identify questions about:
- Edge cases and error handling
- Integration points with existing code
- Performance requirements or constraints
- Ambiguous requirements

Present questions in organized sections. Wait for answers.

If no questions arise (spec is clear and codebase is well-understood), skip to
Phase 4 with a brief note: "Spec is clear — proceeding to design."

---

## Phase 4: Parallel Architecture Design

**Goal:** Present implementation alternatives and get approval.

Launch **2-3 architect agents in parallel**, each proposing a different approach:

- **Agent 1 — Minimal changes:** Least-invasive approach. What's the smallest
  set of changes that satisfies the spec?
- **Agent 2 — Clean architecture:** Principles-first approach. What's the right
  abstraction, even if it means more files?
- **Agent 3 — Pragmatic balance:** Hybrid approach that balances minimal changes
  with good structure.

Use the `codecraft:architect` agent type for each.

After all agents return, **synthesize into a recommendation**:

```
ARCHITECTURE OPTIONS
====================
Option A — Minimal (N files, M changes)
  Approach: ...
  Pros: ...
  Cons: ...

Option B — Clean (N files, M changes)
  Approach: ...
  Pros: ...
  Cons: ...

Option C — Pragmatic (N files, M changes)
  Approach: ...
  Pros: ...
  Cons: ...

RECOMMENDATION: Option X because...
```

**Gate:** Present options. "Which approach do you prefer, or should I go with my
recommendation?" Wait for selection.

After selection, produce the **change plan** — a numbered, ordered list of units:

```
CHANGE PLAN
===========
Phase 1: <description>
  1. <file> — <what changes>
     Verify: <command>
  2. <file> — <what changes>
     Verify: <command>

Risks:
  - <risk 1>
```

---

## Phase 5: Incremental Build

**Goal:** Implement one unit at a time with verification after each.

For each unit in the change plan:

1. **READ** — Read the file(s) you're about to modify. Every time, even if you
   read them before. The file may have changed.
2. **CHANGE** — Make one logical change. Follow codebase patterns identified in
   Phase 2. Match conventions exactly.
3. **CHECK** — Run the verification command for this unit.
   - Pass → next unit
   - Fail → **FIX** (targeted fix, not rewrite)
   - Same failure 3 times → **RETHINK** (stop, diagnose, redesign)

**RETHINK protocol** (if triggered):
1. Stop implementing. Do not make another fix attempt.
2. Diagnose: "My approach failed because ___." Categorize the failure.
3. Preserve failed code (comment out, don't delete).
4. Choose: redesign (back to Phase 4) or re-explore (back to Phase 2).
5. Use the `codecraft:diagnoser` agent if test failures are complex.

Track progress: after each unit, note "Unit N/M complete."

---

## Phase 6: Four-Pass Verification

**Goal:** Quality gate using parallel agents. All 4 passes must succeed.

Use the `codecraft:verifier` agent for Passes 1-2 to keep verbose output out
of the main conversation.

**Pass 1 — Correctness:**
Run the project's test command. All tests must pass.

**Pass 2 — Compliance:**
Run all enforcement commands. No new violations in files you touched.

**Pass 3 — Quality (parallel review):**
Launch 3 `codecraft:reviewer` agents examining different dimensions:
- **Reviewer 1:** Spec compliance — every requirement implemented, no scope creep
- **Reviewer 2:** Codebase conventions — patterns match, naming consistent
- **Reviewer 3:** Code quality — no dead code, no debug artifacts, proper error handling

Reviewers use **≥80% confidence threshold** — only high-confidence issues reported.

**Pass 4 — Governance (audit new code):**
Get the list of changed files (`git diff --name-only`). Launch 3 parallel
`codecraft:auditor` agents scoped to **only those files**:
- **Auditor 1 — Architecture:** Pure imports? Boundary violations? Ad-hoc globals?
  Side effects in wrong layers?
- **Auditor 2 — Type Safety:** Missing annotations? Mutable data where frozen fits?
  Bare exception catches?
- **Auditor 3 — Tooling:** Tests properly layered? No dynamic magic? Deps specified?

New code must not introduce governance debt. Pre-existing violations in untouched
files are not blocking.

**Recovery (REFINE):**
If any pass fails:
1. Identify the specific failure
2. Make a targeted fix (return to Phase 5 for that unit)
3. Re-run ALL passes (a fix can introduce regressions)
4. If same failure 3+ times → RETHINK

**Gate:** "All 4 passes succeeded" or "Issues found: [list]. Fix now?"

---

## Phase 7: Ship

**Goal:** Commit, update tracker, clean up.

1. **Stage specific files.** `git add <file1> <file2> ...` — never `-A`.
2. **Commit with task reference:**
   ```
   feat(<area>): <what was done>

   Implements <TASK_ID>. <brief context.>
   ```
3. **Update tracker** (status → done) if tracker exists.
4. **Remove lock file** if one was created.
5. **Summary:** List what was built, files changed, architectural decisions made,
   and any follow-up work identified.

---

## Budget Awareness

Monitor context budget throughout. Adjust behavior at thresholds:

| Remaining | Behavior |
|-----------|----------|
| > 70% | Full iteration through all phases |
| 30-70% | Finish current unit, skip to verification, ship what works |
| < 30% | Commit what you have. Write progress note. Handoff. |
| < 10% | Emergency: minimal commit + stuck note |

For partial handoff, write a progress note:
```
# <TASK_ID> — Progress Note
Completed: [list of done units]
In Progress: [current unit and state]
Remaining: [uncompleted units]
Context: [key insights, failed approaches]
```

---

## When NOT to Use /codecraft

- Single-line fixes → just fix it directly
- Trivial modifications → too much overhead
- Well-specified simple tasks → use individual skills (/design, /verify)
- Emergency hotfixes → skip the ceremony

Individual skills (/orient, /select, /understand, /design, /verify, /handoff,
/rethink, /status) remain available for manual, targeted use.
