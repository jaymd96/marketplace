---
name: coverage
description: "Show feature exploration coverage status across all features. Use when the user says 'what have we explored', 'which features need more work', 'show me coverage', 'what is missing', 'how complete are we', or 'feature status'."
---

# coverage

Scan `human/features/` directories in the project. For each feature:

1. Count lines in `raw-notes.md` (rough depth proxy)
2. Count open questions in `questions.md`
3. Count resolved questions in `resolved.md`
4. Assess completion checklist status (core behavior, edge cases, interactions, performance, security)
5. Determine status: NOT_STARTED / PARTIAL / COMPLETE

Output a table with all features, status, note count, question counts.
Recommend which feature to explore next and why.

If `scripts/coverage-report.sh` is available, run it for the mechanical scan.
