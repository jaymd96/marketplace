---
name: understand
description: "Deep-read a spec and all code it references using parallel explorer agents. Build a mental model before designing. Use before /design, when starting a new task, or when the spec references unfamiliar code."
---

# understand

Read everything relevant to the task using **parallel exploration agents**.
No code changes in this phase — only comprehension. The goal is to answer
four questions before proceeding.

## Steps

1. **Read the spec completely.** Every section, every detail. Note:
   - What is being built or changed
   - Acceptance criteria (explicit and implied)
   - Edge cases mentioned
   - Non-functional requirements (performance, compatibility)

2. **Launch 2-3 parallel explorer agents.** Each investigates a different
   aspect of the codebase simultaneously:

   - **Explorer 1 — Feature trace:** Trace similar features or the code
     paths that will be affected. Find entry points, execution flows,
     data transformations. Use the `codecraft:explorer` agent.

   - **Explorer 2 — Test & convention scan:** Read existing tests for
     affected areas. Identify fixtures, factories, naming patterns, error
     handling conventions, import organization. Use the `codecraft:explorer`
     agent.

   - **Explorer 3 — Dependency mapping** (if the feature touches multiple
     modules): Map imports, interfaces, and integration points that new
     code must respect. Use the `codecraft:explorer` agent.

3. **Synthesize exploration results.** After all agents return, combine
   their findings into a unified analysis:
   - Key files (5-10 most relevant, with why each matters)
   - Patterns to follow (naming, structure, error handling)
   - Existing test infrastructure
   - Risks and unknowns

4. **Surface gaps.** Identify:
   - Things the explorers didn't find answers to
   - Spec ambiguities that exploration didn't resolve
   - Potential conflicts between existing code and spec requirements

## Exit Guard

You cannot proceed to /design until you can answer all four:

1. **What is the goal?** — One sentence, concrete, testable.
2. **Which files change?** — Complete list with what changes in each.
3. **What patterns should I follow?** — Naming, structure, error handling
   conventions already used in this codebase.
4. **What tests exist?** — Which test files cover the affected code, what
   patterns they use, what fixtures are available.

If you can't answer one of these after exploration, note it as a risk and
proceed with the gap explicitly documented.
