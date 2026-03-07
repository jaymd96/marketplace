---
name: rethink
description: "Step back from a failing approach. Diagnose why it failed, identify what was wrong, propose alternatives. Use when REFINE has looped 3+ times on the same issue."
---

# rethink

The current approach is not working. Stop fixing symptoms and question the
approach itself. This is an escalation from the REFINE loop — if you're here,
targeted fixes have failed repeatedly.

## Steps

1. **Stop all implementation.** Do not make another fix attempt. The pattern
   of fix-fail-fix-fail is the signal that something deeper is wrong.

2. **Write a diagnosis.** Answer these three questions concretely:

   a. **"My approach failed because ___."**
      Not "the test fails" — why does the test fail? What assumption was wrong?

   b. **What category of failure is this?**
      - Misunderstood the spec (built the wrong thing)
      - Wrong abstraction (right behavior, wrong structure)
      - Missing dependency (need something that doesn't exist yet)
      - Wrong test strategy (tests are testing the wrong thing)
      - Environmental issue (config, version, platform)
      - Spec is unclear or contradictory (not your fault — flag it)

   c. **What evidence shows the approach is wrong?**
      Not just that a test fails — what pattern in the failures reveals the
      structural problem? Quote specific error messages or behaviors.

3. **Preserve the failed attempt.** Do not delete code. It's useful context.
   If needed, comment it out or move it to a scratch file. Future sessions
   should see what was tried and why it didn't work.

4. **Choose the recovery path:**

   - **Design was wrong** — the change list doesn't solve the problem.
     Go back to /design with the new understanding of why the first design
     failed. The diagnosis becomes input to the redesign.

   - **Understanding was wrong** — you misread the spec or the codebase.
     Go back to /understand. Re-read the specific parts that were
     misunderstood. The diagnosis tells you what to focus on.

   - **Spec is unclear or wrong** — the spec itself has a gap or contradiction.
     Note the issue explicitly. Flag it for human review. Do not guess what
     the spec meant — document the ambiguity and move on to other tasks
     if possible.

5. **Propose the alternative concretely.** Don't say "try something else."
   State specifically:
   - What the new approach would be
   - Why it avoids the failure mode of the old approach
   - What risks the new approach introduces

6. **Document the rethink.** Write a note (in progress notes or as a comment)
   so future sessions know:
   - What was tried
   - Why it failed
   - What the alternative is
   - Don't repeat this approach

## Anti-patterns

- **Rethinking too early.** If you haven't tried 3 targeted fixes, you're
  not in RETHINK territory — go back to REFINE.
- **Rethinking without diagnosis.** Switching approaches randomly is worse
  than persisting. The diagnosis is mandatory.
- **Deleting the failed attempt.** That code is information. Keep it.
