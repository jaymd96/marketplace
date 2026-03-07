# review

Audit the specification for quality across 5 dimensions.

## Trigger

- "Is the spec ready?"
- "Review the spec"
- "How complete is the specification?"
- The spec has draft content and needs quality assessment

## What to do

Use the spec-reviewer subagent (defined in `agents/spec-reviewer.md`) to
perform a full quality audit in an isolated context.

The reviewer assesses five dimensions:

1. **Completeness** — every feature, entity, and decision represented
2. **Consistency** — no internal contradictions
3. **Clarity** — implementable by someone not in the room
4. **Testability** — every requirement verifiable
5. **Organization** — structure logical, cross-references valid

Each dimension gets a 1-5 score. The report includes specific issues and
top 3 priorities for improvement.

Present the report to the human. Address critical issues before delivery.
