# Mode: Construction

You're writing code. One unit at a time with checks.

## When to Enter
- After planning, when you have a concrete change list
- After a targeted fix during REFINE

## Entry Guard
You have a numbered change list from planning mode.

## The Build Loop

For each unit in the plan:

### 1. READ
Read the file(s) you're about to modify. Every time. Even if you just read them in analysis.
The code may have changed (especially in multi-agent setups).

### 2. CHANGE
Make ONE logical change. Not two changes. Not "while I'm here, let me also..."

Rules:
- Follow the patterns you identified in analysis
- Match existing naming conventions
- Match existing error handling patterns
- Add type hints if the codebase uses them
- Keep line length within project conventions
- Don't add comments unless the logic is genuinely non-obvious
- Don't refactor adjacent code

### 3. CHECK
Quick-verify this unit using the verification command from your plan.

If the check passes: move to the next unit.
If the check fails: FIX.

### 4. FIX (if CHECK failed)
- Read the error carefully. What does it actually say?
- Identify the root cause — don't guess
- Make a targeted fix — change only what's needed
- Re-CHECK

If the same check fails 3 times: RETHINK. The unit design is wrong.

## Budget-Aware Behavior

| Budget remaining | Behavior |
|-----------------|----------|
| > 70% | Normal — full iteration through all units |
| 30-70% | Finish current unit, then validate: ship what you have |
| < 30% | HANDOFF now — commit what works, write progress note |
| < 10% | Emergency — `git add`, commit, stuck note, EXIT |

## Common Traps
- **One-shotting**: Writing all units at once, then testing. Build one, check one.
- **Wishful fixing**: Changing random things until tests pass. Identify root cause first.
- **Scope creep**: "While I'm in this file, let me also refactor..." — Don't.
- **Skipping CHECK**: "I'm pretty sure this works" — Run the check.
- **Over-engineering**: Adding error handling for impossible scenarios, creating abstractions for one-time use.
