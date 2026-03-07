---
name: verify
description: "Run the full four-pass quality gate: correctness, compliance, review, and governance audit on new code. Use after all planned units are built and individually checked."
---

# verify

Four-pass quality gate. All passes must succeed before the task can ship.

## Pass 1 — Correctness

Run the project's test command from `.codecraft.local.md`. Default:

```
python3 -m pytest tests/ -x -q
```

Use the `codecraft:verifier` agent to keep verbose output out of the main
conversation.

**Gate:** All tests pass. Zero failures, zero errors.

If any test fails, stop. Do not proceed to Pass 2. Identify the failure:
- Test you wrote? Fix the test or the implementation.
- Pre-existing failure? Verify it fails on main too (`git stash`, test, `git stash pop`).
- Flaky? Run again. Note if it passes on retry.
- Complex failure? Use the `codecraft:diagnoser` agent for root cause analysis.

## Pass 2 — Compliance

Run all enforcement commands from `.codecraft.local.md`. Default:

```
ruff check .
ruff format --check .
```

**Gate:** No new violations in files you touched. Existing baselines are
acceptable.

## Pass 3 — Quality (parallel review)

Launch **3 parallel reviewer agents** (`codecraft:reviewer`), each examining
a different dimension:

- **Reviewer 1 — Spec compliance:** Every requirement implemented? No scope
  creep? Nothing missed?
- **Reviewer 2 — Codebase conventions:** Patterns match? Naming consistent?
  Imports organized the same way?
- **Reviewer 3 — Code quality + tests:** No dead code? No debug artifacts?
  Error handling correct? Tests cover behavior and edge cases?

Reviewers use **>=80% confidence threshold** — only issues they're confident
about make the report. This eliminates nitpicks and false positives.

Consolidate findings by severity:
- **Critical (>=95% confidence):** Must fix before shipping
- **Important (80-94% confidence):** Should fix, discuss if disagreement

**Gate:** No critical issues. Important issues resolved or justified.

## Pass 4 — Governance (audit new code)

Run **3 parallel auditor agents** (`codecraft:auditor`) scoped to **only the
files you created or modified** (use `git diff --name-only` to get the list).

- **Auditor 1 — Group A (Architecture):** Check new code for pure imports,
  boundary violations, ad-hoc globals, side effects in wrong layers.
- **Auditor 2 — Group B (Type Safety):** Check new code for missing type
  annotations, mutable data where frozen is appropriate, bare exception catches.
- **Auditor 3 — Group C (Tooling):** Check new tests are properly layered,
  no dynamic magic introduced, dependencies properly specified.

Scope the audit to changed files: "Audit only these files against Group X
rules: [file list]. Report violations in the new code, not pre-existing issues."

**Gate:** No violations in new code. New code must not introduce governance
debt — it should follow the 12 rules even if the rest of the codebase doesn't.

Pre-existing violations in untouched files are not your responsibility.
Violations in files you modified but didn't introduce are noted but non-blocking.

## After Verification

- **All 4 passes succeeded:** Proceed to /handoff for delivery.
- **Any pass failed:** Return to construction. Make a targeted fix for the
  specific failure. Then re-run /verify from Pass 1 (a fix can introduce
  regressions).
- **Same failure 3+ times:** Escalate to /rethink. The approach is wrong.
