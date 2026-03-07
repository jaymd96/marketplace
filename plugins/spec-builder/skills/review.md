---
name: review
description: "Audit the specification for quality across 5 dimensions: completeness, consistency, clarity, testability, organization. Use when the user says 'is the spec ready', 'review the spec', 'how complete is the specification', 'audit the spec', or 'quality check'."
---

# review

Use the spec-reviewer subagent (defined in `agents/spec-reviewer.md`) to
perform a full quality audit in an isolated context.

The reviewer assesses five dimensions, each scored 1-5: completeness,
consistency, clarity, testability, and organization. Returns specific
issues and top 3 priorities for improvement.

Present the report to the human. Address critical issues before delivery.
