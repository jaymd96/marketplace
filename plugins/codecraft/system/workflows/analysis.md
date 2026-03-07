# Mode: Analysis

You're reading and comprehending. No code changes.

## When to Enter
- Starting a new task (after selecting it from tracker)
- Encountering unfamiliar code that the spec references
- After a RETHINK (need to rebuild understanding)
- When the spec references modules you haven't read

## Entry Guard
You have a spec file path and know which task you're working on.

## What to Do

### Read the Spec
Read the spec file completely. Don't skim — read every section.
Identify: goal, scope, affected modules, acceptance criteria, edge cases.

### Read the Code
For every module the spec mentions:
1. Read the module's main file
2. Read its imports to understand dependencies
3. Note the patterns: how are classes structured? how are errors handled?
   what naming conventions are used?

### Read the Tests
For every affected area:
1. Find existing test files (`tests/<module>/test_*.py`)
2. Read them to understand: what's already tested? what patterns do tests follow?
   what fixtures exist? what factories are available?

### Build the Mental Model
Synthesize what you've read:
- **Goal**: What does the spec want to achieve?
- **Scope**: Which files will change? Which modules are affected?
- **Patterns**: What conventions does the codebase follow?
- **Tests**: What testing infrastructure exists?
- **Risks**: What could go wrong? What's uncertain?

## Exit Guard
You can answer ALL of these:
1. What is the goal of this task?
2. Which files will change and why?
3. What patterns should new code follow?
4. What tests exist and what testing patterns should I use?

If you can't answer any of them, keep reading. Don't guess.

## Common Traps
- **Skimming**: Reading file names instead of file contents
- **Assumption**: "I know how this probably works" — read it anyway
- **Scope creep in analysis**: Reading everything in the repo. Focus on what the spec references.
- **Moving on too early**: If you find yourself designing changes while still reading, note the idea but finish reading first
