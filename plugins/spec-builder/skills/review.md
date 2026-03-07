---
name: review
description: "Review spec quality using parallel reviewer agents across 5 dimensions with confidence scoring. Use when the user says 'is the spec ready', 'review the spec', 'how complete is the specification', or 'quality check'."
---

# review

Launch **3 parallel spec-reviewer agents** (`spec-builder:spec-reviewer`),
each examining different quality dimensions:

- **Reviewer 1 — Completeness + organization:** Everything represented?
  Structure logical? No orphan sections?
- **Reviewer 2 — Consistency + clarity:** No contradictions? Implementable
  by someone not in the room? No ambiguous quantifiers?
- **Reviewer 3 — Testability + implementability:** Every requirement
  verifiable? Test levels identifiable? Performance thresholds measurable?

All reviewers use **>=80% confidence threshold** — only high-confidence
issues are surfaced.

After all agents return, **synthesize findings** into a consolidated report:

- Group by severity: Critical (>=95% confidence) then Important (80-94%)
- Score each dimension 1-5
- Provide overall verdict: PASS or NEEDS WORK ON: [list]
- List top 3 priorities for improvement

Present the report to the user. Address critical issues before delivery.

For a deeper, rubric-based assessment, use `/audit` instead.
