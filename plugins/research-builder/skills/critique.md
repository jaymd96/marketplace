---
name: critique
description: "Stress-test a line of reasoning for logical soundness. Use when the user says 'does this argument work', 'check this proof', 'what is wrong with this', 'play devil's advocate', 'what am I missing', 'is this sound', 'poke holes in this', or 'is this valid'."
---

# critique

Use the logic-checker subagent for thorough analysis, or critique inline for
quick checks. Follow the methodology in `system/workflows/critique.md` for
specific techniques:

- Counterexample search (boundary, degenerate, adversarial cases)
- Assumption audit (stated and hidden)
- Proof strategy stress test
- Scope check (too strong? too weak?)
- Novelty check (is this known?)

Present findings with a clear verdict: sound, fixable (what to fix), or
unsound (fundamental issue). Always propose fixes when possible.
