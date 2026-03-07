# coverage

Show feature exploration coverage status.

## Trigger

- "What have we explored?"
- "Which features need more work?"
- "Show me coverage"
- "What's missing?"

## What to do

Scan `human/features/` directories in the project. For each feature:

1. Count lines in `raw-notes.md` (proxy for depth)
2. Count open questions in `questions.md`
3. Count resolved questions in `resolved.md`
4. Assess completion checklist status (core behavior, edge cases, interactions, performance, security)
5. Determine status: NOT_STARTED / PARTIAL / COMPLETE

Output a table showing all features with status, note count, question counts.
Highlight which feature needs attention next and why.

If `scripts/coverage-report.sh` is available, run it for the mechanical scan.
