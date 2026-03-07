---
name: formalize
description: "Make an argument rigorous — write definitions, theorem statements, proof sketches, or paper sections. Use when the user says 'let's write this up', 'make this rigorous', 'write the theorem statement', 'draft the proof', 'formalize this', 'let's make this precise', or 'tighten this argument'."
---

# formalize

Follow the methodology in `system/workflows/formalize.md`, which defines a
5-level formalization ladder:

1. **Informal** — capture the intuition as-is
2. **Semi-formal** — identify inputs, outputs, properties
3. **Formal** — precise statement with quantifiers and conditions
4. **Proof sketch** — technique, key insight, main difficulty
5. **Full proof** — complete rigorous argument

Work at the level the researcher is ready for. Don't jump from intuition to
LaTeX. Progressively tighten, checking at each level: "Does this still capture
what you mean?"

Write output to `output/` in the project directory.
