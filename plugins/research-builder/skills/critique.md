# critique

Stress-test a line of reasoning for logical soundness.

## Trigger

- "Does this argument work?"
- "Check this proof"
- "What's wrong with this?"
- "Play devil's advocate"
- "What am I missing?"

## What to do

Use the logic-checker subagent for thorough analysis, or critique inline for
quick checks. Apply the techniques from `workflows/critique.md`:

- Counterexample search (boundary, degenerate, adversarial cases)
- Assumption audit (stated and hidden)
- Proof strategy stress test
- Scope check (too strong? too weak?)
- Novelty check (is this known?)

Present findings with a clear verdict: sound, fixable (what to fix), or
unsound (fundamental issue). Always propose fixes when possible.
