---
name: understand
description: "Deep-read a spec and all code it references. Build a mental model before designing. Use before /design, when starting a new task, or when the spec references unfamiliar code."
---

# understand

Read everything relevant to the task. No code changes in this phase — only
comprehension. The goal is to answer four questions before proceeding.

## Steps

1. **Read the spec completely.** Every section, every detail. Note:
   - What is being built or changed
   - Acceptance criteria (explicit and implied)
   - Edge cases mentioned
   - Non-functional requirements (performance, compatibility)

2. **Read every affected module.** For each file the spec mentions or that
   will need modification:
   - Read the full file, not just the function
   - Understand the module's role in the broader system
   - Note imports, dependencies, and callers

3. **Read existing tests.** For every module that will change:
   - Read the corresponding test file
   - Understand what's already tested
   - Identify test patterns used (fixtures, factories, markers)
   - Note any test infrastructure you'll need to use

4. **Identify codebase patterns.** Look at how similar things are done:
   - Naming conventions (variables, classes, files)
   - Error handling patterns
   - Logging patterns
   - Import organization
   - Dataclass vs dict vs Pydantic usage

5. **Surface risks and unknowns.** Write down:
   - Things you don't understand yet
   - Areas where the spec is ambiguous
   - Potential conflicts with existing code
   - Performance or compatibility concerns

## Exit Guard

You cannot proceed to /design until you can answer all four:

1. **What is the goal?** — One sentence, concrete, testable.
2. **Which files change?** — Complete list with what changes in each.
3. **What patterns should I follow?** — Naming, structure, error handling
   conventions already used in this codebase.
4. **What tests exist?** — Which test files cover the affected code, what
   patterns they use, what fixtures are available.

If you can't answer one of these, keep reading. If you've read everything
available and still can't answer, note it as a risk and proceed with the
gap explicitly documented.
