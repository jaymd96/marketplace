# Mode: Validation

You're verifying the complete solution. Three passes, all must pass.

## When to Enter
- All planned units are implemented and individually checked
- After a REFINE (re-run validation after fixing an issue)

## Entry Guard
Every unit in the change list has been built and its individual CHECK passed.

## The Three Passes

### Pass 1 — Correctness
Run the full test suite.

```bash
# Use the test command from .codecraft.local.md, or default:
python3 -m pytest tests/ -x -q --timeout=30
```

**Pass criteria:** All tests pass. Zero failures, zero errors.

**If it fails:**
- Read the failure. Is it your code or a pre-existing failure?
- If pre-existing (was failing before your changes): note it, continue
- If caused by your changes: go to REFINE
- If unclear: check `git stash`, run tests, `git stash pop` — did it fail before?

### Pass 2 — Compliance
Run all enforcement commands from `.codecraft.local.md`.

```bash
# Typical enforcement commands:
ruff check <source_dir>
ruff format --check <source_dir>
# Project-specific ratchet checks
```

**Pass criteria:** No new violations. Existing baselines are OK.

**If it fails:**
- Linter errors: fix them (usually auto-fixable with `ruff check --fix`)
- Format errors: run the formatter
- Ratchet violations: you introduced a violation the project doesn't allow

### Pass 3 — Quality (Self-Review)
Read the complete diff. Be your own reviewer.

```bash
git diff  # or git diff --cached if staged
```

Check:
- [ ] Implementation matches spec intent
- [ ] No changes outside the planned scope
- [ ] No debug code (print, breakpoint, commented-out code)
- [ ] No dead code (unused imports, unreachable branches)
- [ ] Naming consistent with codebase
- [ ] No hardcoded values that should be configurable
- [ ] No security issues
- [ ] Tests test behavior, not implementation details

**Pass criteria:** You would approve this as a reviewer.

## After All Three Pass
Transition to delivery mode. The code is ready to ship.

## Recovery: REFINE
A specific pass failed. Fix it.

1. Identify the specific failure (which test? which lint rule? which quality issue?)
2. Hypothesize the root cause
3. Make a targeted fix (construction mode, single unit)
4. Re-run ALL three passes (not just the one that failed)

**Escalation:** If REFINE loops 3+ times on the same issue: RETHINK.

## Common Traps
- **Skipping passes**: "Tests pass, good enough" — Run all three.
- **Partial re-validation**: After fixing a lint issue, only re-running lint. Run all three.
- **Ignoring quality pass**: The self-review catches what automated checks miss.
- **Premature shipping**: Committing before all three passes are green.
