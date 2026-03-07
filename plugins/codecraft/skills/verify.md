---
name: verify
description: "Run the full three-pass quality gate after implementation is complete. Use after all planned units are built and individually checked."
---

# verify

Three-pass quality gate. All passes must succeed before the task can ship.
Use the verifier subagent if available; otherwise run directly.

## Pass 1 — Correctness

Run the project's test command from `.codecraft.local.md`. Default:

```
python3 -m pytest tests/ -x -q
```

**Gate:** All tests pass. Zero failures, zero errors.

If any test fails, stop. Do not proceed to Pass 2. Identify the failure:
- Is it a test you wrote? Fix the test or the implementation.
- Is it a pre-existing failure? Verify it fails on main too. If so, note
  it and continue. If not, your change broke it — fix it.
- Is it flaky? Run it again. If it passes on retry, note it but proceed.

## Pass 2 — Compliance

Run all enforcement commands from `.codecraft.local.md`. Default:

```
ruff check .
ruff format --check .
```

Run any ratchet scripts defined in `ratchet_scripts` config.

**Gate:** No new violations. Existing baselines are acceptable — you are not
responsible for pre-existing lint debt unless the spec says otherwise.

If violations exist in files you touched, fix them. If violations are in
files you didn't touch, ignore them.

## Pass 3 — Quality (self-review)

Read the complete diff:
```
git diff
```
Or if changes are staged: `git diff --cached`

Check against each criterion:

- **Spec match:** Does the implementation satisfy every requirement in the spec?
  Walk through acceptance criteria one by one.
- **Scope creep:** Any changes beyond what was planned in /design? If so,
  revert them or justify why they're necessary.
- **Debug artifacts:** Remove print statements, commented-out code, TODO
  placeholders that should be real code, hardcoded test values.
- **Dead code:** Functions or imports added but never used.
- **Naming consistency:** Do new names follow existing codebase conventions?
  Check against patterns identified in /understand.
- **Reviewer test:** Would a competent reviewer approve this diff? If you
  hesitate, identify why.

**Gate:** All criteria satisfied. No issues found, or all issues resolved.

## After Verification

- **All 3 passes succeeded:** Proceed to /handoff for delivery.
- **Any pass failed:** Return to construction mode. Make a targeted fix for
  the specific failure. Then re-run /verify from Pass 1 (not just the
  failing pass — a fix can introduce regressions).
- **Same failure 3+ times:** Escalate to /rethink. The approach is wrong.
